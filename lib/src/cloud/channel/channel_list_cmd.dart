import '../../utils/cli_log.dart';
import '../base_cmd.dart';

class ChannelListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'List channels, optionally filtered by project';

  ChannelListCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to query');
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Project to query (defaults to current project)',
    );
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;

    // resolve project
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // get channels
    final channels = await api.getChannels(project.id);

    if (channels.isEmpty) {
      CliLog.info('No channels found.\n');
      return;
    }

    printTitle(project: project);
    printTable([
      'Channel',
      'Created At',
      'Updated At',
    ], channels.map((p) => [p.name, p.createdAt, p.updatedAt]).toList());
  }
}
