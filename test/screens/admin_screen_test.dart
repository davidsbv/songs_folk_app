import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/screens/admin_screen.dart';

void main() {
  testWidgets('panel admin permite scroll en ventana pequeña', (tester) async {
    tester.view.physicalSize = const Size(800, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final scrollFinder = find.byType(Scrollable);
    expect(scrollFinder, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('APARIENCIA GLOBAL'),
      200,
      scrollable: scrollFinder,
    );
    await tester.pumpAndSettle();

    expect(find.text('APARIENCIA GLOBAL'), findsOneWidget);
  });
}
