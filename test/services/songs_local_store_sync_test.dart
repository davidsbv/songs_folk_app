import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/score.dart';
import 'package:songs_folk_app/models/song.dart';
import 'package:songs_folk_app/services/songs_local_store.dart';

void main() {
  final store = SongsLocalStore();

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() async {
    await store.replaceAllSongs(const []);
  });

  test('primer sync en limpio guarda canciones y metadatos', () async {
    await store.replaceAllSongs([
      const Song(
        remoteId: 's1',
        title: 'Jota de prueba',
        author: 'Ronda',
        type: 'JOTA',
        subtype: 'MAYO',
        lyricsText: 'Letra inicial',
        scores: [Score(instrument: 'CUERDA', scorePdfPath: 'score://s1')],
      ),
      const Song(
        remoteId: 's2',
        title: 'Seguidilla',
        author: 'Cuadrilla',
        type: 'SEGUIDILLA',
        subtype: 'RONDA',
      ),
    ]);

    final songs = await store.getSongs();
    final lastSyncAt = await store.getSongsLastSyncAt();

    expect(songs.length, 2);
    expect(songs.first.title, 'Jota de prueba');
    expect(songs.first.scores.length, 1);
    expect(songs.first.scores.first.instrument, 'CUERDA');
    expect(lastSyncAt, isNotNull);
  });

  test('sync posterior reemplaza snapshot local con versión nueva', () async {
    await store.replaceAllSongs([
      const Song(
        remoteId: 's1',
        title: 'Jota v1',
        author: 'Ronda',
        type: 'JOTA',
        subtype: 'MAYO',
      ),
    ]);

    await store.replaceAllSongs([
      const Song(
        remoteId: 's1',
        title: 'Jota v2',
        author: 'Ronda',
        type: 'JOTA',
        subtype: 'MAYO',
        lyricsText: 'Letra actualizada',
      ),
      const Song(
        remoteId: 's3',
        title: 'Nueva alta',
        author: 'Grupo folk',
        type: 'JOTA',
        subtype: 'ENTRADA',
        scores: [Score(instrument: 'DULZAINA', tabPdfPath: 'tab://s3')],
      ),
    ]);

    final songs = await store.getSongs();
    final byTitle = {for (final s in songs) s.title: s};

    expect(songs.length, 2);
    expect(byTitle.containsKey('Jota v1'), isFalse);
    expect(byTitle['Jota v2']?.lyricsText, 'Letra actualizada');
    expect(byTitle['Nueva alta']?.scores.first.instrument, 'DULZAINA');
  });
}
