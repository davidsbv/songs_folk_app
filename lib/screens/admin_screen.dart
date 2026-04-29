import 'package:flutter/material.dart';

import '../services/admin_auth_service.dart';
import '../widgets/menu_tile.dart';
import 'admin_create_copla_screen.dart';
import 'admin_create_song_screen.dart';
import 'admin_edit_coplas_screen.dart';
import 'admin_edit_songs_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AdminAuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión admin',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MenuTile(
              title: 'ALTA DE CANCION',
              subtitle: 'Crear registro basado en Song',
              icon: Icons.library_music,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCreateSongScreen()),
              ),
            ),
            const SizedBox(height: 16),
            MenuTile(
              title: 'ALTA DE COPLA',
              subtitle: 'Crear registro basado en Copla',
              icon: Icons.edit_note,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCreateCoplaScreen()),
              ),
            ),
            const SizedBox(height: 16),
            MenuTile(
              title: 'EDITAR CANCION',
              subtitle: 'Buscar y actualizar canciones existentes',
              icon: Icons.edit,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminEditSongsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            MenuTile(
              title: 'EDITAR COPLA',
              subtitle: 'Buscar y actualizar coplas existentes',
              icon: Icons.edit_calendar,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminEditCoplasScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
