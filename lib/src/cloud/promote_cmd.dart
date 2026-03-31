import '../utils/cli_log.dart';
import '../utils/prompts.dart';
import 'base_cmd.dart';

class PromoteCommand extends BaseCommand {
  @override
  final name = 'promote';

  @override
  final description = 'Promote a deployment to a different channel';

  PromoteCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Project to use (defaults to project from config)',
    );
    argParser.addOption('from', help: 'Source channel to promote from');
    argParser.addOption('to', help: 'Target channel to promote to');
    argParser.addOption('version', abbr: 'v', help: 'Deployment version to promote');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final fromArg = argResults!['from'] as String?;
    final toArg = argResults!['to'] as String?;
    final versionArg = argResults!['version'] as String?;

    // resolve projectId
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // resolve source channel
    final fromChannel = await resolveChannel(
      project.id,
      channelName: fromArg,
      prompt: 'From channel:',
    );

    // resolve version
    final version =
        versionArg ??
        await inputVersion(fromChannel.id, fromChannel.name, existence: Existence.mustExist);

    // resolve target channel
    final toChannel = await resolveChannel(
      project.id,
      channelName: toArg,
      prompt: 'To channel:',
      allowNew: true,
    );

    // confirm
    if (!confirmContinue('Promote $version to "${toChannel.name}"?')) {
      CliLog.info('Promotion canceled.\n');
      return;
    }

    final promoting = spinnerWorking(
      inProgressPrompt: 'Promoting version $version to "${toChannel.name}"...',
    );

    try {
      // promote
      await api.promoteDeployment(
        fromChannelId: fromChannel.id,
        toChannelId: toChannel.id,
        version: version,
      );
      promoting.done();
    } catch (e) {
      promoting.failed();
      rethrow;
    }
  }
}
