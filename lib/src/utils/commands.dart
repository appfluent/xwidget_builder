import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../constants.dart';
import 'cli_log.dart';
import 'utils.dart';

abstract class FlexCommand extends Command {
  @override
  Future<void> run() async {
    try {
      runWith(argResults!);
    } catch (e) {
      CliLog.error("$e\n");
      exit(1);
    }
  }

  Future<void> runWith(ArgResults argResults) async {}

  Future<void> runStandalone(List<String> args) async {
    await showStandaloneHeader(args);

    ArgResults results;

    try {
      results = argParser.parse(args);
    } catch (e) {
      if (e is UsageException) {
        CliLog.error("${e.message}\n");
        CliLog.info(e.usage);
      } else if (e is FormatException) {
        CliLog.error("${e.message}\n");
        CliLog.info(usage);
      } else {
        CliLog.error("$e\n");
      }
      exit(1);
    }

    if (results['help'] as bool) {
      print(argParser.usage);
      return;
    }

    await runWith(results);
  }

  Future<void> showStandaloneHeader(List<String> args) async {
    final builderVersion = await getBuilderVersion();
    if (!args.contains("--no-logo")) {
      CliLog.info(logo);
    }
    if (!args.contains("--no-title")) {
      CliLog.info("\x1B[1mXWidget Builder $builderVersion\x1B[0m\n");
    }
  }
}
