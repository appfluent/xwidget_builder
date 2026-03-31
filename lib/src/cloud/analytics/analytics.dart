import 'package:args/command_runner.dart';
import 'analytics_downloads_cmd.dart';
import 'analytics_errors_cmd.dart';
import 'analytics_renders_cmd.dart';
import 'analytics_transitions_cmd.dart';

class AnalyticsCommand extends Command {
  @override
  final name = 'analytics';

  @override
  final description = 'Query project analytics';

  AnalyticsCommand() {
    addSubcommand(AnalyticsRendersCommand());
    addSubcommand(AnalyticsDownloadsCommand());
    addSubcommand(AnalyticsErrorsCommand());
    addSubcommand(AnalyticsTransitionsCommand());
  }
}
