import 'package:args/args.dart';
import 'package:xwidget_builder/src/utils/prompts.dart';
import 'package:yaml/yaml.dart';

import 'constants.dart';
import 'generate.dart';
import 'utils/cli_log.dart';
import 'utils/commands.dart';
import 'utils/files.dart';
import 'utils/package_utils.dart';
import 'utils/utils.dart';
import 'utils/yaml_editor.dart';

Future<void> main(List<String> args) async {
  final command = InitializeCommand();
  await command.runStandalone(args);
}

class InitializeCommand extends FlexCommand {
  static const initDirs = ["lib/xwidget/controllers", defaultFragmentsPath, defaultValuesPath];

  static const initFiles = {
    "$exampleDir/xwidget_config.yaml": "xwidget_config.yaml",
    "$exampleDir/lib/xwidget/icon_spec.dart": "lib/xwidget/icon_spec.dart",
    "$exampleDir/lib/xwidget/inflater_spec.dart": "lib/xwidget/inflater_spec.dart",
    "$exampleDir/$defaultValuesPath/colors.xml": "$defaultValuesPath/colors.xml",
    "$exampleDir/$defaultValuesPath/strings.xml": "$defaultValuesPath/strings.xml",
  };

  static const newAppFiles = {
    "$exampleDir/lib/xwidget/controllers/app_controller.dart":
        "lib/xwidget/controllers/app_controller.dart",
    "$exampleDir/$defaultFragmentsPath/my_app.xml": "$defaultFragmentsPath/my_app.xml",
    "$exampleDir/$defaultFragmentsPath/count.xml": "$defaultFragmentsPath/count.xml",
  };

  static const builderPackage = "xwidget_builder";
  static const exampleDir = "xwidget|example";

  static const binDir = "$builderPackage|bin";
  static const pubspecPath = "pubspec.yaml";
  static const builderPubspecPath = "$builderPackage|pubspec.yaml";

  @override
  String get description => "Project setup and configuration commands";

  @override
  String get name => "init";

  InitializeCommand() {
    argParser.addFlag("new-app", abbr: "n", help: "Sets up a basic XWidget app.", negatable: false);
    argParser.addFlag("no-logo", help: "Suppress logo.", negatable: false);
  }

  @override
  Future<void> runWith(ArgResults argResults) async {
    final initialized = argResults["new-app"] ? await initNewApp() : await init();

    if (initialized) {
      CliLog.info("Done!\n");
      final command = GenerateCommand();
      await command.runStandalone(["--no-logo", "--no-title"]);
    } else {
      CliLog.info("Canceled.\n");
    }
  }

  Future<bool> init() async {
    CliLog.info("Initializing existing project...");
    final pubspec = await YamlEditor.parseFromFile(pubspecPath);
    await updatePubspec(pubspec);
    if (await resolveDependencies()) {
      await Files.createDirs(initDirs);
      await Files.copyFiles(initFiles, existsLogger: CliLog.skip);
      return true;
    }
    return false;
  }

  Future<bool> initNewApp() async {
    final overwrite = confirmContinue('Overwrite your current project?');
    if (overwrite) {
      CliLog.info("\nInitializing new project...");
      final pubspec = await YamlEditor.parseFromFile(pubspecPath);
      await updatePubspec(pubspec);
      if (await resolveDependencies()) {
        await buildMain();
        await Files.createDirs(initDirs);
        await Files.copyFiles(initFiles, replace: true);
        await Files.copyFiles(newAppFiles, replace: true);
        return true;
      }
    }
    return false;
  }

  Future<void> updatePubspec(YamlEditor? pubspec) async {
    if (pubspec != null) {
      await addDependencyIfNeeded(pubspec, "xwidget");
      await addDevDependencyIfNeeded(pubspec, "xwidget_builder");

      addAssetDirIfNeeded(pubspec, "$defaultFragmentsPath/");
      addAssetDirIfNeeded(pubspec, "$defaultValuesPath/");

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
        CliLog.error(
          "Problem adding '$package' dependency' - "
          "Cannot find the latest version",
        );
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
        CliLog.error(
          "Problem adding '$package' dev dependency' - "
          "Cannot find the latest version",
        );
      }
    }
  }

  void addAssetDirIfNeeded(YamlEditor editor, String dir) {
    var assets = editor.get("flutter.assets");
    if (assets == null || (assets is YamlList && !assets.contains(dir))) {
      editor.set("flutter.assets[-1]", dir);
    }
  }
}
