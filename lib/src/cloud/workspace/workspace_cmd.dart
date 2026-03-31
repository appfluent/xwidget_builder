import 'package:args/command_runner.dart';

import 'workspace_list_cmd.dart';
import 'workspace_rename_cmd.dart';

class WorkspaceCommand extends Command {
  @override
  final name = 'workspace';

  @override
  final description = 'Manage workspaces';

  WorkspaceCommand() {
    addSubcommand(WorkspaceListCommand());
    addSubcommand(WorkspaceRenameCommand());
    // addSubcommand(WorkspaceMemberCommand());
  }
}
