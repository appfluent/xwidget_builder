import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:xwidget_builder/src/cloud/analytics/analytics.dart';
import 'package:xwidget_builder/src/cloud/base_cmd.dart' hide BaseCommand;

import 'cloud/api/cloud_api.dart';
import 'cloud/cloud_cmd.dart';
import 'constants.dart';
import 'generate.dart';
import 'initialize.dart';
import 'utils/cli_log.dart';
import 'utils/utils.dart';

void main(List<String> args) async {
  final runner = CommandRunner('cli', 'XWidget CLI')
    ..argParser.addFlag('version', help: 'Print version number', negatable: false)
    ..argParser.addFlag("no-logo", help: "Suppress logo.", negatable: false)
    ..addCommand(AnalyticsCommand())
    ..addCommand(CloudCommand())
    ..addCommand(GenerateCommand())
    ..addCommand(InitializeCommand());

  try {
    if (!args.contains("--no-logo")) CliLog.info(logo);

    final results = runner.argParser.parse(args);
    if (results['version'] as bool) {
      CliLog.info("Version ${await getBuilderVersion()}\n");
      return;
    }

    await runner.run(args);
  } catch (e, stackTrace) {
    if (e is UsageException) {
      CliLog.error("${e.message}\n");
      CliLog.info(e.usage);
    } else if (e is FormatException) {
      CliLog.error("${e.message}\n");
    } else if (e is ArgumentError) {
      CliLog.error("${e.message}\n");
    } else if (e is CloudException) {
      CliLog.error("${e.message}\n");
    } else if (e is CanceledException) {
      CliLog.info("${e.message}\n");
    } else {
      CliLog.error("$e\n");
      CliLog.info("$stackTrace");
    }
    exit(1);
  }
}
