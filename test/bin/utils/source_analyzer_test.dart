import 'package:flutter_test/flutter_test.dart';

import '../../../bin/src/utils/source_analyzer.dart';

void main() {

  test('Test new icon spec format', () async {
    final sources = <String>["test/fixtures/src/*.dart"];
    final analyzer = SourceAnalyzer(sdkPath: '/Users/cbarlow/Development/flutter/bin/cache/dart-sdk');
    final libs = await analyzer.getLibraryElements(sources);
  });
}