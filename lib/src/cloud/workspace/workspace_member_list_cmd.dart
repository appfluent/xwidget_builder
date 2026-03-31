import '../base_cmd.dart';

class WorkspaceMemberListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'List members in the active workspace';

  WorkspaceMemberListCommand() {
    argParser.addOption('workspace', help: 'Target workspace (default: active workspace)');
    argParser.addOption(
      'format',
      abbr: 'f',
      help: 'Output format',
      defaultsTo: 'table',
      allowed: ['table', 'json'],
    );
  }

  @override
  Future<void> runAuthenticated() async {
    // final workspace = argResults!['workspace'] as String?;
    // final format = argResults!['format'] as String;

    print('Fetching workspace members...');
    // TODO: List workspace members
  }
}
