import 'dart:ui';

const _privateDefaultValue = "privateDefault";
const publicDefaultValue = "publicDefault";

class TestObject {
  final String name;

  TestObject(this.name);

  @override
  String toString() {
    return 'TestObject {name: $name}';
  }
}

class TestTypeParameters<K, V> {
  final K key;
  final Map<K, V>? map;
  final List<V>? list;
  final Map<K, List<V?>>? cache1;
  final Map<String, List<String?>>? cache2;
  final BoxHeightStyle Function({int height})? func;

  TestTypeParameters(this.key, this.map, this.list, this.cache1, this.cache2, this.func);

  TestTypeParameters.named({
    required this.key,
    this.map,
    this.list,
    this.cache1,
    this.cache2,
    this.func,
  });
}

class TestDefaults {
  final String? noDefault;
  final String? privateDefault;
  final String? publicDefault;

  TestDefaults(
    this.noDefault, [
    this.privateDefault = _privateDefaultValue,
    this.publicDefault = publicDefaultValue,
  ]);

  @override
  String toString() {
    return 'TestDefaults {'
        'noDefault: $noDefault, '
        'privateDefault: $privateDefault, '
        'publicDefault: $publicDefault'
        '}';
  }
}

class TestNamedParams {
  final Map<String, String> requiredMap;
  final List<String> requiredList;
  final Set<String> requiredSet;
  final double requiredDouble;
  final String requiredString;
  final dynamic requiredDynamic;
  final TestObject requiredChild;
  final List<TestObject> requiredChildren;

  final Map<String, String>? optionalMap;
  final List<String>? optionalList;
  final Set<String>? optionalSet;
  final double? optionalDouble;
  final String? optionalString;
  final dynamic optionalDynamic;
  final TestObject? optionalChild;
  final List<TestObject>? optionalChildren;

  TestNamedParams({
    required this.requiredMap,
    required this.requiredList,
    required this.requiredSet,
    required this.requiredDouble,
    required this.requiredString,
    required this.requiredDynamic,
    required this.requiredChild,
    required this.requiredChildren,
    this.optionalMap,
    this.optionalList,
    this.optionalSet,
    this.optionalDouble,
    this.optionalString,
    this.optionalDynamic,
    this.optionalChild,
    this.optionalChildren,
  });

  @override
  String toString() {
    return 'TestPositionalParams {\n'
        '  requiredMap: $requiredMap,\n'
        '  requiredList: $requiredList,\n'
        '  requiredSet: $requiredSet,\n'
        '  requiredDouble: $requiredDouble,\n'
        '  requiredString: $requiredString,\n'
        '  requiredDynamic: $requiredDynamic,\n'
        '  requiredChild: $requiredChild,\n'
        '  requiredChildren: $requiredChildren,\n'
        '  optionalMap: $optionalMap,\n'
        '  optionalList: $optionalList,\n'
        '  optionalSet: $optionalSet,\n'
        '  optionalDouble: $optionalDouble,\n'
        '  optionalString: $optionalString,\n'
        '  optionalDynamic: $optionalDynamic,\n'
        '  optionalChild: $optionalChild,\n'
        '  optionalChildren: $optionalChildren\n'
        '}';
  }
}

class TestPositionalParams {
  final Map<String, String> requiredMap;
  final List<String> requiredList;
  final Set<String> requiredSet;
  final double requiredDouble;
  final String requiredString;
  final dynamic requiredDynamic;
  final TestObject requiredChild;
  final List<TestObject> requiredChildren;

  final Map<String, String>? optionalMap;
  final List<String>? optionalList;
  final Set<String>? optionalSet;
  final double? optionalDouble;
  final String? optionalString;
  final dynamic optionalDynamic;
  final TestObject? optionalChild;
  final List<TestObject>? optionalChildren;

  TestPositionalParams(
    this.requiredMap,
    this.requiredList,
    this.requiredSet,
    this.requiredDouble,
    this.requiredString,
    this.requiredDynamic,
    this.requiredChild,
    this.requiredChildren, [
    this.optionalMap,
    this.optionalList,
    this.optionalSet = const {"defaultSet"},
    this.optionalDouble,
    this.optionalString,
    this.optionalDynamic = "defaultDynamic",
    this.optionalChild,
    this.optionalChildren,
  ]);

  @override
  String toString() {
    return 'TestPositionalParams {\n'
        '  requiredMap: $requiredMap,\n'
        '  requiredList: $requiredList,\n'
        '  requiredSet: $requiredSet,\n'
        '  requiredDouble: $requiredDouble,\n'
        '  requiredString: $requiredString,\n'
        '  requiredDynamic: $requiredDynamic,\n'
        '  requiredChild: $requiredChild,\n'
        '  requiredChildren: $requiredChildren,\n'
        '  optionalMap: $optionalMap,\n'
        '  optionalList: $optionalList,\n'
        '  optionalSet: $optionalSet,\n'
        '  optionalDouble: $optionalDouble,\n'
        '  optionalString: $optionalString,\n'
        '  optionalDynamic: $optionalDynamic,\n'
        '  optionalChild: $optionalChild,\n'
        '  optionalChildren: $optionalChildren\n'
        '}';
  }
}
