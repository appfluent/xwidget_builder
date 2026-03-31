import '../utils/cli_log.dart';
import 'base_cmd.dart';

class LogoutCommand extends BaseCommand {
  @override
  final name = 'logout';

  @override
  final description = 'Logout of XWidget Cloud';

  @override
  Future<void> runAuthenticated() async {
    await api.logout();
    CliLog.success("Successfully logged out\n");
  }
}
