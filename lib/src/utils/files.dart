import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'cli_log.dart';
import 'path_resolver.dart';

class Files {
  static Future<String> readFile(String filePath) async {
    final pathUri = await PathResolver.relativeToAbsolute(filePath);
    return File(pathUri.path).readAsString();
  }

  static Future<File> createFile(String filePath, String contents) async {
    final pathUri = await PathResolver.relativeToAbsolute(filePath);
    final file = await File(pathUri.path).create(recursive: true);
    return file.writeAsString(contents);
  }

  static Future<void> createDirs(List<String> dirs) async {
    for (final dir in dirs) {
      await createDir(Directory(dir));
    }
  }

  static Future<void> createDir(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      CliLog.success("Created directory '${dir.path}'");
    }
  }

  static Future<void> copyFiles(
    Map<String, String> files, {
    bool replace = false,
    void Function(String) existsLogger = CliLog.warn,
  }) async {
    for (final file in files.entries) {
      await copyFile(file.key, file.value, replace: replace, existsLogger: existsLogger);
    }
  }

  static Future<void> copyFile(
    String src,
    String dst, {
    bool replace = false,
    void Function(String) existsLogger = CliLog.warn,
  }) async {
    try {
      final srcPath = await PathResolver.relativeToAbsolute(src);
      final srcFile = File(srcPath.path);
      if (await srcFile.exists()) {
        final dstPath = await PathResolver.relativeToAbsolute(dst);
        final dstFile = File(dstPath.path);
        if (replace || !await dstFile.exists()) {
          await createDir(dstFile.parent);
          await srcFile.copy(dstPath.path);
          CliLog.success("Copied '$src' to '$dst'");
        } else {
          existsLogger("File '$dst' already exists");
        }
      } else {
        CliLog.error("File $srcPath does not exist.");
      }
    } catch (e) {
      CliLog.error("Error while copying file: $e");
    }
  }
}

Future<List<int>> createTarball(List<String> folders, [Manifest? manifest]) async {
  final archive = Archive();

  for (final folder in folders) {
    final dir = Directory(folder);
    if (!await dir.exists()) {
      throw ArgumentError('Directory does not exist: $folder');
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        // Use posix-style paths in the archive
        final archivePath = path.posix.joinAll(path.split(entity.path));
        archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
      }
    }
  }

  if (manifest != null) {
    final content = utf8.encode(manifest.content); // or whatever string
    archive.addFile(ArchiveFile(manifest.fileName, content.length, content));
  }

  final tarData = TarEncoder().encode(archive);
  final gzData = GZipEncoder().encode(tarData);
  return gzData;
}

class Manifest {
  final String fileName;
  final String content;

  Manifest(this.fileName, this.content);
}
