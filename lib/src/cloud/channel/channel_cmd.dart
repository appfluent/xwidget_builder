import 'package:args/command_runner.dart';

import 'channel_delete_cmd.dart';
import 'channel_list_cmd.dart';
import 'channel_rename_cmd.dart';

class ChannelCommand extends Command {
  @override
  final name = 'channel';

  @override
  final description = 'Manage channels';

  ChannelCommand() {
    addSubcommand(ChannelListCommand());
    addSubcommand(ChannelDeleteCommand());
    addSubcommand(ChannelRenameCommand());
  }
}
