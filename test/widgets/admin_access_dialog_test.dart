import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/widgets/admin_access_dialog.dart';

void main() {
  testWidgets('muestra valores iniciales y checkbox marcado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminAccessDialog(
            initialEmail: 'admin@test.com',
            initialPassword: 'secreto',
            initialRememberPassword: true,
          ),
        ),
      ),
    );

    expect(find.text('admin@test.com'), findsOneWidget);
    expect(find.text('secreto'), findsOneWidget);
    expect(find.text('Recordar contraseña'), findsOneWidget);

    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);
  });

  testWidgets('devuelve resultado al pulsar Entrar', (tester) async {
    AdminAccessDialogResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<AdminAccessDialogResult>(
                  context: context,
                  builder: (_) => const AdminAccessDialog(
                    initialEmail: '',
                    initialPassword: '',
                    initialRememberPassword: false,
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'nuevo@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'clave123');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.email, 'nuevo@test.com');
    expect(result!.password, 'clave123');
    expect(result!.rememberPassword, isTrue);
  });
}
