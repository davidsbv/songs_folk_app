import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/partituras_catalog.dart';
import '../models/song.dart';
import '../repositories/songs_repository.dart';
import '../services/admin_auth_service.dart';
import 'admin_screen.dart';
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
  final AdminAuthService _adminAuth = AdminAuthService();

  List<Song> _songs = [];
  List<String> _songTypes = [];
  List<String> _instruments = [];

  /// Subtipos de Song en Partituras por instrumento (CUERDA, DULZAINA) — partituras_catalog.
  Map<String, List<String>> _partiturasSubtypesByInstrument = {};
  bool _loading = true;
  bool _syncing = false;
  String? _error;
  DateTime? _lastSyncAt;

  String? _selectedInstrumentFilter;
  String? _selectedTypeFilter;
  String? _selectedSubtypeFilter;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  static const String _prefsKeyFontScaleGlobal = 'app_font_scale';
  static const String _prefsKeyFontScaleLegacyPartituras = 'partituras_font_scale';
  static const String _prefsKeyFontScaleLegacyCoplero = 'coplero_font_scale';
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFontScale();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      final lastSyncAt = await _repo.getSongsLastSyncAt();
      final partiturasSubtypes = <String, List<String>>{};
      for (final name in instruments) {
        partiturasSubtypes[name] = await _repo
            .getPartiturasSubtypesByInstrument(name);
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _songTypes = songTypes;
          _instruments = instruments;
          _partiturasSubtypesByInstrument = partiturasSubtypes;
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

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final count = await _repo.syncSongsCacheFromRemote();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sincronización completada: $count canciones.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo sincronizar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGlobal = prefs.getDouble(_prefsKeyFontScaleGlobal);
    final savedLegacyPartituras =
        prefs.getDouble(_prefsKeyFontScaleLegacyPartituras);
    final savedLegacyCoplero = prefs.getDouble(_prefsKeyFontScaleLegacyCoplero);
    final saved = savedGlobal ?? savedLegacyPartituras ?? savedLegacyCoplero;
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

  List<Song> get _displayedSongs {
    var list = _songs;
    if (_selectedInstrumentFilter != null) {
      list = list
          .where(
            (s) => s.scores.any(
              (sc) => sc.instrument == _selectedInstrumentFilter,
            ),
          )
          .toList();
    }
    if (_selectedTypeFilter != null) {
      list = list.where((s) => s.type == _selectedTypeFilter!).toList();
    }
    if (_selectedSubtypeFilter != null &&
        _selectedSubtypeFilter != partiturasAllSubtypesKey) {
      list = list.where((s) => s.subtype == _selectedSubtypeFilter!).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _normalizeForSearch(_searchQuery.trim());
      list = list
          .where(
            (s) =>
                _normalizeForSearch(s.title).contains(q) ||
                _normalizeForSearch(s.author).contains(q),
          )
          .toList();
    }
    return list;
  }

  String _normalizeForSearch(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n')
        // Elimina diacríticos "combinantes" (p.ej. "o\u0301" en vez de "ó").
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '');
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
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          _exitSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por título o autor…',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                )
              : const Text('Partituras'),
          actions: [
            if (_isSearching) ...[
              if (_searchQuery.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar',
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                  icon: const Icon(Icons.clear),
                ),
              IconButton(
                tooltip: 'Cerrar búsqueda',
                onPressed: _exitSearch,
                icon: const Icon(Icons.close),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Actualizar datos offline',
                onPressed: _syncing ? null : _syncNow,
                icon: _syncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download),
              ),
              IconButton(
                tooltip: 'Buscar',
                onPressed: _enterSearch,
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Ajustar tamaño de letra',
                onPressed: _openFontSizeDialog,
                icon: const Icon(Icons.text_fields),
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            _buildTypeSubtypeFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  void _enterSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _onSearchChanged(String value) async {
    final trimmed = value.trim();
    if (trimmed.toLowerCase() == '/admin') {
      _searchController.clear();
      setState(() => _searchQuery = '');
      await _requestAdminAccess();
      return;
    }
    if (!mounted) return;
    setState(() => _searchQuery = value);
  }

  Future<void> _requestAdminAccess() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String email = '';
    String password = '';
    bool showPassword = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Acceso Admin'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: 'Contrasena',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: showPassword ? 'Ocultar' : 'Mostrar',
                        icon: Icon(
                          showPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    email = emailCtrl.text.trim();
                    password = passwordCtrl.text;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Entrar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted || confirmed != true) return;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes indicar email y contraseña.')),
      );
      return;
    }
    try {
      await _adminAuth.signInAdmin(email: email, password: password);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Acceso denegado'),
          content: SingleChildScrollView(
            child: Text('$e'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  void _exitSearch() {
    _searchFocusNode.unfocus();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _isSearching = false);
    });
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
        final titleFontSize =
            (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) *
                _fontScale;
        final subtitleFontSize =
            (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) *
                _fontScale;
        return ListTile(
          title: Text(
            song.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: titleFontSize,
                ),
          ),
          subtitle: Text(
            '${song.type} · ${song.subtype}\n${song.author}\n${_instrumentsSummary(song)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: subtitleFontSize,
                ),
          ),
          leading: const Icon(Icons.music_note),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SongDetailScreen(
                song: song,
                showOnlyLyrics: false,
                fontScale: _fontScale,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSubtypeFilters() {
    final subtypes = _subtypesForPartituras;
    final typeDropdown = DropdownButtonFormField<String?>(
      initialValue: _selectedTypeFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tipo',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('TODOS')),
        ..._songTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
      ],
      onChanged: (v) => setState(() {
        _selectedTypeFilter = v;
        _selectedSubtypeFilter = null;
      }),
    );

    final subtypeDropdown = DropdownButtonFormField<String?>(
      initialValue: _selectedSubtypeFilter ?? partiturasAllSubtypesKey,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Subtipo',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(
          value: partiturasAllSubtypesKey,
          child: Text('Todos'),
        ),
        ...subtypes.map((s) => DropdownMenuItem(value: s, child: Text(s))),
      ],
      onChanged: (v) => setState(
        () => _selectedSubtypeFilter = v == partiturasAllSubtypesKey ? null : v,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useColumn = constraints.maxWidth < 420;
          final status = _lastSyncAt == null
              ? null
              : Text(
                  'Última actualización offline: ${_formatDateTime(_lastSyncAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
          if (useColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status != null) ...[status, const SizedBox(height: 8)],
                typeDropdown,
                const SizedBox(height: 12),
                subtypeDropdown,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status != null) ...[status, const SizedBox(height: 8)],
              Row(
                children: [
                  Expanded(child: typeDropdown),
                  const SizedBox(width: 12),
                  Expanded(child: subtypeDropdown),
                ],
              ),
            ],
          );
        },
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
          ..._instruments.map(
            (name) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ChoiceChip(
                label: Text(name),
                selected: _selectedInstrumentFilter == name,
                onSelected: (_) => setState(() {
                  _selectedInstrumentFilter = name;
                  _selectedSubtypeFilter = null;
                }),
              ),
            ),
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
}
