import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:songs_folk_app/models/event.dart';
import 'package:songs_folk_app/repositories/events_repository.dart';
import 'package:songs_folk_app/screens/calendario_screen.dart';

class _RetryEventsRepository extends EventsRepository {
  _RetryEventsRepository() : super(isSupabaseConfigured: false);

  @override
  Future<List<Event>> getEventsForMonth(DateTime month) async {
    throw Exception('timeout');
  }
}

void main() {
  testWidgets('muestra estado de error cuando falla la carga', (tester) async {
    await initializeDateFormatting('es_ES');
    final repo = _RetryEventsRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es', 'ES'),
        supportedLocales: const [Locale('es', 'ES')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CalendarioScreen(eventsRepository: repo),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No se pudieron cargar los eventos.'), findsOneWidget);

    expect(find.textContaining('timeout'), findsOneWidget);
  });
}
