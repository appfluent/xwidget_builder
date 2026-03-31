import 'dart:async';

import '../utils/cli_log.dart';
import 'base_cmd.dart';

class LoginCommand extends BaseCommand {
  @override
  final name = 'login';

  @override
  final description = 'Login to XWidget Cloud';

  @override
  Future<void> run() async {
    CliLog.info("Waiting for authentication... (press Ctrl+C to cancel)");

    try {
      await api.login("google");
      CliLog.success("Login successful.\n");
    } catch (e) {
      CliLog.error("$e\n");
    }
  }
}
