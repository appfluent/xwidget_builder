import 'dart:io';

import 'package:interact2/interact2.dart';
import 'package:pub_semver/pub_semver.dart';

import '../constants.dart';
import '../utils/ansi.dart';
import '../utils/project_config.dart';
import '../utils/prompts.dart';
import 'base_cmd.dart';
import '../utils/cli_log.dart';
import '../utils/files.dart';

class DeployCommand extends BaseCommand {
  @override
  final name = 'deploy';

  @override
  final description = 'Deploy project bundle to a channel';

  DeployCommand() {
    argParser
      ..addOption('channel', abbr: 'c', help: 'Channel to deploy to (e.g., prod, staging, dev)')
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Deployment version (defaults to pubspec.yaml version)',
      )
      ..addOption('notes', abbr: 'n', help: 'Deployment notes');
  }

  @override
  Future<void> runAuthenticated() async {
    final channelArg = argResults!['channel'];
    final versionArg = argResults!['version'];
    final notesArg = argResults!['notes'];
    final projectConfig = ProjectConfig();
    final xwidgetVersion = await projectConfig.getXwidgetVersion();
    final minXwidgetVersion = Version.parse("0.3.0");

    if (xwidgetVersion == null) {
      CliLog.error('XWidget is not listed as a dependency in pubspec.yaml.\n');
      CliLog.info(
        'Run ${Ansi.bold}"dart run xwidget_builder:init"${Ansi.reset} '
        'to initialize an existing app,\nor ${Ansi.bold}"dart run '
        'xwidget_builder:init --new-app${Ansi.reset}" to initialize a new '
        'app.\n',
      );
      return;
    } else if (xwidgetVersion < minXwidgetVersion) {
      CliLog.error(
        'XWidget $xwidgetVersion is not cloud compatible. Minimum '
        'required version is 0.3.0.\n',
      );
      return;
    }

    String? projectId = await projectConfig.getId();
    if (projectId == null) {
      // get project name and description from pubspec
      final projectName = await projectConfig.getName();
      final projectDesc = await projectConfig.getDescription();

      CliLog.note("This project has not been added to the cloud yet.\n");
      CliLog.info(
        "Continuing will create a new cloud project named "
        "'$projectName'\nand generate an xwidget_cloud.yaml config "
        "file in your project root.\n",
      );

      if (!confirmContinue()) {
        CliLog.info("Deploy canceled.\n");
        return;
      }

      final workspace = await selectWorkspace();
      projectId = await api.createProject(workspace.id, projectName!, projectDesc);

      // write project id to cloud config file
      await File("xwidget_cloud.yaml").writeAsString("project_id: $projectId");
    }

    // resolve source channel
    final channel = await resolveChannel(
      projectId,
      channelName: channelArg,
      prompt: "Deployment channel:",
      allowNew: true,
    );

    // resolve version
    final version =
        versionArg ??
        await inputVersion(channel.id, channel.name, initialText: await projectConfig.getVersion());

    final overwrite = await confirmOverwriteVersion(channel.id, version);
    if (!overwrite) {
      CliLog.info("Deployment canceled.\n");
      return;
    }

    // prompt for fragments path if not configured
    String? fragmentsPath = await projectConfig.getFragmentsPath();
    fragmentsPath ??= inputFragmentsPath(defaultFragmentsPath);

    // prompt for values path if not configured
    String? valuesPath = await projectConfig.getValuesPath();
    valuesPath ??= inputValuesPath(defaultValuesPath);

    final ready = confirmContinue("Deploy to cloud?");
    if (!ready) {
      CliLog.warn("Deployment canceled\n");
      return;
    }

    final deploying = spinnerWorking(inProgressPrompt: "Deploying $version to ${channel.name}...");

    try {
      final tarball = await createTarball([
        fragmentsPath,
        valuesPath,
      ], Manifest('version.json', '{"version": "$version"}'));
      await api.createDeployment(
        channelId: channel.id,
        version: version,
        notes: notesArg,
        tarball: tarball,
      );

      deploying.done();
    } catch (e) {
      deploying.failed();
      rethrow;
    }
  }

  String inputFragmentsPath(String defaultValue) {
    return Input(
      prompt: 'Fragments resource path:',
      defaultValue: defaultValue,
      initialText: '',
      validator: isValidAssetPath,
    ).interact();
  }

  String inputValuesPath(String defaultValue) {
    return Input(
      prompt: 'Values resource path:',
      defaultValue: defaultValue,
      initialText: '',
      validator: isValidAssetPath,
    ).interact();
  }

  bool isValidAssetPath(String path) {
    if (path.isEmpty) return false;
    if (path.length > 255) return false;

    // Disallow invalid characters
    final invalidChars = RegExp(r'[<>:"\\|?*\x00-\x1F]');
    if (invalidChars.hasMatch(path)) {
      throw ValidationError("Contains invalid characters");
    }

    // No double slashes or parent directory refs
    if (path.contains('//') || path.contains('..')) {
      throw ValidationError("Double slashes (//) and parent references (..) not allowed");
    }

    // No leading/trailing slashes
    if (path.startsWith('/') || path.endsWith('/')) return false;

    // Check each segment
    final reserved = RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$', caseSensitive: false);
    final segments = path.split('/');

    for (final seg in segments) {
      if (seg.isEmpty) {
        throw ValidationError("Path segment cannot be empty");
      }
      if (seg.endsWith(' ') || seg.endsWith('.')) {
        throw ValidationError("Path segment cannot end with a space or period");
      }
      if (seg.startsWith(' ') || seg.startsWith('.')) {
        throw ValidationError("Path segment cannot start with a space or period");
      }
      if (reserved.hasMatch(seg)) {
        throw ValidationError("Reserved names not allowed: CON, PRN, AUX,NUL, COM1-9, LPT1-9)");
      }
    }

    if (!Directory(path).existsSync()) {
      throw ValidationError('Path does not exist: $path');
    }

    return true;
  }
}
