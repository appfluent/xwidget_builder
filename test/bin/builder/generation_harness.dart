import 'dart:io';

// Shared harness for generation tests.
//
// Generation runs through the real CLI (`dart run xwidget_builder:generate`)
// as a subprocess with the fixture app as the working directory — exactly how
// end users run it. This avoids in-process SDK-path detection problems under
// `flutter test`, and means this harness imports nothing from the package
// itself, so generation tests compile and run unchanged on both sides of an
// analyzer package migration.
//
// IMPORTANT: only generation_test.dart may trigger generation. Test files run
// concurrently in separate isolates, so a second file regenerating the same
// outputs would race.

/// Fixture app location, relative to the xwidget_builder package root
/// (the working directory when running `flutter test`).
const fixturesPath = 'test/fixtures';

/// Captured baseline location. Files are stored with a `.golden` suffix so
/// the Dart analyzer ignores the copies (their relative imports would not
/// resolve from this directory).
const baselinePath = 'test/fixtures/golden_baseline';

/// Generated outputs, relative to [fixturesPath]. The schema path is fixed
/// (internal to the builder, not configurable via xwidget_config.yaml).
const generatedFiles = [
  'src/generated/src/inflaters_test.g.dart',
  'src/generated/src/icons_test.g.dart',
  'src/generated/src/controllers_test.g.dart',
  '.xwidget/fragments_schema.g.xsd',
];

/// Runs the generate CLI from the fixture app root.
Future<ProcessResult> runGenerate([List<String> extraArgs = const []]) {
  return Process.run('dart', [
    'run',
    'xwidget_builder:generate',
    '--no-logo',
    '--no-title',
    ...extraArgs,
  ], workingDirectory: fixturesPath);
}

/// Runs the generate CLI with an alternate config fixture swapped into
/// `.xwidget/xwidget_config.yaml` for the duration of the run. Generate
/// always reads config from that location (there is no --config option),
/// so alternate-config scenarios are exercised by replacing the file.
///
/// The schema output path is fixed, so an alternate-config run overwrites
/// `.xwidget/fragments_schema.g.xsd`. Snapshot and restore it alongside the
/// config so other tests never see the alternate run's schema, regardless
/// of test ordering.
Future<ProcessResult> runGenerateWithConfig(String configFixture) async {
  final configFile = File('$fixturesPath/.xwidget/xwidget_config.yaml');
  final schemaFile = File('$fixturesPath/.xwidget/fragments_schema.g.xsd');
  final originalConfig = configFile.readAsStringSync();
  final originalSchema = schemaFile.existsSync() ? schemaFile.readAsStringSync() : null;
  configFile.writeAsStringSync(File('$fixturesPath/$configFixture').readAsStringSync());
  try {
    return await runGenerate();
  } finally {
    configFile.writeAsStringSync(originalConfig);
    if (originalSchema != null) {
      schemaFile.writeAsStringSync(originalSchema);
    }
  }
}

File generatedFile(String relative) => File('$fixturesPath/$relative');

File baselineFile(String relative) => File('$baselinePath/$relative.golden');
