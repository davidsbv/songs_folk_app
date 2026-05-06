import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia local: modo claro / oscuro / sistema (no va a Supabase).
class ThemePrefsService {
  ThemePrefsService._();

  static final ThemePrefsService _instance = ThemePrefsService._();

  factory ThemePrefsService() => _instance;

  static const _key = 'user_theme_mode';

  Future<ThemeMode> readThemeMode() async {
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_key);
    if (name == null) return ThemeMode.system;
    for (final m in ThemeMode.values) {
      if (m.name == name) return m;
    }
    return ThemeMode.system;
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, mode.name);
  }
}
