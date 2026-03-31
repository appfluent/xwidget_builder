import 'package:args/command_runner.dart';
import 'package:xwidget_builder/src/cloud/project/project_key_rotate_cmd.dart';

import 'project_delete_cmd.dart';
import 'project_list_cmd.dart';
import 'project_rename_cmd.dart';
import 'project_keys_cmd.dart';

class ProjectCommand extends Command {
  @override
  final name = 'project';

  @override
  final description = 'Manage projects';

  ProjectCommand() {
    addSubcommand(ProjectListCommand());
    addSubcommand(ProjectDeleteCommand());
    addSubcommand(ProjectRenameCommand());
    addSubcommand(ProjectKeysCommand());
    addSubcommand(ProjectRotateKeyCommand());
  }
}
