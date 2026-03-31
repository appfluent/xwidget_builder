import 'package:xwidget_builder/src/cloud/api/cloud_api.dart';

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
    argParser.addOption(
      'channel',
      abbr: 'c',
      help: 'Delete deployments by channel (uses current project if --project not specified)',
    );
    argParser.addOption('version', abbr: 'v', help: 'Delete deployment by version');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final channelArg = argResults!['channel'] as String?;
    final version = argResults!['version'] as String?;

    if (projectArg == null && channelArg == null) {
      throw CloudException('Either --project or --channel is required');
    }

    // resolve project by name
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    final channel = channelArg != null ? await api.lookupChannel(project.id, channelArg) : null;

    bool ok = false;

    printTitle(project: project);

    if (channel != null && version != null) {
      ok = confirmContinue('Delete deployment version $version from channel "${channel.name}" ?');
    } else if (channel != null) {
      ok = confirmContinue('Delete ALL deployments from channel "${channel.name}"?');
    } else if (projectArg != null && version != null) {
      ok = confirmContinue('Delete deployment version $version from ALL channels?');
    } else if (projectArg != null) {
      ok = confirmContinue('Delete ALL deployments from project "$projectArg"?');
    }

    if (!ok) {
      CliLog.info('Deletion canceled.\n');
      return;
    }

    final deleting = spinnerWorking(inProgressPrompt: 'Deleting deployments...');

    try {
      // promote
      await api.deleteDeployments(projectId: project.id, channelId: channel?.id, version: version);
      deleting.done();
    } catch (e) {
      deleting.failed();
      rethrow;
    }
  }
}
