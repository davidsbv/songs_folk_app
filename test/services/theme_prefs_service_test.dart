import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_folk_app/services/theme_prefs_service.dart';

void main() {
  group('ThemePrefsService', () {
    test('aplica default system cuando no hay valor', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ThemePrefsService();
      expect(await service.readThemeMode(), ThemeMode.system);
    });

    test('lee y escribe preferencia válida', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ThemePrefsService();
      await service.writeThemeMode(ThemeMode.dark);
      expect(await service.readThemeMode(), ThemeMode.dark);
    });

    test('soporta valor corrupto devolviendo system', () async {
      SharedPreferences.setMockInitialValues({'user_theme_mode': 'broken_value'});
      final service = ThemePrefsService();
      expect(await service.readThemeMode(), ThemeMode.system);
    });
  });
}
