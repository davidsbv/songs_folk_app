import 'package:flutter/material.dart';

import '../widgets/menu_tile.dart';
import 'coplero_list_screen.dart';

/// Pantalla para elegir entre Jotas o Seguidillas en el Coplero.
class CopleroChooseTypeScreen extends StatelessWidget {
  const CopleroChooseTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coplero Tradicional')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MenuTile(
              title: 'JOTAS',
              subtitle: 'Ver letras de jotas',
              icon: Icons.lyrics,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CopleroListScreen(selectedType: 'JOTA'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            MenuTile(
              title: 'SEGUIDILLAS',
              subtitle: 'Ver letras de seguidillas',
              icon: Icons.lyrics,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CopleroListScreen(selectedType: 'SEGUIDILLA'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
