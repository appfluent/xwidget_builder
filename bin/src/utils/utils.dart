import 'dart:io';

import 'cli_log.dart';
import 'config_loader.dart';

/// Returns true if [value] is null or empty.
bool isEmpty(String? value) {
  return value == null || value.isEmpty;
}

/// Returns true if [value] is not null and not empty.
bool isNotEmpty(String? value) {
  return !isEmpty(value);
}

/// Parses a string [value] into an enum of type [T].
/// Returns null if [value] is null or empty.
/// Throws an exception if [value] doesn't match any enum name.
T? parseEnum<T extends Enum>(List<T> values, String? value) {
  if (value == null || value.isEmpty) return null;
  for (final type in values) {
    if (type.name == value) {
      return type;
    }
  }
  throw Exception("Problem parsing enum '$value'. Valid values are "
      "${values.asNameMap().keys}");
}

/// Converts a dynamic value (Map, List, or scalar) to YAML format string.
/// [indent] specifies the starting indentation level (default 0).
/// Handles nested structures, multiline strings, and special characters.
String toYaml(dynamic value, {int indent = 0}) {
  final sb = StringBuffer();
  // final pad = ' ' * indent;

  String scalarToYaml(dynamic v) {
    if (v == null) return 'null';
    if (v is bool || v is num) return v.toString();
    var s = v.toString();
    // multiline string -> block scalar
    if (s.contains('\n')) {
      final lines = s.split('\n');
      final block = StringBuffer('|\n');
      for (var line in lines) {
        block.writeln(' ' * (indent + 2) + line);
      }
      return block.toString();
    }
    // quote if contains special YAML chars or starts/ends with space
    final needsQuote = RegExp(r'[:\-\?\[\]\{\},&\*#\!|\>\<%@`]').hasMatch(s) ||
        s.startsWith(' ') ||
        s.endsWith(' ');
    if (needsQuote) return "'${s.replaceAll("'", "''")}'";
    return s;
  }

  void write(dynamic v, int level) {
    final p = ' ' * level;
    if (v is Map) {
      if (v.isEmpty) {
        sb.writeln('${p}{}');
        return;
      }
      for (final entry in v.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is Map || val is List) {
          sb.writeln('$p$key:');
          write(val, level + 2);
        } else {
          final scalar = scalarToYaml(val);
          // scalarToYaml may return a block (with newlines). If so, it already contains indentation.
          if (scalar.contains('\n') && scalar.trimLeft().startsWith('|')) {
            sb.writeln('$p$key: ${scalar.trimLeft()}');
          } else {
            sb.writeln('$p$key: $scalar');
          }
        }
      }
    } else if (v is List) {
      if (v.isEmpty) {
        sb.writeln('${p}[]');
        return;
      }
      for (final item in v) {
        if (item is Map || item is List) {
          sb.writeln('${p}-');
          write(item, level + 2);
        } else {
          final scalar = scalarToYaml(item);
          if (scalar.contains('\n') && scalar.trimLeft().startsWith('|')) {
            sb.writeln('${p}- ${scalar.trimLeft()}');
          } else {
            sb.writeln('${p}- $scalar');
          }
        }
      }
    } else {
      sb.writeln('$p${scalarToYaml(v)}');
    }
  }

  write(value, indent);
  return sb.toString().trimRight();
}

/// Runs a shell command with the given [arguments].
/// Optionally specify a [workingDirectory] for command execution.
/// Returns a [ProcessResult] with exit code, stdout, and stderr.
/// Handles exceptions gracefully by returning error details in stderr.
Future<ProcessResult> runCommand(
    String command,
    List<String> arguments, {
    String? workingDirectory,
}) async {
  try {
    return Process.run(
      command,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  } on ProcessException catch (e) {
    return ProcessResult(-1, e.errorCode, null, "Error running command '$command': ${e.message}");
  } on Exception catch (e) {
    return ProcessResult(-1, -1, null, "Unexpected error running command '$command': $e");
  }
}

/// Retrieves the version of xwidget_builder from its pubspec.yaml file.
/// Returns the version string or "<unknown>" if not found.
Future<String> getBuilderVersion() async {
  final pubspec = await ConfigLoader.loadYamlDoc("xwidget_builder|pubspec.yaml");
  return ConfigLoader.loadToString(pubspec, "version", "<unknown>");
}

/// Resolves Flutter project dependencies by running `flutter pub get`.
/// Returns true if successful, false otherwise.
/// Logs success or error messages via CliLog.
Future<bool> resolveDependencies() async {
  final result = await runCommand("flutter", ["pub", "get"]);
  if (result.exitCode == 0 && result.stderr.toString().isEmpty) {
    CliLog.success("Resolved project dependencies");
    return true;
  } else {
    CliLog.error("Unable to resolve project dependencies. ${result.stderr}");
    return false;
  }
}