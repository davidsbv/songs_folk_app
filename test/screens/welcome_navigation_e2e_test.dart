import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_folk_app/app_branding.dart';
import 'package:songs_folk_app/models/app_appearance.dart';
import 'package:songs_folk_app/screens/welcome_screen.dart';

void main() {
  Future<void> _pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await initializeDateFormatting('es_ES');
    await tester.pumpWidget(
      AppBranding(
        appearance: AppAppearance.fallback,
        themeMode: ThemeMode.system,
        refreshAppearance: () async {},
        setUserThemeMode: (_) async {},
        child: MaterialApp(
          locale: const Locale('es', 'ES'),
          supportedLocales: const [Locale('es', 'ES')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const WelcomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('navega a Coplero y vuelve al menú principal', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('COPLERO TRADICIONAL'));
    await tester.pumpAndSettle();
    expect(find.text('Coplero Tradicional'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Cancionero Folk'), findsOneWidget);
  });

  testWidgets('navega a Calendario y vuelve al menú principal', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('CALENDARIO DE EVENTOS'));
    await tester.pumpAndSettle();
    expect(find.text('Calendario de eventos'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Cancionero Folk'), findsOneWidget);
  });
}
