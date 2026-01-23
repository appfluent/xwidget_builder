import 'package:flutter_test/flutter_test.dart';

import '../../../bin/src/utils/path_resolver.dart';

void main() {
  test('Test package path resolution should throw exception with specific message', () async {
    await expectLater(
      PathResolver.relativeToAbsolute('package:flutter/src/widgets/fake_widget.dart'),
      throwsA(predicate((e) {
        print(e);
        return e is Exception && e.toString().startsWith('Exception: Package');
      }))
    );
  });
}