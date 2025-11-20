import 'package:args/args.dart';

import 'builders/builder.dart';
import 'builders/controllers.dart';
import 'builders/icons.dart';
import 'builders/inflaters.dart';
import 'utils/cli_log.dart';
import 'utils/config_loader.dart';

// TODO: Add a build function to scan fragments and create a list of all
//  active widgets and then compare it to the spec to see which widgets
//  can be dropped from the spec.

const builderPackage = "xwidget_builder";
const pubspecPath = "$builderPackage|pubspec.yaml";
const defaultConfigPath = "$builderPackage|res/default_config.yaml";

Future<void> main(List<String> unparsedArgs) async {
  final pubspec = await ConfigLoader.loadYamlDocument(pubspecPath);
  final version = ConfigLoader.loadToString(pubspec, "version", "<unknown>");
  CliLog.info("XWidget Builder (version $version)");

  final ArgParser parser = ArgParser();
  parser.addFlag("help", abbr: "h", help: "Usage help", negatable: false);
  parser.addOption(
      "config",
      abbr: "c",
      help: "Path to config file",
      defaultsTo: "xwidget_config.yaml");
  parser.addFlag(
      "allow-deprecated",
      abbr: "d",
      help: "Allow deprecated constructors and constructor arguments.",
      negatable: false);
  parser.addMultiOption(
      "only",
      help: "Comma separated list of components to generate. Defaults to all components.",
      allowed: ["inflaters", "icons", "controllers"],
      defaultsTo: ["inflaters", "icons", "controllers"]);

  final args = parser.parse(unparsedArgs);
  if (args["help"] == true) {
    CliLog.info(parser.usage);
    return;
  }

  // load config files
  final allowDeprecated = args["allow-deprecated"] == true;
  final config = BuilderConfig(allowDeprecated: allowDeprecated);
  await config.loadConfig(defaultConfigPath);
  await config.loadConfig(args["config"]);

  // build components
  final buildComponents = <String>{}..addAll(args["only"]);
  for (final component in buildComponents) {
    switch (component) {
      case "inflaters": await InflaterBuilder(config).build(); break;
      case "icons": await IconsBuilder(config).build(); break;
      case "controllers": await ControllerBuilder(config).build(); break;
    }
  }

  CliLog.info("Done!");
}
