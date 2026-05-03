import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'dart:async';

Future<void> _analyzeQueue = Future.value();
Future<T> _synchronized<T>(Future<T> Function() action) async {
  final completer = Completer<void>();
  final previous = _analyzeQueue;
  _analyzeQueue = completer.future;
  await previous;
  try {
    return await action();
  } finally {
    completer.complete();
  }
}

void main() {
  final rootPath = p.normalize(p.absolute(Directory.current.path));
  final libPath = p.join(rootPath, 'lib');
  final examplePath = p.join(rootPath, 'example', 'lib');

  group('Documentation Validation', () {
    final specificFile = Platform.environment['DOC_FILE'];
    final List<String> files;

    if (specificFile != null) {
      final fullPath = p.normalize(p.absolute(specificFile));
      if (!File(fullPath).existsSync()) {
        throw Exception(
          'File not found: $fullPath (from DOC_FILE=$specificFile)',
        );
      }
      files = [fullPath];
    } else {
      final dartFiles = Glob('**/*.dart');
      files =
          <String>[
                ...dartFiles.listSync(root: libPath).map((e) => e.path),
                ...dartFiles.listSync(root: examplePath).map((e) => e.path),
              ]
              .where(
                (path) =>
                    !path.contains('.freezed.dart') &&
                    !path.contains('.g.dart'),
              )
              .toList();
    }

    for (final filePath in files) {
      final relativePath = p.relative(filePath, from: rootPath);

      group('File: $relativePath', () {
        final result = parseFile(
          path: filePath,
          featureSet: FeatureSet.latestLanguageVersion(),
        );

        final collector = _DocCollector();
        result.unit.accept(collector);

        for (final node in collector.nodes) {
          final nodeName = _getNodeName(node);
          final location = result.lineInfo.getLocation(node.offset);

          test('Line ${location.lineNumber}: $nodeName', () async {
            final validator = _DocValidator(result, rootPath, filePath);
            await validator.validate(node);

            if (validator.errors.isNotEmpty) {
              for (final err in validator.errors) {
                print('DOC_ERROR: $err');
              }
              fail(validator.errors.join('\n\n'));
            }
          });
        }
      });
    }
  });
}

String _getNodeName(AnnotatedNode node) {
  if (node is LibraryDirective) return 'library';
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
  if (node is MixinDeclaration) return 'mixin ${node.name.lexeme}';
  if (node is ExtensionDeclaration)
    return 'extension ${node.name?.lexeme ?? ''}';
  return 'declaration';
}

class _DocValidator {
  final ParseStringResult result;
  final String rootPath;
  final String filePath;
  final List<String> errors = [];

  _DocValidator(this.result, this.rootPath, this.filePath);

  Future<void> validate(AnnotatedNode node) async {
    final doc = node.documentationComment;
    await _validateNode(node, doc);
  }

  Future<void> _validateNode(AnnotatedNode node, Comment? doc) async {
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
      if (node is MixinDeclaration) requiresDoc = true;
      if (node is EnumDeclaration) requiresDoc = true;
      if (node is ExtensionDeclaration) requiresDoc = true;
      if (node is FunctionDeclaration && !node.name.lexeme.startsWith('_')) {
        requiresDoc = true;
      }
      if (node is LibraryDirective) requiresDoc = true;
      if (node is MethodDeclaration && node.isSetter) requiresDoc = true;
      if (node is FieldDeclaration &&
          !node.fields.variables.first.name.lexeme.startsWith('_')) {
        requiresDoc = true;
      }
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
        s = s.substring(3);
      } else if (s.startsWith('/**')) {
        s = s.replaceAll(RegExp(r'^\s*\*+', multiLine: true), '');
      }
      return s.trim(); // Trim each line AFTER removing prefix
    }).toList();
    final rawText = rawLines.join('\n');

    // Rule: Goo2dDocSummary
    final firstContentLine = rawLines.firstWhere(
      (l) => l.isNotEmpty,
      orElse: () => '',
    );
    if (firstContentLine.isNotEmpty && !firstContentLine.endsWith('.')) {
      _addError(
        doc,
        'Documentation must start with a concise summary sentence ending in a period.',
      );
    }

    // Rule: Goo2dDocDepth
    // Improved splitting: split by one or more blank lines (or lines with only whitespace)
    final paragraphs = rawText
        .split(RegExp(r'\n\s*\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p.length > 5)
        .toList();
    bool isTrivial = true;
    if (node is ClassDeclaration ||
        node is EnumDeclaration ||
        node is MixinDeclaration ||
        node is ExtensionDeclaration) {
      isTrivial = false;
    } else if (node is ConstructorDeclaration) {
      if (node.name == null || !node.name!.lexeme.startsWith('_'))
        isTrivial = false;
    } else if (node is MethodDeclaration) {
      if (!node.name.lexeme.startsWith('_')) isTrivial = false;
    } else if (node is FieldDeclaration) {
      final hasPublic = node.fields.variables.any(
        (v) => !v.name.lexeme.startsWith('_'),
      );
      if (hasPublic) isTrivial = false;
    } else if (node is TopLevelVariableDeclaration) {
      final hasPublic = node.variables.variables.any(
        (v) => !v.name.lexeme.startsWith('_'),
      );
      if (hasPublic) isTrivial = false;
    } else if (node is FunctionDeclaration) {
      if (!node.name.lexeme.startsWith('_')) isTrivial = false;
    }

    if (!isTrivial && paragraphs.length < 2) {
      _addError(
        doc,
        'Non-trivial members require at least two paragraphs (Why and How). Found ${paragraphs.length}. Paragraphs: ${paragraphs.join(' | ')}',
      );
    }

    // Rule: Goo2dDocNoExplicitWhyHow
    if (RegExp(r'\b(Why|How)\s*:').hasMatch(fullText)) {
      _addError(
        doc,
        'Do not use explicit "Why:" or "How:" labels. Integrate these explanations naturally into paragraphs.',
      );
    }

    // Rule: Goo2dDocParams
    _checkParams(node, doc, rawText);

    // Rule: Goo2dDocNoPlaceholders
    if (fullText.toUpperCase().contains('TODO') ||
        fullText.toUpperCase().contains('FIXME') ||
        RegExp(r'\.\.\.(?!\w)').hasMatch(fullText)) {
      _addError(
        doc,
        'Documentation contains placeholders like TODO, FIXME, or dots.',
      );
    }

    // Rule: Goo2dDocNoNodoc
    if (fullText.contains('@nodoc')) {
      _addError(
        doc,
        'The use of @nodoc is strictly forbidden. All public members must be fully documented.',
      );
    }

    // Rule: Goo2dDocGenerics & Escaping
    _checkGenerics(doc, fullText);

    // Rule: Goo2dDocLinks
    if (node is ClassDeclaration) {
      if (!rawText.contains('See also:')) {
        _addError(
          doc,
          'Classes must include a "See also:" section at the end with links to related systems.',
        );
      } else {
        final linkRegex = RegExp(r'\[[A-Z][\w\.]+\]');
        final seeAlsoIndex = rawText.indexOf('See also:');
        final seeAlsoText = rawText.substring(seeAlsoIndex);
        if (!linkRegex.hasMatch(seeAlsoText)) {
          _addError(
            doc,
            'The "See also:" section must contain at least one cross-link [Class].',
          );
        }
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
    await _checkExamples(node, doc, rawText);
  }

  void _checkParams(AnnotatedNode node, Comment doc, String rawText) {
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

      final regex = RegExp('\\*\\s+\\[$name\\]: \\S');
      if (!regex.hasMatch(rawText)) {
        _addError(
          doc,
          'Parameter [$name] must be documented with "* [$name]: explanation".',
        );
      }
    }
  }

  void _checkGenerics(Comment doc, String fullText) {
    final strippedText = fullText.replaceAll(RegExp(r'```dart[\s\S]*?```'), '');
    final lines = strippedText.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 1. Find all backtick regions
      final backtickMatches = RegExp(r'`[^`]*`').allMatches(line);
      final backtickRegions = backtickMatches
          .map((m) => [m.start, m.end])
          .toList();

      // Helper to check if a position is inside any backtick region
      bool isInsideBackticks(int pos) {
        return backtickRegions.any((r) => pos >= r[0] && pos < r[1]);
      }

      // Check for UNESCAPED < or > OUTSIDE backticks
      final literalLess = RegExp(r'(?<!&|\\)<');
      final literalGreater = RegExp(r'(?<!&|\\|-)>(?! )');

      for (final m in literalLess.allMatches(line)) {
        if (!isInsideBackticks(m.start)) {
          _addError(
            doc,
            'Direct use of "<" is forbidden outside of code blocks; use "&lt;" or "\\<" instead. Line ${i + 1}: $line',
          );
        }
      }

      for (final m in literalGreater.allMatches(line)) {
        if (!isInsideBackticks(m.start)) {
          if (!line.contains('->') && !line.contains('=>')) {
            _addError(
              doc,
              'Direct use of ">" is forbidden outside of code blocks; use "&gt;" or "\\>" instead. Line ${i + 1}: $line',
            );
          }
        }
      }

      // Check for ESCAPED \< or \> INSIDE backticks
      final escapedLess = RegExp(r'\\<');
      final escapedGreater = RegExp(r'\\>');

      for (final m in escapedLess.allMatches(line)) {
        if (isInsideBackticks(m.start)) {
          _addError(
            doc,
            'Escape character "\\" is forbidden for "<" inside code blocks. Line ${i + 1}: $line',
          );
        }
      }

      for (final m in escapedGreater.allMatches(line)) {
        if (isInsideBackticks(m.start)) {
          _addError(
            doc,
            'Escape character "\\" is forbidden for ">" inside code blocks. Line ${i + 1}: $line',
          );
        }
      }
    }
  }

  Future<void> _checkExamples(
    AnnotatedNode node,
    Comment doc,
    String fullText,
  ) async {
    if (node is LibraryDirective) {
      if (!fullText.contains('```dart')) {
        _addError(
          doc,
          'Library documentation must include a ```dart code example.',
        );
      }
      return;
    }
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

      final result = await _validateSnippet(code);
      if (!result.success) {
        _addError(
          doc,
          'Code example failed validation.\n\nErrors:\n${result.errors.join('\n')}\n\nSnippet:\n$code',
        );
      }
    }
  }

  Future<_SnippetResult> _validateSnippet(String code) async {
    final unescapedCode = code
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(r'\<', '<')
        .replaceAll(r'\>', '>');

    // 2. Semantic check (harden)
    // We create a temporary file that imports common libraries and the current file.
    final tempDir = Directory(
      p.join(rootPath, 'test', 'documentation', '.temp'),
    );
    if (!tempDir.existsSync()) tempDir.createSync(recursive: true);

    // Determine the import for the current file
    String currentFileImport = '';
    if (filePath.startsWith(p.join(rootPath, 'lib'))) {
      final content = File(filePath).readAsStringSync();
      if (content.trimLeft().startsWith('part of')) {
        // Find the library file. For now, we assume it's in the same directory or relative.
        final match = RegExp(r"part of\s+'([^']+)'").firstMatch(content);
        if (match != null) {
          final libraryFile = match.group(1)!;
          final libraryPath = p.normalize(
            p.join(p.dirname(filePath), libraryFile),
          );
          if (libraryPath.startsWith(p.join(rootPath, 'lib'))) {
            final relLibPath = p
                .relative(libraryPath, from: p.join(rootPath, 'lib'))
                .replaceAll('\\', '/');
            currentFileImport = "import 'package:goo2d/$relLibPath';";
          }
        }
      }

      if (currentFileImport.isEmpty) {
        final relativePath = p
            .relative(filePath, from: p.join(rootPath, 'lib'))
            .replaceAll('\\', '/');
        currentFileImport = "import 'package:goo2d/$relativePath';";
      }
    }

    final isExplicitlyTopLevel = unescapedCode.contains(
      RegExp(r'\b(class|enum|mixin|extension)\b'),
    );

    if (!isExplicitlyTopLevel) {
      final proceduralCode = _buildTestCode(
        currentFileImport,
        unescapedCode,
        true,
      );
      final proceduralResult = await _runAnalyze(
        proceduralCode,
        rootPath,
        tempDir,
      );
      if (proceduralResult.success) return proceduralResult;
    }

    final topLevelCode = _buildTestCode(
      currentFileImport,
      unescapedCode,
      false,
    );
    final topLevelResult = await _runAnalyze(topLevelCode, rootPath, tempDir);
    if (topLevelResult.success) return topLevelResult;

    // If we reach here, both failed (or just topLevel if isExplicitlyTopLevel)
    final errors = <String>[];
    if (!isExplicitlyTopLevel) {
      final proceduralCode = _buildTestCode(
        currentFileImport,
        unescapedCode,
        true,
      );
      final proceduralResult = await _runAnalyze(
        proceduralCode,
        rootPath,
        tempDir,
      );
      errors.add('Procedural Analysis Errors:');
      errors.addAll(proceduralResult.errors);
      errors.add('\nTop-Level Analysis Errors:');
    } else {
      errors.add(
        'Top-Level Analysis Errors (Procedural skipped for class/enum/etc):',
      );
    }
    errors.addAll(topLevelResult.errors);

    return _SnippetResult(false, errors);
  }

  String _buildTestCode(
    String currentFileImport,
    String code,
    bool wrapInMain,
  ) {
    final header =
        "import 'dart:ui' as ui;\n"
        "import 'dart:ui';\n"
        "import 'dart:typed_data';\n"
        "import 'package:flutter/material.dart';\n"
        "import 'package:flutter/gestures.dart';\n"
        "import 'package:flutter_soloud/flutter_soloud.dart' as soloud;\n"
        "import 'package:goo2d/goo2d.dart';\n"
        "$currentFileImport\n\n";

    if (wrapInMain) {
      return header + "void main() async {\n" + code + "\n}\n";
    } else {
      return header + code + "\n";
    }
  }

  Future<_SnippetResult> _runAnalyze(
    String fullCode,
    String rootPath,
    Directory tempDir,
  ) async {
    final tempFile = File(
      p.join(tempDir.path, 'snippet_${fullCode.hashCode}.dart'),
    );
    tempFile.writeAsStringSync(fullCode);

    try {
      final flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
      final res = await _synchronized(
        () async => Process.runSync(
          flutterCmd,
          ['analyze', '--no-pub', tempFile.path],
          workingDirectory: rootPath,
        ),
      );

      if (res.exitCode != 0) {
        final output = res.stdout.toString() + res.stderr.toString();

        final lines = output.split('\n');
        final issues = lines.where((line) {
          final isError = RegExp(
            r'^\s*error\b',
            caseSensitive: false,
          ).hasMatch(line);
          return isError;
        }).toList();

        if (issues.isNotEmpty) {
          final errorLines = issues
              .map((i) {
                final match = RegExp(r':(\d+):\d+').firstMatch(i);
                return match != null ? int.parse(match.group(1)!) : -1;
              })
              .where((l) => l > 0)
              .toSet();

          final sourceLines = fullCode.split('\n');
          final numberedSource = <String>[];
          for (var i = 0; i < sourceLines.length; i++) {
            final lineNum = i + 1;
            var line = '${lineNum.toString().padLeft(3)}: ${sourceLines[i]}';
            if (errorLines.contains(lineNum)) {
              line += ' // <--- PROBLEM AT THIS LINE HERE';
            }
            numberedSource.add(line);
          }

          return _SnippetResult(false, [
            'Found ${issues.length} semantic issues (Exit Code ${res.exitCode}):',
            ...issues,
            '\nFull Analysis Output:\n$output',
            '\nGenerated Code Source:\n${numberedSource.join('\n')}',
          ]);
        } else {
          // If all issues were ignored, it's a success
          return _SnippetResult(true, []);
        }
      }
      return _SnippetResult(true, []);
    } catch (e) {
      return _SnippetResult(false, ['Validation process failed: $e']);
    } finally {
      if (tempFile.existsSync()) tempFile.deleteSync();
    }
  }

  bool _isPublic(AnnotatedNode node) {
    // Check for @internal annotation
    bool isInternal(AnnotatedNode n) {
      return n.metadata.any((m) => m.name.name == 'internal');
    }

    if (isInternal(node)) return false;

    // If the node itself is private, it's not public.
    bool selfPublic = true;
    if (node is ClassDeclaration)
      selfPublic = !node.name.lexeme.startsWith('_');
    else if (node is MethodDeclaration)
      selfPublic = !node.name.lexeme.startsWith('_');
    else if (node is FunctionDeclaration)
      selfPublic = !node.name.lexeme.startsWith('_');
    else if (node is ConstructorDeclaration)
      selfPublic = true;
    else if (node is FieldDeclaration) {
      selfPublic = node.fields.variables.any(
        (v) => !v.name.lexeme.startsWith('_'),
      );
    } else if (node is EnumDeclaration) {
      selfPublic = !node.name.lexeme.startsWith('_');
    } else if (node is MixinDeclaration) {
      selfPublic = !node.name.lexeme.startsWith('_');
    } else if (node is ExtensionDeclaration) {
      selfPublic = node.name == null || !node.name!.lexeme.startsWith('_');
    }

    if (!selfPublic) return false;

    // Check parent visibility and internal annotation
    AstNode? parent = node.parent;
    while (parent != null) {
      if (parent is AnnotatedNode && isInternal(parent)) return false;
      if (parent is ClassDeclaration && parent.name.lexeme.startsWith('_'))
        return false;
      if (parent is MixinDeclaration && parent.name.lexeme.startsWith('_'))
        return false;
      if (parent is ExtensionDeclaration &&
          parent.name?.lexeme.startsWith('_') == true)
        return false;
      if (parent is EnumDeclaration && parent.name.lexeme.startsWith('_'))
        return false;
      parent = parent.parent;
    }

    return true;
  }

  bool _isOverride(AnnotatedNode node) {
    if (node is LibraryDirective) return false;
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
  final List<AnnotatedNode> nodes = [];

  @override
  void visitLibraryDirective(LibraryDirective node) {
    nodes.add(node);
    super.visitLibraryDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    nodes.add(node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    nodes.add(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    nodes.add(node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    nodes.add(node);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    nodes.add(node);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    nodes.add(node);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    nodes.add(node);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    nodes.add(node);
    super.visitExtensionDeclaration(node);
  }
}

class _SnippetResult {
  final bool success;
  final List<String> errors;
  _SnippetResult(this.success, this.errors);
}
