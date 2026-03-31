import '../../utils/cli_log.dart';
import '../../utils/project_config.dart';
import '../../utils/prompts.dart';
import '../../utils/utils.dart';
import '../api/api_models.dart';
import '../base_cmd.dart';

class ProjectDeleteCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  final description = 'Delete a project and all its deployments';

  @override
  final invocation = 'delete <project>';

  ProjectDeleteCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to query');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'];
    final projectName = requiredPositionalArg(0, 'project');
    final projectConfig = ProjectConfig();

    // resolve workspace and project
    final project = await resolveProject(
      workspaceName: workspaceArg,
      projectName: projectName,
      projectConfig: projectConfig,
    );

    // confirm deletion
    if (!confirmContinue(
      'Delete "$projectName" and '
      'ALL its channels and deployments?',
    )) {
      CliLog.info('Deletion canceled.\n');
      return;
    }

    ProjectDeletes? deletes;
    final deleting = spinnerWorking(
      inProgressPrompt: 'Deleting project "${project.name}"...',
      done: () {
        return deletes != null
            ? '${plural(deletes.projects, "project")}, '
                  '${plural(deletes.channels, "channel")}, '
                  '${plural(deletes.deployments, "deployment")} deleted.\n'
            : 'Done!\n';
      },
    );

    try {
      deletes = await api.deleteProject(project.id);

      final localProjectId = await projectConfig.getId();
      if (localProjectId == project.id) {
        await projectConfig.deleteCloudConfig();
      }

      deleting.done();
    } catch (e) {
      deleting.failed();
      rethrow;
    }
  }
}
