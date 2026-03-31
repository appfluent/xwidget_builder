import '../../utils/cli_log.dart';
import '../base_cmd.dart';

class ProjectListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'List projects in the active workspace';

  ProjectListCommand() {
    argParser.addOption(
      'workspace',
      abbr: 'w',
      help: 'Workspace to query (auto-detected by default)',
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show additional details (id, description, created, updated)',
      negatable: false,
    );
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final verbose = argResults!['verbose'] as bool;

    // resolve workspace
    final workspace = await resolveWorkspace(workspaceArg);

    printTitle(workspace: workspace);

    // get project for workspace
    final projects = await api.getProjects(workspace.id);

    if (projects.isEmpty) {
      CliLog.blankLine();
      CliLog.info('No projects found.\n');
      return;
    }

    if (verbose) {
      printTable(
        ['ID', 'Project', 'Created At', 'Updated At', 'Description'],
        projects.map((p) => [p.id, p.name, p.createdAt, p.updatedAt, p.description ?? '']).toList(),
      );
    } else {
      printTable([
        'Project',
        'Created At',
        'Updated At',
      ], projects.map((p) => [p.name, p.createdAt, p.updatedAt]).toList());
    }
  }
}
