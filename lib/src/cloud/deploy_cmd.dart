import 'dart:io';

import 'package:interact2/interact2.dart';
import 'package:pub_semver/pub_semver.dart';

import '../constants.dart';
import '../utils/ansi.dart';
import '../utils/project_config.dart';
import '../utils/prompts.dart';
import 'api/api_models.dart';
import 'base_cmd.dart';
import '../utils/cli_log.dart';
import '../utils/files.dart';

class DeployCommand extends BaseCommand {
  @override
  final name = 'deploy';

  @override
  final description = 'Deploy project bundle';

  DeployCommand() {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Deployment version (defaults to pubspec.yaml version)',
      )
      ..addOption('notes', abbr: 'n', help: 'Deployment notes')
      ..addOption(
        'publish',
        abbr: 'p',
        valueHelp: 'channel',
        help:
            'Publish the new revision to this channel after deploying. '
            'The channel must already exist.',
      );
  }

  @override
  Future<void> runAuthenticated() async {
    final versionArg = argResults!['version'];
    final notesArg = argResults!['notes'];
    final projectConfig = ProjectConfig();
    final xwidgetVersion = await projectConfig.getXwidgetVersion();
    final minXwidgetVersion = Version.parse("0.6.0");

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
        'required version is 0.6.0.\n',
      );
      return;
    }

    String? projectId = await projectConfig.getId();
    if (projectId == null) {
      // creating a cloud project requires consent — never do it non-interactively
      if (!stdin.hasTerminal) {
        CliLog.error(
          'This project has not been added to the cloud yet. Run '
          '"xc cloud deploy" interactively once to create it.\n',
        );
        exit(1);
      }

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

    // --publish preflight: the channel must already exist. Validated before
    // any prompts or upload so a typo'd channel fails fast, especially in CI.
    final publishArg = (argResults!['publish'] as String?)?.trim();
    Channel? publishChannel;
    if (publishArg != null) {
      if (publishArg.isEmpty) {
        CliLog.error('--publish requires a channel name.');
        exit(1);
      }
      if (!await canPublish(projectId)) {
        CliLog.error('You do not have permission to publish in this project.');
        exit(1);
      }
      publishChannel = await api.lookupChannel(projectId, publishArg, mustExist: false);
      if (publishChannel == null) {
        CliLog.error(
          'Channel "$publishArg" does not exist. Create it first, then '
          'deploy again.\n',
        );
        exit(1);
      }
    }

    // resolve version (arg takes precedence; both paths validate + normalize)
    final projectVersion = await projectConfig.getVersion();
    String? version =
        versionArg ?? (stdin.hasTerminal ? await inputVersion(initialText: projectVersion) : null);
    if (version == null || version.isEmpty) {
      CliLog.error('A version is required.');
      exit(1);
    }
    try {
      version = normalizeVersion(version);
    } on ValidationError catch (e) {
      CliLog.error(e.toString());
      exit(1);
    }

    // prompt for fragments path if not configured (non-interactive: defaults)
    String? fragmentsPath = await projectConfig.getFragmentsPath();
    fragmentsPath ??= stdin.hasTerminal
        ? inputFragmentsPath(defaultFragmentsPath)
        : defaultFragmentsPath;

    // prompt for values path if not configured (non-interactive: defaults)
    String? valuesPath = await projectConfig.getValuesPath();
    valuesPath ??= stdin.hasTerminal ? inputValuesPath(defaultValuesPath) : defaultValuesPath;

    // running non-interactively implies consent to deploy
    final ready = !stdin.hasTerminal || confirmContinue(prompt: "Deploy to cloud?");
    if (!ready) {
      CliLog.warn("Deployment canceled\n");
      return;
    }

    // deploy first — pure deployment, no channel. Publishing is a separate,
    // optional step below.
    final deploying = spinnerWorking(inProgressPrompt: "Deploying $version...");

    final ({String id, int? revision}) deployed;
    try {
      final tarball = await createTarball([
        fragmentsPath,
        valuesPath,
      ], Manifest('version.json', '{"version": "$version"}'));
      deployed = await api.createDeployment(
        projectId: projectId,
        version: version,
        notes: notesArg,
        tarball: tarball,
      );

      deploying.done();
    } catch (e) {
      deploying.failed();
      rethrow;
    }

    final revLabel = deployed.revision != null ? ' rev ${deployed.revision}' : '';

    // publish step — only offered if the user has publishing rights.
    if (!await canPublish(projectId)) {
      CliLog.info('Version $version$revLabel deployed.\n');
      return;
    }

    // --publish resolves the channel up front; otherwise offer interactively
    Channel? channel = publishChannel;
    if (channel == null && stdin.hasTerminal) {
      final publish = confirmContinue(prompt: "Publish this deployment to a channel?");
      if (publish) {
        channel = await resolveChannel(projectId, prompt: "Publish to channel:", allowNew: true);
      }
    }

    if (channel == null) {
      CliLog.info("Deployed $version$revLabel (not published).\n");
      return;
    }

    final publishing = spinnerWorking(
      inProgressPrompt: "Publishing $version to ${channel.name}...",
    );

    try {
      await api.publishDeployment(channelId: channel.id, deploymentId: deployed.id);
      publishing.done();
    } catch (e) {
      publishing.failed();
      if (publishChannel != null) {
        // --publish: the deploy half stands — report it and how to finish
        // the job without redeploying.
        CliLog.error(
          'Deployed $version$revLabel, but publishing to '
          '"${channel.name}" failed: $e\n',
        );
        final recovery = deployed.revision != null
            ? 'xc cloud publish -c ${channel.name} -v $version -r ${deployed.revision}'
            : 'xc cloud publish -c ${channel.name} -v $version';
        CliLog.info('Recover with: ${Ansi.bold}$recovery${Ansi.reset}\n');
        exit(1);
      }
      rethrow;
    }
  }

  // TODO(permissions): wire this to a real permission lookup (e.g. whoami roles
  // or a server-side permission endpoint) once role data is available client-side.
  // Phase 1: all users effectively have deployment:publish, so this returns true.
  // The server enforces the real check on the publish endpoint regardless.
  Future<bool> canPublish(String projectId) async {
    return true;
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
