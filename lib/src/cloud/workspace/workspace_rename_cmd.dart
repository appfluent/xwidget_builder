import 'package:interact2/interact2.dart';

import '../../utils/cli_log.dart';
import '../../utils/prompts.dart';
import '../base_cmd.dart';

class WorkspaceRenameCommand extends BaseCommand {
  @override
  final name = 'rename';

  @override
  final description = 'Rename an workspace';

  @override
  final invocation = 'rename <name> <new-name>';

  @override
  Future<void> runAuthenticated() async {
    final name = positionalArg(0);
    String? newName = positionalArg(1);

    // resolve workspace
    final workspace = await resolveWorkspace(name);
    printTitle(workspace: workspace);

    // prompt for new name
    newName ??= await AsyncInput(
      prompt: "New workspace name:",
      validator: (input) async {
        final value = input.trim();
        if (value.isEmpty) {
          throw ValidationError("Workspace name is required.");
        }
        if (value.length > 64) {
          throw ValidationError("Workspace name exceeds max length of 64 characters.");
        }
        return true;
      },
    ).interact();

    if (!confirmContinue("Rename workspace to $newName?")) {
      CliLog.info("Rename canceled.\n");
      return;
    }

    // working...
    final renaming = spinnerWorking(inProgressPrompt: "Renaming workspace...");

    try {
      await api.renameWorkspace(workspace.id, newName);
      renaming.done();
    } catch (e) {
      renaming.failed();
      rethrow;
    }
  }
}
