import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/score.dart';
import 'package:songs_folk_app/models/song.dart';
import 'package:songs_folk_app/repositories/partituras_repository.dart';
import 'package:songs_folk_app/screens/partituras_screen.dart';
import 'package:songs_folk_app/services/admin_auth_service.dart';
import 'package:songs_folk_app/services/admin_credentials_store.dart';

class _RepoOk implements PartiturasRepository {
  @override
  Future<List<Song>> getSongs() async => [
    Song(
      title: 'Jota de prueba',
      author: 'Ana',
      type: 'JOTA',
      subtype: 'TRADICIONAL',
      scores: const [Score(instrument: 'CUERDA')],
    ),
    Song(
      title: 'Pasacalles',
      author: 'Pepe',
      type: 'OTRO',
      subtype: 'MODERNO',
      scores: const [Score(instrument: 'DULZAINA')],
    ),
  ];

  @override
  Future<List<String>> getSongTypes() async => ['JOTA', 'OTRO'];
  @override
  Future<List<String>> getInstruments() async => ['CUERDA', 'DULZAINA'];
  @override
  Future<DateTime?> getSongsLastSyncAt() async => null;
  @override
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName) async =>
      instrumentName == 'CUERDA' ? ['TRADICIONAL'] : ['MODERNO'];
  @override
  Future<int> syncSongsCacheFromRemote() async => 2;
}

class _RepoEmpty extends _RepoOk {
  @override
  Future<List<Song>> getSongs() async => [];
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
  Future<void> _pump(WidgetTester tester, PartiturasRepository repo) async {
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

  testWidgets('filtra por instrumento y por tipo', (tester) async {
    await _pump(tester, _RepoOk());
    expect(find.text('Jota de prueba'), findsOneWidget);
    expect(find.text('Pasacalles'), findsOneWidget);

    await tester.tap(find.text('CUERDA'));
    await tester.pumpAndSettle();
    expect(find.text('Jota de prueba'), findsOneWidget);
    expect(find.text('Pasacalles'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OTRO').last);
    await tester.pumpAndSettle();
    expect(find.text('Jota de prueba'), findsNothing);
  });

  testWidgets('permite búsqueda por título y autor', (tester) async {
    await _pump(tester, _RepoOk());
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ana');
    await tester.pumpAndSettle();
    expect(find.text('Jota de prueba'), findsOneWidget);
    expect(find.text('Pasacalles'), findsNothing);
  });

  testWidgets('renderiza lista vacía sin romper pantalla', (tester) async {
    await _pump(tester, _RepoEmpty());
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
