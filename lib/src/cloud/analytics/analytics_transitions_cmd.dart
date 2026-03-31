import 'package:pub_semver/pub_semver.dart';

import '../../utils/prompts.dart';
import '../base_cmd.dart';

class AnalyticsTransitionsCommand extends BaseCommand {
  @override
  final name = 'transitions';

  @override
  final description = 'Query page transitions for a project';

  AnalyticsTransitionsCommand() {
    argParser
      ..addOption('workspace', abbr: 'w', help: 'Workspace to query')
      ..addOption('project', abbr: 'p', help: 'Project to query (defaults to current project)')
      ..addOption('channel', abbr: 'c', help: 'Filter by channel name')
      ..addOption('version', abbr: 'v', help: 'Filter by version number')
      ..addOption(
        'platform',
        help: 'Filter by device platform',
        allowed: ['android', 'ios', 'linux', 'macos', 'windows', 'web'],
      )
      ..addOption('from', abbr: 'f', help: 'From page name')
      ..addOption('to', abbr: 't', help: 'To page name')
      ..addOption('locale', abbr: 'l', help: 'Filter by device locale')
      ..addOption('country', help: 'Filter by country')
      ..addOption(
        'range',
        abbr: 'r',
        help: 'Query the past N days',
        allowed: ['7', '14', '30'],
        defaultsTo: '7',
      );
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final channelArg = argResults!['channel'] as String?;
    final versionArg = argResults!['version'] as String?;
    final platformArg = argResults!['platform'] as String?;
    final fromPageArg = argResults!['from'] as String?;
    final toPageArg = argResults!['to'] as String?;
    final localeArg = argResults!['locale'] as String?;
    final countryArg = argResults!['country'] as String?;
    final rangeArg = argResults!['range'] as String?;

    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    final version = versionArg != null ? Version.parse(versionArg) : null;
    final range = int.parse(rangeArg ?? '7');
    final endDate = DateTime.now().toUtc();
    final startDate = endDate.subtract(Duration(days: range));

    int rowCount = 0;
    final loading = spinnerWorking(
      inProgressPrompt: 'Querying page transitions...',
      done: () => 'Transitions query returned $rowCount rows.\n',
      failed: () => 'Transitions query failed.\n',
    );

    try {
      final results = await api.queryPageTransitions(
        startDate: startDate,
        endDate: endDate,
        projectId: project.id,
        channel: channelArg,
        version: versionArg,
        platform: platformArg,
        fromPage: fromPageArg,
        toPage: toPageArg,
        locale: localeArg,
        country: countryArg,
      );

      rowCount = results.length;
      loading.done();

      if (results.isEmpty) return;

      final tableData = results.map((e) => e.toJson()).toList();
      printResults(tableData, {
        'project': (label: 'Project', value: project.name),
        'channel': (label: 'Channel', value: channelArg),
        'version': (label: 'Version', value: version?.toString()),
        'platform': (label: 'Platform', value: platformArg),
        'locale': (label: 'Locale', value: localeArg),
        'countryCode': (label: 'Country', value: countryArg),
        'fromPage': (label: 'From Page', value: fromPageArg),
        'toPage': (label: 'To Page', value: toPageArg),
        'transitions': (label: 'Count', value: null),
        'percentage': (label: 'Avg %', value: null),
        'avgDurationSeconds': (label: 'Avg Time', value: null),
        'range': (label: 'Range', value: 'Last $range days'),
      });
    } catch (e) {
      loading.failed();
      rethrow;
    }
  }
}
