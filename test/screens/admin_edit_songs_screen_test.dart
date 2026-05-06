import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/score.dart';
import 'package:songs_folk_app/models/song.dart';
import 'package:songs_folk_app/repositories/songs_repository.dart';
import 'package:songs_folk_app/screens/admin_edit_songs_screen.dart';

class _TestNavObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

class _FakeSongsAdminRepo extends SongsRepository {
  _FakeSongsAdminRepo() : super(isSupabaseConfigured: false);

  bool deleteCalled = false;
  String? deletedId;
  final List<Song> _songs = [
    Song(
      remoteId: 'song-1',
      title: 'Ronda',
      author: 'Grupo',
      type: 'JOTA',
      subtype: 'TRADICIONAL',
      scores: const [Score(instrument: 'CUERDA')],
    ),
    Song(
      title: 'Borrador',
      author: 'Anonimo',
      type: 'JOTA',
      subtype: 'OTRA',
      scores: const [Score(instrument: 'DULZAINA')],
    ),
  ];

  @override
  Future<List<Song>> getAdminSongs() async => List<Song>.from(_songs);

  @override
  Future<void> deleteSong(String remoteId) async {
    deleteCalled = true;
    deletedId = remoteId;
    _songs.removeWhere((song) => song.remoteId == remoteId);
  }

  @override
  Future<int> syncSongsCacheFromRemote() async => 0;
}

void main() {
  testWidgets('tocar una canción dispara navegación de edición', (tester) async {
    final repo = _FakeSongsAdminRepo();
    final observer = _TestNavObserver();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminEditSongsScreen(repository: repo),
        navigatorObservers: [observer],
      ),
    );
    await tester.pumpAndSettle();
    final beforeTap = observer.pushCount;

    await tester.tap(find.text('Ronda'));
    await tester.pump();
    expect(observer.pushCount, greaterThan(beforeTap));
  });

  testWidgets('muestra aviso al borrar canción sin id remoto', (tester) async {
    final repo = _FakeSongsAdminRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEditSongsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('Borrador'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Eliminar canción')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No se puede eliminar: canción sin id remoto.'),
      findsOneWidget,
    );
    expect(repo.deleteCalled, isFalse);
  });

  testWidgets('confirma borrado y elimina la canción', (tester) async {
    final repo = _FakeSongsAdminRepo();
    await tester.pumpWidget(
      MaterialApp(home: AdminEditSongsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('Ronda'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Eliminar canción')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Ronda'), findsNothing);
    expect(repo.deleteCalled, isTrue);
    expect(repo.deletedId, 'song-1');
    expect(find.text('Canción eliminada.'), findsOneWidget);
  });
}
