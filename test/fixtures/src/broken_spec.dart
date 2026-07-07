// Intentionally broken source for the error-path generation tests.
// The ignore comments keep `dart analyze` quiet, but the analyzer's element
// model still resolves these declarations to InvalidType, which is what the
// builders must detect and report.
// ignore_for_file: undefined_class, undefined_identifier, unused_element

import 'test_classes.dart';

// InvalidType property: hits the property error path before spec discovery.
const badProperty = undefinedIdentifier;

const inflaters = [
  BrokenWidget,
  // a valid class after the broken one proves generation continues
  TestObject,
];

class BrokenWidget {
  final UndefinedType broken;
  final String ok;

  BrokenWidget(this.broken, this.ok);
}
