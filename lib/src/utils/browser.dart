import 'dart:io';

Future<void> openInBrowser(String url, {int width = 350, int height = 500}) async {
  if (Platform.isMacOS) {
    await _openMacOS(url, width, height);
  } else if (Platform.isWindows) {
    await _openWindows(url, width, height);
  } else if (Platform.isLinux) {
    await _openLinux(url, width, height);
  } else {
    throw UnsupportedError('Platform not supported');
  }
}

Future<void> _openMacOS(String url, int width, int height) async {
  final chromePaths = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
  ];

  for (final chromePath in chromePaths) {
    if (File(chromePath).existsSync()) {
      try {
        await Process.start(chromePath, [
          '--app=$url',
          '--new-window',
          '--window-size=$width,$height',
          '--window-position=100,100',
        ], mode: ProcessStartMode.detached);
        return;
      } catch (e) {
        print('Failed to launch Chrome: $e');
      }
    }
  }

  // Fallback: default browser
  await Process.run('open', [url]);
}

Future<void> _openWindows(String url, int width, int height) async {
  final chromePaths = [
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
  ];

  final localAppData = Platform.environment['LOCALAPPDATA'];
  if (localAppData != null) {
    chromePaths.add(r'$localAppData\Google\Chrome\Application\chrome.exe');
  }

  for (final chromePath in chromePaths) {
    if (File(chromePath).existsSync()) {
      await Process.start(chromePath, [
        '--app=$url',
        '--new-window',
        '--window-size=$width,$height',
        '--window-position=100,100',
      ], mode: ProcessStartMode.detached);
      return;
    }
  }

  // Fallback: default browser
  await Process.run('cmd', ['/c', 'start', url]);
}

Future<void> _openLinux(String url, int width, int height) async {
  final browsers = ['google-chrome', 'chromium-browser', 'chromium'];

  for (final browser in browsers) {
    try {
      final result = await Process.run('which', [browser]);
      if (result.exitCode == 0) {
        await Process.start(browser, [
          '--app=$url',
          '--new-window',
          '--window-size=$width,$height',
          '--window-position=100,100',
        ], mode: ProcessStartMode.detached);
        return;
      }
    } catch (_) {
      continue;
    }
  }

  // Fallback: default browser
  await Process.run('xdg-open', [url]);
}
