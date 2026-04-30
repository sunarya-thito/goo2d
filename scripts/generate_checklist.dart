import 'dart:io';
import 'dart:convert';

void main() async {
  final libDir = Directory('lib/src');
  if (!libDir.existsSync()) {
    print('Error: lib/src directory not found.');
    exit(1);
  }

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // Get modified files from git
  final statusResult = await Process.run('git', ['status', '--porcelain']);
  final modifiedPaths = (statusResult.stdout as String)
      .split('\n')
      .where((line) => line.length > 3)
      .map((line) => line.substring(3).replaceAll('\\', '/'))
      .toSet();

  print('Generating checklist for ${files.length} files...');
  print('Detected ${modifiedPaths.length} modified files.');

  final checklist = StringBuffer();
  checklist.writeln('# Goo2D Documentation Integrity Checklist');
  checklist.writeln('Generated on: ${DateTime.now()}\n');

  // Read lints from the pre-generated file
  print('Parsing checklist_lints_utf8.txt...');
  final lintFile = File('checklist_lints_utf8.txt');
  final fallbackLintFile = File('checklist_lints.txt');
  Map<String, List<String>> lintMap = {};
  
  File? fileToRead;
  if (lintFile.existsSync()) {
    fileToRead = lintFile;
  } else if (fallbackLintFile.existsSync()) {
    fileToRead = fallbackLintFile;
  }

  if (fileToRead != null) {
    String content;
    try {
      content = fileToRead.readAsStringSync(encoding: utf8);
    } catch (e) {
      content = fileToRead.readAsStringSync(encoding: latin1).replaceAll('\x00', '');
    }
    lintMap = _parseLintOutput(content);
  }

  for (final file in files) {
    final relativePath = file.path.replaceAll('\\', '/');
    final shortPath = relativePath.startsWith('e:/gameproj/goo2d/') 
        ? relativePath.substring('e:/gameproj/goo2d/'.length)
        : relativePath;
    
    // Normalize path to match git status output
    final gitPath = shortPath;

    checklist.writeln('## $gitPath');

    // Integrity Check (Only for modified files)
    if (modifiedPaths.contains(gitPath)) {
      print('  Checking integrity for $gitPath...');
      final integrityResult = await Process.run('dart', [
        'scripts/verify_integrity.dart',
        gitPath,
      ]);
      final integrityStatus = integrityResult.exitCode == 0 ? '✅ VERIFIED' : '❌ VIOLATED';
      checklist.writeln('- Integrity: $integrityStatus');
      if (integrityResult.exitCode != 0) {
        checklist.writeln('  > ${integrityResult.stdout.toString().trim().replaceAll('\n', '\n  > ')}');
      }
    } else {
      checklist.writeln('- Integrity: ⚪ NOT MODIFIED');
    }

    // Linter Output
    final fileLints = lintMap[gitPath] ?? [];
    if (fileLints.isEmpty) {
      print('  No lints for $gitPath');
      checklist.writeln('- Lints: ✅ CLEAN');
    } else {
      print('  Found ${fileLints.length} lints for $gitPath');
      checklist.writeln('- Lints: ⚠️ ${fileLints.length} issues');
      // Only show first 5 lints to keep checklist readable, or show all if specifically requested
      for (var i = 0; i < fileLints.length; i++) {
        if (i >= 10) {
          checklist.writeln('  - ... and ${fileLints.length - 10} more');
          break;
        }
        checklist.writeln('  - ${fileLints[i]}');
      }
    }
    checklist.writeln('');
  }

  final outputFile = File('checklist.txt');
  outputFile.writeAsStringSync(checklist.toString());
  print('Checklist generated: checklist.txt');
}

Map<String, List<String>> _parseLintOutput(String output) {
  final map = <String, List<String>>{};
  final lines = output.split('\n');
  
  for (final line in lines) {
    final trimmed = line.trim().replaceAll('\x00', '');
    if (trimmed.isEmpty) continue;
    
    final parts = trimmed.split(' • ');
    if (parts.length < 3) continue;
    
    final location = parts[0].trim();
    final message = parts[1].trim();
    final rule = parts[2].trim();
    
    final locationParts = location.split(':');
    if (locationParts.length < 3) continue;
    
    var filePath = locationParts[0].replaceAll('\\', '/');
    if (filePath.startsWith('lib/')) {
       // Keep as is
    } else {
       final libIndex = filePath.indexOf('lib/');
       if (libIndex != -1) {
         filePath = filePath.substring(libIndex);
       } else {
         // Try to handle absolute paths or paths starting with src/
         final srcIndex = filePath.indexOf('src/');
         if (srcIndex != -1 && srcIndex > 0) {
            // Check if it's part of goo2d/lib/src
            final libBeforeSrc = filePath.substring(0, srcIndex).endsWith('lib/');
            if (libBeforeSrc) {
              filePath = filePath.substring(srcIndex - 4); // Include 'lib/'
            }
         }
       }
    }
    
    // Final normalization: ensure no leading slashes or e:/...
    filePath = filePath.replaceAll('\\', '/');
    if (filePath.contains('goo2d/lib/')) {
      filePath = filePath.substring(filePath.indexOf('lib/'));
    }

    
    final lineNum = locationParts[1];
    map.putIfAbsent(filePath, () => []).add('Line $lineNum: $message ($rule)');
  }
  return map;
}
