import 'dart:io';

import 'ansi.dart';
import 'path_resolver.dart';

class CliLog {
  static LoggingOptions options = LoggingOptions();
  static IOSink? _sink;
  static int _warnings = 0;
  static int _errors = 0;
  static bool _lastWasBlank = false;

  static int get warnings => _warnings;
  static int get errors => _errors;

  static void blankLine() {
    if (!_lastWasBlank) info("");
  }

  static void fine(String msg) {
    _output(msg, LogLevel.fine);
  }

  static void info(String msg) {
    _output(msg, LogLevel.info);
  }

  static void bold(String msg) {
    final formatted = _formatMessage(text: msg, bold: true);
    _output(formatted, LogLevel.info);
  }

  static void note(String msg) {
    final formatted = _formatMessage(text: msg, icon: "➤", color: 36, bold: true);
    _output(formatted, LogLevel.info);
  }

  static void success(String msg) {
    final formatted = _formatMessage(text: msg, icon: "✔", iconColor: 32);
    _output(formatted, LogLevel.info);
  }

  static void skip(String msg) {
    final formatted = _formatMessage(text: msg, icon: "✔", color: 2, iconColor: 32);
    _output(formatted, LogLevel.info);
  }

  static void warn(String msg) {
    _warnings++;
    final formatted = _formatMessage(text: msg, icon: "⚠", color: 33);
    _output(formatted, LogLevel.warn);
  }

  static void error(String msg) {
    _errors++;
    final formatted = _formatMessage(text: msg, icon: "✘", color: 31);
    _output(formatted, LogLevel.error);
  }

  static void reset() {
    _warnings = 0;
    _errors = 0;
    _lastWasBlank = false;
  }

  static void resetBlankLines() {
    _lastWasBlank = false;
  }

  static Future<void> withFileLogging(Future<void> Function() app) async {
    try {
      if (_sink == null && options.fileLogLevel != LogLevel.none) {
        final uri = await PathResolver.relativeToAbsolute(options.logFile);
        _sink = File(uri.path).openWrite();
      }
      await app();
    } finally {
      await _sink?.close();
    }
  }

  static void _output(String msg, LogLevel level) {
    if (options.logLevel.index <= level.index) {
      _lastWasBlank = msg.isEmpty || msg.endsWith('\n');
      stdout.writeln(msg);
    }
    if (options.fileLogLevel.index <= level.index) {
      _sink?.writeln(msg);
    }
  }

  static String _formatMessage({
    required String text,
    int? textColor,
    String? icon,
    int? iconColor,
    int? color,
    bool bold = false,
  }) {
    final lines = text.split('\n');
    final firstLine = StringBuffer();

    if (bold) firstLine.write(Ansi.bold);

    // icon formatting
    if (icon != null) {
      final ic = iconColor ?? color;
      if (ic != null) firstLine.write("\x1B[1;${ic}m");
      firstLine.write("$icon ");
      if (ic != null) firstLine.write(Ansi.reset);
    }

    // text formatting
    final tc = textColor ?? color;
    if (tc != null) firstLine.write("\x1B[1;${tc}m");
    firstLine.write(lines.first);
    if (tc != null || bold) firstLine.write(Ansi.reset);

    if (lines.length > 1) {
      final rest = lines.skip(1).join('\n');
      return "$firstLine\n$rest";
    } else {
      return firstLine.toString();
    }
  }
}

class LoggingOptions {
  final LogLevel logLevel;
  final LogLevel fileLogLevel;
  final String logFile;

  LoggingOptions({
    this.logLevel = LogLevel.info,
    this.fileLogLevel = LogLevel.none,
    this.logFile = "xwidget_builder.log",
  });
}

enum LogLevel { fine, info, warn, error, none }
