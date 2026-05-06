import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> read(String key) => _secureStorage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _secureStorage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _secureStorage.delete(key: key);
}

class AdminCredentials {
  final bool rememberPassword;
  final String email;
  final String password;

  const AdminCredentials({
    this.rememberPassword = false,
    this.email = '',
    this.password = '',
  });
}

abstract class AdminCredentialsStoreBase {
  Future<AdminCredentials> load();
  Future<void> save({
    required bool rememberPassword,
    required String email,
    required String password,
  });
}

class AdminCredentialsStore implements AdminCredentialsStoreBase {
  AdminCredentialsStore({
    SecureKeyValueStore? secureStorage,
    Future<SharedPreferences> Function()? prefsProvider,
  }) : _secureStorage = secureStorage ?? FlutterSecureKeyValueStore(),
       _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static const String _prefsKeyRememberPassword = 'admin_remember_password';
  static const String _prefsKeyEmailLegacy = 'admin_email';
  static const String _prefsKeyPasswordLegacy = 'admin_password';
  static const String _secureKeyEmail = 'admin_email';
  static const String _secureKeyPassword = 'admin_password';

  final SecureKeyValueStore _secureStorage;
  final Future<SharedPreferences> Function() _prefsProvider;

  Future<AdminCredentials> load() async {
    final prefs = await _prefsProvider();
    final rememberPassword = prefs.getBool(_prefsKeyRememberPassword) ?? false;
    if (!rememberPassword) {
      return const AdminCredentials();
    }

    await _migrateLegacyIfNeeded(prefs);

    final email = await _secureStorage.read(_secureKeyEmail);
    final password = await _secureStorage.read(_secureKeyPassword);
    return AdminCredentials(
      rememberPassword: true,
      email: email ?? '',
      password: password ?? '',
    );
  }

  Future<void> save({
    required bool rememberPassword,
    required String email,
    required String password,
  }) async {
    final prefs = await _prefsProvider();
    await prefs.setBool(_prefsKeyRememberPassword, rememberPassword);
    if (rememberPassword) {
      await _secureStorage.write(_secureKeyEmail, email);
      await _secureStorage.write(_secureKeyPassword, password);
      return;
    }
    await _secureStorage.delete(_secureKeyEmail);
    await _secureStorage.delete(_secureKeyPassword);
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    final legacyEmail = prefs.getString(_prefsKeyEmailLegacy);
    final legacyPassword = prefs.getString(_prefsKeyPasswordLegacy);
    final hasLegacyData =
        (legacyEmail != null && legacyEmail.isNotEmpty) ||
        (legacyPassword != null && legacyPassword.isNotEmpty);
    if (!hasLegacyData) return;

    final secureEmail = await _secureStorage.read(_secureKeyEmail);
    final securePassword = await _secureStorage.read(_secureKeyPassword);

    if ((secureEmail == null || secureEmail.isEmpty) && legacyEmail != null) {
      await _secureStorage.write(_secureKeyEmail, legacyEmail);
    }
    if ((securePassword == null || securePassword.isEmpty) &&
        legacyPassword != null) {
      await _secureStorage.write(_secureKeyPassword, legacyPassword);
    }

    await prefs.remove(_prefsKeyEmailLegacy);
    await prefs.remove(_prefsKeyPasswordLegacy);
  }
}
