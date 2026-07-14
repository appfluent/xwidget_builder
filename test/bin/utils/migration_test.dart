import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xwidget_builder/src/utils/cli_log.dart';
import 'package:xwidget_builder/src/utils/migration.dart';

// Tests for the 0.7.0 config migration and the legacy-namespace warning.
//
// Migration resolves paths against PathResolver.packageRoot, which falls back
// to Directory.current when no .dart_tool/package_config.json exists in an
// ancestor. Each test runs inside a fresh temp dir carrying its own marker so
// path resolution can never escape into the real filesystem.
void main() {
  late Directory tempDir;
  late Directory originalDir;

  File rootFile(String name) => File("${tempDir.path}/$name");
  File configDirFile(String name) => File("${tempDir.path}/.xwidget/$name");

  setUp(() {
    originalDir = Directory.current;
    tempDir = Directory.systemTemp.createTempSync("migration_test");
    // Anchor PathResolver.packageRoot to the temp dir.
    File("${tempDir.path}/.dart_tool/package_config.json")
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages": []}');
    Directory.current = tempDir;
    CliLog.reset();
  });

  tearDown(() {
    Directory.current = originalDir;
    tempDir.deleteSync(recursive: true);
  });

  group("migrateConfigFiles", () {
    test("moves both config files from the root into .xwidget/", () async {
      rootFile("xwidget_config.yaml").writeAsStringSync("fragmentsPath: custom/fragments");
      rootFile("xwidget_cloud.yaml").writeAsStringSync("project_id: p123");

      await Migration.migrateConfigFiles();

      expect(
        configDirFile("xwidget_config.yaml").readAsStringSync(),
        "fragmentsPath: custom/fragments",
      );
      expect(configDirFile("xwidget_cloud.yaml").readAsStringSync(), "project_id: p123");
      expect(rootFile("xwidget_config.yaml").existsSync(), false);
      expect(rootFile("xwidget_cloud.yaml").existsSync(), false);
      expect(CliLog.warnings, 0);
    });

    test("moves only the files that exist", () async {
      rootFile("xwidget_config.yaml").writeAsStringSync("valuesPath: v");

      await Migration.migrateConfigFiles();

      expect(configDirFile("xwidget_config.yaml").existsSync(), true);
      expect(configDirFile("xwidget_cloud.yaml").existsSync(), false);
      expect(CliLog.warnings, 0);
    });

    test("warns and preserves both copies when root and .xwidget both exist", () async {
      configDirFile("xwidget_config.yaml")
        ..createSync(recursive: true)
        ..writeAsStringSync("fragmentsPath: migrated");
      rootFile("xwidget_config.yaml").writeAsStringSync("fragmentsPath: stale");

      await Migration.migrateConfigFiles();

      // .xwidget copy wins and is untouched; the differing root copy is the
      // user's to delete — never removed silently.
      expect(configDirFile("xwidget_config.yaml").readAsStringSync(), "fragmentsPath: migrated");
      expect(rootFile("xwidget_config.yaml").readAsStringSync(), "fragmentsPath: stale");
      expect(CliLog.warnings, 1);
    });

    test("no-ops when everything is already migrated", () async {
      configDirFile("xwidget_config.yaml")
        ..createSync(recursive: true)
        ..writeAsStringSync("a: 1");

      await Migration.migrateConfigFiles();

      expect(configDirFile("xwidget_config.yaml").readAsStringSync(), "a: 1");
      expect(CliLog.warnings, 0);
    });

    test("no-ops on an empty project", () async {
      await Migration.migrateConfigFiles();
      expect(Directory("${tempDir.path}/.xwidget").existsSync(), false);
      expect(CliLog.warnings, 0);
    });
  });

  group("warnLegacyFragmentNamespaces", () {
    test("warns once when legacy-namespace fragments exist", () async {
      File("${tempDir.path}/resources/fragments/old.xml")
        ..createSync(recursive: true)
        ..writeAsStringSync('<Text xmlns="http://www.appfluent.us/xwidget" data="x"/>');
      File("${tempDir.path}/resources/fragments/nested/old2.xml")
        ..createSync(recursive: true)
        ..writeAsStringSync("<Column xmlns='http://www.appfluent.us/xwidget'/>");

      await Migration.warnLegacyFragmentNamespaces("resources/fragments");

      expect(CliLog.warnings, 1);
    });

    test("stays silent for new-namespace fragments", () async {
      File("${tempDir.path}/resources/fragments/new.xml")
        ..createSync(recursive: true)
        ..writeAsStringSync('<Text xmlns="https://xwidget.dev/fragments" data="x"/>');

      await Migration.warnLegacyFragmentNamespaces("resources/fragments");

      expect(CliLog.warnings, 0);
    });

    test("stays silent when the fragments folder does not exist", () async {
      await Migration.warnLegacyFragmentNamespaces("resources/fragments");
      expect(CliLog.warnings, 0);
    });
  });
}
