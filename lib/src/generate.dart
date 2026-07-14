import 'package:args/args.dart';

import 'builders/builder.dart';
import 'builders/controllers.dart';
import 'builders/icons.dart';
import 'builders/inflaters.dart';
import 'builders/registry.dart';
import 'utils/cli_log.dart';
import 'utils/commands.dart';
import 'utils/files.dart';
import 'utils/migration.dart';
import 'utils/path_resolver.dart';

// TODO: Add a build function to scan fragments and create a list of all
//  active widgets and then compare it to the spec to see which widgets
//  can be dropped from the spec.

const builderPackage = "xwidget_builder";
const defaultConfigPath = "$builderPackage|res/default_config.yaml";

Future<void> main(List<String> args) async {
  final command = GenerateCommand();
  command.runStandalone(args);
}

class GenerateCommand extends FlexCommand {
  static const builderPackage = "xwidget_builder";
  static const defaultConfigPath = "$builderPackage|res/default_config.yaml";
  static const resDir = "$builderPackage|res";

  @override
  String get description => "Code generation commands";

  @override
  String get name => "generate";

  GenerateCommand() {
    argParser.addFlag(
      "allow-deprecated",
      abbr: "d",
      help: "Allow deprecated constructors and constructor arguments.",
      negatable: false,
    );
    argParser.addOption(
      "schema-docs",
      abbr: "s",
      help:
          "Schema documentation output format. Overrides schema.documentationFormat "
          "in xwidget_config.yaml. Use 'html' for proper formatting in IntelliJ-based IDEs.",
      allowed: ["cdata", "html"],
    );
    argParser.addMultiOption(
      "only",
      help: "Comma separated list of components to generate. Defaults to all components.",
      allowed: ["inflaters", "icons", "controllers"],
      defaultsTo: ["inflaters", "icons", "controllers"],
    );
    argParser.addFlag("no-logo", help: "Suppress logo.", negatable: false);
    argParser.addFlag("no-title", help: "Suppress title.", negatable: false);
  }

  @override
  Future<void> runWith(ArgResults argResults) async {
    // Move any root-level config files into .xwidget/ before anything reads
    // them, so a single generate fully adopts the layout — including
    // xwidget_cloud.yaml, which generate itself never reads.
    await Migration.migrateConfigFiles();
    final configPath = PathResolver.resolveConfigFile("xwidget_config.yaml");
    final allowDeprecated = argResults['allow-deprecated'] == true;
    final schemaFormat = argResults["schema-docs"] as String?;
    final only = argResults['only'] as List<String>;
    CliLog.info("Generating components...");

    // load config files
    final config = BuilderConfig(allowDeprecated: allowDeprecated);
    await config.loadConfig(defaultConfigPath, internal: true);
    await config.loadConfig(configPath);

    if (schemaFormat != null) {
      config.schemaConfig.documentationFormat = schemaFormat;
    }

    // build components
    final buildComponents = <String>{}..addAll(only);
    for (final component in buildComponents) {
      switch (component) {
        case "inflaters":
          await InflaterBuilder(config).build();
          break;
        case "icons":
          await IconsBuilder(config).build();
          break;
        case "controllers":
          await ControllerBuilder(config).build();
          break;
      }
    }

    // always build the registry last, regardless of --only, so it reflects
    // the current state of the filesystem
    await RegistryBuilder(config).build();

    // copy schema files
    const configDir = PathResolver.configDir;
    await Files.copyFiles({
      "$resDir/routes_schema.xsd": "$configDir/routes_schema.g.xsd",
      "$resDir/values_schema.xsd": "$configDir/values_schema.g.xsd",
      "$resDir/schema_catalog.xml": "$configDir/schema_catalog.g.xml",
    }, skipUnchanged: true);

    // generated artifacts live in .xwidget/ as of 0.7.0 — remove stale root
    // copies left behind by earlier versions so IDEs don't resolve outdated
    // schemas. The schema location is internal (not user-configurable), so
    // these root names can only be pre-0.7.0 leftovers.
    await Files.deleteFiles(["xwidget_schema.g.xsd"]);

    // nudge un-migrated projects — legacy-namespace fragments get no IDE
    // validation against the generated schema/catalog
    await Migration.warnLegacyFragmentNamespaces(config.fragmentsPath);

    CliLog.info("Done!\n");
  }
}
