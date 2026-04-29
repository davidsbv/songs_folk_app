import 'package:flutter/material.dart';

import '../models/song.dart';
import '../repositories/songs_repository.dart';
import 'admin_create_song_screen.dart';

class AdminEditSongsScreen extends StatefulWidget {
  const AdminEditSongsScreen({super.key});

  @override
  State<AdminEditSongsScreen> createState() => _AdminEditSongsScreenState();
}

class _AdminEditSongsScreenState extends State<AdminEditSongsScreen> {
  final SongsRepository _repo = SongsRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Song> _songs = const [];
  bool _loading = true;
  String _search = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final songs = await _repo.getAdminSongs();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<Song> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _songs;
    return _songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.author.toLowerCase().contains(q) ||
          s.type.toLowerCase().contains(q) ||
          s.subtype.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Canciones')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar por título, autor, tipo o subtipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudieron cargar canciones:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return const Center(child: Text('No hay canciones para editar.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final song = list[index];
          return ListTile(
            leading: const Icon(Icons.library_music),
            title: Text(song.title),
            subtitle: Text('${song.type} · ${song.subtype}\n${song.author}'),
            trailing: IconButton(
              tooltip: 'Eliminar canción',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(song),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminCreateSongScreen(initialSong: song),
                ),
              );
              await _load();
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Song song) async {
    final id = song.remoteId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede eliminar: canción sin id remoto.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar canción'),
        content: const Text('Se eliminará la canción y sus partituras/tablaturas asociadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final previous = List<Song>.from(_songs);
    var undo = false;
    setState(() {
      _songs = _songs.where((s) => s.remoteId != id).toList();
    });
    final messenger = ScaffoldMessenger.of(context);
    final result = await messenger.showSnackBar(
      SnackBar(
        content: const Text('Canción preparada para eliminar'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => undo = true,
        ),
        duration: const Duration(seconds: 4),
      ),
    ).closed;
    if (!mounted) return;
    if (undo || result == SnackBarClosedReason.action) {
      setState(() => _songs = previous);
      return;
    }
    try {
      await _repo.deleteSong(id);
      await _repo.syncSongsCacheFromRemote();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Canción eliminada.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _songs = previous);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }
}
