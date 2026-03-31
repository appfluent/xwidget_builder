import 'package:xwidget_builder/src/cloud/api/cloud_api.dart';

import '../../utils/cli_log.dart';
import '../../utils/prompts.dart';
import '../base_cmd.dart';

class ProjectRenameCommand extends BaseCommand {
  @override
  final name = 'rename';

  @override
  final description = 'Rename a project';

  @override
  final invocation = 'rename <name> <new-name>';

  ProjectRenameCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'];
    final name = positionalArg(0);
    String? newName = positionalArg(1);

    // resolve workspace and project
    final project = await resolveProject(workspaceName: workspaceArg, projectName: name);

    // prompt for new name
    if (newName == null) {
      newName = await inputProjectName(
        project.workspaceId,
        prompt: "New project name:",
        existence: Existence.mustNotExist,
      );
    } else {
      final existing = await api.lookupProject(project.workspaceId, newName, strict: false);
      if (existing != null) {
        throw CloudException("A project named '$newName' already exists.");
      }
    }

    if (!confirmContinue("Rename project to $newName?")) {
      CliLog.info("Rename canceled.\n");
      return;
    }

    // working...
    final renaming = spinnerWorking(inProgressPrompt: "Renaming project...");

    try {
      await api.renameProject(project.id, newName);
      renaming.done();
    } catch (e) {
      renaming.failed();
      rethrow;
    }
  }
}
