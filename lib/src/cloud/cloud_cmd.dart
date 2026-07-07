import 'package:args/command_runner.dart';

import 'channel/channel_cmd.dart';
import 'deploy_cmd.dart';
import 'deployment/deployment_cmd.dart';
import 'login_cmd.dart';
import 'logout_cmd.dart';
import 'project/project_cmd.dart';
import 'publish_cmd.dart';
import 'unpublish_cmd.dart';
import 'usage_cmd.dart';
import 'whoami_cmd.dart';
import 'workspace/workspace_cmd.dart';

class CloudCommand extends Command {
  @override
  String get description => "Cloud management commands";

  @override
  String get name => "cloud";

  CloudCommand() {
    addSubcommand(LoginCommand());
    addSubcommand(LogoutCommand());
    addSubcommand(WhoamiCommand());
    addSubcommand(DeployCommand());
    addSubcommand(PublishCommand());
    addSubcommand(UnpublishCommand());
    addSubcommand(WorkspaceCommand());
    addSubcommand(ProjectCommand());
    addSubcommand(DeploymentCommand());
    addSubcommand(ChannelCommand());
    addSubcommand(UsageCommand());
  }
}
