import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/copla.dart';
import '../models/song_catalog.dart';
import '../repositories/songs_repository.dart';

/// Lista de canciones del Coplero: tipo elegido en la pantalla anterior (JOTA/SEGUIDILLA),
/// filtro por subtipo ([song_catalog]) y listado continuo de coplas.
class CopleroListScreen extends StatefulWidget {
  final String selectedType;
  final SongsRepository? repository;

  const CopleroListScreen({
    super.key,
    required this.selectedType,
    this.repository,
  });

  @override
  State<CopleroListScreen> createState() => _CopleroListScreenState();
}

class _CopleroListScreenState extends State<CopleroListScreen> {
  late final SongsRepository _repo;

  List<Copla> _coplas = [];
  List<String> _subtypes = [];
  bool _loading = true;
  bool _syncing = false;
  String? _error;
  DateTime? _lastSyncAt;

  String? _selectedSubtypeFilter;

  static const String _prefsKeyFontScaleGlobal = 'app_font_scale';
  static const String _prefsKeyFontScaleLegacyCoplero = 'coplero_font_scale';
  static const String _prefsKeyFontScaleLegacyPartituras = 'partituras_font_scale';
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? SongsRepository();
    _loadData();
    _loadFontScale();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coplas = await _repo.getCoplasByType(widget.selectedType);
      final subtypes = await _repo.getCoplaSubtypesByType(widget.selectedType);
      final lastSyncAt = await _repo.getCoplasLastSyncAt();
      if (mounted) {
        setState(() {
          _coplas = coplas;
          _subtypes = subtypes;
          _lastSyncAt = lastSyncAt;
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

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGlobal = prefs.getDouble(_prefsKeyFontScaleGlobal);
    final savedLegacyCoplero = prefs.getDouble(_prefsKeyFontScaleLegacyCoplero);
    final savedLegacyPartituras =
        prefs.getDouble(_prefsKeyFontScaleLegacyPartituras);
    final saved = savedGlobal ?? savedLegacyCoplero ?? savedLegacyPartituras;
    if (savedGlobal == null && saved != null) {
      await prefs.setDouble(_prefsKeyFontScaleGlobal, saved);
    }
    if (!mounted) return;
    setState(() {
      _fontScale = saved != null ? saved.clamp(0.85, 2.0) : 1.0;
    });
  }

  Future<void> _saveFontScale(double scale) async {
    final clamped = scale.clamp(0.85, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKeyFontScaleGlobal, clamped);
  }

  Future<void> _openFontSizeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Tamaño de letra'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Actual: ${(_fontScale * 100).round()}%',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _fontScale,
                    min: 0.85,
                    max: 2.0,
                    divisions: 12,
                    label: '${(_fontScale * 100).round()}%',
                    onChanged: (v) {
                      setState(() => _fontScale = v);
                      setStateDialog(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _saveFontScale(_fontScale);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final count = await _repo.syncCoplasCacheFromRemote();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sincronización completada: $count coplas.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo sincronizar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  List<Copla> get _displayedCoplas {
    var list = _coplas;
    if (_selectedSubtypeFilter != null &&
        _selectedSubtypeFilter != allSubtypesKey) {
      list = list.where((c) => c.subtype == _selectedSubtypeFilter!).toList();
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
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download),
            tooltip: 'Actualizar datos offline',
          ),
          IconButton(
            onPressed: _openFontSizeDialog,
            tooltip: 'Ajustar tamaño de letra',
            icon: const Icon(Icons.text_fields),
          ),
        ],
      ),
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
          if (_lastSyncAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Última actualización offline: ${_formatDateTime(_lastSyncAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          DropdownButtonFormField<String?>(
            initialValue: _selectedSubtypeFilter ?? allSubtypesKey,
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

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  Widget _buildList() {
    final list = _displayedCoplas;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _selectedSubtypeFilter != null
              ? 'No hay coplas para este subtipo.'
              : 'No hay canciones de este tipo.',
        ),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final copla = list[index];

        // Factor de escalado para mejorar la accesibilidad (visión reducida).
        final titleFontSize =
            (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) *
                _fontScale;
        final authorFontSize =
            (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) *
                _fontScale;
        final bodyFontSize =
            (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) *
                _fontScale;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${copla.subtype}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: titleFontSize,
                  ),
                ),
                if (copla.author != null && copla.author!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    copla.author!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: authorFontSize,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  copla.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: bodyFontSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
