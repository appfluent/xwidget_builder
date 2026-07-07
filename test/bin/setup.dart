import 'dart:io';

main() async {
  // Run setup as separate Dart process from the fixture app root, the same
  // way an end user runs the generator from their project root.
  final result = await Process.run('dart', [
    'run',
    'xwidget_builder:generate',
  ], workingDirectory: 'test/fixtures');
  print(result.stdout);
}
