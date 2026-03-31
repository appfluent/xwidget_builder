import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/src/test_classes.dart';
import '../../generated/src/inflaters_test.g.dart';

void main() {
  test('Test InflaterBuilder dependency resolution', () async {});

  test('Test new inflater spec format', () async {});

  test('Test inflater spec generics', () async {});

  test('Test inflater named arg methods', () async {
    final attributes = <String, dynamic>{
      "requiredMap": {},
      "requiredList": [],
      "requiredSet": <dynamic>{},
      "requiredDouble": 0,
      "requiredString": "",
      "requiredDynamic": null,
      "requiredChild": TestObject("child"),
      "requiredChildren": TestObject("children"),
      "optionalDouble": 3,
    };
    final children = <dynamic>[];
    final text = <String>[];
    final inflater = TestNamedParamsInflater();

    final inflated = inflater.inflate(attributes, children, text);
    print(inflated);
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
      "requiredChildren": TestObject("children"),
      "optionalDouble": 32,
    };
    final children = <dynamic>[];
    final text = <String>[];
    final inflater = TestPositionalParamsInflater();

    final inflated = inflater.inflate(attributes, children, text);
    print(inflated);
  });
}
