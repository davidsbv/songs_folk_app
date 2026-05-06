import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/copla.dart';
import 'package:songs_folk_app/repositories/songs_repository.dart';
import 'package:songs_folk_app/screens/admin_create_copla_screen.dart';

class _FakeAdminCoplaRepo extends SongsRepository {
  _FakeAdminCoplaRepo() : super(isSupabaseConfigured: false);

  bool createCalled = false;

  @override
  Future<List<String>> getCoplaTypes() async => ['JOTA'];

  @override
  Future<List<String>> getCoplaSubtypesByType(String typeName) async => ['MAYO'];

  @override
  Future<void> createCopla(Copla copla) async {
    createCalled = true;
  }

  @override
  Future<int> syncCoplasCacheFromRemote() async => 0;

  @override
  Future<int> syncSongsCacheFromRemote() async => 0;
}

void main() {
  testWidgets('valida texto obligatorio en alta de copla', (tester) async {
    final repo = _FakeAdminCoplaRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminCreateCoplaScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar copla'));
    await tester.pumpAndSettle();

    expect(find.text('El texto de la copla es obligatorio'), findsOneWidget);
    expect(repo.createCalled, isFalse);
  });
}
