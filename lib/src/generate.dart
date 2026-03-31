import 'package:args/args.dart';

import 'builders/builder.dart';
import 'builders/controllers.dart';
import 'builders/icons.dart';
import 'builders/inflaters.dart';
import 'utils/cli_log.dart';
import 'utils/commands.dart';

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

  @override
  String get description => "Code generation commands";

  @override
  String get name => "generate";

  GenerateCommand() {
    argParser.addOption(
      "config",
      abbr: "c",
      help: "Path to config file",
      defaultsTo: "xwidget_config.yaml",
    );
    argParser.addFlag(
      "allow-deprecated",
      abbr: "d",
      help: "Allow deprecated constructors and constructor arguments.",
      negatable: false,
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
    final configPath = argResults['config'] as String;
    final allowDeprecated = argResults['allow-deprecated'] == true;
    final only = argResults['only'] as List<String>;
    CliLog.info("Generating components...");

    // load config files
    final config = BuilderConfig(allowDeprecated: allowDeprecated);
    await config.loadConfig(defaultConfigPath);
    await config.loadConfig(configPath);

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
    CliLog.info("Done!\n");
  }
}
