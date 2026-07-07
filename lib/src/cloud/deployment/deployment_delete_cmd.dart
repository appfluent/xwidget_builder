import 'dart:io';

import 'package:interact2/interact2.dart';

import '../../utils/cli_log.dart';
import '../../utils/prompts.dart';
import '../base_cmd.dart';

class DeploymentDeleteCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  final description = 'Delete a deployment';

  @override
  final invocation = 'delete <id>';

  DeploymentDeleteCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Delete deployments by workspace');
    argParser.addOption('project', abbr: 'p', help: 'Delete deployments by project');
    argParser.addOption('version', abbr: 'v', help: 'Delete deployment by version');
    argParser.addOption('revision', abbr: 'r', help: 'Delete deployment by revision');
    argParser.addFlag('yes', abbr: 'y', negatable: false, help: 'Skip confirmation prompt');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final versionArg = argResults!['version'] as String?;
    final revisionArg = argResults!['revision'] as String?;
    final yes = argResults!['yes'] as bool;

    // Interactive when no project was supplied AND we have a terminal to prompt
    // on. In a non-interactive environment (e.g. CI) a missing project is a
    // hard error rather than a hang.
    final interactive = projectArg == null && stdin.hasTerminal;

    if (projectArg == null && !interactive) {
      CliLog.error('The --project option is required in non-interactive mode.');
      exit(1);
    }

    // TODO(non-interactive): resolveProject and its helpers can still prompt
    //   internally even when `interactive` is false, which will hang in CI.
    //   To make the non-interactive flow safe, thread `interactive` (or a
    //   `nonInteractive` flag) down through:
    //     - resolveProject  -> when a project can't be resolved unambiguously,
    //                          throw/log+exit instead of calling selectProject.
    //     - resolveWorkspace -> same: error instead of selectWorkspace when the
    //                          workspace is missing/ambiguous and not interactive.
    //     - selectProject / selectWorkspace -> these call Select(...).interact();
    //                          they must not be reached in non-interactive mode.
    //   The error should tell the caller exactly what to pass
    //   (e.g. "--project X --workspace Y") so a CI failure is actionable.
    //   Until then, a non-interactive run with an unresolvable/ambiguous
    //   project name can still block on a prompt.
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // Args take precedence; interactive prompts only for what wasn't supplied.
    // Non-interactive uses the args as-is (no prompts).
    String? version = versionArg;
    String? revisionStr = revisionArg;

    if (interactive) {
      // inputVersion validates + normalizes and returns null on empty
      version ??= await inputVersion(isRequired: false);
      if (version != null && version.isNotEmpty) {
        revisionStr ??= await inputRevision(isRequired: false);
      }
    }

    // normalize empties to null
    if (version != null && version.isEmpty) version = null;
    if (revisionStr != null && revisionStr.isEmpty) revisionStr = null;

    // validate + normalize the version (the --version arg path bypasses the
    // prompt's validation, so it must be checked here)
    if (version != null) {
      try {
        version = normalizeVersion(version);
      } on ValidationError catch (e) {
        CliLog.error(e.toString());
        exit(1);
      }
    }

    // parse + validate revision (string came from arg or prompt)
    int? revision;
    if (revisionStr != null) {
      revision = int.tryParse(revisionStr);
      if (revision == null) {
        CliLog.error('Revision must be a valid number.');
        exit(1);
      }
      if (revision < 0) {
        CliLog.error('Revision must be >= 0.');
        exit(1);
      }
    }

    // revision requires version
    if (revision != null && version == null) {
      CliLog.error('A version is required when specifying a revision.');
      exit(1);
    }

    printTitle(project: project);

    // confirm based on resolved values, not raw args
    final String prompt;
    if (version != null && revision != null) {
      prompt = 'Delete deployment $version, revision $revision?';
    } else if (version != null) {
      prompt = 'Delete ALL revisions for deployment version $version?';
    } else {
      prompt = 'Delete ALL deployments from project "${project.name}"?';
    }

    final ok = yes || confirmContinue(prompt: prompt);
    if (!ok) {
      CliLog.info('Deletion canceled.\n');
      return;
    }

    final deleting = spinnerWorking(inProgressPrompt: 'Deleting deployments...');
    try {
      await api.deleteDeployments(projectId: project.id, version: version, revision: revision);
      deleting.done();
    } catch (e) {
      deleting.failed();
      rethrow;
    }
  }
}
