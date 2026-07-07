import 'package:xwidget/xwidget.dart';

// Fixture classes that exercise analyzer-dependent builder behavior not
// covered by the Material widgets or the original test classes:
// annotation decoding, enums, super formals, deprecations, private
// constructors, config exclusions/defaults/parsers, and function-typed
// parameters.

enum TestMode { alpha, beta, gamma }

class TestEnumWidget {
  /// The selected mode.
  final TestMode mode;

  /// Inflates a [TestEnumWidget]. Also documents a [Map<String, int>]
  /// reference to exercise generic doc-comment escaping.
  TestEnumWidget(this.mode);
}

class TestSuperBase {
  /// Documentation that lives on the base class field.
  final String baseField;

  TestSuperBase(this.baseField);
}

class TestSuperFormals extends TestSuperBase {
  TestSuperFormals(super.baseField);
}

@InflaterDef(inflaterType: "MyCustom", inflatesOwnChildren: true)
class TestCustomWidget {
  final Dependencies dependencies;
  final String? title;

  TestCustomWidget(this.dependencies, {this.title});
}

class TestDeprecations {
  final String current;
  final String? old;

  TestDeprecations(this.current, [@Deprecated("gone") this.old]);

  @Deprecated("use the default constructor")
  TestDeprecations.legacy(this.current) : old = null;
}

class TestPrivateCtor {
  final String value;

  TestPrivateCtor(this.value);

  TestPrivateCtor._internal(this.value);
}

class TestExclusions {
  final String visible;
  final String? excludedArg;
  final String? excludedAttr;

  TestExclusions(this.visible, this.excludedArg, this.excludedAttr);
}

class TestFunctionParams {
  final void Function(int count)? onCount;
  final List<String> Function()? makeList;
  final String Function(String input)? transform;

  TestFunctionParams({this.onCount, this.makeList, this.transform});
}
