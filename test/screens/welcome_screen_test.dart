import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/app_branding.dart';
import 'package:songs_folk_app/models/app_appearance.dart';
import 'package:songs_folk_app/screens/welcome_screen.dart';

void main() {
  Future<void> pumpWelcome(WidgetTester tester) async {
    await tester.pumpWidget(
      AppBranding(
        appearance: AppAppearance.fallback,
        themeMode: ThemeMode.system,
        refreshAppearance: () async {},
        setUserThemeMode: (_) async {},
        child: const MaterialApp(home: WelcomeScreen()),
      ),
    );
  }

  testWidgets('muestra los módulos principales', (tester) async {
    await pumpWelcome(tester);
    expect(find.text('PARTITURAS'), findsOneWidget);
    expect(find.text('COPLERO TRADICIONAL'), findsOneWidget);
    expect(find.text('CALENDARIO DE EVENTOS'), findsOneWidget);
  });

  testWidgets('navega a partituras al pulsar el tile', (tester) async {
    await pumpWelcome(tester);
    await tester.tap(find.text('PARTITURAS'));
    await tester.pumpAndSettle();
    expect(find.text('Partituras'), findsOneWidget);
  });
}
