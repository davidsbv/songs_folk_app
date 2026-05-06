import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_folk_app/services/admin_credentials_store.dart';

class _MockSecureStorage extends Mock implements SecureKeyValueStore {}

void main() {
  group('AdminCredentialsStore', () {
    test('si recordar está desactivado, no devuelve credenciales', () async {
      SharedPreferences.setMockInitialValues({});
      final secureStorage = _MockSecureStorage();
      final store = AdminCredentialsStore(
        secureStorage: secureStorage,
      );

      final credentials = await store.load();

      expect(credentials.rememberPassword, isFalse);
      expect(credentials.email, isEmpty);
      expect(credentials.password, isEmpty);
      verifyNever(() => secureStorage.read(any()));
    });

    test('guarda y recupera email y contraseña desde secure storage', () async {
      SharedPreferences.setMockInitialValues({});
      final secureStorage = _MockSecureStorage();
      final secureValues = <String, String>{};

      when(() => secureStorage.write(any(), any())).thenAnswer((invocation) async {
        final key = invocation.positionalArguments[0] as String;
        final value = invocation.positionalArguments[1] as String;
        secureValues[key] = value;
      });
      when(() => secureStorage.read(any())).thenAnswer((invocation) async {
        final key = invocation.positionalArguments[0] as String;
        return secureValues[key];
      });
      when(() => secureStorage.delete(any())).thenAnswer((_) async {});

      final store = AdminCredentialsStore(
        secureStorage: secureStorage,
      );

      await store.save(
        rememberPassword: true,
        email: 'admin@test.com',
        password: 'secreto',
      );
      final credentials = await store.load();

      expect(credentials.rememberPassword, isTrue);
      expect(credentials.email, 'admin@test.com');
      expect(credentials.password, 'secreto');
    });

    test('migra credenciales legacy de SharedPreferences a secure storage', () async {
      SharedPreferences.setMockInitialValues({
        'admin_remember_password': true,
        'admin_email': 'legacy@test.com',
        'admin_password': 'legacy-pass',
      });
      final secureStorage = _MockSecureStorage();
      final secureValues = <String, String>{};

      when(() => secureStorage.read(any())).thenAnswer((invocation) async {
        final key = invocation.positionalArguments[0] as String;
        return secureValues[key];
      });
      when(() => secureStorage.write(any(), any())).thenAnswer((invocation) async {
        final key = invocation.positionalArguments[0] as String;
        final value = invocation.positionalArguments[1] as String;
        secureValues[key] = value;
      });

      final store = AdminCredentialsStore(
        secureStorage: secureStorage,
      );
      final credentials = await store.load();
      final prefs = await SharedPreferences.getInstance();

      expect(credentials.rememberPassword, isTrue);
      expect(credentials.email, 'legacy@test.com');
      expect(credentials.password, 'legacy-pass');
      expect(prefs.getString('admin_email'), isNull);
      expect(prefs.getString('admin_password'), isNull);
      expect(secureValues['admin_email'], 'legacy@test.com');
      expect(secureValues['admin_password'], 'legacy-pass');
    });
  });
}
