import 'dart:io';

import 'package:interact2/interact2.dart';

import '../utils/cli_log.dart';
import '../utils/prompts.dart';
import 'base_cmd.dart';

class UnpublishCommand extends BaseCommand {
  @override
  final name = 'unpublish';

  @override
  final description = 'Unpublish a deployment from a channel';

  UnpublishCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Project to use (defaults to project from config)',
    );
    argParser.addOption('channel', abbr: 'c', help: 'Channel to unpublish from');
    argParser.addOption('version', abbr: 'v', help: 'Deployment version to unpublish');
    argParser.addFlag('yes', abbr: 'y', negatable: false, help: 'Skip confirmation prompt');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final channelArg = argResults!['channel'] as String?;
    final versionArg = argResults!['version'] as String?;
    final yes = argResults!['yes'] as bool;

    // Unpublish removes the channel's pointer for a version. The deployment
    // itself is untouched and can be published again later. In a
    // non-interactive environment (e.g. CI) everything required must be
    // supplied — fail fast rather than hang on a prompt.
    final missingRequired = projectArg == null || channelArg == null || versionArg == null;
    final interactive = stdin.hasTerminal;

    if (missingRequired && !interactive) {
      CliLog.error('In non-interactive mode, --project, --channel, and --version are required.');
      exit(1);
    }

    // TODO(non-interactive): resolveProject and resolveChannel (and their
    //   helpers) can still prompt internally even when there's no terminal,
    //   which will hang in CI. To make the non-interactive flow safe, thread
    //   `interactive` (or a `nonInteractive` flag) down through:
    //     - resolveProject   -> error instead of selectProject when the project
    //                           can't be resolved unambiguously.
    //     - resolveWorkspace -> error instead of selectWorkspace when missing/
    //                           ambiguous.
    //     - resolveChannel   -> error instead of selectChannel.
    //     - selectProject / selectWorkspace / selectChannel -> these call
    //                           Select(...).interact() and must not be reached
    //                           in non-interactive mode.
    //   Errors should name exactly what to pass (e.g. "--project X --channel Y")
    //   so a CI failure is actionable. Until then, a non-interactive run with
    //   an unresolvable/ambiguous name can still block on a prompt.

    // resolve projectId
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // resolve channel (must exist — unpublishing from a new channel makes no sense)
    final channel = await resolveChannel(
      project.id,
      channelName: channelArg,
      prompt: 'Unpublish from channel:',
    );

    // resolve version: arg takes precedence; both paths verify the version is
    // actually live on the channel (there's nothing to unpublish otherwise)
    String? version = versionArg;
    if (version == null) {
      version = await inputVersion(
        isRequired: true,
        validator: (value) async {
          final v = normalizeVersion(value);
          final existing = await api.getDeploymentSummary(channel.id, v, mustExist: false);
          if (existing == null) {
            throw ValidationError('Version "$v" is not published on channel "${channel.name}".');
          }
        },
      );
    } else {
      // validate + normalize the --version arg (bypasses the prompt's checks)
      try {
        version = normalizeVersion(version);
      } on ValidationError catch (e) {
        CliLog.error(e.toString());
        exit(1);
      }
      final existing = await api.getDeploymentSummary(channel.id, version, mustExist: false);
      if (existing == null) {
        CliLog.error('Version $version is not published on channel "${channel.name}".');
        exit(1);
      }
    }

    // confirm
    final ok = yes || confirmContinue(prompt: 'Unpublish $version from "${channel.name}"?');
    if (!ok) {
      CliLog.info('Unpublish canceled.\n');
      return;
    }

    final unpublishing = spinnerWorking(
      inProgressPrompt: 'Unpublishing $version from "${channel.name}"...',
    );

    try {
      await api.unpublishDeployment(channelId: channel.id, version: version!);
      unpublishing.done();
    } catch (e) {
      unpublishing.failed();
      rethrow;
    }
  }
}
