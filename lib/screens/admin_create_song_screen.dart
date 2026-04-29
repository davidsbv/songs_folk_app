import 'package:flutter/material.dart';

import '../models/score.dart';
import '../models/song.dart';
import '../repositories/songs_repository.dart';
import '../services/admin_upload_service.dart';

class AdminCreateSongScreen extends StatefulWidget {
  final Song? initialSong;

  const AdminCreateSongScreen({super.key, this.initialSong});

  @override
  State<AdminCreateSongScreen> createState() => _AdminCreateSongScreenState();
}

class _AdminCreateSongScreenState extends State<AdminCreateSongScreen> {
  static const String _otherSubtype = 'OTRO';
  final _repo = SongsRepository();
  final _uploadService = AdminUploadService();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();
  final _lyricsPdfCtrl = TextEditingController();
  final _lyricsImageCtrl = TextEditingController();
  final _scorePdfCtrl = TextEditingController();
  final _scoreImageCtrl = TextEditingController();
  final _tabPdfCtrl = TextEditingController();
  final _tabImageCtrl = TextEditingController();

  List<String> _types = const [];
  List<String> _subtypes = const [];
  List<String> _instruments = const [];
  String? _selectedType;
  String? _selectedSubtype;
  String? _selectedInstrument;
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSong;
    if (initial != null) {
      _titleCtrl.text = initial.title;
      _authorCtrl.text = initial.author;
      _lyricsCtrl.text = initial.lyricsText ?? '';
      _lyricsPdfCtrl.text = initial.lyricsPdfPath ?? '';
      _lyricsImageCtrl.text = initial.lyricsImagePath ?? '';
      if (initial.scores.isNotEmpty) {
        final first = initial.scores.first;
        _scorePdfCtrl.text = first.scorePdfPath ?? '';
        _scoreImageCtrl.text = first.scoreImagePath ?? '';
        _tabPdfCtrl.text = first.tabPdfPath ?? '';
        _tabImageCtrl.text = first.tabImagePath ?? '';
      }
    }
    _loadCatalogs();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _lyricsCtrl.dispose();
    _lyricsPdfCtrl.dispose();
    _lyricsImageCtrl.dispose();
    _scorePdfCtrl.dispose();
    _scoreImageCtrl.dispose();
    _tabPdfCtrl.dispose();
    _tabImageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    final types = await _repo.getSongTypes();
    final instruments = await _repo.getInstruments();
    final selectedInstrument = widget.initialSong?.scores.isNotEmpty == true
        ? widget.initialSong!.scores.first.instrument
        : (instruments.isEmpty ? null : instruments.first);
    final subtypes = selectedInstrument == null
        ? <String>[_otherSubtype]
        : await _repo.getPartiturasSubtypesByInstrument(selectedInstrument);
    if (!subtypes.contains(_otherSubtype)) {
      subtypes.add(_otherSubtype);
    }
    final initialType = widget.initialSong?.type;
    final effectiveType = (initialType != null && types.contains(initialType))
        ? initialType
        : null;
    final initialSubtype = widget.initialSong?.subtype;
    final effectiveSubtype = (initialSubtype != null && subtypes.contains(initialSubtype))
        ? initialSubtype
        : null;
    if (!mounted) return;
    final isEdit = widget.initialSong != null;
    setState(() {
      _types = types;
      _instruments = instruments;
      _selectedType = isEdit ? effectiveType : null;
      _subtypes = subtypes;
      _selectedSubtype = isEdit
          ? (effectiveSubtype ?? (subtypes.isEmpty ? null : subtypes.first))
          : (subtypes.isEmpty ? null : subtypes.first);
      _selectedInstrument = selectedInstrument;
      _loading = false;
    });
  }

  Future<void> _onTypeChanged(String? type) async {
    setState(() {
      _selectedType = type;
    });
  }

  Future<void> _onInstrumentChanged(String? instrument) async {
    setState(() {
      _selectedInstrument = instrument;
      _selectedSubtype = null;
      _subtypes = const [];
    });
    if (instrument == null) return;
    final subtypes = await _repo.getPartiturasSubtypesByInstrument(instrument);
    if (!subtypes.contains(_otherSubtype)) {
      subtypes.add(_otherSubtype);
    }
    if (!mounted) return;
    setState(() {
      _subtypes = subtypes;
      _selectedSubtype = subtypes.isEmpty ? null : subtypes.first;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedSubtype == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar tipo y subtipo para guardar.'),
        ),
      );
      return;
    }
    final typeForSave = _selectedType!;
    final subtypeForSave = _selectedSubtype!;
    setState(() => _saving = true);
    try {
      final hasScoreData = _selectedInstrument != null ||
          _scorePdfCtrl.text.trim().isNotEmpty ||
          _scoreImageCtrl.text.trim().isNotEmpty ||
          _tabPdfCtrl.text.trim().isNotEmpty ||
          _tabImageCtrl.text.trim().isNotEmpty;
      final scores = <Score>[];
      if (hasScoreData && _selectedInstrument != null) {
        scores.add(
          Score(
            instrument: _selectedInstrument!,
            scorePdfPath: _emptyToNull(_scorePdfCtrl.text),
            scoreImagePath: _emptyToNull(_scoreImageCtrl.text),
            tabPdfPath: _emptyToNull(_tabPdfCtrl.text),
            tabImagePath: _emptyToNull(_tabImageCtrl.text),
          ),
        );
      }

      final song = Song(
        remoteId: widget.initialSong?.remoteId,
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        type: typeForSave,
        subtype: subtypeForSave,
        lyricsText: _emptyToNull(_lyricsCtrl.text),
        lyricsPdfPath: _emptyToNull(_lyricsPdfCtrl.text),
        lyricsImagePath: _emptyToNull(_lyricsImageCtrl.text),
        scores: scores,
      );
      if (widget.initialSong != null) {
        await _repo.updateSong(song);
      } else {
        await _repo.createSong(song);
      }
      await _repo.syncSongsCacheFromRemote();
      await _repo.syncCoplasCacheFromRemote();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialSong != null
                ? 'Canción actualizada correctamente.'
                : 'Canción creada correctamente.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadToController(
    TextEditingController controller, {
    required String folder,
    required List<String> allowedExtensions,
    required String successLabel,
  }) async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final url = await _uploadService.pickAndUpload(
        folder: folder,
        allowedExtensions: allowedExtensions,
      );
      if (!mounted || url == null) return;
      setState(() => controller.text = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$successLabel subido correctamente.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo subir archivo: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialSong != null;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Canción' : 'Alta de Canción')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Título obligatorio' : null,
            ),
            TextFormField(
              controller: _authorCtrl,
              decoration: const InputDecoration(labelText: 'Autor'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipo *'),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: _onTypeChanged,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedInstrument,
              decoration: const InputDecoration(labelText: 'Instrumento'),
              items: _instruments
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: _onInstrumentChanged,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubtype,
              decoration: const InputDecoration(
                labelText: 'Subtipo de Partituras *',
              ),
              items: _subtypes
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubtype = v),
            ),
            const SizedBox(height: 16),
            Text('Letra',
                style: Theme.of(context).textTheme.titleSmall),
            TextFormField(
              controller: _lyricsCtrl,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Letra (texto)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lyricsPdfCtrl,
              decoration: const InputDecoration(
                labelText: 'URL PDF de letra',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _uploadToController(
                          _lyricsPdfCtrl,
                          folder: 'lyrics/pdf',
                          allowedExtensions: const ['pdf'],
                          successLabel: 'PDF de letra',
                        ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar PDF de letra'),
              ),
            ),
            TextFormField(
              controller: _lyricsImageCtrl,
              decoration: const InputDecoration(
                labelText: 'URL imagen de letra',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _uploadToController(
                          _lyricsImageCtrl,
                          folder: 'lyrics/image',
                          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                          successLabel: 'Imagen de letra',
                        ),
                icon: const Icon(Icons.upload),
                label: const Text('Seleccionar imagen de letra'),
              ),
            ),
            const Divider(height: 32),
            Text('Partitura y tablatura (opcional)',
                style: Theme.of(context).textTheme.titleSmall),
            TextFormField(
              controller: _scorePdfCtrl,
              decoration: const InputDecoration(
                labelText: 'URL PDF de partitura',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _uploadToController(
                          _scorePdfCtrl,
                          folder: 'scores/pdf',
                          allowedExtensions: const ['pdf'],
                          successLabel: 'PDF de partitura',
                        ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar PDF de partitura'),
              ),
            ),
            TextFormField(
              controller: _scoreImageCtrl,
              decoration: const InputDecoration(
                labelText: 'URL imagen de partitura',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _uploadToController(
                          _scoreImageCtrl,
                          folder: 'scores/image',
                          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                          successLabel: 'Imagen de partitura',
                        ),
                icon: const Icon(Icons.upload),
                label: const Text('Seleccionar imagen de partitura'),
              ),
            ),
            TextFormField(
              controller: _tabPdfCtrl,
              decoration: const InputDecoration(
                labelText: 'URL PDF de tablatura',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _uploadToController(
                          _tabPdfCtrl,
                          folder: 'tabs/pdf',
                          allowedExtensions: const ['pdf'],
                          successLabel: 'PDF de tablatura',
                        ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar PDF de tablatura'),
              ),
            ),
            TextFormField(
              controller: _tabImageCtrl,
              decoration: const InputDecoration(
                labelText: 'URL imagen de tablatura',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _uploadToController(
                          _tabImageCtrl,
                          folder: 'tabs/image',
                          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                          successLabel: 'Imagen de tablatura',
                        ),
                icon: const Icon(Icons.upload),
                label: const Text('Seleccionar imagen de tablatura'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: (_saving || _uploading) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isEdit ? 'Guardar cambios' : 'Guardar canción'),
            ),
          ],
        ),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
