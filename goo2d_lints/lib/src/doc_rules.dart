import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// Hide LintCode from analyzer to avoid ambiguity with custom_lint_builder
import 'package:analyzer/error/error.dart' hide LintCode;

/// Base rule for Goo2D documentation standards.
abstract class Goo2dDocRule extends DartLintRule {
  const Goo2dDocRule({
    required super.code,
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      node.accept(_DocVisitor(this, reporter));
    });
  }

  void checkNode(AstNode node, ErrorReporter reporter);
}

class _DocVisitor extends RecursiveAstVisitor<void> {
  final Goo2dDocRule rule;
  final ErrorReporter reporter;

  _DocVisitor(this.rule, this.reporter);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    rule.checkNode(node, reporter);
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    rule.checkNode(node, reporter);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    rule.checkNode(node, reporter);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    rule.checkNode(node, reporter);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    rule.checkNode(node, reporter);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    rule.checkNode(node, reporter);
    super.visitEnumDeclaration(node);
  }
}

class Goo2dDocSummary extends Goo2dDocRule {
  const Goo2dDocSummary()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_summary',
            problemMessage: 'Documentation must start with a concise summary sentence ending in a period.',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! Declaration) return;
    final doc = node.documentationComment;
    if (doc == null) return;

    final firstLine = doc.tokens.firstOrNull?.lexeme ?? '';
    if (!firstLine.contains('.') && !firstLine.contains('///')) {
      reporter.atNode(doc, code);
    }
  }
}

class Goo2dDocDepth extends Goo2dDocRule {
  const Goo2dDocDepth()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_depth',
            problemMessage: 'Non-trivial members require at least two paragraphs (Why and How).',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! Declaration) return;
    
    // Skip overrides
    if (_isOverride(node)) return;

    final doc = node.documentationComment;

    // Only enforce depth for public classes and major methods/setters
    bool isTrivial = true;
    if (node is ClassDeclaration) isTrivial = false;
    if (node is MethodDeclaration && !node.name.lexeme.startsWith('_')) isTrivial = false;

    if (isTrivial) {
      if (doc != null) {
        // If it HAS a doc, check if it's actually trivial or just lazy
        final text = doc.tokens.map((t) => t.lexeme).join('\n');
        if (text.length < 20) return; // Very short doc is allowed for trivial
      } else {
        return;
      }
    }

    if (doc == null) {
      // For non-trivial members, missing documentation is a depth violation
      reporter.atNode(node, code);
      return;
    }

    final rawText = doc.tokens.map((t) {
      String l = t.lexeme.trim();
      if (l.startsWith('///')) {
        l = l.substring(3);
      } else if (l.startsWith('/**')) {
        // Handle block comments if any
        l = l.replaceAll(RegExp(r'^\s*\*+', multiLine: true), '');
      }
      return l.trim();
    }).join('\n');

    final paragraphs = rawText.split('\n\n').where((p) => p.trim().length > 10);
    
    if (paragraphs.length < 2) {
      reporter.atNode(doc, code);
    }
  }

  bool _isOverride(AstNode node) {
    if (node is! AnnotatedNode) return false;
    return node.metadata.any((m) => m.name.name == 'override');
  }
}

class Goo2dDocNoGetterParams extends Goo2dDocRule {
  const Goo2dDocNoGetterParams()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_no_getter_params',
            problemMessage: 'Getters cannot have parameter documentation (* [name]).',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! MethodDeclaration || !node.isGetter) return;
    final doc = node.documentationComment;
    if (doc == null) return;

    final text = doc.tokens.map((t) => t.lexeme).join('\n');
    if (text.contains('* [')) {
      reporter.atNode(doc, code);
    }
  }
}

class Goo2dDocPublicSetter extends Goo2dDocRule {
  const Goo2dDocPublicSetter()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_public_setter',
            problemMessage: 'Public setters must be documented.',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! MethodDeclaration || !node.isSetter || node.name.lexeme.startsWith('_')) return;
    if (_isOverride(node)) return;
    
    if (node.documentationComment == null) {
      reporter.atNode(node, code);
    }
  }

  bool _isOverride(AstNode node) {
    if (node is! AnnotatedNode) return false;
    return node.metadata.any((m) => m.name.name == 'override');
  }
}

class Goo2dDocExample extends Goo2dDocRule {
  const Goo2dDocExample()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_example',
            problemMessage: 'Public classes must include a ```dart code example.',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! ClassDeclaration) return;
    final doc = node.documentationComment;
    if (doc == null) return;

    final text = doc.tokens.map((t) => t.lexeme).join('\n');
    if (!text.contains('```dart')) {
      reporter.atNode(doc, code);
    }
  }
}

class Goo2dDocParams extends Goo2dDocRule {
  const Goo2dDocParams()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_params',
            problemMessage: 'All parameters must be documented using * [name].',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    FormalParameterList? parameters;
    Comment? doc;

    if (node is MethodDeclaration) {
      parameters = node.parameters;
      doc = node.documentationComment;
    } else if (node is ConstructorDeclaration) {
      parameters = node.parameters;
      doc = node.documentationComment;
    } else if (node is FunctionDeclaration) {
      parameters = node.functionExpression.parameters;
      doc = node.documentationComment;
    }

    if (doc == null || parameters == null || parameters.parameters.isEmpty) return;

    final text = doc.tokens.map((t) => t.lexeme).join('\n');
    for (final param in parameters.parameters) {
      final name = param.name?.lexeme;
      if (name == null) continue;

      // Strictly enforce '* [paramName]: description'
      // We look for the asterisk, the bracketed name, a colon, and at least one non-whitespace character.
      final regex = RegExp('\\* \\[$name\\]: \\S');
      if (!regex.hasMatch(text)) {
        reporter.atNode(doc, code);
      }
    }
  }
}

class Goo2dDocNoPlaceholders extends Goo2dDocRule {
  const Goo2dDocNoPlaceholders()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_no_placeholders',
            problemMessage: 'Documentation contains placeholders like TODO, FIXME, or dots.',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! Declaration) return;
    final doc = node.documentationComment;
    if (doc == null) return;

    final text = doc.tokens.map((t) => t.lexeme).join('\n').toUpperCase();
    if (text.contains('TODO') || text.contains('FIXME') || text.contains('...')) {
      reporter.atNode(doc, code);
    }
  }
}

class Goo2dDocNoOverrideDocs extends Goo2dDocRule {
  const Goo2dDocNoOverrideDocs()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_no_override_docs',
            problemMessage: 'Members annotated with @override should not have documentation; they inherit from the base.',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! AnnotatedNode) return;
    if (node.documentationComment != null && _isOverride(node)) {
      reporter.atNode(node.documentationComment!, code);
    }
  }

  bool _isOverride(AnnotatedNode node) {
    return node.metadata.any((m) => m.name.name == 'override');
  }
}

class Goo2dDocGenerics extends Goo2dDocRule {
  const Goo2dDocGenerics()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_generics',
            problemMessage: 'Use [T] instead of <T> in Dartdocs.',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! Declaration) return;
    final doc = node.documentationComment;
    if (doc == null) return;

    final text = doc.tokens.map((t) => t.lexeme).join('\n');
    final genericRegex = RegExp(r'<\w+>');
    if (genericRegex.hasMatch(text)) {
      reporter.atNode(doc, code);
    }
  }
}

class Goo2dDocLinks extends Goo2dDocRule {
  const Goo2dDocLinks()
      : super(
          code: const LintCode(
            name: 'goo2d_doc_links',
            problemMessage: 'Classes must include at least one cross-link [Class] to related systems.',
          ),
        );

  @override
  void checkNode(AstNode node, ErrorReporter reporter) {
    if (node is! ClassDeclaration) return;
    final doc = node.documentationComment;
    if (doc == null) return;

    final text = doc.tokens.map((t) => t.lexeme).join('\n');
    final linkRegex = RegExp(r'\[[A-Z]\w+\]');
    if (!linkRegex.hasMatch(text)) {
      reporter.atNode(doc, code);
    }
  }
}
