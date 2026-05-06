import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/event.dart';

/// Repositorio de eventos: usa Supabase si está configurado y
/// recurre a datos de ejemplo cuando no hay backend disponible.
class EventsRepository {
  EventsRepository({
    SupabaseClient? client,
    bool? isSupabaseConfigured,
  }) : _clientOverride = client,
       _isSupabaseConfiguredOverride = isSupabaseConfigured;

  final SupabaseClient? _clientOverride;
  final bool? _isSupabaseConfiguredOverride;

  SupabaseClient? get _client =>
      _clientOverride ??
      ((_isSupabaseConfiguredOverride ?? isSupabaseConfigured)
          ? Supabase.instance.client
          : null);

  Future<List<Event>> getEventsForMonth(DateTime month) async {
    final monthStart = DateTime(month.year, month.month, 1);
    final nextMonthStart = DateTime(month.year, month.month + 1, 1);

    final client = _client;
    if (client == null) {
      return _sampleEventsForMonth(monthStart);
    }

    try {
      final response = await client
          .from('events')
          .select(
            'id, title, description, start_at, end_at, all_day, location, updated_at, deleted_at',
          )
          .isFilter('deleted_at', null)
          .lt('start_at', nextMonthStart.toIso8601String())
          .gte('end_at', monthStart.toIso8601String())
          .order('start_at', ascending: true);

      final list = response as List<dynamic>? ?? [];
      return list
          .map((row) => _eventFromRemoteRow(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _sampleEventsForMonth(monthStart);
    }
  }

  Future<List<Event>> getAdminEvents() async {
    final client = _client;
    if (client == null) {
      final now = DateTime.now();
      return _sampleEventsForMonth(DateTime(now.year, now.month, 1));
    }

    final response = await client
        .from('events')
        .select(
          'id, title, description, start_at, end_at, all_day, location, updated_at, deleted_at',
        )
        .isFilter('deleted_at', null)
        .order('start_at', ascending: true);
    final list = response as List<dynamic>? ?? [];
    return list
        .map((row) => _eventFromRemoteRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEvent(Event event) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no esta configurado en esta ejecucion.');
    }
    await client.from('events').insert({
      'title': event.title.trim(),
      'description': _emptyToNull(event.description),
      'start_at': event.startAt.toUtc().toIso8601String(),
      'end_at': event.endAt.toUtc().toIso8601String(),
      'all_day': event.allDay,
      'location': _emptyToNull(event.location),
    });
  }

  Future<void> updateEvent(Event event) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no esta configurado en esta ejecucion.');
    }
    final eventId = event.remoteId;
    if (eventId == null || eventId.isEmpty) {
      throw Exception('El evento no tiene id remoto para poder editarse.');
    }
    await client
        .from('events')
        .update({
          'title': event.title.trim(),
          'description': _emptyToNull(event.description),
          'start_at': event.startAt.toUtc().toIso8601String(),
          'end_at': event.endAt.toUtc().toIso8601String(),
          'all_day': event.allDay,
          'location': _emptyToNull(event.location),
        })
        .eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no esta configurado en esta ejecucion.');
    }
    await client
        .from('events')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', eventId);
  }

  Event _eventFromRemoteRow(Map<String, dynamic> row) {
    final startAt =
        DateTime.tryParse(row['start_at'] as String? ?? '') ?? DateTime.now();
    final endAt =
        DateTime.tryParse(row['end_at'] as String? ?? '') ?? startAt;

    return Event(
      remoteId: row['id'] as String?,
      title: (row['title'] as String? ?? '').trim(),
      description: (row['description'] as String?)?.trim(),
      startAt: startAt.toLocal(),
      endAt: endAt.toLocal(),
      allDay: row['all_day'] as bool? ?? false,
      location: (row['location'] as String?)?.trim(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  List<Event> _sampleEventsForMonth(DateTime monthStart) {
    final y = monthStart.year;
    final m = monthStart.month;
    return [
      Event(
        title: 'Ensayo general',
        description: 'Repaso de repertorio para fiestas.',
        startAt: DateTime(y, m, 5, 20, 0),
        endAt: DateTime(y, m, 5, 22, 0),
        location: 'Casa de cultura',
      ),
      Event(
        title: 'Pasacalles del pueblo',
        description: 'Salida desde la plaza mayor.',
        startAt: DateTime(y, m, 12, 11, 30),
        endAt: DateTime(y, m, 12, 13, 0),
        location: 'Plaza Mayor',
      ),
      Event(
        title: 'Festival folk',
        description: 'Actuaciones durante todo el fin de semana.',
        startAt: DateTime(y, m, 20, 10, 0),
        endAt: DateTime(y, m, 21, 23, 0),
        location: 'Recinto ferial',
      ),
    ];
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
