import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/copla.dart';
import 'package:songs_folk_app/repositories/songs_repository.dart';
import 'package:songs_folk_app/screens/coplero_list_screen.dart';

class _FakeSongsRepository extends SongsRepository {
  _FakeSongsRepository({
    this.throwOnLoad = false,
    this.throwOnSync = false,
  }) : super(isSupabaseConfigured: false);

  final bool throwOnLoad;
  final bool throwOnSync;

  @override
  Future<List<Copla>> getCoplasByType(String typeName, {bool forceRefresh = false}) async {
    if (throwOnLoad) throw Exception('fallo carga');
    return const [
      Copla(type: 'JOTA', subtype: 'A', text: 'Texto 1'),
      Copla(type: 'JOTA', subtype: 'B', text: 'Texto 2'),
    ];
  }

  @override
  Future<List<String>> getCoplaSubtypesByType(String typeName) async => ['A', 'B'];

  @override
  Future<DateTime?> getCoplasLastSyncAt() async => null;

  @override
  Future<int> syncCoplasCacheFromRemote() async {
    if (throwOnSync) throw Exception('sync error');
    return 2;
  }
}

void main() {
  testWidgets('carga inicial del coplero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CopleroListScreen(
          selectedType: 'JOTA',
          repository: _FakeSongsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Texto 1'), findsOneWidget);
    expect(find.text('Texto 2'), findsOneWidget);
  });

  testWidgets('muestra estado de error y botón reintentar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CopleroListScreen(
          selectedType: 'JOTA',
          repository: _FakeSongsRepository(throwOnLoad: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Error al cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('muestra snackbar si falla la sincronización', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CopleroListScreen(
          selectedType: 'JOTA',
          repository: _FakeSongsRepository(throwOnSync: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actualizar datos offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo sincronizar'), findsOneWidget);
  });
}
