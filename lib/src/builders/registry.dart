import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../utils/cli_log.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import '../utils/utils.dart';
import 'builder.dart';

/// Builds the XWidget registry file.
///
/// The registry is a single generated file (typically `registry.g.dart`) that
/// users import into their `main.dart`. It contains a `registerXWidgetComponents()`
/// function that assigns runtime config and calls the register functions of
/// whichever other generated files exist (icons, inflaters, controllers).
///
/// This builder always runs, regardless of the `--only` flag, so that the
/// registry always reflects the current state of the filesystem.
class RegistryBuilder extends SpecBuilder {
  static final _minXWidgetVersion = Version(0, 5, 0);
  static const _controllersDefaultSources = ["lib/xwidget/controllers/**.dart"];

  final RegistryConfig registryConfig;

  RegistryBuilder(super.config) : registryConfig = config.registryConfig;

  @override
  Future<BuilderResult> build() async {
    final result = BuilderResult();
    if (!registryConfig.isValid()) return result;

    // Registry uses XWidget.config / XWidgetConfig APIs introduced in xwidget 0.5.0.
    // Skip generation on older xwidget to avoid producing a file that won't compile.
    final xwidgetVersion = await getXWidgetVersion();
    if (!_supportsRegistry(xwidgetVersion)) {
      CliLog.info(
        "Skipping registry generation: requires xwidget "
        "$_minXWidgetVersion or newer (resolved: $xwidgetVersion).",
      );
      return result;
    }

    final analyzer = SourceAnalyzer();
    final registryUri = await PathResolver.relativeToAbsolute(registryConfig.target);
    final registryDir = p.dirname(registryUri.path);

    final imports = <_RegistryImport>[];

    // icons
    await _checkComponent(
      label: "icons",
      sources: config.iconConfig.sources,
      defaultSources: const [],
      target: config.iconConfig.target,
      registerFn: "registerXWidgetIcons",
      analyzer: analyzer,
      registryDir: registryDir,
      imports: imports,
    );

    // inflaters
    await _checkComponent(
      label: "inflaters",
      sources: config.inflaterConfig.sources,
      defaultSources: const [],
      target: config.inflaterConfig.target,
      registerFn: "registerXWidgetInflaters",
      analyzer: analyzer,
      registryDir: registryDir,
      imports: imports,
    );

    // controllers
    await _checkComponent(
      label: "controllers",
      sources: config.controllerConfig.sources,
      defaultSources: _controllersDefaultSources,
      target: config.controllerConfig.target,
      registerFn: "registerXWidgetControllers",
      analyzer: analyzer,
      registryDir: registryDir,
      imports: imports,
    );

    // build output
    final output = StringBuffer();
    output.write(buildFileComments());
    output.write("import 'package:xwidget/xwidget.dart';\n");
    for (final imp in imports) {
      output.write("import '${imp.path}';\n");
    }
    output.write("\n");
    output.write(_buildRegisterComponentsMethod(imports));

    // write output to target
    final targetFile = await File(registryUri.path).create(recursive: true);
    await targetFile.writeAsString(output.toString());
    result.outputs.add(targetFile);
    CliLog.success("Registry output to '${registryConfig.target}'");

    return result;
  }

  Future<void> _checkComponent({
    required String label,
    required Set<String> sources,
    required List<String> defaultSources,
    required String target,
    required String registerFn,
    required SourceAnalyzer analyzer,
    required String registryDir,
    required List<_RegistryImport> imports,
  }) async {
    // target must be configured to check anything
    if (isEmpty(target)) return;

    final targetUri = await PathResolver.relativeToAbsolute(target);
    final targetExists = await File(targetUri.path).exists();

    // resolve source globs
    final sourceManifest = await analyzer.getSourceManifest(sources, defaultSources);
    final hasResolvedSources = sourceManifest.paths.isNotEmpty;

    if (targetExists && hasResolvedSources) {
      // include in registry
      final relativePath = p.posix.joinAll(p.split(p.relative(targetUri.path, from: registryDir)));
      imports.add(_RegistryImport(path: relativePath, registerFn: registerFn));
    } else if (targetExists && !hasResolvedSources) {
      // orphaned — warn and exclude
      CliLog.warn(
        "Orphaned '$label' output at '$target' - no sources matched. "
        "Excluded from registry.",
      );
    }
    // else: target missing - skip silently (not yet generated, or feature unused)
  }

  String _buildRegisterComponentsMethod(List<_RegistryImport> imports) {
    final code = StringBuffer();
    code.write("void registerXWidgetComponents() {\n");
    code.write("  XWidget.config = XWidgetConfig(\n");
    code.write("    fragmentsPath: '${_escape(config.fragmentsPath)}',\n");
    code.write("    valuesPath: '${_escape(config.valuesPath)}',\n");
    code.write("  );\n");
    for (final imp in imports) {
      code.write("  ${imp.registerFn}();\n");
    }
    code.write("}\n");
    return code.toString();
  }

  String _escape(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('\$', '\\\$');
  }

  bool _supportsRegistry(String version) {
    try {
      return Version.parse(version) >= _minXWidgetVersion;
    } catch (_) {
      // "<unknown>" or malformed version — treat as unsupported.
      return false;
    }
  }
}

class _RegistryImport {
  final String path;
  final String registerFn;

  _RegistryImport({required this.path, required this.registerFn});
}
