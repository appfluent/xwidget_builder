import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import '../utils/path_resolver.dart';

import 'config_loader.dart';

class ProjectConfig {
  dynamic _cloud;
  dynamic _config;
  dynamic _pubspec;
  dynamic _pubspecLock;

  ProjectConfig();

  Future<String?> getId() async {
    return ConfigLoader.loadToStringOrNull(await _getCloud(), 'project_id');
  }

  Future<String?> getName() async {
    return ConfigLoader.loadToStringOrNull(await _getPubspec(), 'name');
  }

  Future<String?> getDescription() async {
    return ConfigLoader.loadToStringOrNull(await _getPubspec(), 'description');
  }

  Future<String?> getVersion() async {
    return ConfigLoader.loadToStringOrNull(await _getPubspec(), 'version');
  }

  Future<bool> isXwidgetInstalled() async {
    final dependency = ConfigLoader.loadToStringOrNull(
      await _getPubspecLock(),
      'packages.xwidget.dependency',
    );
    return dependency == 'direct main';
  }

  Future<Version?> getXwidgetVersion() async {
    if (!await isXwidgetInstalled()) return null;
    final version = ConfigLoader.loadToStringOrNull(
      await _getPubspecLock(),
      'packages.xwidget.version',
    );
    return version != null ? Version.parse(version) : null;
  }

  Future<String?> getFragmentsPath() async {
    return ConfigLoader.loadToStringOrNull(await _getConfig(), 'resources.fragments');
  }

  Future<String?> getValuesPath() async {
    return ConfigLoader.loadToStringOrNull(await _getConfig(), 'resources.values');
  }

  Future<void> deleteCloudConfig() async {
    final uri = await PathResolver.relativeToAbsolute('xwidget_cloud.yaml');
    final file = File.fromUri(uri);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<dynamic> _getCloud() async {
    return _cloud ??= await ConfigLoader.loadYamlDoc('xwidget_cloud.yaml') ?? {};
  }

  Future<dynamic> _getPubspec() async {
    return _pubspec ??= await ConfigLoader.loadYamlDoc('pubspec.yaml') ?? {};
  }

  Future<dynamic> _getPubspecLock() async {
    return _pubspecLock ??= await ConfigLoader.loadYamlDoc('pubspec.lock') ?? {};
  }

  Future<dynamic> _getConfig() async {
    return _config ??= await ConfigLoader.loadYamlDoc('xwidget_config.yaml') ?? {};
  }
}
