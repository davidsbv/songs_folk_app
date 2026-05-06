import 'package:flutter/material.dart';

import '../app_branding.dart';
import '../widgets/menu_tile.dart';
import 'calendario_screen.dart';
import 'coplero_choose_type_screen.dart';
import 'partituras_screen.dart';

/// Pantalla de bienvenida con el menú principal de la app.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Seguir sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }

  static IconData _iconForTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = AppBranding.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancionero Folk'),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Aspecto (solo este dispositivo)',
            icon: Icon(_iconForTheme(branding.themeMode)),
            onSelected: (mode) => branding.setUserThemeMode(mode),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text(_themeLabel(ThemeMode.system)),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text(_themeLabel(ThemeMode.light)),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text(_themeLabel(ThemeMode.dark)),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MenuTile(
              title: 'PARTITURAS',
              subtitle: 'Letras, partituras y tablaturas por instrumento',
              icon: Icons.music_note,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartiturasScreen()),
              ),
            ),
            const SizedBox(height: 16),
            MenuTile(
              title: 'COPLERO TRADICIONAL',
              subtitle: 'Jotas y seguidillas (solo letras)',
              icon: Icons.menu_book,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CopleroChooseTypeScreen()),
              ),
            ),
            const SizedBox(height: 16),
            MenuTile(
              title: 'CALENDARIO DE EVENTOS',
              subtitle: 'Fiestas y eventos populares',
              icon: Icons.calendar_today,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarioScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
