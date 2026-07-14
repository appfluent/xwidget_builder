import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'generation_harness.dart';

// End-to-end generation tests. The first green run on a machine captures
// the generated outputs as a baseline (delete test/fixtures/golden_baseline
// to re-capture). Subsequent runs must reproduce the baseline byte-for-byte,
// which is the safety net for dependency migrations: capture on the old
// analyzer, then verify identical output on the new one.
//
// The content spot-checks below pin down *semantics* independently of the
// baseline, so coverage survives a deliberate baseline re-capture.

void main() {
  late ProcessResult generateResult;
  late String inflaters;
  late String icons;
  late String controllers;
  late String schema;

  setUpAll(() async {
    generateResult = await runGenerate();
    inflaters = generatedFile('src/generated/src/inflaters_test.g.dart').readAsStringSync();
    icons = generatedFile('src/generated/src/icons_test.g.dart').readAsStringSync();
    controllers = generatedFile('src/generated/src/controllers_test.g.dart').readAsStringSync();
    schema = generatedFile('.xwidget/fragments_schema.g.xsd').readAsStringSync();
  });

  test('CLI generate exits cleanly with no errors or warnings', () {
    final output = '${generateResult.stdout}';
    expect(
      generateResult.exitCode,
      0,
      reason: 'stdout:\n$output\nstderr:\n${generateResult.stderr}',
    );
    expect(output, isNot(contains('✘')), reason: 'errors logged:\n$output');
    expect(output, isNot(contains('⚠')), reason: 'warnings logged:\n$output');
  });

  test('all expected outputs are generated', () {
    for (final relative in generatedFiles) {
      final file = generatedFile(relative);
      expect(file.existsSync(), isTrue, reason: '$relative is missing');
      expect(file.lengthSync(), greaterThan(0), reason: '$relative is empty');
    }
  });

  group('inflater content', () {
    test('basic and named constructors produce inflaters', () {
      expect(inflaters, contains('class TextInflater extends Inflater'));
      expect(inflaters, contains('class TestObjectInflater extends Inflater'));
      expect(inflaters, contains('class TestTypeParameters_namedInflater extends Inflater'));
    });

    test('generic specs produce typed inflaters', () {
      expect(inflaters, contains('class TestTypeParametersIntIntInflater'));
      expect(inflaters, contains('class TestTypeParametersStringStringInflater'));
      expect(inflaters, contains('class TestTypeParametersStringTestObjectInflater'));
    });

    test('@InflaterDef annotation is decoded', () {
      expect(inflaters, contains("String get type => 'MyCustom';"));
      expect(inflaters, contains('bool get inflatesOwnChildren => true;'));
      expect(inflaters, contains('bool get inflatesCustomWidget => true;'));
    });

    test('enum params get parseEnum cases', () {
      expect(inflaters, contains("case 'mode': return parseEnum(TestMode.values, value);"));
    });

    test('deprecated optional params and constructors are skipped', () {
      expect(inflaters, isNot(contains("addArg('old'")));
      expect(inflaters, isNot(contains('TestDeprecations.legacy')));
      expect(inflaters, contains("addArg('current'"));
    });

    test('private constructors are skipped', () {
      expect(inflaters, isNot(contains('_internal')));
      expect(inflaters, contains('class TestPrivateCtorInflater'));
    });

    test('config-driven exclusions, defaults, and parsers are applied', () {
      expect(inflaters, isNot(contains("addArg('excludedArg'")));
      expect(inflaters, contains("'fallbackValue'"));
      expect(inflaters, contains("case 'visible': return value.trim();"));
    });

    test('include file is inlined without imports', () {
      expect(inflaters, contains('String testIncludeHelper(String input)'));
      expect(inflaters, isNot(contains("import 'dart:core';")));
    });

    test('function-typed params are wrapped', () {
      expect(inflaters, contains("addFnArg('onCount'"));
      expect(inflaters, contains("addFnArg('makeList'"));
      expect(inflaters, contains("addFnArg('transform'"));
    });
  });

  group('schema content', () {
    test('custom inflaterType names the schema element', () {
      expect(schema, contains('<xs:element name="MyCustom">'));
    });

    test('enum schema types are generated with values', () {
      expect(schema, contains('<xs:simpleType name="TestModeAttributeType">'));
      expect(schema, contains('<xs:enumeration value="alpha"/>'));
      expect(schema, contains('<xs:enumeration value="gamma"/>'));
    });

    test('super formal params resolve docs from the base class', () {
      expect(schema, contains('Documentation that lives on the base class field.'));
    });

    test('excluded attributes are omitted', () {
      expect(schema, isNot(contains('excludedAttr')));
      expect(schema, contains('<xs:attribute name="visible"'));
    });

    test('generic doc references are escaped', () {
      expect(schema, contains('[Map&lt;String, int&gt;]'));
    });
  });

  group('icons content', () {
    test('explicit icons list is registered', () {
      expect(icons, contains("XWidget.registerIcon('Icons.add', Icons.add)"));
      expect(icons, contains("XWidget.registerIcon('Icons.delete', Icons.delete)"));
    });

    test('individual icon set via typed getter is expanded', () {
      expect(icons, contains('CupertinoIcons.'));
    });
  });

  group('controller content', () {
    test('concrete Controller subclasses are registered', () {
      expect(
        controllers,
        contains("XWidget.registerControllerFactoryForName('TestPageController'"),
      );
    });

    test('abstract and unrelated classes are not registered', () {
      expect(controllers, isNot(contains('TestAbstractController')));
      expect(controllers, isNot(contains('TestNotAController')));
    });
  });

  test('outputs match captured baseline', () {
    final baseline = Directory(baselinePath);
    if (!baseline.existsSync()) {
      for (final relative in generatedFiles) {
        final copy = baselineFile(relative);
        copy.parent.createSync(recursive: true);
        generatedFile(relative).copySync(copy.path);
      }
      // First run on this machine: baseline captured, nothing to compare.
      return;
    }

    final mismatches = <String>[];
    for (final relative in generatedFiles) {
      final actual = generatedFile(relative).readAsStringSync();
      final expected = baselineFile(relative).readAsStringSync();
      if (actual != expected) {
        final actualLines = actual.split('\n');
        final expectedLines = expected.split('\n');
        var line = 0;
        while (line < actualLines.length &&
            line < expectedLines.length &&
            actualLines[line] == expectedLines[line]) {
          line++;
        }
        mismatches.add(
          '$relative first differs at line ${line + 1}\n'
          '  baseline: ${line < expectedLines.length ? expectedLines[line] : "<eof>"}\n'
          '  actual:   ${line < actualLines.length ? actualLines[line] : "<eof>"}',
        );
      }
    }
    expect(mismatches, isEmpty, reason: mismatches.join('\n'));
  });

  group('error paths (broken sources)', () {
    late ProcessResult brokenResult;
    late String output;
    late String brokenInflaters;

    setUpAll(() async {
      brokenResult = await runGenerateWithConfig('broken_config.yaml');
      output = '${brokenResult.stdout}';
      brokenInflaters = generatedFile(
        'src/generated/broken/inflaters_broken.g.dart',
      ).readAsStringSync();
    });

    test('errors are logged but the CLI still exits 0', () {
      expect(brokenResult.exitCode, 0);
      expect(output, contains('✘'), reason: 'expected errors:\n$output');
    });

    test('InvalidType property is reported and skipped', () {
      expect(output, contains("InvalidType for property"));
      expect(output, contains("badProperty"));
    });

    test('InvalidType constructor param is reported and omitted', () {
      expect(output, contains("InvalidType for param"));
      expect(output, contains("BrokenWidget"));
      expect(brokenInflaters, contains('class BrokenWidgetInflater'));
      expect(brokenInflaters, contains("addArg('ok'"));
      expect(brokenInflaters, isNot(contains("addArg('broken'")));
    });

    test('generation continues past broken elements', () {
      expect(brokenInflaters, contains('class TestObjectInflater'));
    });
  });
}
