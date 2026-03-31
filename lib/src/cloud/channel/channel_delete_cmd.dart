import 'package:xwidget_builder/src/utils/cli_log.dart';

import '../../utils/prompts.dart';
import '../../utils/utils.dart';
import '../api/api_models.dart';
import '../base_cmd.dart';

class ChannelDeleteCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  final description = 'Delete a channel';

  @override
  final invocation = 'delete <channel>';

  ChannelDeleteCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
    argParser.addOption('project', abbr: 'p', help: 'Project to use');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'];
    final projectArg = argResults!['project'];
    final channelArg = requiredPositionalArg(0, "channel");

    // resolve projectId
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // resolve source channel
    final channel = await resolveChannel(
      project.id,
      channelName: channelArg,
      prompt: 'Delete channel:',
    );

    printTitle(project: project);

    // confirm
    if (!confirmContinue(
      'Delete channel "${channel.name}" and '
      'ALL its deployments?',
    )) {
      CliLog.info("Deletion canceled.\n");
      return;
    }

    ChannelDeletes? deletes;
    final deleting = spinnerWorking(
      inProgressPrompt: 'Deleting channel "${channel.name}"...',
      done: () {
        return deletes != null
            ? '${plural(deletes.channels, "channel")}, '
                  '${plural(deletes.deployments, "deployment")} deleted.\n'
            : 'Done!\n';
      },
    );

    try {
      deletes = await api.deleteChannel(channel.id);
      deleting.done();
    } catch (e) {
      deleting.failed();
      rethrow;
    }
  }
}
