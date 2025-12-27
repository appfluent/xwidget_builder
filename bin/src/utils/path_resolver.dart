import 'dart:io';
import 'dart:isolate';

import 'package_utils.dart';

class PathResolver {
  static Future<Uri> get packageRoot async {
    final package = await Isolate.packageConfig;
    return package != null ? package.resolve("../") : Directory.current.uri;
  }

  /// Resolves relative package path to an absolute file path.
  ///
  /// Accepted formats:
  /// - "package:<package_name>/<file_path>": package lib/ relative
  /// - "<package_name>|<file_path>": package root relative
  /// - "<file_path>": current project root relative
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
      final basePath = findPackageInCache(packageUri.pathSegments[0])?.path;
      if (basePath != null) {
        final relativePath = packageUri.pathSegments.skip(1).join('/');
        return Uri.parse("file://$basePath/$relativePath");
      }
      throw Exception("Invalid package path: '$path'");
    }
    final root = await packageRoot;
    return root.resolve(path);
  }
}
