import 'dart:io';

import 'package_utils.dart';

class PathResolver {
  static Uri get packageRoot {
    Uri? configUri = findPackageConfigUri(Directory.current);
    return configUri != null ? configUri.resolve("../") : Directory.current.uri;
  }

  /// Finds the URI of the package_config.json file by walking up from
  /// a starting directory.
  static Uri? findPackageConfigUri(Directory startDir) {
    Directory? current = startDir;
    while (current != null) {
      final configFile = File('${current.path}/.dart_tool/package_config.json');
      if (configFile.existsSync()) {
        return configFile.uri;
      }
      // Move up to the parent directory
      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }
    return null;
  }

  /// Resolves relative package path to an absolute file path.
  ///
  /// Accepted formats:
  /// - `package:<package_name>/<file_path>`: package lib/ relative
  /// - `<package_name>|<file_path>`: package root relative
  /// - `<file_path>`: current project root relative
  ///
  /// Throws an [Exception] if the specified package can't be found, presumably
  /// because it wasn't added as a dependency.
  static Future<Uri> relativeToAbsolute(String path) async {
    String uriPath = path;
    if (path.contains("|")) {
      final parts = path.split("|");
      uriPath = "package:${parts[0]}/${parts[1]}";
    }
    if (uriPath.startsWith("package:")) {
      final packageUri = Uri.parse(uriPath);
      final basePath = await findPackagePath(packageUri.pathSegments[0]);
      final relativePath = packageUri.pathSegments.skip(1).join('/');
      final absoluteBase = Directory(basePath).absolute.path;
      return Uri.file('$absoluteBase/$relativePath');
    }
    final root = packageRoot;
    return root.resolve(path);
  }
}
