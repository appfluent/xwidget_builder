import 'package:flutter/material.dart';

import 'test_classes.dart';

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
  FloatingActionButton,
  Icon,
  MaterialApp,
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
  TestPositionalParams
];