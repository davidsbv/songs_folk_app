import 'package:flutter/material.dart';

import '../models/copla.dart';
import '../repositories/songs_repository.dart';

class AdminCreateCoplaScreen extends StatefulWidget {
  final Copla? initialCopla;
  final SongsRepository? repository;

  const AdminCreateCoplaScreen({
    super.key,
    this.initialCopla,
    this.repository,
  });

  @override
  State<AdminCreateCoplaScreen> createState() => _AdminCreateCoplaScreenState();
}

class _AdminCreateCoplaScreenState extends State<AdminCreateCoplaScreen> {
  late final SongsRepository _repo;
  final _formKey = GlobalKey<FormState>();
  final _authorCtrl = TextEditingController();
  final _textCtrl = TextEditingController();

  List<String> _types = const [];
  List<String> _subtypes = const [];
  String? _selectedType;
  String? _selectedSubtype;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? SongsRepository();
    final initial = widget.initialCopla;
    if (initial != null) {
      _authorCtrl.text = initial.author ?? '';
      _textCtrl.text = initial.text;
    }
    _loadCatalogs();
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final types = await _repo.getCoplaTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _selectedType = widget.initialCopla?.type;
        _subtypes = const <String>[];
        _selectedSubtype = widget.initialCopla?.subtype;
        _loading = false;
      });
      if (widget.initialCopla != null && widget.initialCopla!.type.isNotEmpty) {
        await _onTypeChanged(widget.initialCopla!.type, keepSubtype: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  Future<void> _onTypeChanged(String? type, {bool keepSubtype = false}) async {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      _selectedSubtype = null;
      _subtypes = const [];
    });
    final subtypes = await _repo.getCoplaSubtypesByType(type);
    if (!mounted) return;
    setState(() {
      _subtypes = subtypes;
      if (!keepSubtype || !_subtypes.contains(_selectedSubtype)) {
        _selectedSubtype = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedSubtype == null) return;
    setState(() => _saving = true);
    try {
      if (widget.initialCopla != null) {
        await _repo.updateCopla(
          Copla(
            remoteId: widget.initialCopla?.remoteId,
            type: _selectedType!,
            subtype: _selectedSubtype!,
            text: _textCtrl.text.trim(),
            author: _emptyToNull(_authorCtrl.text),
          ),
        );
      } else {
        await _repo.createCopla(
          Copla(
            type: _selectedType!,
            subtype: _selectedSubtype!,
            text: _textCtrl.text.trim(),
            author: _emptyToNull(_authorCtrl.text),
          ),
        );
      }
      await _repo.syncCoplasCacheFromRemote();
      await _repo.syncSongsCacheFromRemote();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialCopla != null
                ? 'Copla actualizada correctamente.'
                : 'Copla creada correctamente.',
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialCopla != null;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alta de Copla')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No se pudieron cargar tipos/subtipos:\n$_loadError',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadCatalogs,
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
      appBar: AppBar(title: Text(isEdit ? 'Editar Copla' : 'Alta de Copla')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('copla-type-${_selectedType ?? ''}'),
              initialValue: _selectedType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo *'),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: _onTypeChanged,
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('copla-subtype-${_selectedSubtype ?? ''}-${_subtypes.length}'),
              initialValue: _selectedSubtype,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Subtipo *'),
              items: _subtypes
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubtype = v),
            ),
            TextFormField(
              controller: _authorCtrl,
              decoration: const InputDecoration(labelText: 'Autor (opcional)'),
            ),
            TextFormField(
              controller: _textCtrl,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Texto de la copla *',
                hintText: 'Escribe el cuarteto o copla completa',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El texto de la copla es obligatorio'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isEdit ? 'Guardar cambios' : 'Guardar copla'),
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
