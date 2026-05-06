import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/event.dart';
import 'package:songs_folk_app/repositories/events_repository.dart';
import 'package:songs_folk_app/screens/admin_events_screen.dart';

class _FakeEventsRepo extends EventsRepository {
  _FakeEventsRepo() : super(isSupabaseConfigured: false);

  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  String? deletedId;
  Event? lastUpdatedEvent;
  final List<Event> _events = [
    Event(
      remoteId: 'evt-1',
      title: 'Evento inicial',
      startAt: DateTime(2026, 5, 10, 20, 0),
      endAt: DateTime(2026, 5, 10, 22, 0),
      location: 'Plaza',
    ),
    Event(
      title: 'Sin id remoto',
      startAt: DateTime(2026, 5, 12, 18, 0),
      endAt: DateTime(2026, 5, 12, 19, 0),
    ),
  ];

  @override
  Future<List<Event>> getAdminEvents() async => List<Event>.from(_events);

  @override
  Future<void> createEvent(Event event) async {
    createCalled = true;
    _events.add(event);
  }

  @override
  Future<void> updateEvent(Event event) async {
    updateCalled = true;
    lastUpdatedEvent = event;
    final index = _events.indexWhere((item) => item.remoteId == event.remoteId);
    if (index != -1) {
      _events[index] = event;
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    deleteCalled = true;
    deletedId = eventId;
    _events.removeWhere((item) => item.remoteId == eventId);
  }
}

void main() {
  testWidgets('valida título obligatorio al crear evento', (tester) async {
    final repo = _FakeEventsRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEventsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo evento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear evento'));
    await tester.pumpAndSettle();

    expect(find.text('Titulo obligatorio'), findsOneWidget);
    expect(repo.createCalled, isFalse);
  });

  testWidgets('edita un evento existente desde el listado', (tester) async {
    final repo = _FakeEventsRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEventsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Evento inicial'));
    await tester.pumpAndSettle();

    expect(find.text('Editar evento'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Titulo *'),
      'Evento actualizado',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repo.updateCalled, isTrue);
    expect(repo.lastUpdatedEvent?.title, 'Evento actualizado');
    expect(find.text('Evento actualizado'), findsOneWidget);
  });

  testWidgets('avisa si se intenta borrar evento sin id remoto', (tester) async {
    final repo = _FakeEventsRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEventsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('Sin id remoto'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: row, matching: find.byIcon(Icons.delete_outline)));
    await tester.pumpAndSettle();

    expect(
      find.text('No se puede eliminar: evento sin id remoto.'),
      findsOneWidget,
    );
    expect(repo.deleteCalled, isFalse);
  });

  testWidgets('elimina evento con id remoto tras confirmar', (tester) async {
    final repo = _FakeEventsRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEventsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('Evento inicial'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: row, matching: find.byIcon(Icons.delete_outline)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(repo.deleteCalled, isTrue);
    expect(repo.deletedId, 'evt-1');
    expect(find.text('Evento inicial'), findsNothing);
  });
}
