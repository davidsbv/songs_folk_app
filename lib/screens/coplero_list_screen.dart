import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/song_catalog.dart';
import '../repositories/songs_repository.dart';
import 'song_detail_screen.dart';

/// Lista de canciones del Coplero: tipo elegido en la pantalla anterior (JOTA/SEGUIDILLA),
/// filtro por subtipo ([song_catalog]) y búsqueda por título.
class CopleroListScreen extends StatefulWidget {
  final String selectedType;

  const CopleroListScreen({super.key, required this.selectedType});

  @override
  State<CopleroListScreen> createState() => _CopleroListScreenState();
}

class _CopleroListScreenState extends State<CopleroListScreen> {
  final SongsRepository _repo = SongsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Song> _songs = [];
  List<String> _subtypes = [];
  bool _loading = true;
  String? _error;

  String? _selectedSubtypeFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _repo.getSongs();
      final subtypes = await _repo.getSongSubtypesByType(widget.selectedType);
      if (mounted) {
        setState(() {
          _songs = all.where((s) => s.type == widget.selectedType).toList();
          _subtypes = subtypes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Song> get _displayedSongs {
    var list = _songs;
    if (_selectedSubtypeFilter != null &&
        _selectedSubtypeFilter != allSubtypesKey) {
      list = list.where((s) => s.subtype == _selectedSubtypeFilter!).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((s) => s.title.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.selectedType == 'JOTA' ? 'Jotas' : 'Seguidillas';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error al cargar: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar por título',
              hintText: 'Escribe parte del título...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _selectedSubtypeFilter ?? allSubtypesKey,
            decoration: const InputDecoration(
              labelText: 'Subtipo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: allSubtypesKey,
                child: const Text('Todos los subtipos'),
              ),
              ..._subtypes.map(
                (s) => DropdownMenuItem(value: s, child: Text(s)),
              ),
            ],
            onChanged: (v) => setState(() {
              _selectedSubtypeFilter =
                  v == allSubtypesKey ? null : v;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _displayedSongs;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty || _selectedSubtypeFilter != null
              ? 'Ninguna canción coincide con los filtros.'
              : 'No hay canciones de este tipo.',
        ),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final song = list[index];
        return ListTile(
          title: Text(song.title),
          subtitle: Text('${song.subtype}\n${song.author}'),
          leading: const Icon(Icons.menu_book),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SongDetailScreen(
                song: song,
                showOnlyLyrics: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
