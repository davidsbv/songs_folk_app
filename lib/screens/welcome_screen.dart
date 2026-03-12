import 'package:flutter/material.dart';

import '../widgets/menu_tile.dart';
import 'calendario_screen.dart';
import 'coplero_choose_type_screen.dart';
import 'partituras_screen.dart';

/// Pantalla de bienvenida con el menú principal de la app.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancionero Folk')),
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
