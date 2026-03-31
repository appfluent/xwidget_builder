import '../../utils/cli_log.dart';
import '../base_cmd.dart';

class WorkspaceListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'List workspaces you belong to';

  WorkspaceListCommand();

  @override
  Future<void> runAuthenticated() async {
    final workspaces = await api.getWorkspaces();

    if (workspaces.isEmpty) {
      CliLog.info('You are not a member of any workspaces.');
      return;
    }

    printTitle(user: await api.whoami());
    printTable(['Workspace', 'Role'], workspaces.map((w) => [w.name, w.roleId]).toList());
  }
}
