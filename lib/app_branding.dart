import 'package:flutter/material.dart';

import 'models/app_appearance.dart';

/// Expone apariencia remota y tema local a todo el arbol bajo [MaterialApp].
class AppBranding extends InheritedWidget {
  final AppAppearance appearance;
  final ThemeMode themeMode;
  final Future<void> Function() refreshAppearance;
  final Future<void> Function(ThemeMode mode) setUserThemeMode;

  const AppBranding({
    super.key,
    required this.appearance,
    required this.themeMode,
    required this.refreshAppearance,
    required this.setUserThemeMode,
    required super.child,
  });

  static AppBranding of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppBranding>();
    assert(scope != null, 'AppBranding debe envolver MaterialApp');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppBranding oldWidget) {
    return appearance != oldWidget.appearance || themeMode != oldWidget.themeMode;
  }
}
