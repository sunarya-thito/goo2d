import 'dart:io';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rootPath = p.normalize(p.absolute(Directory.current.path));
  final libPath = p.join(rootPath, 'lib');
  final examplePath = p.join(rootPath, 'example', 'lib');

  group('Documentation Validation', () {
    final dartFiles = Glob('**/*.dart');
    final files =
        <String>[
              ...dartFiles.listSync(root: libPath).map((e) => e.path),
              ...dartFiles.listSync(root: examplePath).map((e) => e.path),
            ]
            .where(
              (path) =>
                  !path.contains('.freezed.dart') && !path.contains('.g.dart'),
            )
            .toList();

    for (final filePath in files) {
      final relativePath = p.relative(filePath, from: rootPath);

      group('File: $relativePath', () {
        final result = parseFile(
          path: filePath,
          featureSet: FeatureSet.latestLanguageVersion(),
        );

        final collector = _DocCollector();
        result.unit.accept(collector);

        for (final decl in collector.declarations) {
          final declName = _getDeclarationName(decl);
          final location = result.lineInfo.getLocation(decl.offset);

          test('Line ${location.lineNumber}: $declName', () {
            final validator = _DocValidator(result, rootPath, filePath);
            validator.checkDeclaration(decl);

            if (validator.errors.isNotEmpty) {
              fail(validator.errors.join('\n\n'));
            }
          });
        }
      });
    }
  });
}

String _getDeclarationName(Declaration node) {
  if (node is ClassDeclaration) return 'class ${node.name.lexeme}';
  if (node is MethodDeclaration) return 'method ${node.name.lexeme}';
  if (node is FunctionDeclaration) return 'function ${node.name.lexeme}';
  if (node is ConstructorDeclaration) {
    return 'constructor ${node.returnType}${node.name != null ? '.${node.name!.lexeme}' : ''}';
  }
  if (node is FieldDeclaration) {
    return 'fields ${node.fields.variables.map((v) => v.name.lexeme).join(', ')}';
  }
  if (node is EnumDeclaration) return 'enum ${node.name.lexeme}';
  return 'declaration';
}

class _DocValidator {
  final ParseStringResult result;
  final String rootPath;
  final String filePath;
  final List<String> errors = [];

  _DocValidator(this.result, this.rootPath, this.filePath);

  void checkDeclaration(Declaration node) {
    final doc = node.documentationComment;
    final isPublic = _isPublic(node);
    final isOverride = _isOverride(node);

    if (isOverride && doc != null) {
      _addError(
        doc,
        'Members annotated with @override should not have documentation; they inherit from the base.',
      );
    }

    if (!isPublic || isOverride) return;

    if (doc == null) {
      bool requiresDoc = false;
      if (node is ClassDeclaration) requiresDoc = true;
      if (node is MethodDeclaration && node.isSetter) requiresDoc = true;
      if (node is MethodDeclaration && !node.name.lexeme.startsWith('_')) {
        if (!node.isGetter) requiresDoc = true;
      }

      if (requiresDoc) {
        _addError(node, 'Missing documentation for public member.');
      }
      return;
    }

    final tokens = doc.tokens.map((t) => t.lexeme).toList();
    final fullText = tokens.join('\n');
    final rawLines = tokens.map((l) {
      var s = l.trim();
      if (s.startsWith('///')) {
        s = s.substring(3).trim();
      } else if (s.startsWith('/**')) {
        s = s.replaceAll(RegExp(r'^\s*\*+', multiLine: true), '').trim();
      }
      return s;
    }).toList();
    final rawText = rawLines.join('\n');

    // Rule: Goo2dDocSummary
    final firstLine = rawLines.firstOrNull ?? '';
    if (firstLine.isNotEmpty && !firstLine.endsWith('.')) {
      _addError(
        doc,
        'Documentation must start with a concise summary sentence ending in a period.',
      );
    }

    // Rule: Goo2dDocDepth
    final paragraphs = rawText
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().length > 10)
        .toList();
    bool isTrivial = true;
    if (node is ClassDeclaration) isTrivial = false;
    if (node is MethodDeclaration && !node.name.lexeme.startsWith('_')) {
      if (!node.isGetter) isTrivial = false;
    }

    if (!isTrivial && paragraphs.length < 2) {
      _addError(
        doc,
        'Non-trivial members require at least two paragraphs (Why and How). Found ${paragraphs.length}.',
      );
    }

    // Rule: Goo2dDocParams
    _checkParams(node, doc, rawText);

    // Rule: Goo2dDocNoPlaceholders
    if (fullText.toUpperCase().contains('TODO') ||
        fullText.toUpperCase().contains('FIXME') ||
        fullText.contains('...')) {
      _addError(
        doc,
        'Documentation contains placeholders like TODO, FIXME, or dots.',
      );
    }

    // Rule: Goo2dDocGenerics & Escaping
    _checkGenerics(doc, fullText);

    // Rule: Goo2dDocLinks
    if (node is ClassDeclaration) {
      final linkRegex = RegExp(r'\[[A-Z]\w+\]');
      if (!linkRegex.hasMatch(rawText)) {
        _addError(
          doc,
          'Classes must include at least one cross-link [Class] to related systems.',
        );
      }
    }

    // Rule: Goo2dDocNoGetterParams
    if (node is MethodDeclaration && node.isGetter) {
      if (fullText.contains('* [')) {
        _addError(
          doc,
          'Getters cannot have parameter documentation (* [name]).',
        );
      }
    }

    // Rule: Advanced Code Example Validation
    _checkExamples(node, doc, fullText);
  }

  void _checkParams(Declaration node, Comment doc, String rawText) {
    FormalParameterList? parameters;
    if (node is MethodDeclaration) {
      parameters = node.parameters;
    } else if (node is ConstructorDeclaration) {
      parameters = node.parameters;
    } else if (node is FunctionDeclaration) {
      parameters = node.functionExpression.parameters;
    }

    if (parameters == null || parameters.parameters.isEmpty) return;

    for (final param in parameters.parameters) {
      final name = param.name?.lexeme;
      if (name == null || name.startsWith('_')) continue;

      final regex = RegExp('\\* \\[$name\\]: \\S');
      if (!regex.hasMatch(rawText)) {
        _addError(
          doc,
          'Parameter [$name] must be documented with "* [$name]: explanation".',
        );
      }
    }
  }

  void _checkGenerics(Comment doc, String fullText) {
    final lines = fullText.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final literalLess = RegExp(r'(?<!&|\\)<');
      final literalGreater = RegExp(r'(?<!&|\\|-)>(?! )');

      if (literalLess.hasMatch(line)) {
        _addError(
          doc,
          'Direct use of "<" is forbidden; use "&lt;" or "\\<" instead. Line ${i + 1}: $line',
        );
      }
      if (literalGreater.hasMatch(line)) {
        if (!line.contains('->') && !line.contains('=>')) {
          _addError(
            doc,
            'Direct use of ">" is forbidden; use "&gt;" or "\\>" instead. Line ${i + 1}: $line',
          );
        }
      }
    }
  }

  void _checkExamples(Declaration node, Comment doc, String fullText) {
    if (node is! ClassDeclaration) return;

    final codeBlockRegex = RegExp(r'```dart([\s\S]*?)```');
    final matches = codeBlockRegex.allMatches(fullText);

    if (matches.isEmpty) {
      _addError(doc, 'Public classes must include a ```dart code example.');
      return;
    }

    for (final match in matches) {
      final code = match.group(1) ?? '';
      if (code.trim().isEmpty) continue;

      final result = _validateSnippet(code);
      if (!result.success) {
        _addError(
          doc,
          'Code example failed validation.\n\nErrors:\n${result.errors.join('\n')}\n\nSnippet:\n$code',
        );
      }
    }
  }

  _SnippetResult _validateSnippet(String code) {
    final unescapedCode = code
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(r'\<', '<')
        .replaceAll(r'\>', '>');

    // 1. Try as a compilation unit (top-level members)
    try {
      final parseResult = parseString(
        content: unescapedCode,
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      bool hasErrors = parseResult.errors.any(
        (e) => e.severity.name == 'ERROR',
      );
      if (!hasErrors) return _SnippetResult(true, []);

      // 2. Try as a statement (wrapped in a function)
      // We can't use parseString for statements easily, so we wrap it.
      final wrappedCode = 'void _() {\n$unescapedCode\n}';
      final wrappedResult = parseString(
        content: wrappedCode,
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      bool wrappedHasErrors = wrappedResult.errors.any(
        (e) => e.severity.name == 'ERROR',
      );
      if (!wrappedHasErrors) return _SnippetResult(true, []);

      return _SnippetResult(false, [
        'Compilation Unit Errors: ${parseResult.errors.map((e) => e.message).join(', ')}',
        'Function Wrapped Errors: ${wrappedResult.errors.map((e) => e.message).join(', ')}',
      ]);
    } catch (e) {
      return _SnippetResult(false, ['Parsing failed: $e']);
    }
  }

  bool _isPublic(Declaration node) {
    if (node is ClassDeclaration) return !node.name.lexeme.startsWith('_');
    if (node is MethodDeclaration) return !node.name.lexeme.startsWith('_');
    if (node is FunctionDeclaration) return !node.name.lexeme.startsWith('_');
    if (node is ConstructorDeclaration) return true;
    if (node is FieldDeclaration) {
      return node.fields.variables.any((v) => !v.name.lexeme.startsWith('_'));
    }
    return true;
  }

  bool _isOverride(Declaration node) {
    return node.metadata.any((m) => m.name.name == 'override');
  }

  void _addError(AstNode node, String message) {
    final lineInfo = result.lineInfo;
    final location = lineInfo.getLocation(node.offset);
    errors.add(
      '$filePath:${location.lineNumber}:${location.columnNumber}: $message',
    );
  }
}

class _DocCollector extends RecursiveAstVisitor<void> {
  final List<Declaration> declarations = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    declarations.add(node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    declarations.add(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    declarations.add(node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    declarations.add(node);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    declarations.add(node);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    declarations.add(node);
    super.visitEnumDeclaration(node);
  }
}

class _SnippetResult {
  final bool success;
  final List<String> errors;
  _SnippetResult(this.success, this.errors);
}
