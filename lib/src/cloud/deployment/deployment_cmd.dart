import 'package:args/command_runner.dart';

import 'deployment_delete_cmd.dart';
import 'deployment_list_cmd.dart';

class DeploymentCommand extends Command {
  @override
  final name = 'deployment';

  @override
  final description = 'Manage deployments';

  DeploymentCommand() {
    addSubcommand(DeploymentListCommand());
    addSubcommand(DeploymentDeleteCommand());
  }
}
