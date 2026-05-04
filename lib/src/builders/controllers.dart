import 'dart:io';

import 'package:analyzer/dart/element/element.dart';

import '../utils/cli_log.dart';
import '../utils/import_utils.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import 'builder.dart';

class ControllerBuilder extends SpecBuilder {
  final ControllerConfig controllerConfig;

  ControllerBuilder(super.config) : controllerConfig = config.controllerConfig;

  @override
  Future<BuilderResult> build() async {
    final result = BuilderResult();
    if (_isOkToBuild()) {
      final output = StringBuffer();
      final registrations = StringBuffer();
      final analyzer = SourceAnalyzer();
      final defaultSources = [
        "lib/xwidget/controllers/**.dart",
      ]; // hardcoding the path here is a hack
      final sourceManifest = await analyzer.getSourceManifest(
        controllerConfig.sources,
        defaultSources,
      );
      final libraryElements = await analyzer.getLibraryElements(sourceManifest.paths);
      final targetUri = await PathResolver.relativeToAbsolute(controllerConfig.target);
      final importBuilder = ImportBuilder();

      await importBuilder.loadLibraries(libraryElements.values, false);
      importBuilder.addImports(controllerConfig.imports);

      // build controller registrations
      for (final path in sourceManifest.paths) {
        final library = libraryElements[path];
        if (library != null) {
          for (final element in library.topLevelElements) {
            if (element is ClassElement && !element.isAbstract) {
              for (final interfaceType in element.allSupertypes) {
                if (getInterfaceElementFQN(interfaceType.element) ==
                    "package:xwidget/src/custom/controller.dart::Controller") {
                  importBuilder.addImport(element.source.uri.toString());
                  registrations.write(_buildRegisterControllerCall(element));
                }
              }
            }
          }
        } else {
          CliLog.warn("Library element not found for path $path.");
        }
      }

      if (registrations.isNotEmpty) {
        output.write(buildFileComments());
        output.write(importBuilder.buildImports(controllerConfig.target));
        output.write(_buildRegisterControllersMethod(registrations.toString()));

        // write output to target
        final targetFile = await File(targetUri.path).create(recursive: true);
        await targetFile.writeAsString(output.toString());
        result.outputs.add(targetFile);
        CliLog.success("Controllers output to '${controllerConfig.target}'");
      } else {
        CliLog.success("Skipping controllers. No controllers found in sources.");
      }
    }
    return result;
  }

  String _buildRegisterControllersMethod(String registrationCalls) {
    final code = StringBuffer();
    code.write("void registerXWidgetControllers() {\n");
    code.write(registrationCalls);
    code.write("}\n\n");
    return code.toString();
  }

  String _buildRegisterControllerCall(ClassElement element) {
    final params = "'${element.name}', () => ${element.name}()";
    return "  XWidget.registerControllerFactoryForName($params);\n";
  }

  bool _isOkToBuild() {
    var ok = controllerConfig.isValid();
    if (controllerConfig.sources.isEmpty) {
      CliLog.success("Skipping controllers. No sources specified.");
      ok = false;
    }
    return ok;
  }
}
