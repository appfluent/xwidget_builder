import '../base_cmd.dart';

class WorkspaceMemberRemoveCommand extends BaseCommand {
  @override
  final name = 'remove';

  @override
  final description = 'Remove a member from the workspace';

  @override
  final invocation = 'remove <user>';

  WorkspaceMemberRemoveCommand() {
    argParser.addFlag('force', help: 'Skip confirmation prompt', negatable: false);
  }

  @override
  Future<void> runAuthenticated() async {
    final user = requiredPositionalArg(0, 'user');
    final force = argResults!['force'] as bool;

    if (!force) {
      // TODO: Prompt for confirmation
    }

    print('Removing $user from workspace...');
    // TODO: Remove member
  }
}
