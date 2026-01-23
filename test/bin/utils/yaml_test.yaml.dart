import 'package:flutter_test/flutter_test.dart';

import '../../../bin/src/utils/yaml_editor.dart';


void main() {
  group('Basic Operations', () {
    test('should parse and modify basic values', () {
      final yaml = '''
name: test_project
version: 1.0.0
description: A test project
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('version', '2.0.0');
      final result = editor.toYamlString();

      expect(result, contains('version: 2.0.0'));
      expect(result, contains('name: test_project'));
    });

    test('should get values by path', () {
      final yaml = '''
name: test_project
version: 1.0.0
''';

      final editor = YamlEditor.parse(yaml);

      expect(editor.get('name'), equals('test_project'));
      expect(editor.get('version'), equals('1.0.0'));
    });

    test('should add new root-level keys', () {
      final yaml = '''
name: test_project
version: 1.0.0
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('homepage', 'https://example.com');
      final result = editor.toYamlString();

      // URLs with :// will be quoted
      expect(result, contains("homepage: 'https://example.com'"));
    });
  });

  group('Nested Keys', () {
    test('should add nested keys to existing maps', () {
      final yaml = '''
dependencies:
  flutter:
    sdk: flutter
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('dependencies.cupertino_icons', '^1.0.0');
      final result = editor.toYamlString();

      expect(result, contains('cupertino_icons: ^1.0.0'));
      expect(result, contains('flutter:'));
    });

    test('should create deeply nested structures', () {
      final yaml = '''
name: test
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('a.b.c.d', 'value');
      final result = editor.toYamlString();

      expect(result, contains('a:'));
      expect(result, contains('b:'));
      expect(result, contains('c:'));
      expect(result, contains('d: value'));
    });

    test('should get nested values', () {
      final yaml = '''
environment:
  sdk: '>=3.0.0 <4.0.0'
''';

      final editor = YamlEditor.parse(yaml);

      expect(editor.get('environment.sdk'), equals('>=3.0.0 <4.0.0'));
    });
  });

  group('Formatting Preservation', () {
    test('should preserve blank lines', () {
      final yaml = '''
name: test

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  test: ^1.0.0
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('dependencies.http', '^0.13.0');
      final result = editor.toYamlString();

      // Should still have blank lines between sections
      expect('\n\n'.allMatches(result).length, greaterThanOrEqualTo(2));
    });

    test('should preserve comments above keys', () {
      final yaml = '''
# This is a comment
name: test_project
version: 1.0.0
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('description', 'New description');
      final result = editor.toYamlString();

      expect(result, contains('# This is a comment'));
    });

    test('should preserve inline comments', () {
      final yaml = '''
name: test_project
version: 1.0.0 # inline comment
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('version', '2.0.0');
      final result = editor.toYamlString();

      expect(result, contains('# inline comment'));
    });

    test('should preserve indentation', () {
      final yaml = '''
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.0
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('dependencies.path', '^1.8.0');
      final result = editor.toYamlString();

      final lines = result.split('\n');
      final pathLine = lines.firstWhere((line) => line.contains('path:'));

      // Should be indented 2 spaces (same as other dependencies)
      expect(pathLine.startsWith('  '), isTrue);
    });
  });

  group('List Operations', () {
    test('should modify existing list items', () {
      final yaml = '''
flutter:
  assets:
    - images/logo.png
    - images/background.png
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('flutter.assets[0]', 'images/new_logo.png');
      final result = editor.toYamlString();

      expect(result, contains('images/new_logo.png'));
      expect(result, contains('images/background.png'));
    });

    test('should append to existing lists', () {
      final yaml = '''
flutter:
  assets:
    - images/logo.png
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('flutter.assets[-1]', 'images/icon.png');
      final result = editor.toYamlString();

      expect(result, contains('images/logo.png'));
      expect(result, contains('images/icon.png'));
    });

    test('should get list items by index', () {
      final yaml = '''
flutter:
  assets:
    - images/logo.png
    - images/background.png
''';

      final editor = YamlEditor.parse(yaml);

      expect(editor.get('flutter.assets[0]'), equals('images/logo.png'));
      expect(editor.get('flutter.assets[1]'), equals('images/background.png'));
    });

    test('should convert empty map to list', () {
      final yaml = '''
name: test
flutter:
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('flutter[-1]', 'item1');
      final result = editor.toYamlString();

      expect(result, contains('flutter:'));
      expect(result, contains('- item1'));
    });

    test('should append multiple items to empty map converted to list', () {
      final yaml = '''
name: test
flutter:
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('flutter[-1]', 'item1');
      editor.set('flutter[-1]', 'item2');
      editor.set('flutter[-1]', 'item3');
      final result = editor.toYamlString();

      expect(result, contains('- item1'));
      expect(result, contains('- item2'));
      expect(result, contains('- item3'));
    });

    test('should create new list at specific index', () {
      final yaml = '''
name: test
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('items[0]', 'first');
      editor.set('items[1]', 'second');
      final result = editor.toYamlString();

      expect(result, contains('items:'));
      expect(result, contains('- first'));
      expect(result, contains('- second'));
    });
  });

  group('Multiple Keys With Same Name', () {
    test('should distinguish between root and nested keys', () {
      final yaml = '''
environment:
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter

flutter:
''';

      final editor = YamlEditor.parse(yaml);

      print('All paths: ${editor.getPaths()}');
      print('dependencies.flutter value: ${editor.get('dependencies.flutter')}');
      print('dependencies value: ${editor.get('dependencies')}');
      print('flutter node: ${editor.nodes['flutter']}');
      print('flutter value directly: ${editor.nodes['flutter']?.value}');

      expect(editor.get('environment.flutter'), equals('>=1.17.0'));
      expect(editor.get('dependencies.flutter'), isA<Map>());
      expect(editor.get('dependencies.flutter.sdk'), equals('flutter'));

      // Empty map in YAML might be parsed as null, so check for that
      final flutterValue = editor.get('flutter');
      expect(flutterValue == null || flutterValue is Map, isTrue, reason: 'flutter should be null or a Map');
    });

    test('should add to correct flutter section', () {
      final yaml = '''
environment:
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter

flutter:
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('flutter[-1]', 'test_item');
      final result = editor.toYamlString();

      // Verify it was added to root flutter, not environment or dependencies
      final lines = result.split('\n');
      var foundRootFlutter = false;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() == 'flutter:' && lines[i].indexOf('flutter:') == 0) {
          // This is root-level flutter
          if (i + 1 < lines.length && lines[i + 1].contains('- test_item')) {
            foundRootFlutter = true;
            break;
          }
        }
      }

      expect(foundRootFlutter, isTrue);
      // Make sure environment.flutter wasn't changed
      expect(result, contains('flutter: ">=1.17.0"'));
    });
  });

  group('Edge Cases', () {
    test('should handle values with special characters', () {
      final yaml = '''
name: test
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('description', 'Has: colons # and hashes');
      final result = editor.toYamlString();

      // Should be quoted
      expect(result, contains("'Has: colons # and hashes'"));
    });

    test('should handle empty yaml', () {
      final yaml = '';

      expect(() => YamlEditor.parse(yaml), throwsA(anything));
    });

    test('should create non-existent list paths', () {
      final yaml = '''
name: test
''';

      final editor = YamlEditor.parse(yaml);

      editor.set('nonexistent[-1]', 'value');
      final result = editor.toYamlString();

      expect(result, contains('nonexistent:'));
      expect(result, contains('- value'));
    });

    test('should handle very long paths', () {
      final yaml = '''
name: test
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('a.b.c.d.e.f.g', 'deep_value');
      final result = editor.toYamlString();

      expect(result, contains('g: deep_value'));
    });

    test('should preserve original content for unchanged sections', () {
      final yaml = '''
name: original_name
version: 1.0.0
description: original description
''';

      final editor = YamlEditor.parse(yaml);
      editor.set('version', '2.0.0');
      final result = editor.toYamlString();

      expect(result, contains('name: original_name'));
      expect(result, contains('description: original description'));
    });
  });

  group('Complex Real-World Scenarios', () {
    test('should handle pubspec.yaml-like structure', () {
      final yaml = '''
name: xwidget_builder
description: "Development tool"
version: 0.1.2

environment:
  sdk: '>=3.4.4 <4.0.0'
  flutter: ">=1.17.0"

dependencies:
  analyzer: ^7.7.1
  flutter:
    sdk: flutter

dev_dependencies:
  test: ^1.0.0

flutter:
''';

      final editor = YamlEditor.parse(yaml);

      // Add a dependency
      editor.set('dependencies.http', '^0.13.0');

      // Modify version
      editor.set('version', '0.2.0');

      // Add to flutter section
      editor.set('flutter[-1]', 'uses-material-design: true');

      final result = editor.toYamlString();

      expect(result, contains('http: ^0.13.0'));
      expect(result, contains('version: 0.2.0'));
      expect(result, contains('uses-material-design: true'));

      // Ensure blank lines are preserved
      expect('\n\n'.allMatches(result).length, greaterThanOrEqualTo(3));
    });
  });

  group('getPaths', () {
    test('should list all available paths', () {
      final yaml = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
''';

      final editor = YamlEditor.parse(yaml);
      final paths = editor.getPaths();

      expect(paths, contains('name'));
      expect(paths, contains('version'));
      expect(paths, contains('dependencies'));
      expect(paths, contains('dependencies.flutter'));
      // Map children are stored as separate paths
      expect(paths, contains('dependencies.flutter.sdk'));
    });
  });
}