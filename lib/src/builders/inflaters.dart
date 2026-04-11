import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart';

import '../utils/cli_log.dart';
import '../utils/extensions.dart';
import '../utils/import_utils.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import 'builder.dart';

part 'inflaters_includes.dart';

class InflaterBuilder extends SpecBuilder {
  static const inflaterDefAnnotation = "InflaterDef";
  static const inflaterTypeParam = "inflaterType";
  static const inflatesOwnChildrenParam = "inflatesOwnChildren";

  final importBuilder = ImportBuilder();
  final InflaterConfig inflaterConfig;
  final SchemaConfig schemaConfig;
  final Map<String, SchemaType> schemaTypes = {};

  InflaterBuilder(super.config)
    : inflaterConfig = config.inflaterConfig,
      schemaConfig = config.schemaConfig;

  @override
  Future<BuilderResult> build() async {
    final result = BuilderResult();
    if (!_isOkToBuild()) return result;

    final output = StringBuffer();
    final inflaters = StringBuffer();
    final schemaElements = StringBuffer();
    final initializers = StringBuffer();
    final analyzer = SourceAnalyzer();
    final sourceManifest = await analyzer.getSourceManifest(inflaterConfig.sources);
    final includeManifest = await analyzer.getSourceManifest(inflaterConfig.includes);
    final libraryElements = await analyzer.getLibraryElements([
      ...sourceManifest.paths,
      ...includeManifest.paths,
    ]);

    await importBuilder.loadLibraries(libraryElements.values, true);
    importBuilder.addImports(inflaterConfig.imports);

    // build inflater classes and schema
    for (final path in sourceManifest.paths) {
      final library = libraryElements[path];
      if (library == null) {
        CliLog.warn("Library element not found for path '$path'");
        continue;
      }

      // found source library
      for (final element in library.topLevelElements) {
        if (element is! PropertyAccessorElement) continue;
        if (element.returnType.toString() == "InvalidType") {
          CliLog.error("InvalidType for property '$element' in '${basename(path)}'");
          continue;
        }

        // has a known/valid return type
        final contexts = <InflaterContext>[];
        if (element.name == "inflaters") {
          // found a list of class to create inflaters for
          final inflaterSpecs = element.variable2?.computeConstantValue()?.toListValue()?.toSet();
          if (inflaterSpecs != null) {
            for (final inflaterSpec in inflaterSpecs) {
              final inflaterType = inflaterSpec.toTypeValue();
              if (inflaterType == null) continue;

              // not a null list item
              final element = inflaterType.element;
              if (element is ClassElement) {
                contexts.add(
                  InflaterContext(
                    element,
                    inflaterType is ParameterizedType ? inflaterType.typeArguments : <DartType>[],
                  ),
                );
              }
            }
          }
        }

        // process all class elements
        for (final context in contexts) {
          final annotations = decodeMetadata(context.classElement.metadata);
          for (final constructor in context.classElement.constructors) {
            if (!constructor.isPrivate && (!constructor.hasDeprecated || config.allowDeprecated)) {
              // build inflater from constructor metadata
              final inflater = _buildInflaterClass(context, constructor, annotations);
              inflaters.write(inflater[0]);
              initializers.write(inflater[1]);
              schemaElements.write(_buildSchemaElement(context, constructor, annotations));
            }
          }
        }
      }
    }

    // construct output
    output.write(buildFileComments());
    output.write(importBuilder.buildImports(inflaterConfig.target));
    output.write(_buildIncludeSource(includeManifest));
    output.write(_buildInflaterAddIns());
    output.write(inflaters.toString());
    output.write(_buildInitializerMethod(initializers.toString()));

    // write to inflater target
    final outputTargetUri = await PathResolver.relativeToAbsolute(inflaterConfig.target);
    final outputTargetFile = await File(outputTargetUri.path).create(recursive: true);
    await outputTargetFile.writeAsString(output.toString());
    result.outputs.add(outputTargetFile);
    CliLog.success("Inflaters output to '${inflaterConfig.target}'");

    // write to schema target
    final schemaTargetUri = await PathResolver.relativeToAbsolute(schemaConfig.target);
    final schemaTargetFile = await File(schemaTargetUri.path).create(recursive: true);
    final schema = await _buildSchema(schemaElements.toString());
    await schemaTargetFile.writeAsString(schema);
    result.outputs.add(schemaTargetFile);
    CliLog.success("Schema output to '${schemaConfig.target}'");

    result.errors = CliLog.errors;
    result.warnings = CliLog.warnings;

    return result;
  }

  //===================================
  // private methods
  //===================================

  String _buildIncludeSource(SourceManifest includes) {
    final code = StringBuffer();
    for (final file in includes.files) {
      final sourceCode = file.readAsLinesSync();
      code.write("// ==> Start include from '${basename(file.path)}'. <==\n\n");
      for (final line in sourceCode) {
        if (!line.trim().startsWith("import ")) {
          code.writeln(line);
        }
      }
      code.write("\n// ==> End include from '${basename(file.path)}'. <==\n\n");
    }
    return code.toString();
  }

  String _buildInflaterInitializer(String className) {
    return "    XWidget.registerInflater($className());\n";
  }

  String _buildInitializerMethod(String initializers) {
    final code = StringBuffer();
    code.write("void registerXWidgetInflaters() {\n");
    code.write(initializers);
    code.write("}\n\n");
    return code.toString();
  }

  List _buildInflaterClass(
    InflaterContext context,
    ConstructorElement constructor,
    Map<String, dynamic> annotations,
  ) {
    final code = StringBuffer();
    final constructorArgs = StringBuffer();
    final parseCases = StringBuffer();
    final constructorName = constructor.displayName;
    final typedConstructorName = _buildTypedConstructorName(context, constructorName);
    final className = "${_buildInflaterName(context, constructorName, "_")}Inflater";
    final isCustomWidget = annotations.containsKey(inflaterDefAnnotation);
    final inflaterKey =
        annotations[inflaterDefAnnotation]?[inflaterTypeParam] ??
        _buildInflaterName(context, constructorName, ".");
    final inflatesOwnChildren =
        annotations[inflaterDefAnnotation]?[inflatesOwnChildrenParam] ?? false;
    final inflaterReturnType = context.classElement.name;

    for (final param in constructor.parameters) {
      if (!param.hasDeprecated || param.isRequired || config.allowDeprecated) {
        final paramType = param.type.displayStringWithoutNullability();
        if (paramType != "InvalidType") {
          if (inflaterConfig.isNotExcludedConstructorArg(constructorName, param.name)) {
            final privateAccess = isPrivateAccessParam(param, isCustomWidget);
            constructorArgs.write(
              _buildConstructorArg(constructorName, context, param, privateAccess),
            );
            if (schemaConfig.isNotExcludedAttribute(constructorName, param.name) &&
                !privateAccess) {
              parseCases.write(_buildInflaterParseCase(context, constructorName, param));
            }
          }
        } else {
          CliLog.error("InvalidType for param '$param' of class '${context.classElement.name}'");
        }
      }
    }
    code.write("class $className extends Inflater {\n\n");
    code.write("    @override\n    String get type => '$inflaterKey';\n\n");
    code.write("    @override\n    bool get inflatesOwnChildren => $inflatesOwnChildren;\n\n");
    code.write("    @override\n    bool get inflatesCustomWidget => $isCustomWidget;\n\n");
    code.write(
      _buildInflaterInflateMethod(
        inflaterReturnType,
        typedConstructorName,
        constructorArgs.toString(),
      ),
    );
    code.write(_buildInflaterParseMethod(parseCases.toString()));
    code.write("}\n\n");
    return [code.toString(), _buildInflaterInitializer(className)];
  }

  String _buildConstructorArg(
    String constructorName,
    InflaterContext context,
    ParameterElement param,
    bool privateAccess,
  ) {
    final code = StringBuffer();
    code.write("        ");

    final paramName = param.name;
    final paramType = param.type;
    final isRequired = param.isRequired;
    final isPositional = param.isPositional;
    final defaultValue = inflaterConfig.findConstructorArgDefault(constructorName, param.name);

    if (paramType.isDartCoreMap) {
      final typeArgs = (paramType as ParameterizedType).typeArguments;
      final mapKeyType = context.resolveToType(typeArgs[0]);
      final mapValueType = context.resolveToType(typeArgs[1]);

      // only import types we're explicitly creating type arguments for
      importBuilder.addImportsForType(context.resolveToType(mapKeyType));
      importBuilder.addImportsForType(context.resolveToType(mapValueType));

      code.write(
        "args.addMapArg<$mapKeyType, $mapValueType>('$paramName', $isRequired, $isPositional, $defaultValue);",
      );
    } else if (paramType.isDartCoreList ||
        paramType.isDartCoreSet ||
        paramType.isDartCoreIterable) {
      final coreType = paramType.coreType()?.getBaseTypeName();
      final typeArgs = (paramType as ParameterizedType).typeArguments;
      final listItemType = context.resolveToType(typeArgs[0]);

      // only import type we're explicitly creating type arguments for
      importBuilder.addImportsForType(context.resolveToType(listItemType));

      final castExpr = _buildCastExpression(context, listItemType, 0);
      if (castExpr != null) {
        code.write(
          "args.addArg<$listItemType>('$paramName', $coreType, $isRequired, $isPositional, $defaultValue, "
          "castElement: (e0) => $castExpr);",
        );
      } else {
        code.write(
          "args.addArg<$listItemType>('$paramName', $coreType, $isRequired, $isPositional, $defaultValue);",
        );
      }
    } else if (paramType is FunctionType) {
      final fnType = paramType;
      final resolvedReturnType = context.resolveToType(fnType.returnType);
      final returnTypeStr = context.resolveToString(fnType.returnType);
      final paramCount = fnType.parameters.length;
      final paramStr = List.generate(paramCount, (i) => 'p$i').join(', ');

      String returnExpr;
      if (returnTypeStr == 'void') {
        returnExpr = 'Function.apply(fn, [$paramStr])';
      } else if (_isCoreCollection(resolvedReturnType)) {
        final baseType = resolvedReturnType.element!.name;
        final typeArgs = (resolvedReturnType as ParameterizedType).typeArguments
            .map((t) => context.resolveToString(t))
            .join(', ');
        returnExpr = '(Function.apply(fn, [$paramStr]) as $baseType).cast<$typeArgs>()';
        for (final t in (resolvedReturnType).typeArguments) {
          importBuilder.addImportsForType(context.resolveToType(t));
        }
      } else {
        returnExpr = 'Function.apply(fn, [$paramStr]) as $returnTypeStr';
        importBuilder.addImportsForType(resolvedReturnType);
      }

      code.write(
        "args.addFnArg('$paramName', (fn) => "
        "($paramStr) => $returnExpr, $isRequired, $isPositional, $defaultValue);",
      );
    } else {
      final coreType = paramType.coreType()?.getBaseTypeName();
      code.write(
        "args.addArg('$paramName', $coreType, $isRequired, $isPositional, $defaultValue);",
      );
    }
    code.write("\n");
    return code.toString();
  }

  String _buildInflaterParseCase(
    InflaterContext context,
    String constructorName,
    ParameterElement param,
  ) {
    final code = StringBuffer();
    final paramName = param.name;
    final paramType = context.resolveToType(param.type);
    final parser = inflaterConfig.findConstructorArgParser(
      constructorName,
      paramName,
      paramType.toString(),
    );
    code.write("            case '$paramName': ");
    if (parser != null) {
      code.write("return $parser");
    } else if (paramType.element is EnumElement) {
      importBuilder.addImportsForType(context.resolveToType(paramType));
      code.write("return parseEnum(${paramType.element?.name}.values, value)");
    } else {
      code.write("break");
    }
    code.write(";\n");
    return code.toString();
  }

  String _buildInflaterInflateMethod(
    String returnType,
    String constructorName,
    String constructorArgs,
  ) {
    final code = StringBuffer();
    final constructorFunc = constructorName.contains(".")
        ? constructorName
        : "$constructorName.new";

    code.write("    @override\n");
    code.write("    $returnType? ");
    code.write(
      "inflate(Map<String, dynamic> attributes, List<dynamic> children, List<String> text) {\n",
    );
    code.write("        final args = InflaterArgs(attributes, children, text);\n");
    if (constructorArgs.isNotEmpty) {
      code.write(constructorArgs);
    }
    code.write(
      "        return Function.apply($constructorFunc, args.posArgs, args.namedArgs) as $returnType?;\n",
    );
    code.write("    }\n\n");
    return code.toString();
  }

  String _buildInflaterParseMethod(String parseCases) {
    final code = StringBuffer();
    code.write("    @override\n");
    code.write("    dynamic parseAttribute(String name, String value) {\n");
    code.write("        switch (name) {\n");
    code.write(parseCases);
    code.write("        }\n");
    code.write("        return value;\n");
    code.write("    }\n");
    return code.toString();
  }

  bool _isCoreCollection(DartType type) {
    return type.isDartCoreList ||
        type.isDartCoreSet ||
        type.isDartCoreIterable ||
        type.isDartCoreMap;
  }

  bool _isOkToBuild() {
    var ok = inflaterConfig.isValid() && schemaConfig.isValid(inflaterConfig);
    if (inflaterConfig.sources.isEmpty) {
      CliLog.success("Skipping inflaters. No sources specified.");
      ok = false;
    }
    return ok;
  }

  String _buildTypedConstructorName(InflaterContext context, String constructorName) {
    final typeNames = context.getTypeArgumentNames(withNullability: false, noneIfAllDynamic: true);
    final types = typeNames.isNotEmpty ? "<${typeNames.join(',')}>" : "";
    final dotIndex = constructorName.indexOf(".");
    return dotIndex > 0
        ? constructorName.substring(0, dotIndex) +
              types +
              constructorName.substring(dotIndex, constructorName.length)
        : constructorName + types;
  }

  String _buildInflaterName(InflaterContext context, String constructorName, String separator) {
    final typeNames = context.getTypeArgumentNames(withNullability: false, noneIfAllDynamic: true);
    final types = typeNames.map((e) => e.capitalizeFirst()).join();
    final dotIndex = constructorName.indexOf(".");
    return dotIndex > 0
        ? constructorName.substring(0, dotIndex) +
              types +
              separator +
              constructorName.substring(dotIndex + 1, constructorName.length)
        : constructorName + types;
  }

  String? _buildCastExpression(InflaterContext context, DartType type, int depth) {
    final v = 'e$depth';
    if (type.isDartCoreList || type.isDartCoreIterable) {
      final innerType = (type as ParameterizedType).typeArguments[0];
      final resolvedInner = context.resolveToType(innerType);
      final innerCast = _buildCastExpression(context, resolvedInner, depth + 1);
      if (innerCast != null) {
        return '($v as List).map((e${depth + 1}) => $innerCast).toList()';
      }
      final innerStr = context.resolveToString(innerType);
      return '($v as List).cast<$innerStr>()';
    }
    if (type.isDartCoreMap) {
      final typeArgs = (type as ParameterizedType).typeArguments;
      final keyStr = context.resolveToString(typeArgs[0]);
      final valStr = context.resolveToString(typeArgs[1]);
      return '($v as Map).cast<$keyStr, $valStr>()';
    }
    if (type.isDartCoreSet) {
      final innerType = (type as ParameterizedType).typeArguments[0];
      final innerStr = context.resolveToString(innerType);
      return '($v as Set).cast<$innerStr>()';
    }
    return null;
  }

  //=============================================
  // schema methods
  //=============================================

  Future<String> _buildSchema(String elements) async {
    final templateUri = await PathResolver.relativeToAbsolute(schemaConfig.template);
    final templateFile = File(templateUri.path);
    final templateLines = templateFile.readAsLinesSync();
    final code = StringBuffer();
    for (final line in templateLines) {
      if (line.contains("<!--@@enumTypes@@-->")) {
        for (final schemaType in schemaTypes.values) {
          code.write(schemaType.code);
        }
      } else if (line.contains("<!--@@inflaters@@-->")) {
        code.write(elements);
      } else {
        code.write("$line\n");
      }
    }
    return code.toString();
  }

  String _buildSchemaElement(
    InflaterContext context,
    ConstructorElement constructor,
    Map<String, dynamic> annotations,
  ) {
    final code = StringBuffer();
    final attributes = StringBuffer();
    final constructorName = constructor.displayName;
    final isCustomWidget = annotations.containsKey(inflaterDefAnnotation);
    final inflaterKey =
        annotations[inflaterDefAnnotation]?[inflaterTypeParam] ??
        _buildInflaterName(context, constructorName, ".");

    for (final param in constructor.parameters) {
      if ((!param.hasDeprecated || config.allowDeprecated) &&
          inflaterConfig.isNotExcludedConstructorArg(constructorName, param.name) &&
          schemaConfig.isNotExcludedAttribute(constructorName, param.name) &&
          !isPrivateAccessParam(param, isCustomWidget)) {
        final paramType = param.type.element;
        if (paramType is EnumElement && !schemaTypes.containsKey(paramType.name)) {
          _buildSchemaAttributeType(paramType);
        }
        attributes.write(_buildSchemaAttribute(context, param));
      }
    }
    code.write('    <xs:element name="$inflaterKey">\n');
    code.write(_buildSchemaDocumentation(constructor.documentationComment, 8));
    code.write('        <xs:complexType>\n');
    code.write('            <xs:complexContent>\n');
    code.write('                <xs:extension base="objectType">\n');
    code.write(attributes);
    code.write('                </xs:extension>\n');
    code.write('            </xs:complexContent>\n');
    code.write('        </xs:complexType>\n');
    code.write('    </xs:element>\n\n');
    return code.toString();
  }

  String _buildSchemaDocumentation(String? documentation, int indent) {
    final code = StringBuffer();
    final padding = "".padLeft(indent);
    final docs = documentationToMarkdown(documentation);
    if (docs != null && docs.isNotEmpty) {
      code.write('$padding<xs:annotation>\n');
      code.write('$padding    <xs:documentation xml:lang="en">\n');
      code.writeln(docs);
      code.write('$padding    </xs:documentation>\n');
      code.write('$padding</xs:annotation>\n');
    }
    return code.toString();
  }

  String _buildSchemaAttribute(InflaterContext context, ParameterElement param) {
    final code = StringBuffer();
    final schemaType = _getSchemaAttributeType(param);
    final paramDocs = getParameterDocumentation(context.classElement, param);
    code.write('                    <xs:attribute name="${param.name}"');
    if (schemaType != null) {
      code.write(' type="$schemaType"');
    }
    if (paramDocs != null && paramDocs.isNotEmpty) {
      code.write(">\n");
      code.write(_buildSchemaDocumentation(paramDocs, 24));
      code.write('                    </xs:attribute>\n');
    } else {
      code.write('/>\n');
    }
    return code.toString();
  }

  void _buildSchemaAttributeType(EnumElement enumElement) {
    final enumName = enumElement.name;
    final schemaTypeName = "${enumName}AttributeType";
    final code = StringBuffer();
    code.write('    <xs:simpleType name="$schemaTypeName">\n');
    code.write('        <xs:union memberTypes="expressionAttributeType">\n');
    code.write('            <xs:simpleType>\n');
    code.write('                <xs:restriction base="xs:string">\n');
    final values = enumElement.getField("values")?.computeConstantValue()?.toListValue();
    if (values != null) {
      for (final enumItem in values) {
        final enumItemName = enumItem.variable?.name;
        code.write('                    <xs:enumeration value="$enumItemName"/>\n');
      }
    }
    code.write('                </xs:restriction>\n');
    code.write('            </xs:simpleType>\n');
    code.write('        </xs:union>\n');
    code.write('    </xs:simpleType>\n\n');
    schemaTypes[enumElement.name] = SchemaType(schemaTypeName, code.toString());
  }

  String? _getSchemaAttributeType(ParameterElement param) {
    final paramType = param.type.element;
    final paramTypeName = paramType?.name;
    return schemaConfig.findAttributeType(paramTypeName) ?? schemaTypes[paramTypeName]?.name;
  }
}

class SchemaType {
  final String name;
  final String code;

  SchemaType(this.name, this.code);
}

class InflaterContext {
  final ClassElement classElement;
  final List<DartType> typeArguments;
  final List<String> typeArgumentNames;
  final Map<String, DartType> paramToArg;

  DartType get dynamicType => classElement.library.typeProvider.dynamicType;

  InflaterContext(this.classElement, this.typeArguments)
    : typeArgumentNames = typeArguments.map((arg) => arg.getDisplayString()).toList(),
      paramToArg = {
        for (int i = 0; i < classElement.typeParameters.length; i++)
          classElement.typeParameters[i].name: typeArguments[i],
      };

  Iterable<String> getTypeArgumentNames({
    bool withNullability = true,
    bool noneIfAllDynamic = false,
  }) {
    final typeArgs = withNullability
        ? typeArguments.map((arg) => arg.getDisplayString())
        : typeArguments.map((arg) => arg.name ?? "dynamic");
    return noneIfAllDynamic && typeArgs.every((e) => e == "dynamic") ? <String>[] : typeArgs;
  }

  String resolveToString(DartType type) {
    if (type is TypeParameterType) {
      return paramToArg[type.name]?.getDisplayString() ?? "dynamic";
    }
    if (type is FunctionType) {
      return "Function";
    }
    if (type is ParameterizedType) {
      if (type.name == null) return "dynamic";

      final args = type.typeArguments.map(resolveToString).toList();
      if (args.isEmpty) return type.getDisplayString();

      final nullable = type.nullabilitySuffix == NullabilitySuffix.question;
      return "${type.name}<${args.join(', ')}>${nullable ? "?" : ""}";
    }
    return type.getDisplayString();
  }

  DartType resolveToType(DartType type) {
    if (type is TypeParameterType) {
      return paramToArg[type.name] ?? dynamicType;
    }
    if (type is ParameterizedType) {
      if (type.name == null) return dynamicType;

      final args = type.typeArguments.map(resolveToType).toList();
      if (args.isEmpty) return type;

      final interface = type as InterfaceType;
      return interface.element.instantiate(
        typeArguments: args,
        nullabilitySuffix: type.nullabilitySuffix,
      );
    }
    return type;
  }
}
