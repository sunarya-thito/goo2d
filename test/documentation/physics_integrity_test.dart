import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final roadmapDir = Directory(r'e:\gameproj\roadmap\physics\data');
  final libDir = Directory(r'e:\gameproj\goo2d\lib\src\physics');

  if (!roadmapDir.existsSync()) {
    print('Roadmap directory not found: ${roadmapDir.path}');
    return;
  }

  final specs = roadmapDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));

  group('Physics API Integrity', () {
    for (final specFile in specs) {
      final specName = p.basenameWithoutExtension(specFile.path);
      test('Class $specName matches Unity spec', () {
        final spec = jsonDecode(specFile.readAsStringSync());
        final rawClassName = spec['name'].toString().replaceAll('2D', '');

        // Handle dotted names like "CompositeCollider.GenerationType"
        final isDotted = rawClassName.contains('.');
        final className = isDotted ? rawClassName.split('.').last : rawClassName;
        final parentClassName = isDotted ? rawClassName.split('.').first : null;

        final dartFile = _findDartFile(libDir, className, parentClassName);
        expect(dartFile, isNotNull, reason: 'Could not find Dart file for class $className');

        final result = parseFile(path: dartFile!.path, featureSet: _featureSet);
        final visitor = _MemberVisitor();
        result.unit.accept(visitor);

        final dartMembers = visitor.members[className]
            ?? visitor.enumValues[className]
            ?? visitor.members.values.expand((e) => e).toSet();

        // Include static_properties and static_methods in required set
        final specProperties = (spec['properties'] as List? ?? []).map((p) => p['name'].toString()).toSet();
        final specMethods = (spec['methods'] as List? ?? []).map((m) => m['name'].toString()).toSet();
        final specStaticProperties = (spec['static_properties'] as List? ?? []).map((p) => p['name'].toString()).toSet();
        final specStaticMethods = (spec['static_methods'] as List? ?? []).map((m) => m['name'].toString()).toSet();
        final requiredMembers = {...specProperties, ...specMethods, ...specStaticProperties, ...specStaticMethods};

        // Normalize to lowercase for case-insensitive comparison (Dart = camelCase, Unity spec = PascalCase for methods)
        final dartLower = dartMembers.map((m) => m.toLowerCase()).toSet();
        final requiredLower = requiredMembers.map((m) => m.toLowerCase()).toSet();

        final missing = requiredLower.difference(dartLower).toList()..sort();

        final ignoredExtra = <String>{
          // Internal engine members
          'jointtype', 'syncproperties', 'internalattach', 'internaldetach', 'handle',
          'shapetype', 'effectortype', 'worker', 'gameobject', 'attached',
          'onattach', 'ondetach', 'update', 'render', 'tostring', 'nosuchmethod',
          'hashcode', 'runtimetype',
          // Common joint anchors (present on all joints, not listed per-joint in spec)
          'anchor', 'connectedanchor', 'autoconfigureconnectedanchor',
          // Screen visibility tracking (goo2d-specific, not in Unity spec)
          'worldbounds', 'wasoverlappingscreen', 'wasfullyinsidescreen',
          // Rigidbody internal
          'worldmatrix',
          // Data class factory
          'fromdata',
          // Physics global — internal init
          'initialize',
          // ForceMode 3D-only values (ForceMode2D spec only requires impulse/force)
          'acceleration', 'velocitychange',
        };

        final extra = dartLower.difference(requiredLower).difference(ignoredExtra)
            .where((m) => !m.startsWith('_')).toList()..sort();

        final errors = <String>[];
        if (missing.isNotEmpty) errors.add('Missing members: ${missing.join(', ')}');
        if (extra.isNotEmpty) errors.add('Extra members not in spec: ${extra.join(', ')}');

        if (errors.isNotEmpty) fail('Integrity violations for $className:\n${errors.join('\n')}');
      });
    }
  });
}

File? _findDartFile(Directory dir, String className, String? parentClassName) {
  final snakeCase = _toSnakeCase(className);

  final allFiles = dir.listSync(recursive: true).whereType<File>()
      .where((f) => f.path.endsWith('.dart')).toList();

  // 1. Exact filename match for class (highest priority — avoids returning parent class file)
  for (final file in allFiles) {
    final name = p.basenameWithoutExtension(file.path);
    if (name == snakeCase || name == className.toLowerCase()) return file;
  }

  // 2. Search file contents for class/enum declaration
  for (final file in allFiles) {
    final content = file.readAsStringSync();
    if (content.contains('enum $className ') || content.contains('enum $className{') ||
        content.contains('class $className ') || content.contains('class $className{') ||
        content.contains('class $className\n') || content.contains('enum $className\n')) {
      return file;
    }
  }

  return null;
}

String _toSnakeCase(String className) => className
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)}_${m.group(2)!.toLowerCase()}')
    .toLowerCase();

final _featureSet = parseString(content: '').unit.featureSet;

class _MemberVisitor extends RecursiveAstVisitor<void> {
  final Map<String, Set<String>> members = {};
  final Map<String, Set<String>> enumValues = {};

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    final classMembers = members.putIfAbsent(className, () => {});
    for (final member in node.members) {
      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          classMembers.add(variable.name.lexeme);
        }
      } else if (member is MethodDeclaration) {
        classMembers.add(member.name.lexeme);
      }
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final enumName = node.name.lexeme;
    final values = enumValues.putIfAbsent(enumName, () => {});
    for (final constant in node.constants) {
      values.add(constant.name.lexeme);
    }
    super.visitEnumDeclaration(node);
  }
}
