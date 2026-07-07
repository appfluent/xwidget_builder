import 'package:interact2/interact2.dart';

import '../../utils/cli_log.dart';
import '../../utils/prompts.dart';
import '../api/cloud_api.dart';
import '../base_cmd.dart';

class ProjectRotateKeyCommand extends BaseCommand {
  @override
  final name = 'rotate-key';

  @override
  final description = 'Rotate project key';

  @override
  final invocation = 'rotate-key';

  ProjectRotateKeyCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to use');
    argParser.addOption('project', abbr: 'p', help: 'Project to retrieve the key for');
    argParser.addOption('grace', abbr: 'g', help: 'Days the old project key remains valid');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final graceArg = argResults!['grace'] as String?;

    CliLog.warn('This will generate a new key for project authentication.\n');
    CliLog.info(
      'Your current key will remain valid for the grace period you '
      'choose\n(0-90 days, default 7), giving you time to update clients.\n',
    );

    // resolve project
    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    int? graceDays = int.tryParse(graceArg ?? '');
    if (graceArg == null || graceDays == null) {
      graceDays =
          int.tryParse(
            Input(
              prompt: 'Grace period (days):',
              defaultValue: '7',
              validator: (input) {
                final value = input.trim();
                if (value.isEmpty) {
                  throw ValidationError('Grace period is required.');
                }
                final grace = int.tryParse(value);
                if (grace == null) {
                  throw ValidationError('Grace period must be an integer.');
                }
                if (grace < 0 || grace > 90) {
                  throw ValidationError('Grace period must be between 0 and 90.');
                }
                return true;
              },
            ).interact(),
          ) ??
          7;
    } else if (graceDays < 0 || graceDays > 90) {
      throw CloudException('Grace period must be between 0 and 90.');
    }

    if (!confirmContinue(prompt: 'Rotate key for project "${project.name}"?')) {
      CliLog.info('Key rotation canceled.');
      return;
    }

    final rotating = spinnerWorking(inProgressPrompt: "Rotating key...");

    try {
      final key = await api.rotateProjectKey(project.id, graceDays: graceDays);
      rotating.done();

      CliLog.blankLine();
      CliLog.info('New project key: $key\n');
    } catch (e) {
      rotating.failed();
      rethrow;
    }
  }
}
