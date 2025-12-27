import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'constants.dart';
import 'generate.dart' as generate;
import 'utils/cli_log.dart';
import 'utils/files.dart';
import 'utils/package_utils.dart';
import 'utils/utils.dart';
import 'utils/yaml_editor.dart';

const builderPackage = "xwidget_builder";
const exampleDir = "xwidget|example";

const binDir = "$builderPackage|bin";
const pubspecPath = "pubspec.yaml";
const builderPubspecPath = "$builderPackage|pubspec.yaml";

const initDirs = [
  "lib/xwidget/controllers",
  "resources/fragments",
  "resources/values",
];

const initFiles = {
  "$exampleDir/xwidget_config.yaml": "xwidget_config.yaml",
  "$exampleDir/lib/xwidget/icon_spec.dart": "lib/xwidget/icon_spec.dart",
  "$exampleDir/lib/xwidget/inflater_spec.dart": "lib/xwidget/inflater_spec.dart",
  "$exampleDir/resources/values/colors.xml": "resources/values/colors.xml",
  "$exampleDir/resources/values/strings.xml": "resources/values/strings.xml",
};

const newAppFiles = {
  "$exampleDir/lib/xwidget/controllers/app_controller.dart": "lib/xwidget/controllers/app_controller.dart",
  "$exampleDir/resources/fragments/my_app.xml": "resources/fragments/my_app.xml",
};

Future<void> main(List<String> unparsedArgs) async {
  final ArgParser parser = ArgParser();
  parser.addFlag("help", abbr: "h", help: "Usage help", negatable: false);
  parser.addFlag(
      "new-app",
      abbr: "n",
      help: "Sets up a basic XWidget app.",
      negatable: false);
  parser.addFlag(
      "no-logo",
      help: "Suppress logo.",
      negatable: false);

  final builderVersion = await getBuilderVersion();
  if (!unparsedArgs.contains("--no-logo")) CliLog.info(logo);
  CliLog.info("\x1B[1mXWidget Initializer $builderVersion\x1B[0m");

  try {
    final args = parser.parse(unparsedArgs);
    if (args["help"] == true) {
      CliLog.info(parser.usage);
    } else if (args["new-app"]) {
      await initNewApp();
    } else {
      await init();
    }
    CliLog.info("Done!\n");
    await generate.main(["--no-logo"]);
  } on FormatException catch(e) {
    CliLog.error(e.message);
    CliLog.info(parser.usage);
  } catch (e) {
    CliLog.error("$e");
  }
}

Future<void> init() async {
  final pubspec = await YamlEditor.parseFromFile(pubspecPath);
  await updatePubspec(pubspec);
  if (await resolveDependencies()) {
    await Files.createDirs(initDirs);
    await Files.copyFiles(initFiles);
  };
}

Future<void> initNewApp() async {
  stdout.write('Overwrite your current project? (Y/n): ');
  final response = stdin.readLineSync();
  if (response == "y" || response == "Y") {
    final pubspec = await YamlEditor.parseFromFile(pubspecPath);
    await updatePubspec(pubspec);
    if (await resolveDependencies()) {
      await buildMain();
      await Files.createDirs(initDirs);
      await Files.copyFiles(initFiles, true);
      await Files.copyFiles(newAppFiles, true);
    }
  }
}

Future<void> updatePubspec(YamlEditor? pubspec) async {
  if (pubspec != null) {
    await addDependencyIfNeeded(pubspec, "xwidget");
    await addDevDependencyIfNeeded(pubspec, "xwidget_builder");

    addAssetDirIfNeeded(pubspec, "resources/fragments/");
    addAssetDirIfNeeded(pubspec, "resources/values/");

    Files.createFile("pubspec.yaml", pubspec.toYamlString());
    CliLog.success("Updated pubspec.yaml");
  }
}

Future<void> buildMain() async {
  final main = await Files.readFile("$exampleDir/lib/main.dart");
  final mainContents = main.replaceAll("package:xwidget_example/", "");
  Files.createFile("lib/main.dart", mainContents);
}

Future<void> addDependencyIfNeeded(YamlEditor editor, String package) async {
  final version = editor.get('dependencies.$package');
  if (version == null) {
    final packageInfo = await getPackageInfo(package);
    if (packageInfo?.version != null) {
      editor.set("dependencies.$package", packageInfo?.version);
    } else {
      CliLog.error("Problem adding '$package' dependency' - "
          "Cannot find the latest version");
    }
  }
}

Future<void> addDevDependencyIfNeeded(YamlEditor editor, String package) async {
  final version = editor.get('dev_dependencies.$package');
  if (version == null) {
    final packageInfo = await getPackageInfo(package);
    if (packageInfo?.version != null) {
      editor.set("dev_dependencies.$package", packageInfo?.version);
    } else {
      CliLog.error("Problem adding '$package' dev dependency' - "
          "Cannot find the latest version");
    }
  }
}

void addAssetDirIfNeeded(YamlEditor editor, String dir) {
  var assets = editor.get("flutter.assets");
  if (assets == null || (assets is YamlList && !assets.contains(dir))) {
    editor.set("flutter.assets[-1]", dir);
  }
}