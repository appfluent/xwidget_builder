import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/src/test_classes.dart';
import '../../fixtures/src/generated/src/inflaters_test.g.dart';

// Functional tests for generated inflaters: they execute the generated code
// (produced by generation_test.dart / setup.dart) against the fixture
// classes, proving the output not only matches the baseline but actually
// runs. Run generation first if inflaters_test.g.dart is missing.

void main() {
  test('Test inflater named arg methods', () async {
    final attributes = <String, dynamic>{
      "requiredMap": {},
      "requiredList": [],
      "requiredSet": <dynamic>{},
      "requiredDouble": 0,
      "requiredString": "",
      "requiredDynamic": null,
      "requiredChild": TestObject("child"),
      "requiredChildren": [TestObject("children")],
      "optionalDouble": 3,
    };
    final children = <dynamic>[];
    final text = <String>[];
    final inflater = TestNamedParamsInflater();

    final inflated = inflater.inflate(attributes, children, text);

    expect(inflated, isA<TestNamedParams>());
    final named = inflated as TestNamedParams;
    expect(named.requiredMap, isEmpty);
    expect(named.requiredList, isEmpty);
    expect(named.requiredSet, isEmpty);
    expect(named.requiredDouble, 0.0);
    expect(named.requiredString, "");
    expect(named.requiredDynamic, isNull);
    expect(named.requiredChild.name, "child");
    expect(named.requiredChildren.single.name, "children");
    expect(named.optionalDouble, 3.0);
    expect(named.optionalString, isNull);
    expect(named.optionalChildren, isNull);
  });

  test('Test inflater positional arg methods', () async {
    final attributes = <String, dynamic>{
      "requiredMap": {"key": "value"},
      "requiredList": [],
      "requiredSet": <dynamic>{},
      "requiredDouble": 0,
      "requiredString": 8,
      "requiredDynamic": null,
      "requiredChild": TestObject("child"),
      "requiredChildren": [TestObject("children")],
      // NOTE: optional positional args must be contiguous - supplying a
      // later positional (e.g. optionalDouble) while skipping earlier ones
      // misaligns Function.apply. Omit them all to exercise ctor defaults.
    };
    final children = <dynamic>[];
    final text = <String>[];
    final inflater = TestPositionalParamsInflater();

    final inflated = inflater.inflate(attributes, children, text);

    expect(inflated, isA<TestPositionalParams>());
    final positional = inflated as TestPositionalParams;
    expect(positional.requiredMap, {"key": "value"});
    expect(positional.requiredString, "8"); // non-strings are stringified
    expect(positional.requiredDouble, 0.0);
    expect(positional.requiredChild.name, "child");
    expect(positional.requiredChildren.single.name, "children");
    // omitted optional positionals fall back to constructor defaults
    expect(positional.optionalSet, {"defaultSet"});
    expect(positional.optionalDynamic, "defaultDynamic");
    expect(positional.optionalDouble, isNull);
  });
}
