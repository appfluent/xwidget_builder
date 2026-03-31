import 'package:args/command_runner.dart';

import 'workspace_member_invite_cmd.dart';
import 'workspace_member_list_cmd.dart';
import 'workspace_member_remove_cmd.dart';

class WorkspaceMemberCommand extends Command {
  @override
  final name = 'member';

  @override
  final description = 'Manage workspace members';

  WorkspaceMemberCommand() {
    addSubcommand(WorkspaceMemberListCommand());
    addSubcommand(WorkspaceMemberInviteCommand());
    addSubcommand(WorkspaceMemberRemoveCommand());
  }
}
