import 'dart:io';
import 'package:yaml/yaml.dart';
import 'path_resolver.dart';

/// Represents a node in a YAML document with metadata about its position,
/// formatting, comments, and modification state.
class YamlNode {
  final dynamic value;
  final int startLine;
  final int endLine;
  final String originalText;
  final List<String> commentsAbove;
  final String? inlineComment;
  final int indentLevel;
  final bool isModified;

  YamlNode({
    required this.value,
    required this.startLine,
    required this.endLine,
    required this.originalText,
    required this.commentsAbove,
    this.inlineComment,
    required this.indentLevel,
    this.isModified = false,
  });

  /// Creates a copy of this node with optionally updated properties.
  YamlNode copyWith({
    dynamic value,
    int? startLine,
    int? endLine,
    String? originalText,
    List<String>? commentsAbove,
    String? inlineComment,
    int? indentLevel,
    bool? isModified,
  }) {
    return YamlNode(
      value: value ?? this.value,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      originalText: originalText ?? this.originalText,
      commentsAbove: commentsAbove ?? this.commentsAbove,
      inlineComment: inlineComment ?? this.inlineComment,
      indentLevel: indentLevel ?? this.indentLevel,
      isModified: isModified ?? this.isModified,
    );
  }
}

/// A YAML editor that preserves formatting, comments, and structure while
/// allowing programmatic modifications to YAML documents.
///
/// Supports reading, modifying, and writing YAML files while maintaining
/// original formatting, indentation, comments, and style (block vs flow).
class YamlEditor {
  final String originalContent;
  final List<String> lines;
  final YamlMap parsedYaml;
  final Map<String, YamlNode> nodes = {};

  YamlEditor._(this.originalContent, this.lines, this.parsedYaml);

  /// Parses YAML content string into a YamlEditor instance.
  /// Normalizes tabs to spaces and builds an internal node map for editing.
  static YamlEditor parse(String yamlContent) {
    final normalized = yamlContent.replaceAll('\t', '  ');
    final lines = normalized.split('\n');
    final parsed = loadYaml(normalized) as YamlMap;

    final editor = YamlEditor._(normalized, lines, parsed);
    editor._buildNodeMap();

    return editor;
  }

  /// Parses a YAML file from the given [path] into a YamlEditor instance.
  /// Returns null if the file doesn't exist.
  static Future<YamlEditor?> parseFromFile(String path) async {
    final uri = await PathResolver.relativeToAbsolute(path);
    final file = File.fromUri(uri);
    if (file.existsSync()) {
      final yaml = await file.readAsString();
      return parse(yaml);
    }
    return null;
  }

  /// Retrieves the value at the given dot-notation [path].
  /// For lists, use bracket notation (e.g., "parent.list[0]").
  /// Returns null if the path doesn't exist.
  dynamic get(String path) {
    final node = nodes[path];
    return node?.value;
  }

  /// Sets the value at the given [path] to [newValue].
  /// Creates new nodes if the path doesn't exist.
  /// Use "list[-1]" to append to a list.
  void set(String path, dynamic newValue) {
    final node = nodes[path];
    if (node != null) {
      nodes[path] = node.copyWith(value: newValue, isModified: true);
    } else {
      _addNewPath(path, newValue);
    }
  }

  /// Returns a list of all node paths in dot notation.
  /// List items use bracket notation (e.g., "list[0]").
  List<String> getPaths() {
    return nodes.keys.toList();
  }

  //===================================
  // private methods
  //===================================

  void _buildNodeMap() {
    _processMap(parsedYaml, '', 0);
  }

  void _processMap(YamlMap map, String parentPath, int currentLine) {
    int expectedIndent;
    if (parentPath.isEmpty) {
      expectedIndent = 0;
    } else {
      final parentNode = nodes[parentPath];
      if (parentNode != null) {
        expectedIndent = parentNode.indentLevel + 2;
      } else {
        final depth = parentPath.split('.').length;
        expectedIndent = depth * 2;
      }
    }

    for (var entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final path = parentPath.isEmpty ? key : '$parentPath.$key';

      final keyLine = _findKeyLineAtIndent(key, currentLine, expectedIndent);
      if (keyLine == -1) continue;

      final commentsAbove = _getCommentsAbove(keyLine);
      final inlineComment = _getInlineComment(keyLine);
      final indentLevel = _getIndentLevel(keyLine);

      int endLine = keyLine;
      if (value is YamlMap) {
        endLine = _findMapEndLine(keyLine, indentLevel);
      } else if (value is YamlList) {
        endLine = _findListEndLine(keyLine, indentLevel);
      }

      final originalText = _extractNodeText(keyLine, endLine);

      nodes[path] = YamlNode(
        value: value,
        startLine: keyLine,
        endLine: endLine,
        originalText: originalText,
        commentsAbove: commentsAbove,
        inlineComment: inlineComment,
        indentLevel: indentLevel,
      );

      if (value is YamlMap) {
        _processMap(value, path, keyLine + 1);
      } else if (value is YamlList) {
        _processList(value, path, keyLine + 1);
      }
    }
  }

  void _processList(YamlList list, String parentPath, int currentLine) {
    for (var i = 0; i < list.length; i++) {
      final value = list[i];
      final path = '$parentPath[$i]';

      final itemLine = _findListItemLine(currentLine, i);
      if (itemLine == -1) continue;

      final indentLevel = _getIndentLevel(itemLine);
      final inlineComment = _getInlineComment(itemLine);

      int endLine = itemLine;
      if (value is YamlMap) {
        endLine = _findMapEndLine(itemLine, indentLevel);
        _processMap(value, path, itemLine + 1);
      } else if (value is YamlList) {
        endLine = _findListEndLine(itemLine, indentLevel);
        _processList(value, path, itemLine + 1);
      }

      final originalText = _extractNodeText(itemLine, endLine);

      nodes[path] = YamlNode(
        value: value,
        startLine: itemLine,
        endLine: endLine,
        originalText: originalText,
        commentsAbove: [],
        inlineComment: inlineComment,
        indentLevel: indentLevel,
      );
    }
  }

  int _findListItemLine(int startLine, int index) {
    var count = 0;
    for (var i = startLine; i < lines.length; i++) {
      final line = lines[i].trimLeft();
      if (line.startsWith('- ')) {
        if (count == index) return i;
        count++;
      }
    }
    return -1;
  }

  int _findKeyLineAtIndent(String key, int startLine, int expectedIndent) {
    for (var i = startLine; i < lines.length; i++) {
      final line = lines[i].trimLeft();
      if (line.startsWith('$key:') || line.startsWith('$key :')) {
        final lineIndent = _getIndentLevel(i);
        if (lineIndent == expectedIndent) return i;
      }
    }
    return -1;
  }

  List<String> _getCommentsAbove(int keyLine) {
    final comments = <String>[];
    final keyIndent = _getIndentLevel(keyLine);

    for (var i = keyLine - 1; i >= 0; i--) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#')) {
        final lineIndent = _getIndentLevel(i);
        if (lineIndent == keyIndent) {
          comments.insert(0, line);
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return comments;
  }

  String? _getInlineComment(int lineIndex) {
    final line = lines[lineIndex];
    final commentIndex = line.indexOf('#');

    if (commentIndex > 0) {
      final beforeComment = line.substring(0, commentIndex);
      if (!_isInsideString(beforeComment)) {
        return line.substring(commentIndex).trim();
      }
    }

    return null;
  }

  bool _isInsideString(String text) {
    var inSingle = false;
    var inDouble = false;

    for (var i = 0; i < text.length; i++) {
      if (text[i] == "'" && (i == 0 || text[i - 1] != '\\')) {
        inSingle = !inSingle;
      } else if (text[i] == '"' && (i == 0 || text[i - 1] != '\\')) {
        inDouble = !inDouble;
      }
    }

    return inSingle || inDouble;
  }

  int _getIndentLevel(int lineIndex) {
    final line = lines[lineIndex];
    var spaces = 0;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == ' ') {
        spaces++;
      } else {
        break;
      }
    }
    return spaces;
  }

  int _findMapEndLine(int startLine, int indentLevel) {
    for (var i = startLine + 1; i < lines.length; i++) {
      final line = lines[i].trimLeft();
      if (line.isEmpty || line.startsWith('#')) continue;

      final lineIndent = _getIndentLevel(i);
      if (lineIndent <= indentLevel) return i - 1;
    }
    return lines.length - 1;
  }

  int _findListEndLine(int startLine, int indentLevel) {
    for (var i = startLine + 1; i < lines.length; i++) {
      final line = lines[i].trimLeft();
      if (line.isEmpty || line.startsWith('#')) continue;

      final lineIndent = _getIndentLevel(i);
      if (lineIndent <= indentLevel) return i - 1;
    }
    return lines.length - 1;
  }

  String _extractNodeText(int startLine, int endLine) {
    return lines.sublist(startLine, endLine + 1).join('\n');
  }

  void _addNewPath(String path, dynamic value) {
    if (path.endsWith('[-1]')) {
      _appendToList(path.substring(0, path.length - 4), value);
      return;
    }

    final listIndexMatch = RegExp(r'\[(\d+)\]').firstMatch(path);
    if (listIndexMatch != null) {
      _addListItem(path, value);
      return;
    }

    final parts = path.split('.');
    String? parentPath;
    int existingDepth = 0;

    for (var i = parts.length - 1; i >= 0; i--) {
      final testPath = parts.sublist(0, i).join('.');
      if (testPath.isEmpty) break;

      if (nodes.containsKey(testPath)) {
        parentPath = testPath;
        existingDepth = i;
        break;
      }
    }

    if (parentPath == null) {
      _addRootKey(parts[0], value, parts.length > 1 ? parts.sublist(1).join('.') : null);
    } else {
      final remainingPath = parts.sublist(existingDepth).join('.');
      _addChildKey(parentPath, remainingPath, value);
    }
  }

  void _appendToList(String listPath, dynamic value) {
    final listNode = nodes[listPath];
    if (listNode == null) {
      _createNewList(listPath, 0, value);
      return;
    }

    if (_isFlowStyleList(listNode)) {
      _convertFlowStyleToBlockStyle(listPath, value);
      return;
    }

    int lastIndex = -1;
    for (var key in nodes.keys) {
      if (key.startsWith('$listPath[') && key.indexOf('[') == listPath.length) {
        final match = RegExp(r'\[(\d+)\]').firstMatch(key.substring(listPath.length));
        if (match != null) {
          final idx = int.parse(match.group(1)!);
          if (idx > lastIndex) lastIndex = idx;
        }
      }
    }

    if (lastIndex == -1 && listNode.value is YamlMap) {
      final yamlMap = listNode.value as YamlMap;
      if (yamlMap.isEmpty) {
        _convertEmptyMapToList(listPath, value);
        return;
      } else {
        throw Exception('Cannot append to "$listPath" - it is a map with properties, not a list.');
      }
    }

    final newIndex = lastIndex + 1;
    final newPath = '$listPath[$newIndex]';
    int itemIndent = listNode.indentLevel + 2;
    int insertLine;

    if (lastIndex >= 0) {
      final lastItemNode = nodes['$listPath[$lastIndex]'];
      if (lastItemNode != null) {
        itemIndent = lastItemNode.indentLevel;
        insertLine = lastItemNode.endLine + 1;
      } else {
        insertLine = listNode.endLine + 1;
      }
    } else {
      insertLine = listNode.endLine + 1;
    }

    nodes[listPath] = listNode.copyWith(endLine: insertLine);

    nodes[newPath] = YamlNode(
      value: value,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: itemIndent,
      isModified: true,
    );
  }

  bool _isFlowStyleList(YamlNode listNode) {
    if (listNode.startLine >= lines.length) return false;
    final line = lines[listNode.startLine];
    return line.contains('[') && line.contains(']');
  }

  void _convertFlowStyleToBlockStyle(String listPath, dynamic newValue) {
    final listNode = nodes[listPath]!;
    final listValue = listNode.value as YamlList;

    nodes[listPath] = listNode.copyWith(isModified: true);

    var insertLine = listNode.startLine + 1;
    final itemIndent = listNode.indentLevel + 2;

    for (var i = 0; i < listValue.length; i++) {
      final itemPath = '$listPath[$i]';

      nodes[itemPath] = YamlNode(
        value: listValue[i],
        startLine: insertLine,
        endLine: insertLine,
        originalText: '',
        commentsAbove: [],
        inlineComment: null,
        indentLevel: itemIndent,
        isModified: true,
      );
      insertLine++;
    }

    final newIndex = listValue.length;
    final newPath = '$listPath[$newIndex]';

    nodes[newPath] = YamlNode(
      value: newValue,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: itemIndent,
      isModified: true,
    );

    nodes[listPath] = listNode.copyWith(endLine: insertLine, isModified: true);
  }

  void _convertEmptyMapToList(String listPath, dynamic value) {
    final listNode = nodes[listPath]!;

    nodes[listPath] = listNode.copyWith(isModified: true);

    final itemPath = '$listPath[0]';
    final insertLine = listNode.startLine + 1;
    final itemIndent = listNode.indentLevel + 2;

    nodes[itemPath] = YamlNode(
      value: value,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: itemIndent,
      isModified: true,
    );

    nodes[listPath] = listNode.copyWith(endLine: insertLine, isModified: true);
  }

  void _addListItem(String path, dynamic value) {
    final match = RegExp(r'(.+)\[(\d+)\]$').firstMatch(path);
    if (match == null) return;

    final listPath = match.group(1)!;
    final index = int.parse(match.group(2)!);

    final listNode = nodes[listPath];
    if (listNode == null) {
      _createNewList(listPath, index, value);
    } else {
      _insertListItemAtIndex(listPath, index, value);
    }
  }

  void _createNewList(String listPath, int index, dynamic value) {
    final parts = listPath.split('.');
    String? parentPath;

    for (var i = parts.length - 1; i >= 0; i--) {
      final testPath = parts.sublist(0, i).join('.');
      if (testPath.isEmpty) break;
      if (nodes.containsKey(testPath)) {
        parentPath = testPath;
        break;
      }
    }

    int insertLine;
    int listIndent;

    if (parentPath != null) {
      final parentNode = nodes[parentPath]!;
      insertLine = parentNode.endLine + 1;
      listIndent = parentNode.indentLevel + 2;
    } else {
      insertLine = lines.length;
      listIndent = 0;
    }

    nodes[listPath] = YamlNode(
      value: null,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: listIndent,
      isModified: true,
    );

    final itemPath = '$listPath[$index]';
    nodes[itemPath] = YamlNode(
      value: value,
      startLine: insertLine + 1,
      endLine: insertLine + 1,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: listIndent + 2,
      isModified: true,
    );
  }

  void _insertListItemAtIndex(String listPath, int index, dynamic value) {
    final listNode = nodes[listPath]!;
    int insertLine = listNode.startLine + 1;
    int itemIndent = listNode.indentLevel + 2;

    final existingItems = <int, YamlNode>{};
    for (var entry in nodes.entries) {
      if (entry.key.startsWith('$listPath[')) {
        final match = RegExp(r'\[(\d+)\]').firstMatch(entry.key);
        if (match != null) {
          final idx = int.parse(match.group(1)!);
          existingItems[idx] = entry.value;
        }
      }
    }

    if (existingItems.isNotEmpty) {
      itemIndent = existingItems.values.first.indentLevel;

      if (index == 0) {
        insertLine = existingItems[0]?.startLine ?? listNode.startLine + 1;
      } else {
        final prevIndex = index - 1;
        if (existingItems.containsKey(prevIndex)) {
          insertLine = existingItems[prevIndex]!.endLine + 1;
        } else {
          final lastIdx = existingItems.keys.reduce((a, b) => a > b ? a : b);
          insertLine = existingItems[lastIdx]!.endLine + 1;
        }
      }
    }

    final itemPath = '$listPath[$index]';
    nodes[itemPath] = YamlNode(
      value: value,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: itemIndent,
      isModified: true,
    );

    nodes[listPath] = listNode.copyWith(endLine: insertLine);
  }

  void _addRootKey(String key, dynamic value, String? remainingPath) {
    int insertLine = 0;

    for (var node in nodes.values) {
      if (node.indentLevel == 0 && node.endLine > insertLine) {
        insertLine = node.endLine + 1;
      }
    }

    if (insertLine == 0) insertLine = lines.length;

    final nodeValue = remainingPath == null ? value : null;
    nodes[key] = YamlNode(
      value: nodeValue,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: 0,
      isModified: true,
    );

    if (remainingPath != null) {
      _addChildKey(key, remainingPath, value);
    }
  }

  void _addChildKey(String parentPath, String childPath, dynamic value) {
    final parentNode = nodes[parentPath];
    if (parentNode == null) return;

    if (_isFlowStyleMap(parentNode)) {
      _convertFlowStyleMapToBlockStyle(parentPath, childPath, value);
      return;
    }

    final parts = childPath.split('.');
    final key = parts[0];
    final fullPath = '$parentPath.$key';

    int insertLine = parentNode.startLine + 1;
    int childIndent = parentNode.indentLevel + 2;

    int maxChildEndLine = parentNode.startLine;
    for (var entry in nodes.entries) {
      final nodePath = entry.key;
      final node = entry.value;

      if (nodePath.startsWith('$parentPath.')) {
        final remainder = nodePath.substring(parentPath.length + 1);
        if (!remainder.contains('.') || remainder.indexOf('.') > remainder.indexOf('[')) {
          if (node.indentLevel > parentNode.indentLevel) {
            childIndent = node.indentLevel;
          }
          if (node.endLine > maxChildEndLine) {
            maxChildEndLine = node.endLine;
          }
        }
      }
    }

    insertLine = maxChildEndLine + 1;

    final nodeValue = parts.length > 1 ? null : value;
    nodes[fullPath] = YamlNode(
      value: nodeValue,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: childIndent,
      isModified: true,
    );

    nodes[parentPath] = parentNode.copyWith(endLine: insertLine);

    if (parts.length > 1) {
      _addChildKey(fullPath, parts.sublist(1).join('.'), value);
    }
  }

  bool _isFlowStyleMap(YamlNode mapNode) {
    if (mapNode.startLine >= lines.length) return false;
    final line = lines[mapNode.startLine];
    return line.contains('{') && line.contains('}');
  }

  void _convertFlowStyleMapToBlockStyle(String parentPath, String childPath, dynamic newValue) {
    final parentNode = nodes[parentPath]!;
    final mapValue = parentNode.value as YamlMap;

    nodes[parentPath] = parentNode.copyWith(isModified: true);

    var lineOffset = 1;
    for (var entry in mapValue.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final itemPath = '$parentPath.$key';
      final insertLine = parentNode.startLine + lineOffset;
      final itemIndent = parentNode.indentLevel + 2;

      nodes[itemPath] = YamlNode(
        value: value,
        startLine: insertLine,
        endLine: insertLine,
        originalText: '',
        commentsAbove: [],
        inlineComment: null,
        indentLevel: itemIndent,
        isModified: true,
      );
      lineOffset++;
    }

    final parts = childPath.split('.');
    final key = parts[0];
    final fullPath = '$parentPath.$key';
    final insertLine = parentNode.startLine + lineOffset;
    final itemIndent = parentNode.indentLevel + 2;
    final nodeValue = parts.length > 1 ? null : newValue;

    nodes[fullPath] = YamlNode(
      value: nodeValue,
      startLine: insertLine,
      endLine: insertLine,
      originalText: '',
      commentsAbove: [],
      inlineComment: null,
      indentLevel: itemIndent,
      isModified: true,
    );

    nodes[parentPath] = parentNode.copyWith(endLine: insertLine, isModified: true);

    if (parts.length > 1) {
      _addChildKey(fullPath, parts.sublist(1).join('.'), newValue);
    }
  }

  String toYamlString() {
    final result = List<String>.from(lines);
    final updates = <int, String>{};
    final inserts = <int, String>{};

    for (var entry in nodes.entries) {
      final node = entry.value;
      if (!node.isModified) continue;

      final pathParts = entry.key.split('.');
      final key = pathParts.last.replaceAll(RegExp(r'\[\d+\]'), '');
      final indent = ' ' * node.indentLevel;
      final valueStr = _formatValue(node.value);
      final comment = node.inlineComment != null ? ' ${node.inlineComment}' : '';

      String newLine;

      if (RegExp(r'\[\d+\]').hasMatch(entry.key)) {
        newLine = '$indent- $valueStr$comment';
      } else if (node.value == null && entry.key.split('.').length > 1) {
        newLine = '$indent$key:$comment';
      } else if (node.value is YamlList && _hasFlowStyleChildren(entry.key)) {
        newLine = '$indent$key:$comment';
      } else if (node.value is YamlMap && _hasFlowStyleMapChildren(entry.key)) {
        newLine = '$indent$key:$comment';
      } else {
        newLine = '$indent$key: $valueStr$comment';
      }

      if (node.startLine >= result.length) {
        inserts[node.startLine] = newLine;
      } else if (node.startLine < lines.length && lines[node.startLine].trim().isNotEmpty) {
        updates[node.startLine] = newLine;
      } else {
        inserts[node.startLine] = newLine;
      }
    }

    for (var entry in updates.entries) {
      result[entry.key] = entry.value;
    }

    if (inserts.isNotEmpty) {
      final sortedInserts = inserts.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

      for (var entry in sortedInserts) {
        final lineNum = entry.key;
        final line = entry.value;

        if (lineNum <= result.length) {
          result.insert(lineNum, line);
        } else {
          result.add(line);
        }
      }
    }
    return result.join('\n');
  }

  bool _hasFlowStyleChildren(String path) {
    for (var key in nodes.keys) {
      if (key.startsWith('$path[') && nodes[key]?.isModified == true) {
        return true;
      }
    }
    return false;
  }

  bool _hasFlowStyleMapChildren(String path) {
    for (var key in nodes.keys) {
      if (key.startsWith('$path.') && nodes[key]?.isModified == true) {
        final remainder = key.substring(path.length + 1);
        if (!remainder.contains('.') && !remainder.contains('[')) {
          return true;
        }
      }
    }
    return false;
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is String) {
      if (value.contains(':') ||
          value.contains('#') ||
          value.contains('\n') ||
          value.contains('//') ||
          value.startsWith('http://') ||
          value.startsWith('https://')) {
        return "'$value'";
      }
      return value;
    }
    return value.toString();
  }
}
