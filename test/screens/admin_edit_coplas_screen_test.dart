import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/copla.dart';
import 'package:songs_folk_app/repositories/songs_repository.dart';
import 'package:songs_folk_app/screens/admin_edit_coplas_screen.dart';

class _TestNavObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

class _FakeCoplasAdminRepo extends SongsRepository {
  _FakeCoplasAdminRepo() : super(isSupabaseConfigured: false);

  bool deleteCalled = false;
  String? deletedId;
  final List<Copla> _coplas = [
    Copla(
      remoteId: 'copla-1',
      type: 'JOTA',
      subtype: 'MAYO',
      text: 'Texto principal',
      author: 'Autor',
    ),
    Copla(
      type: 'JOTA',
      subtype: 'RONDA',
      text: 'Sin id',
    ),
  ];

  @override
  Future<List<Copla>> getAdminCoplas() async => List<Copla>.from(_coplas);

  @override
  Future<void> deleteCopla(String remoteId) async {
    deleteCalled = true;
    deletedId = remoteId;
    _coplas.removeWhere((copla) => copla.remoteId == remoteId);
  }

  @override
  Future<int> syncCoplasCacheFromRemote() async => 0;
}

void main() {
  testWidgets('tocar una copla dispara navegación de edición', (tester) async {
    final repo = _FakeCoplasAdminRepo();
    final observer = _TestNavObserver();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminEditCoplasScreen(repository: repo),
        navigatorObservers: [observer],
      ),
    );
    await tester.pumpAndSettle();
    final beforeTap = observer.pushCount;

    await tester.tap(find.text('JOTA · MAYO'));
    await tester.pump();
    expect(observer.pushCount, greaterThan(beforeTap));
  });

  testWidgets('muestra aviso al borrar copla sin id remoto', (tester) async {
    final repo = _FakeCoplasAdminRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEditCoplasScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('JOTA · RONDA'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Eliminar copla')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No se puede eliminar: copla sin id remoto.'),
      findsOneWidget,
    );
    expect(repo.deleteCalled, isFalse);
  });

  testWidgets('confirma borrado y aplica eliminación optimista', (tester) async {
    final repo = _FakeCoplasAdminRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEditCoplasScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('JOTA · MAYO'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Eliminar copla')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pump();

    expect(find.text('JOTA · MAYO'), findsNothing);
    expect(find.text('Copla preparada para eliminar'), findsOneWidget);
  });
}
