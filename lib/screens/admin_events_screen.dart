import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../models/event.dart';
import '../repositories/events_repository.dart';

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminEventsView();
  }
}

class _AdminEventsView extends StatefulWidget {
  const _AdminEventsView();

  @override
  State<_AdminEventsView> createState() => _AdminEventsViewState();
}

class _AdminEventsViewState extends State<_AdminEventsView> {
  final EventsRepository _repo = EventsRepository();
  List<Event> _events = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _repo.getAdminEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
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

  Future<void> _openEditor({Event? initialEvent}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminEventFormScreen(initialEvent: initialEvent),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _confirmDelete(Event event) async {
    final id = event.remoteId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede eliminar: evento sin id remoto.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('El evento se ocultara del calendario publico.'),
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
    try {
      await _repo.deleteEvent(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion de eventos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No se pudieron cargar eventos:\n$_error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _events.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text('No hay eventos creados.'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return ListTile(
                              leading: const Icon(Icons.event),
                              title: Text(event.title),
                              subtitle: Text(_eventSummary(event)),
                              trailing: IconButton(
                                tooltip: 'Eliminar evento',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(event),
                              ),
                              onTap: () => _openEditor(initialEvent: event),
                            );
                          },
                        ),
                ),
    );
  }

  String _eventSummary(Event event) {
    final day = '${_twoDigits(event.startAt.day)}/${_twoDigits(event.startAt.month)}';
    if (event.allDay) {
      return '$day · Todo el dia'
          '${event.location == null || event.location!.isEmpty ? '' : '\n${event.location}'}';
    }
    final startHour = '${_twoDigits(event.startAt.hour)}:${_twoDigits(event.startAt.minute)}';
    final endHour = '${_twoDigits(event.endAt.hour)}:${_twoDigits(event.endAt.minute)}';
    final hasEndTime = !event.startAt.isAtSameMomentAs(event.endAt);
    return '$day · ${hasEndTime ? '$startHour - $endHour' : startHour}'
        '${event.location == null || event.location!.isEmpty ? '' : '\n${event.location}'}';
  }

  String _twoDigits(int value) => value < 10 ? '0$value' : '$value';
}

class _AdminEventFormScreen extends StatefulWidget {
  final Event? initialEvent;

  const _AdminEventFormScreen({this.initialEvent});

  @override
  State<_AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<_AdminEventFormScreen> {
  final EventsRepository _repo = EventsRepository();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _allDay = false;
  bool _hasEndTime = true;
  bool _saving = false;
  late DateTime _startAt;
  late DateTime _endAt;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEvent;
    if (initial != null) {
      _titleCtrl.text = initial.title;
      _descriptionCtrl.text = initial.description ?? '';
      _locationCtrl.text = initial.location ?? '';
      _allDay = initial.allDay;
      _startAt = initial.startAt;
      _endAt = initial.endAt;
      _hasEndTime = _allDay ? true : !initial.startAt.isAtSameMomentAs(initial.endAt);
    } else {
      final now = DateTime.now();
      _startAt = DateTime(now.year, now.month, now.day, now.hour, 0);
      _endAt = _startAt.add(const Duration(hours: 2));
      _hasEndTime = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = isStart ? _startAt : _endAt;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      locale: const Locale('es', 'ES'),
    );
    if (pickedDate == null || !mounted) return;

    TimeOfDay pickedTime = TimeOfDay(hour: current.hour, minute: current.minute);
    if (!_allDay) {
      final maybeTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      );
      if (maybeTime == null || !mounted) return;
      pickedTime = maybeTime;
    }

    final next = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      _allDay ? 0 : pickedTime.hour,
      _allDay ? 0 : pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startAt = next;
        if (!_allDay && !_hasEndTime) {
          _endAt = _startAt;
        } else if (_endAt.isBefore(_startAt)) {
          _endAt = _allDay
              ? DateTime(_startAt.year, _startAt.month, _startAt.day, 23, 59)
              : _startAt.add(const Duration(hours: 1));
        }
      } else {
        _endAt = next;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_allDay || _hasEndTime) && _endAt.isBefore(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha/hora de fin no puede ser anterior al inicio.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final event = Event(
        remoteId: widget.initialEvent?.remoteId,
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        startAt: _allDay
            ? DateTime(_startAt.year, _startAt.month, _startAt.day, 0, 0)
            : _startAt,
        endAt: _allDay
            ? DateTime(_endAt.year, _endAt.month, _endAt.day, 23, 59)
            : (_hasEndTime ? _endAt : _startAt),
        allDay: _allDay,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      );
      if (widget.initialEvent == null) {
        await _repo.createEvent(event);
      } else {
        await _repo.updateEvent(event);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialEvent == null
                ? 'Evento creado correctamente.'
                : 'Evento actualizado correctamente.',
          ),
        ),
      );
      Navigator.pop(context, true);
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
    final isEdit = widget.initialEvent != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar evento' : 'Nuevo evento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titulo *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Titulo obligatorio' : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Evento de todo el dia'),
              value: _allDay,
              onChanged: (value) => setState(() {
                _allDay = value;
                if (_allDay) {
                  _hasEndTime = true;
                } else if (!_hasEndTime) {
                  _endAt = _startAt;
                }
              }),
            ),
            if (!_allDay)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Incluir hora de fin'),
                value: _hasEndTime,
                onChanged: (value) => setState(() {
                  _hasEndTime = value;
                  if (!_hasEndTime) {
                    _endAt = _startAt;
                  } else if (_endAt.isAtSameMomentAs(_startAt)) {
                    _endAt = _startAt.add(const Duration(hours: 1));
                  }
                }),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Inicio'),
              subtitle: Text(_dateTimeLabel(_startAt, allDay: _allDay)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pickDateTime(isStart: true),
            ),
            if (_allDay || _hasEndTime)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available),
                title: const Text('Fin'),
                subtitle: Text(_dateTimeLabel(_endAt, allDay: _allDay)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () => _pickDateTime(isStart: false),
              ),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Ubicacion'),
            ),
            TextFormField(
              controller: _descriptionCtrl,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Descripcion'),
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
              label: Text(isEdit ? 'Guardar cambios' : 'Crear evento'),
            ),
          ],
        ),
      ),
    );
  }

  String _dateTimeLabel(DateTime dt, {required bool allDay}) {
    final day = '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year}';
    if (allDay) return day;
    return '$day ${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
  }

  String _twoDigits(int value) => value < 10 ? '0$value' : '$value';
}
