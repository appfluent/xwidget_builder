import '../base_cmd.dart';

class WorkspaceMemberInviteCommand extends BaseCommand {
  @override
  final name = 'invite';

  @override
  final description = 'Invite a user to the workspace by email';

  @override
  final invocation = 'invite <email>';

  WorkspaceMemberInviteCommand() {
    argParser.addOption('role', abbr: 'r', help: 'Workspace role', defaultsTo: 'member');
  }

  @override
  Future<void> runAuthenticated() async {
    final email = requiredPositionalArg(0, 'email');
    final role = argResults!['role'] as String;

    print('Inviting $email as $role...');
    // TODO: Invite member
  }
}
