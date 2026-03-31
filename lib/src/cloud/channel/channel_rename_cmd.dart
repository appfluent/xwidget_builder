import '../../utils/cli_log.dart';
import '../../utils/prompts.dart';
import '../api/cloud_api.dart';
import '../base_cmd.dart';

class ChannelRenameCommand extends BaseCommand {
  @override
  final name = 'rename';

  @override
  final description = 'Rename a channel';

  @override
  final invocation = 'rename <name> <new-name>';

  ChannelRenameCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
    argParser.addOption('project', abbr: 'p', help: 'Project to use');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'];
    final projectArg = argResults!['project'];
    final name = positionalArg(0);
    String? newName = positionalArg(1);

    // resolve workspace and project
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // resolve channel
    final channel = await resolveChannel(project.id, channelName: name);

    // check to see if there are any deployments
    final deployments = await api.getDeployments(
      projectId: project.id,
      channelId: channel.id,
      limit: 1,
    );

    if (deployments.isNotEmpty) {
      CliLog.blankLine();
      CliLog.warn('This channel has deployments.\n');
      CliLog.info(
        'Renaming this channel may cause applications that depend on\n'
        'this name to stop reporting analytics and prevent them from\n'
        'downloading updates. Please make sure to update affected apps\n'
        'as soon as possible.\n',
      );

      printTitle(project: project);

      if (!confirmContinue()) {
        CliLog.info('Rename canceled.\n');
        return;
      }
    }

    if (newName == null) {
      newName = await inputChannelName(
        project.id,
        prompt: 'New channel name:',
        existence: Existence.mustNotExist,
      );
    } else {
      final existing = await api.lookupChannel(project.workspaceId, newName, strict: false);
      if (existing != null) {
        throw CloudException('A channel named "$newName" already exists.');
      }
    }

    if (!confirmContinue('Rename channel "${channel.name}" to "$newName"?')) {
      CliLog.info('Rename canceled.\n');
      return;
    }

    // working...
    final renaming = spinnerWorking(inProgressPrompt: 'Renaming channel...');

    try {
      await api.renameChannel(channel.id, newName);
      renaming.done();
    } catch (e) {
      renaming.failed();
      rethrow;
    }
  }
}
