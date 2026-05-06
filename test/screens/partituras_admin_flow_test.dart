import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/score.dart';
import 'package:songs_folk_app/models/song.dart';
import 'package:songs_folk_app/repositories/partituras_repository.dart';
import 'package:songs_folk_app/screens/partituras_screen.dart';
import 'package:songs_folk_app/services/admin_auth_service.dart';
import 'package:songs_folk_app/services/admin_credentials_store.dart';

class _FakePartiturasRepository implements PartiturasRepository {
  @override
  Future<List<Song>> getSongs() async => [
    Song(
      title: 'Test Song',
      author: 'Tester',
      type: 'JOTA',
      subtype: 'TRADICIONAL',
      scores: const [Score(instrument: 'CUERDA')],
    ),
  ];

  @override
  Future<List<String>> getSongTypes() async => ['JOTA'];

  @override
  Future<List<String>> getInstruments() async => ['CUERDA'];

  @override
  Future<DateTime?> getSongsLastSyncAt() async => null;

  @override
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName) async =>
      ['TRADICIONAL'];

  @override
  Future<int> syncSongsCacheFromRemote() async => 0;
}

class _FakeAdminAuth implements AdminAuthGateway {
  String? lastEmail;
  String? lastPassword;
  Object? errorToThrow;

  @override
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastEmail = email;
    lastPassword = password;
  }
}

class _FakeAdminCredentialsStore implements AdminCredentialsStoreBase {
  _FakeAdminCredentialsStore(this._initial);

  final AdminCredentials _initial;
  bool saveCalled = false;
  bool? savedRememberPassword;
  String? savedEmail;
  String? savedPassword;

  @override
  Future<AdminCredentials> load() async => _initial;

  @override
  Future<void> save({
    required bool rememberPassword,
    required String email,
    required String password,
  }) async {
    saveCalled = true;
    savedRememberPassword = rememberPassword;
    savedEmail = email;
    savedPassword = password;
  }
}

void main() {
  Future<void> _pumpScreen(
    WidgetTester tester, {
    required _FakePartiturasRepository repo,
    required _FakeAdminAuth auth,
    required _FakeAdminCredentialsStore store,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PartiturasScreen(
          repository: repo,
          adminAuth: auth,
          adminCredentialsStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('flujo admin exitoso guarda credenciales recordadas', (tester) async {
    final repo = _FakePartiturasRepository();
    final auth = _FakeAdminAuth();
    final store = _FakeAdminCredentialsStore(
      const AdminCredentials(
        rememberPassword: true,
        email: 'saved@test.com',
        password: 'saved-pass',
      ),
    );
    await _pumpScreen(tester, repo: repo, auth: auth, store: store);

    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '/admin');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'nuevo@test.com');
    await tester.enterText(find.byType(TextField).at(2), 'clave123');
    final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    if (!(checkbox.value ?? false)) {
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(auth.lastEmail, 'nuevo@test.com');
    expect(auth.lastPassword, 'clave123');
    expect(store.saveCalled, isTrue);
    expect(store.savedRememberPassword, isTrue);
    expect(store.savedEmail, 'nuevo@test.com');
    expect(store.savedPassword, 'clave123');
  });

  testWidgets('muestra snackbar si faltan email o contraseña', (tester) async {
    final repo = _FakePartiturasRepository();
    final auth = _FakeAdminAuth();
    final store = _FakeAdminCredentialsStore(const AdminCredentials());
    await _pumpScreen(tester, repo: repo, auth: auth, store: store);

    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '/admin');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Debes indicar email y contraseña.'), findsOneWidget);
    expect(auth.lastEmail, isNull);
    expect(store.saveCalled, isFalse);
  });

  testWidgets('muestra diálogo de acceso denegado cuando falla login', (tester) async {
    final repo = _FakePartiturasRepository();
    final auth = _FakeAdminAuth()..errorToThrow = Exception('credenciales inválidas');
    final store = _FakeAdminCredentialsStore(const AdminCredentials());
    await _pumpScreen(tester, repo: repo, auth: auth, store: store);

    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '/admin');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'admin@test.com');
    await tester.enterText(find.byType(TextField).at(2), 'wrong');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Acceso denegado'), findsOneWidget);
    expect(find.textContaining('credenciales inválidas'), findsOneWidget);
    expect(store.saveCalled, isFalse);
  });
}
