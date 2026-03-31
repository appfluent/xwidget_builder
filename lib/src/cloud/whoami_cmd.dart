import '../utils/cli_log.dart';
import 'base_cmd.dart';

class WhoamiCommand extends BaseCommand {
  @override
  final name = 'whoami';

  @override
  final description = 'Show current user';

  @override
  Future<void> run() async {
    final whoami = await api.whoami();
    if (whoami != null) {
      CliLog.success("You are logged in as $whoami\n");
    } else {
      CliLog.warn("You are not logged in.\n");
    }
  }
}
