import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'cli_log.dart';

/// Represents metadata information about a Dart/Flutter package.
/// Contains basic package details typically found in pubspec.yaml
/// and retrieved from pub.dev API.
class PackageInfo {
  final String name;
  final String version;
  final String? description;
  final String? homepage;
  final List<String>? authors;

  PackageInfo({
    required this.name,
    required this.version,
    this.description,
    this.homepage,
    this.authors,
  });

  @override
  String toString() {
    return 'PackageInfo(name: $name, version: $version)';
  }
}

/// Fetches package information from pub.dev for the given [packageName].
/// Returns a [PackageInfo] object with details like version, description, etc.
/// Returns null if the package is not found or an error occurs.
Future<PackageInfo?> getPackageInfo(String packageName) async {
  final client = HttpClient();

  try {
    final request = await client.getUrl(
      Uri.parse('https://pub.dev/api/packages/$packageName'),
    );
    final response = await request.close();

    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final latest = json['latest'] as Map<String, dynamic>;
      final pubspec = latest['pubspec'] as Map<String, dynamic>?;

      return PackageInfo(
        name: json['name'] as String,
        version: latest['version'] as String,
        description: pubspec?['description'] as String?,
        homepage: pubspec?['homepage'] as String?,
        authors: (pubspec?['authors'] as List?)?.cast<String>(),
      );
    }
    await response.drain();
  } catch (e) {
    CliLog.error('Error: $e');
  } finally {
    client.close();
  }
  return null;
}

/// Gets the pub cache directory
Directory getPubCacheDir() {
  final pubCache = Platform.environment['PUB_CACHE'] ??
      path.join(Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ?? '',
          '.pub-cache');
  return Directory(pubCache);
}

/// Finds a package in the pub cache
Directory? findPackageInCache(String packageName) {
  final pubCache = getPubCacheDir();
  final hostedDir = Directory(path.join(pubCache.path, 'hosted', 'pub.dev'));
  if (!hostedDir.existsSync()) return null;

  // Find all versions of the package
  final packages = hostedDir
      .listSync()
      .whereType<Directory>()
      .where((dir) => path.basename(dir.path).startsWith('$packageName-'))
      .toList();
  if (packages.isEmpty) return null;

  // Sort by version and get the latest (simple string sort)
  packages.sort((a, b) => path.basename(b.path).compareTo(path.basename(a.path)));
  return packages.first;
}