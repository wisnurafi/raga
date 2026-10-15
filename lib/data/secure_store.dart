import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Encrypted storage for the backup code — the one secret that must not
// sit in plaintext SharedPreferences. Android: EncryptedSharedPreferences
// via the Android KeyStore. iOS: Keychain.
class SecureStore {
  static const _kBackupCode = 'raga.backup_code';
  static const _storage = FlutterSecureStorage();

  static Future<String?> readBackupCode() => _storage.read(key: _kBackupCode);

  static Future<void> writeBackupCode(String code) =>
      _storage.write(key: _kBackupCode, value: code);
}
