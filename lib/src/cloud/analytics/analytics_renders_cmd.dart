import 'package:pub_semver/pub_semver.dart';

import '../../utils/prompts.dart';
import '../base_cmd.dart';

class AnalyticsRendersCommand extends BaseCommand {
  @override
  final name = 'renders';

  @override
  final description = 'Query fragment render analytics for a project';

  AnalyticsRendersCommand() {
    argParser
      ..addOption('workspace', abbr: 'w', help: 'Workspace to query')
      ..addOption('project', abbr: 'p', help: 'Project to query (defaults to current project)')
      ..addOption('channel', abbr: 'c', help: 'Filter by channel name')
      ..addOption('version', abbr: 'v', help: 'Filter by version number')
      ..addOption(
        'platform',
        abbr: 't',
        help: 'Filter by device platform',
        allowed: ['android', 'ios', 'linux', 'macos', 'windows', 'web'],
      )
      ..addOption(
        'fragment',
        abbr: 'f',
        help: 'Filter by fragment name (supports wildcards, e.g. "profile/*")',
      )
      ..addOption('locale', abbr: 'l', help: 'Filter by device locale')
      ..addOption('country', help: 'Filter by country')
      ..addOption(
        'range',
        abbr: 'r',
        help: 'Query the past N days',
        allowed: ['7', '14', '30'],
        defaultsTo: '7',
      )
      ..addOption(
        'interval',
        abbr: 'i',
        help: 'Aggregation granularity',
        allowed: ['hourly', 'daily', 'weekly', 'monthly'],
        defaultsTo: 'daily',
      );
  }

  @override
  Future<void> runAuthenticated() async {
    final workspaceArg = argResults!['workspace'] as String?;
    final projectArg = argResults!['project'] as String?;
    final channelArg = argResults!['channel'] as String?;
    final versionArg = argResults!['version'] as String?;
    final platformArg = argResults!['platform'] as String?;
    final fragmentArg = argResults!['fragment'] as String?;
    final localeArg = argResults!['locale'] as String?;
    final countryArg = argResults!['country'] as String?;
    final rangeArg = argResults!['range'] as String?;
    final intervalArg = argResults!['interval'] as String?;

    final project = await resolveProject(workspaceName: workspaceArg, projectName: projectArg);

    final version = versionArg != null ? Version.parse(versionArg) : null;
    final range = int.parse(rangeArg ?? '7');
    final interval = intervalArg ?? 'daily';
    final endDate = DateTime.now().toUtc();
    final startDate = endDate.subtract(Duration(days: range));

    int rowCount = 0;
    final loading = spinnerWorking(
      inProgressPrompt: 'Querying render events...',
      done: () => 'Renders query returned $rowCount rows.\n',
      failed: () => 'Renders query failed.\n',
    );

    try {
      final results = await api.queryRenderEvents(
        startDate: startDate,
        endDate: endDate,
        interval: interval,
        projectId: project.id,
        channel: channelArg,
        version: versionArg,
        platform: platformArg,
        fragment: fragmentArg,
        locale: localeArg,
        country: countryArg,
      );

      rowCount = results.length;
      loading.done();

      if (results.isEmpty) return;

      final tableData = results.map((e) => e.toJson()).toList();
      final fragmentCol = fragmentArg != null && !fragmentArg.contains('*') ? fragmentArg : null;

      printResults(tableData, {
        'project': (label: 'Project', value: project.name),
        'period': (label: 'Period', value: null),
        'channel': (label: 'Channel', value: channelArg),
        'version': (label: 'Version', value: version?.toString()),
        'fragment': (label: 'Fragment', value: fragmentCol),
        'platform': (label: 'Platform', value: platformArg),
        'locale': (label: 'Locale', value: localeArg),
        'countryCode': (label: 'Country', value: countryArg),
        'range': (label: 'Range', value: 'Last $range days'),
        'interval': (label: 'Interval', value: interval),
        'renderCount': (label: 'Renders', value: null),
        'errorCount': (label: 'Errors', value: null),
      });
    } catch (e) {
      loading.failed();
      rethrow;
    }
  }
}
