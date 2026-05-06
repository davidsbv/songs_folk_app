import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:songs_folk_app/models/event.dart';
import 'package:songs_folk_app/repositories/events_repository.dart';
import 'package:songs_folk_app/screens/calendario_screen.dart';

class _FakeEventsRepository extends EventsRepository {
  _FakeEventsRepository() : super(isSupabaseConfigured: false);

  @override
  Future<List<Event>> getEventsForMonth(DateTime month) async => [
    Event(
      title: 'Evento folk',
      startAt: DateTime(month.year, month.month, 10, 18),
      endAt: DateTime(month.year, month.month, 10, 20),
    ),
  ];
}

void main() {
  testWidgets('carga inicial y muestra eventos del mes', (tester) async {
    await initializeDateFormatting('es_ES');
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es', 'ES'),
        supportedLocales: const [Locale('es', 'ES')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CalendarioScreen(eventsRepository: _FakeEventsRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Eventos del mes'), findsOneWidget);
    expect(find.text('Evento folk'), findsOneWidget);
  });
}
