import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/song.dart';
import 'package:songs_folk_app/repositories/partituras_repository.dart';
import 'package:songs_folk_app/screens/partituras_screen.dart';
import 'package:songs_folk_app/services/admin_auth_service.dart';
import 'package:songs_folk_app/services/admin_credentials_store.dart';

class _FailingSyncRepo implements PartiturasRepository {
  @override
  Future<List<Song>> getSongs() async => const [];
  @override
  Future<List<String>> getSongTypes() async => const [];
  @override
  Future<List<String>> getInstruments() async => const [];
  @override
  Future<DateTime?> getSongsLastSyncAt() async => null;
  @override
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName) async =>
      const [];
  @override
  Future<int> syncSongsCacheFromRemote() async => throw Exception('timeout');
}

class _RetryableLoadRepo implements PartiturasRepository {
  int loads = 0;
  @override
  Future<List<Song>> getSongs() async {
    loads++;
    if (loads == 1) throw Exception('dns');
    return const [Song(title: 'Recuperada', author: 'Autor', type: 'JOTA', subtype: 'X')];
  }

  @override
  Future<List<String>> getSongTypes() async => ['JOTA'];
  @override
  Future<List<String>> getInstruments() async => const [];
  @override
  Future<DateTime?> getSongsLastSyncAt() async => null;
  @override
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName) async =>
      const [];
  @override
  Future<int> syncSongsCacheFromRemote() async => 0;
}

class _NoopAuth implements AdminAuthGateway {
  @override
  Future<void> signInAdmin({required String email, required String password}) async {}
}

class _NoopStore implements AdminCredentialsStoreBase {
  @override
  Future<AdminCredentials> load() async => const AdminCredentials();
  @override
  Future<void> save({
    required bool rememberPassword,
    required String email,
    required String password,
  }) async {}
}

void main() {
  Future<void> pump(WidgetTester tester, PartiturasRepository repo) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PartiturasScreen(
          repository: repo,
          adminAuth: _NoopAuth(),
          adminCredentialsStore: _NoopStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra snackbar cuando falla sync offline', (tester) async {
    await pump(tester, _FailingSyncRepo());
    await tester.tap(find.byTooltip('Actualizar datos offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo sincronizar'), findsOneWidget);
  });

  testWidgets('permite reintento tras error de carga', (tester) async {
    final repo = _RetryableLoadRepo();
    await pump(tester, repo);
    expect(find.text('Error al cargar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperada'), findsOneWidget);
  });
}
