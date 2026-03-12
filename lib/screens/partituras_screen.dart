import 'package:flutter/material.dart';

import '../models/partituras_catalog.dart';
import '../models/song.dart';
import '../repositories/songs_repository.dart';
import 'song_detail_screen.dart';

/// Pantalla de partituras: instrumento (chips), tipo y subtipo de Song.
/// En Partituras el desplegable Subtipo usa los catálogos de Cuerda/Dulzaina (partituras_catalog / partituras_subtypes).
class PartiturasScreen extends StatefulWidget {
  const PartiturasScreen({super.key});

  @override
  State<PartiturasScreen> createState() => _PartiturasScreenState();
}

class _PartiturasScreenState extends State<PartiturasScreen> {
  final SongsRepository _repo = SongsRepository();

  List<Song> _songs = [];
  List<String> _songTypes = [];
  List<String> _instruments = [];
  /// Subtipos de Song en Partituras por instrumento (CUERDA, DULZAINA) — partituras_catalog.
  Map<String, List<String>> _partiturasSubtypesByInstrument = {};
  bool _loading = true;
  String? _error;

  String? _selectedInstrumentFilter;
  String? _selectedTypeFilter;
  String? _selectedSubtypeFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final songs = await _repo.getSongs();
      final songTypes = await _repo.getSongTypes();
      final instruments = await _repo.getInstruments();
      final partiturasSubtypes = <String, List<String>>{};
      for (final name in instruments) {
        partiturasSubtypes[name] = await _repo.getPartiturasSubtypesByInstrument(name);
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _songTypes = songTypes;
          _instruments = instruments;
          _partiturasSubtypesByInstrument = partiturasSubtypes;
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
    if (_selectedInstrumentFilter != null) {
      list = list
          .where((s) =>
              s.scores.any((sc) => sc.instrument == _selectedInstrumentFilter))
          .toList();
    }
    if (_selectedTypeFilter != null) {
      list = list.where((s) => s.type == _selectedTypeFilter!).toList();
    }
    if (_selectedSubtypeFilter != null &&
        _selectedSubtypeFilter != partiturasAllSubtypesKey) {
      list = list.where((s) => s.subtype == _selectedSubtypeFilter!).toList();
    }
    return list;
  }

  /// Subtipos de Song para el desplegable en Partituras: según instrumento (Cuerda/Dulzaina).
  /// Si no hay instrumento seleccionado (Todas), se muestra la unión de ambos catálogos.
  List<String> get _subtypesForPartituras {
    switch (_selectedInstrumentFilter) {
      case 'CUERDA':
        return _partiturasSubtypesByInstrument['CUERDA'] ?? [];
      case 'DULZAINA':
        return _partiturasSubtypesByInstrument['DULZAINA'] ?? [];
      default:
        final combined = [
          ...(_partiturasSubtypesByInstrument['CUERDA'] ?? []),
          ...(_partiturasSubtypesByInstrument['DULZAINA'] ?? []),
        ];
        final result = List<String>.from(combined.toSet());
        result.sort();
        return result;
    }
  }

  String _instrumentsSummary(Song song) {
    final instruments = song.scores.map((s) => s.instrument).toSet().toList();
    instruments.sort();
    return instruments.isEmpty ? 'Sin instrumentos' : instruments.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partituras')),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildTypeSubtypeFilters(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error al cargar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _displayedSongs.length,
      itemBuilder: (context, index) {
        final song = _displayedSongs[index];
        return ListTile(
          title: Text(song.title),
          subtitle: Text(
            '${song.type} · ${song.subtype}\n${song.author}\n${_instrumentsSummary(song)}',
          ),
          leading: const Icon(Icons.music_note),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SongDetailScreen(
                song: song,
                showOnlyLyrics: false,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSubtypeFilters() {
    final subtypes = _subtypesForPartituras;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedTypeFilter,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('TODOS')),
                ..._songTypes.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() {
                _selectedTypeFilter = v;
                _selectedSubtypeFilter = null;
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedSubtypeFilter ?? partiturasAllSubtypesKey,
              decoration: const InputDecoration(
                labelText: 'Subtipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: partiturasAllSubtypesKey,
                  child: Text('Todos los subtipos'),
                ),
                ...subtypes.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) => setState(() =>
                  _selectedSubtypeFilter =
                      v == partiturasAllSubtypesKey ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: _selectedInstrumentFilter == null,
            onSelected: (_) => setState(() {
              _selectedInstrumentFilter = null;
              _selectedSubtypeFilter = null;
            }),
          ),
          ..._instruments.map((name) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ChoiceChip(
                  label: Text(name),
                  selected: _selectedInstrumentFilter == name,
                  onSelected: (_) => setState(() {
                    _selectedInstrumentFilter = name;
                    _selectedSubtypeFilter = null;
                  }),
                ),
              )),
        ],
      ),
    );
  }
}
