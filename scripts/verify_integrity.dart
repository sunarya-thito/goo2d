import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:path/path.dart' as p;

class TokenInfo {
  final String lexeme;
  final int offset;
  final int end;
  TokenInfo(this.lexeme, this.offset, this.end);
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart verify_integrity.dart <file_path>');
    exit(1);
  }

  final inputPath = args[0];
  final file = File(inputPath);

  if (!file.existsSync()) {
    print('Error: File $inputPath not found.');
    exit(1);
  }

  // Get repository root and relative path for git
  final repoRoot = _findRepoRoot(file.absolute.parent.path);
  if (repoRoot == null) {
    print('Error: Could not find .git directory in parent hierarchy of $inputPath');
    exit(1);
  }

  final relativePath = p.relative(file.absolute.path, from: repoRoot).replaceAll('\\', '/');
  final currContent = file.readAsStringSync();

  // Retrieve previous content from git HEAD
  final gitProcess = await Process.run('git', ['show', 'HEAD:$relativePath'], workingDirectory: repoRoot);
  if (gitProcess.exitCode != 0) {
    print('Error: Could not retrieve $relativePath from git HEAD.');
    print('Git error: ${gitProcess.stderr}');
    exit(1);
  }
  final prevContent = gitProcess.stdout as String;

  final prevTokens = _tokenize(prevContent);
  final currTokens = _tokenize(currContent);

  int? firstDiff;
  final minLen = prevTokens.length < currTokens.length ? prevTokens.length : currTokens.length;
  
  for (var i = 0; i < minLen; i++) {
    if (prevTokens[i].lexeme != currTokens[i].lexeme) {
      firstDiff = i;
      break;
    }
  }

  if (firstDiff != null || prevTokens.length != currTokens.length) {
    print('\n❌ INTEGRITY VIOLATED in $relativePath');
    print('--------------------------------------------------');
    
    if (prevTokens.length != currTokens.length) {
      print('Token count mismatch: Prev ${prevTokens.length}, Curr ${currTokens.length}');
    }
    
    if (firstDiff != null) {
      print('First difference at token $firstDiff:');
      print('  Expected: "${prevTokens[firstDiff].lexeme}"');
      print('  Actual:   "${currTokens[firstDiff].lexeme}"');
    } else {
      print('Files match up to token $minLen, but the current file has trailing tokens.');
      firstDiff = minLen > 0 ? minLen - 1 : 0;
    }
    
    _showMismatchDetails(prevContent, currContent, prevTokens, currTokens, firstDiff);
    print('--------------------------------------------------');
    exit(1);
  }

  print('✅ INTEGRITY VERIFIED: $relativePath');
}

String? _findRepoRoot(String path) {
  var current = Directory(path);
  while (true) {
    if (Directory(p.join(current.path, '.git')).existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) break;
    current = parent;
  }
  return null;
}

void _showMismatchDetails(
  String prevContent, 
  String currContent, 
  List<TokenInfo> prevTokens, 
  List<TokenInfo> currTokens, 
  int diffIndex
) {
  if (prevTokens.isEmpty || currTokens.isEmpty) return;

  final startTokenIdx = (diffIndex - 5).clamp(0, prevTokens.length - 1);
  final endTokenIdxPrev = (diffIndex + 10).clamp(0, prevTokens.length - 1);
  final endTokenIdxCurr = (diffIndex + 10).clamp(0, currTokens.length - 1);

  final prevStart = prevTokens[startTokenIdx].offset;
  final prevEnd = prevTokens[endTokenIdxPrev].end;

  final currStart = currTokens[startTokenIdx].offset;
  final currEnd = currTokens[endTokenIdxCurr].end;

  print('\n[EXPECTED HEAD CONTEXT]');
  print(_getFormattedSnippet(prevContent, prevStart, prevEnd));
  
  print('\n[ACTUAL CURRENT CONTEXT]');
  print(_getFormattedSnippet(currContent, currStart, currEnd));
}

String _getFormattedSnippet(String content, int start, int end) {
  final startLineIdx = content.lastIndexOf('\n', start) + 1;
  var endLineIdx = content.indexOf('\n', end);
  if (endLineIdx == -1) endLineIdx = content.length;
  
  var snippet = content.substring(startLineIdx, endLineIdx).trimRight();
  // Highlight the specific mismatch line if possible? 
  // For now, just return the block.
  return snippet;
}

List<TokenInfo> _tokenize(String content) {
  final tokens = <TokenInfo>[];
  try {
    final result = parseString(content: content, throwIfDiagnostics: false);
    var token = result.unit.beginToken;

    while (!token.isEof) {
      // In Dart analyzer, comments are not in the main token stream.
      // They are linked as precedingComments.
      // beginToken starts at the first non-comment token.
      tokens.add(TokenInfo(token.lexeme, token.offset, token.end));
      token = token.next!;
    }
  } catch (e) {
    print('Warning: Analyzer failed to parse content: $e');
  }
  return tokens;
}
