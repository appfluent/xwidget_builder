import '../../utils/cli_log.dart';
import '../base_cmd.dart';

class DeploymentListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'List deployments, optionally filtered by project or channel';

  DeploymentListCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to query');
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Project to query (defaults to current project)',
    );
    argParser.addOption('channel', abbr: 'c', help: 'Channel to filter by');
    argParser.addOption('version', abbr: 'v', help: 'Deployment version to filter by');
    argParser.addOption(
      'limit',
      abbr: 'l',
      help: 'Maximum number of results to return',
      defaultsTo: '10',
    );
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final channelArg = argResults!['channel'] as String?;
    final version = argResults!['version'] as String?;
    final limit = int.tryParse(argResults!['limit'] as String);

    // resolve projectId
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    // resolve channel by name
    final channel = channelArg != null ? await api.lookupChannel(project.id, channelArg) : null;

    final deployments = await api.getDeployments(
      projectId: project.id,
      channelId: channel?.id,
      version: version,
      limit: limit ?? 10,
    );

    if (deployments.isEmpty) {
      CliLog.info('No deployments found.\n');
      return;
    }

    printTitle(project: project);
    printTable(
      ['Channel', 'Version', 'Size (KB)', 'Deployed By', 'Created At', "Updated At"],
      deployments
          .map(
            (d) => [
              d.channelName,
              d.version,
              (d.sizeBytes / 1000).toStringAsFixed(1),
              d.deployedByUserName ?? '',
              d.createdAt,
              d.updatedAt,
            ],
          )
          .toList(),
    );
  }
}
