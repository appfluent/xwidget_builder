import 'dart:io';

import 'package:interact2/interact2.dart';

import '../utils/cli_log.dart';
import '../utils/prompts.dart';
import 'base_cmd.dart';

class PublishCommand extends BaseCommand {
  @override
  final name = 'publish';

  @override
  final description = 'Publish a deployment to a channel';

  PublishCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Project to use (defaults to project from config)',
    );
    argParser.addOption('channel', abbr: 'c', help: 'Target channel to publish to');
    argParser.addOption('deployment-id', abbr: 'd', help: 'Deployment to publish');
    argParser.addOption('version', abbr: 'v', help: 'Deployment version to publish');
    argParser.addOption('revision', abbr: 'r', help: 'Deployment revision to publish');
    argParser.addFlag('yes', abbr: 'y', negatable: false, help: 'Skip confirmation prompt');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final channelArg = argResults!['channel'] as String?;
    final deploymentIdArg = argResults!['deployment-id'] as String?;
    final versionArg = argResults!['version'] as String?;
    final revisionArg = argResults!['revision'] as String?;
    final yes = argResults!['yes'] as bool;

    // Publish targets a channel and identifies the deployment either by
    // --deployment-id, or by --version and --revision together. In a
    // non-interactive environment (e.g. CI) everything required must be
    // supplied — fail fast rather than hang on a prompt.
    final hasDeploymentRef = deploymentIdArg != null || (versionArg != null && revisionArg != null);
    final missingRequired = projectArg == null || channelArg == null || !hasDeploymentRef;
    final interactive = stdin.hasTerminal;

    if (missingRequired && !interactive) {
      CliLog.error(
        'In non-interactive mode, --project, --channel, and either '
        '--deployment-id or both --version and --revision are required.',
      );
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
    //     - resolveChannel   -> error instead of selectChannel; and note
    //                           `allowNew` triggers createNewChannel which
    //                           prompts for a new channel name.
    //     - selectProject / selectWorkspace / selectChannel -> these call
    //                           Select(...).interact() and must not be reached
    //                           in non-interactive mode.
    //   Errors should name exactly what to pass (e.g. "--project X --channel Y")
    //   so a CI failure is actionable. Until then, a non-interactive run with
    //   an unresolvable/ambiguous name can still block on a prompt.

    // resolve projectId
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // resolve target channel
    final channel = await resolveChannel(
      project.id,
      channelName: channelArg,
      prompt: 'Publish to channel:',
      allowNew: true,
    );

    // identify the deployment: --deployment-id wins; otherwise version + revision
    // (args take precedence; interactive prompts only for what wasn't supplied)
    String? deploymentId = deploymentIdArg;
    String? version = versionArg;
    int? revision;

    if (deploymentId == null) {
      // version: arg takes precedence; prompt validates existence against the db
      if (version == null) {
        version = await inputVersion(
          isRequired: true,
          validator: (value) async {
            final v = normalizeVersion(value);
            final exists = await api.hasDeployments(projectId: project.id, version: v);
            if (!exists) {
              throw ValidationError('No deployments found for version "$v".');
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
        final exists = await api.hasDeployments(projectId: project.id, version: version);
        if (!exists) {
          CliLog.error('No deployments found for version "$version".');
          exit(1);
        }
      }

      // revision: arg takes precedence; prompt validates existence against the db
      String? revisionStr = revisionArg;
      revisionStr ??= await inputRevision(
        isRequired: true,
        validator: (value) async {
          final exists = await api.hasDeployments(
            projectId: project.id,
            version: version!,
            revision: int.parse(value),
          );
          if (!exists) {
            throw ValidationError('Revision $value does not exist for version $version.');
          }
        },
      );
      revision = int.tryParse(revisionStr ?? '');
      if (revision == null) {
        CliLog.error('Revision must be a valid number.');
        exit(1);
      }
      if (revision < 0) {
        CliLog.error('Revision must be >= 0.');
        exit(1);
      }

      // the exact revision must exist (covers the --revision arg path;
      // the prompt path was already validated inline)
      if (revisionArg != null) {
        final exists = await api.hasDeployments(
          projectId: project.id,
          version: version!,
          revision: revision,
        );
        if (!exists) {
          CliLog.error('Revision $revision does not exist for version $version.');
          exit(1);
        }
      }
    }

    // confirm
    final target = deploymentId != null ? 'deployment $deploymentId' : '$version (rev $revision)';
    final ok = yes || confirmContinue(prompt: 'Publish $target to "${channel.name}"?');
    if (!ok) {
      CliLog.info('Publish canceled.\n');
      return;
    }

    final publishing = spinnerWorking(
      inProgressPrompt: 'Publishing $target to "${channel.name}"...',
    );

    try {
      await api.publishDeployment(
        channelId: channel.id,
        deploymentId: deploymentId,
        projectId: deploymentId == null ? project.id : null,
        version: deploymentId == null ? version : null,
        revision: deploymentId == null ? revision : null,
      );
      publishing.done();
    } catch (e) {
      publishing.failed();
      rethrow;
    }
  }
}
