import '../utils/utils.dart';
import 'base_cmd.dart';

class UsageCommand extends BaseCommand {
  @override
  final name = 'usage';

  @override
  final description = 'Show workspace usages';

  UsageCommand() {
    argParser.addOption('workspace', abbr: 'w', help: 'Workspace to query');
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'];

    // resolve workspace
    final workspace = await resolveWorkspace(workspaceArg);

    // get workspace usages
    final usages = await api.getWorkspaceUsage(workspace.id);

    printTitle(workspace: workspace);
    printTable(
      ['Metric', 'Period Type', 'Period', 'Limit', 'Used'],
      usages
          .map(
            (w) => [
              w.metric,
              w.periodType,
              w.period,
              w.metric.endsWith("_bytes")
                  ? formatBytes(w.maxAllowed)
                  : formatWithCommas(w.maxAllowed),
              w.metric.endsWith("_bytes") ? formatBytes(w.used) : formatWithCommas(w.used),
            ],
          )
          .toList(),
    );
  }
}
