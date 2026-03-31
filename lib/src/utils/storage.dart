import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

import 'cli_log.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;

  late final Key _key;
  late final Encrypter _encrypter;
  late final String _storagePath;

  SecureStorage._internal() {
    _key = _deriveKey();
    _encrypter = Encrypter(AES(_key));

    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) throw Exception('Could not find home directory');

    final configDir = path.join(home, '.xwidget');
    Directory(configDir).createSync(recursive: true);
    _storagePath = path.join(configDir, 'secure_storage');
  }

  Future<void> set(String key, String value) async {
    final data = _loadAll();
    data[key] = value;
    _saveAll(data);
  }

  Future<String?> get(String key) async {
    final data = _loadAll();
    return data[key];
  }

  Future<void> delete(String key) async {
    final data = _loadAll();
    data.remove(key);
    _saveAll(data);
  }

  Future<void> clear() async {
    try {
      await File(_storagePath).delete();
    } on PathNotFoundException {
      // file doesn't exist; nothing to clear
    } catch (e) {
      CliLog.warn('Problem clearing storage: $e');
    }
  }

  Future<bool> has(String key) async {
    final data = _loadAll();
    return data.containsKey(key);
  }

  Future<List<String>> keys() async {
    final data = _loadAll();
    return data.keys.toList();
  }

  Key _deriveKey() {
    // Use home directory path as machine identifier
    // This is stable across reboots and simple to get
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/unknown';

    final username = Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown';

    // Combine with app-specific salt
    final salt = 'xwidget-secure-storage-v1';
    final combined = '$home:$username:$salt';

    // Hash to create 32-byte key
    final bytes = sha256.convert(utf8.encode(combined)).bytes;
    return Key.fromBase64(base64.encode(bytes));
  }

  Map<String, String> _loadAll() {
    try {
      final file = File(_storagePath);
      if (!file.existsSync()) return {};

      final content = file.readAsStringSync();
      final parts = content.split(':');
      if (parts.length != 2) return {};

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      return Map<String, String>.from(jsonDecode(decrypted));
    } catch (e) {
      return {};
    }
  }

  void _saveAll(Map<String, String> data) {
    final json = jsonEncode(data);
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(json, iv: iv);

    final combined = '${iv.base64}:${encrypted.base64}';
    final file = File(_storagePath);
    final exists = file.existsSync();
    file.writeAsStringSync(combined);

    if (!exists) {
      _setFilePermissions(_storagePath);
    }
  }

  void _setFilePermissions(String path) {
    if (Platform.isWindows) {
      Process.runSync("icacls", [
        path,
        "/inheritance:r",
        "/grant:r",
        "${Platform.environment['USERNAME']}:RW",
      ]);
    } else {
      Process.runSync("chmod", ["600", path]);
    }
  }
}
