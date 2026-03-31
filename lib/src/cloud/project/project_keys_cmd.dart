import '../../utils/cli_log.dart';
import '../base_cmd.dart';

class ProjectKeysCommand extends BaseCommand {
  @override
  final name = 'keys';

  @override
  final description = 'Retrieve a project\'s secret keys';

  @override
  final invocation = 'keys';

  ProjectKeysCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
    argParser.addOption('project', abbr: 'p', help: 'Project to retrieve the keys for');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;

    // resolve project
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    final keys = await api.getProjectKeys(project.id);

    printTitle(project: project);
    CliLog.info('Project key: ${keys.projectKey}');
    CliLog.info('Storage key: ${keys.storageKey}\n');
  }
}
