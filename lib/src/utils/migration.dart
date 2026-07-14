import 'dart:io';

import 'cli_log.dart';
import 'path_resolver.dart';
import 'utils.dart';

/// Migration concerns for adopting the `.xwidget/` config layout and the
/// xwidget.dev namespaces (builder 0.7.0). Collected in one class so a
/// dedicated `migrate` command can be built on top of it later.
class Migration {
  /// Config files that live in [PathResolver.configDir]. Kept in one place
  /// so [migrateConfigFiles] covers every config file the builder knows
  /// about.
  static const configFiles = ['xwidget_config.yaml', 'xwidget_cloud.yaml'];

  static const legacyFragmentNamespace = 'http://www.appfluent.us/xwidget';
  static const fragmentNamespace = 'https://xwidget.dev/fragments';

  /// Migrates every known config file (see [configFiles]) from the project
  /// root into `.xwidget/`. This is the only place config files are moved —
  /// [PathResolver.resolveConfigFile] is a pure lookup — so commands call
  /// this up front to adopt the `.xwidget/` layout in one explicit step.
  /// When copies exist in both locations, the `.xwidget/` copy wins and the
  /// root copy is left for the user to delete — its contents may differ, so
  /// it's not removed silently.
  static Future<void> migrateConfigFiles() async {
    var announced = false;
    for (final fileName in configFiles) {
      final preferredPath = '${PathResolver.configDir}/$fileName';
      final preferredFile = File.fromUri(await PathResolver.relativeToAbsolute(preferredPath));
      final rootFile = File.fromUri(await PathResolver.relativeToAbsolute(fileName));
      if (!rootFile.existsSync()) continue;
      if (preferredFile.existsSync()) {
        CliLog.warn(
          "Found '$fileName' in both '${PathResolver.configDir}/' and the project "
          "root. Using '$preferredPath'. Please delete the root copy.",
        );
        continue;
      }
      if (!announced) {
        CliLog.info("Migrating config files...");
        announced = true;
      }
      await preferredFile.parent.create(recursive: true);
      await rootFile.rename(preferredFile.path);
      CliLog.success("Moved '$fileName' to '$preferredPath'");
    }
    if (announced) {
      CliLog.blankLine();
    }
  }

  /// Warns when fragments under [fragmentsPath] still declare the legacy
  /// namespace. The generated schema and catalog only carry the xwidget.dev
  /// namespaces, so legacy-namespace fragments get no IDE validation or
  /// completion. The fix is a project-wide find and replace — deliberately
  /// left to the user rather than rewriting their source files.
  static Future<void> warnLegacyFragmentNamespaces(String fragmentsPath) async {
    final dirUri = await PathResolver.relativeToAbsolute(fragmentsPath);
    final dir = Directory.fromUri(dirUri);
    if (!dir.existsSync()) return;

    var count = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.xml')) {
        final content = await entity.readAsString();
        if (content.contains('xmlns="$legacyFragmentNamespace"') ||
            content.contains("xmlns='$legacyFragmentNamespace'")) {
          count++;
        }
      }
    }
    if (count > 0) {
      CliLog.warn(
        "Found ${plural(count, 'fragment')} using the legacy namespace "
        "'$legacyFragmentNamespace'.\nReplace with '$fragmentNamespace' "
        "to restore IDE validation and completion.\n"
        "See https://docs.xwidget.dev/getting_started/upgrading/",
      );
    }
  }
}
