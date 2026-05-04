import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

import 'cli_log.dart';

class ImportBuilder {
  final _resolver = ImportResolver();
  final _locations = SplayTreeSet<String>();

  Future<void> loadLibraries(Iterable<LibraryElement> libraries, bool addImports) async {
    for (final library in libraries) {
      if (addImports) {
        for (final importedLib in library.importedLibraries) {
          // added top level imports to imported locations
          final location = importedLib.location.toString();
          if (location != "dart:core") {
            _locations.add(location);
          }
        }
      }
      await _resolver.cacheLibrary(library);
    }
  }

  void addImportsForTypes(Iterable<DartType> types) {
    for (final type in types) {
      addImportsForType(type);
    }
  }

  void addImportsForType(DartType type) {
    final foundImports = _resolver.getImportsForType(type, _locations);
    _locations.addAll(foundImports);
  }

  void addImport(String location) {
    _locations.add(location.trim());
  }

  void addImports(Iterable<String> locations) {
    for (final location in locations) {
      _locations.add(location.trim());
    }
  }

  String buildImports(String relativeTo) {
    final code = StringBuffer();
    for (final location in _locations) {
      final importPath = location.startsWith("file:///")
          ? path.relative(Uri.parse(location).toFilePath(), from: path.dirname(relativeTo))
          : location;
      code.write("import '$importPath';\n");
    }
    code.write("\n");
    return code.toString();
  }
}

class ImportResolver {
  // private and public URIs -> element names -> public URIs
  final _locationCache = <String, Map<String?, Set<String>>>{};

  /// Get all public imports required for a DartType
  Set<String> getImportsForType(DartType type, [Set<String>? preferredImports]) {
    final imports = <String>{};

    void collectImports(DartType currType) {
      // Get the element for this type
      final element = currType.element;
      if (element != null) {
        final elementLibrary = element.library;
        if (elementLibrary != null) {
          final uri = elementLibrary.source.uri.toString();
          final publicUri = _resolvePublicImport(currType, uri, preferredImports);

          // Skip dart:core (implicit)
          if (publicUri != null && !publicUri.startsWith('dart:core')) {
            imports.add(publicUri);
          }
        }
      }

      // Handle generic types (List<T>, Map<K,V>, etc)
      if (currType is ParameterizedType) {
        for (final typeArg in currType.typeArguments) {
          collectImports(typeArg);
        }
      }

      // Handle function types (callbacks, etc)
      if (currType is FunctionType) {
        // Return type
        collectImports(currType.returnType);

        // Parameter types
        for (final param in currType.parameters) {
          collectImports(param.type);
        }
      }
    }

    collectImports(type);
    return imports;
  }

  /// Build cache from libraries - will automatically discover all dependencies
  Future<void> cacheLibraries(Iterable<LibraryElement> libraries) async {
    for (final library in libraries) {
      await cacheLibrary(library);
    }
  }

  Future<void> cacheLibrary(LibraryElement startingLibrary) async {
    final processed = <String>{};
    final toProcess = <LibraryElement>[startingLibrary];

    while (toProcess.isNotEmpty) {
      final current = toProcess.removeLast();
      final uri = current.source.uri.toString();

      // Skip if already processed
      if (processed.contains(uri)) continue;
      processed.add(uri);

      // Cache exports from public libraries
      if (!uri.contains('/src/')) {
        _cacheExportsFromLibrary(current, uri);
      }

      // Add all imported libraries
      for (final importedLib in current.importedLibraries) {
        if (!processed.contains(importedLib.source.uri.toString())) {
          toProcess.add(importedLib);
        }
      }

      // Add all exported libraries
      for (final exportedLib in current.exportedLibraries) {
        if (!processed.contains(exportedLib.source.uri.toString())) {
          toProcess.add(exportedLib);
        }
      }
    }
  }

  void _cacheExportsFromLibrary(LibraryElement library, String publicUri) {
    // Get the defining compilation unit
    final definingUnit = library.definingCompilationUnit;
    CliLog.fine("processing lib: $publicUri");

    // Iterate through actual export directives
    for (final export in definingUnit.libraryExports) {
      final exportedLib = export.exportedLibrary;
      if (exportedLib == null) continue;

      final combinators = export.combinators;
      CliLog.fine("  exported lib: ${exportedLib.source.uri}");

      if (combinators.isEmpty) {
        // no show/hide - include everything from this library
        for (final element in exportedLib.exportNamespace.definedNames.values) {
          CliLog.fine("    showAll: ${element.name}");
          _mapElementToPublic(element, publicUri);
        }
      } else {
        // has show/hide combinators
        for (final combinator in combinators) {
          if (combinator is ShowElementCombinator) {
            // include shown names
            for (final name in combinator.shownNames) {
              final element = exportedLib.exportNamespace.get(name);
              if (element != null) {
                CliLog.fine("    show: ${element.name}, ${element.runtimeType}");
                _mapElementToPublic(element, publicUri);
              }
            }
          } else if (combinator is HideElementCombinator) {
            // exclude hidden names
            for (final element in exportedLib.exportNamespace.definedNames.values) {
              if (!combinator.hiddenNames.contains(element.name)) {
                _mapElementToPublic(element, publicUri);
              }
            }
          }
        }
      }
    }
  }

  void _mapElementToPublic(Element element, String publicUri) {
    final elementName = element.name;

    if (elementName == null) return;
    final elementLibrary = element.library;

    if (elementLibrary == null) return;
    final definingUri = elementLibrary.source.uri.toString();
    final exported = _locationCache.putIfAbsent(definingUri, () => <String, Set<String>>{});
    final locations = exported.putIfAbsent(elementName, () => SplayTreeSet<String>());
    locations.add(publicUri);
  }

  String? _resolvePublicImport(DartType type, String uri, [Set<String>? preferredImports]) {
    final possibleImports = _locationCache[uri]?[type.name];
    if (possibleImports == null) return !uri.contains("/src/") ? uri : null;

    if (preferredImports != null) {
      final intersection = possibleImports.intersection(preferredImports);
      if (intersection.isNotEmpty) return intersection.first;
    }

    return possibleImports.first;
  }
}
