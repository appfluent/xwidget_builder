import 'package:flutter/material.dart';

import 'test_classes.dart';
import 'test_custom_widgets.dart';

// Define constants for all widgets and objects we want to generate inflaters for.
// Used by the builder to generate inflaters.

// ignore_for_file: unused_element

const inflaters = [
  // material widgets
  AlertDialog,
  AlwaysStoppedAnimation,
  AlwaysStoppedAnimation<Color>,
  AlwaysStoppedAnimation<int>,
  AnimatedCrossFade,
  AppBar,
  BoxConstraints,
  Center,
  CircularProgressIndicator,
  Column,
  Container,
  FloatingActionButton,
  Icon,
  MaterialApp,
  Row,
  Scaffold,
  Text,
  TextButton,
  TextStyle,
  ThemeData,

  // test classes
  TestObject,
  TestDefaults,
  TestTypeParameters,
  TestTypeParameters<int, int>,
  TestTypeParameters<String, String>,
  TestTypeParameters<String, TestObject?>,
  TestNamedParams,
  TestPositionalParams,

  // analyzer edge cases: annotations, enums, super formals, deprecations,
  // private constructors, exclusions, function-typed params
  TestCustomWidget,
  TestEnumWidget,
  TestSuperFormals,
  TestDeprecations,
  TestPrivateCtor,
  TestExclusions,
  TestFunctionParams,
];
