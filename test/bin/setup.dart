import 'dart:io';

main() async {
  // Run setup as separate Dart process
  final result = await Process.run(
    'dart',
    ['run', 'xwidget_builder:generate', "-c", "test/fixtures/res/xwidget_config.yaml"],
  );
  print(result.stdout);
}