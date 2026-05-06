import 'package:flutter/material.dart';

import '../models/copla.dart';
import '../repositories/songs_repository.dart';
import 'admin_create_copla_screen.dart';

class AdminEditCoplasScreen extends StatefulWidget {
  const AdminEditCoplasScreen({super.key, SongsRepository? repository})
    : _repository = repository;

  final SongsRepository? _repository;

  @override
  State<AdminEditCoplasScreen> createState() => _AdminEditCoplasScreenState();
}

class _AdminEditCoplasScreenState extends State<AdminEditCoplasScreen> {
  late final SongsRepository _repo;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Copla> _coplas = const [];
  bool _loading = true;
  String _search = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget._repository ?? SongsRepository();
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
      final coplas = await _repo.getAdminCoplas();
      if (!mounted) return;
      setState(() {
        _coplas = coplas;
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

  List<Copla> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _coplas;
    return _coplas.where((c) {
      return c.type.toLowerCase().contains(q) ||
          c.subtype.toLowerCase().contains(q) ||
          (c.author ?? '').toLowerCase().contains(q) ||
          c.text.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Coplas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar por tipo, subtipo, autor o texto',
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
              Text('No se pudieron cargar coplas:\n$_error', textAlign: TextAlign.center),
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
      return const Center(child: Text('No hay coplas para editar.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final copla = list[index];
          return ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text('${copla.type} · ${copla.subtype}'),
            subtitle: Text(
              '${copla.author ?? 'Sin autor'}\n${copla.text}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Eliminar copla',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(copla),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminCreateCoplaScreen(initialCopla: copla, repository: _repo),
                ),
              );
              await _load();
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Copla copla) async {
    final id = copla.remoteId;
    if (id == null || id.isEmpty) {
      await _showUserMessage('No se puede eliminar: copla sin id remoto.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar copla'),
        content: const Text('Se marcará como eliminada y dejará de mostrarse en Coplero.'),
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
    final previous = List<Copla>.from(_coplas);
    setState(() {
      _coplas = _coplas.where((c) => c.remoteId != id).toList();
    });
    try {
      await _repo.deleteCopla(id);
      await _repo.syncCoplasCacheFromRemote();
      if (!mounted) return;
      await _showUserMessage('Copla eliminada.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _coplas = previous);
      await _showUserMessage('No se pudo eliminar: $e');
    }
  }

  Future<void> _showUserMessage(String message) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
