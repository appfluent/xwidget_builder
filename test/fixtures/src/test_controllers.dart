import 'package:xwidget/xwidget.dart';

// Fixture classes for ControllerBuilder: it must register concrete
// Controller subclasses, skip abstract ones, and ignore unrelated classes.

class TestPageController extends Controller {}

abstract class TestAbstractController extends Controller {}

class TestNotAController {
  final String name;

  TestNotAController(this.name);
}
