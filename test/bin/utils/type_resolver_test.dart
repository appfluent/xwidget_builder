import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xwidget_builder/src/builders/inflaters.dart';
import 'package:xwidget_builder/src/utils/source_analyzer.dart';

const sdkPath = '/Users/cbarlow/Development/flutter/bin/cache/dart-sdk';

void main() async {
  final analyzer = SourceAnalyzer(sdkPath: sdkPath);
  final libraries = await analyzer.getLibraryElements(["test/fixtures/src/test_classes.dart"]);

  final library = libraries.values.first;
  final typeProvider = library.typeProvider;

  // type elements
  final intElement = typeProvider.intElement;
  final stringElement = typeProvider.stringElement;
  final mapElement = typeProvider.mapElement;
  final listElement = typeProvider.listElement;
  final setElement = typeProvider.setElement;

  // types
  final dynamicType = typeProvider.dynamicType;
  final stringType = typeProvider.stringType;
  final intType = typeProvider.intType;

  // nullable types
  final nullableStringType = stringElement.instantiate(
    typeArguments: [],
    nullabilitySuffix: NullabilitySuffix.question,
  );
  final nullableIntType = intElement.instantiate(
    typeArguments: [],
    nullabilitySuffix: NullabilitySuffix.question,
  );

  test('Test type parameter names', () async {
    final kTypeArg = intType;
    final vTypeArg = nullableStringType;
    final resolver = InflaterContext(mapElement, [kTypeArg, vTypeArg]);
    final result = resolver.getTypeArgumentNames();
    expect(result, ["int", "String?"]);
  });

  test('Test simple string type parameter string resolution', () async {
    final typeParams = mapElement.typeParameters;
    final vTypeParam = typeParams[1].instantiate(nullabilitySuffix: NullabilitySuffix.question);
    final kTypeArg = intType;
    final vTypeArg = nullableStringType;
    final resolver = InflaterContext(mapElement, [kTypeArg, vTypeArg]);
    final result = resolver.resolveToString(vTypeParam);
    expect(result, "String?");
  });

  test('Test map multi type parameter string resolution', () async {
    final typeParams = mapElement.typeParameters;
    final kTypeParam = typeParams[0].instantiate(nullabilitySuffix: NullabilitySuffix.none);
    final vTypeParam = typeParams[1].instantiate(nullabilitySuffix: NullabilitySuffix.question);
    final kTypeArg = intType;
    final vTypeArg = nullableStringType;
    final resolver = InflaterContext(mapElement, [kTypeArg, vTypeArg]);
    final mapType = mapElement.instantiate(
      typeArguments: [kTypeParam, vTypeParam],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    final result = resolver.resolveToString(mapType);
    expect(mapType.getDisplayString(), "Map<K, V?>");
    expect(result, "Map<int, String?>");
  });

  test('Test map nested type parameter string resolution', () async {
    final typeParams = mapElement.typeParameters;
    final kTypeParam = typeParams[0].instantiate(nullabilitySuffix: NullabilitySuffix.none);
    final vTypeParam = typeParams[1].instantiate(nullabilitySuffix: NullabilitySuffix.question);
    final kTypeArg = intType;
    final vTypeArg = nullableStringType;
    final resolver = InflaterContext(mapElement, [kTypeArg, vTypeArg]);
    final listType = listElement.instantiate(
      typeArguments: [vTypeParam],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    final mapType = mapElement.instantiate(
      typeArguments: [kTypeParam, listType],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    final result = resolver.resolveToString(mapType);
    expect(mapType.getDisplayString(), "Map<K, List<V?>>");
    expect(result, "Map<int, List<String?>>");
  });

  test('Test map nested type parameter string resolution w/ no type arguments', () async {
    final typeParams = mapElement.typeParameters;
    final kTypeParam = typeParams[0].instantiate(nullabilitySuffix: NullabilitySuffix.none);
    final vTypeParam = typeParams[1].instantiate(nullabilitySuffix: NullabilitySuffix.question);
    final resolver = InflaterContext(mapElement, []);
    final listType = listElement.instantiate(
      typeArguments: [vTypeParam],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    final mapType = mapElement.instantiate(
      typeArguments: [kTypeParam, listType],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    final result = resolver.resolveToString(mapType);
    expect(mapType.getDisplayString(), "Map<K, List<V?>>");
    expect(result, "Map<dynamic, List<dynamic>>");
  });

  test('Test map nested type parameter type resolution', () async {
    final typeParams = mapElement.typeParameters;
    final kTypeParam = typeParams[0].instantiate(nullabilitySuffix: NullabilitySuffix.none);
    final vTypeParam = typeParams[1].instantiate(nullabilitySuffix: NullabilitySuffix.question);
    final kTypeArg = intType;
    final vTypeArg = nullableStringType;
    final resolver = InflaterContext(mapElement, [kTypeArg, vTypeArg]);
    final listType = listElement.instantiate(
      typeArguments: [vTypeParam],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    final mapType = mapElement.instantiate(
      typeArguments: [kTypeParam, listType],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    final result = resolver.resolveToType(mapType);
    expect(mapType.getDisplayString(), "Map<K, List<V?>>");
    expect(result.getDisplayString(), "Map<int, List<String?>>");
  });
}
