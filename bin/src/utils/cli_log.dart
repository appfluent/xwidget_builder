import 'dart:io';

import 'path_resolver.dart';

class CliLog {
  static LoggingOptions options = LoggingOptions();
  static IOSink? _sink;
  static int _warnings = 0;
  static int _errors = 0;

  static int get warnings => _warnings;
  static int get errors => _errors;

  static void fine(String msg) {
    if (options.logLevel.index <= LogLevel.fine.index) {
      print(msg);
    }
    if (options.fileLogLevel.index <= LogLevel.fine.index) {
      _sink?.writeln(msg);
    }
  }

  static void info(String msg) {
    if (options.logLevel.index <= LogLevel.info.index) {
      print(msg);
    }
    if (options.fileLogLevel.index <= LogLevel.info.index) {
      _sink?.writeln(msg);
    }
  }

  static void success(String msg) {
    final formatted = "\x1B[32m[✓]\x1B[0m $msg";
    if (options.logLevel.index <= LogLevel.info.index) {
      print(formatted);
    }
    if (options.fileLogLevel.index <= LogLevel.info.index) {
      _sink?.writeln(formatted);
    }
  }

  static void warn(String msg) {
    _warnings++;
    final formatted = "\x1B[33m[!]\x1B[0m \x1B[1m$msg\x1B[0m";
    if (options.logLevel.index <= LogLevel.warn.index) {
      print(formatted);
    }
    if (options.fileLogLevel.index <= LogLevel.warn.index) {
      _sink?.writeln(formatted);
    }
  }

  static void error(String msg) {
    _errors++;
    final formatted = "\x1B[31m[x]\x1B[0m \x1B[1m$msg\x1B[0m";
    if (options.logLevel.index <= LogLevel.error.index) {
      print(formatted);
    }
    if (options.fileLogLevel.index <= LogLevel.error.index) {
      _sink?.writeln(formatted);
    }
  }

  static reset() {
    _warnings = 0;
    _errors = 0;
  }

  static Future<void> withFileLogging(Future<void> Function() app) async {
    try {
      if (_sink == null && options.fileLogLevel != LogLevel.none) {
        final uri = await PathResolver.relativeToAbsolute(options.logFile);
        _sink = await File(uri.path).openWrite();
      }
      await app();
    } finally {
        await _sink?.close();
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
    this.logFile = "xwidget_builder.log"
  });
}

enum LogLevel {
  fine, info, warn, error, none;
}