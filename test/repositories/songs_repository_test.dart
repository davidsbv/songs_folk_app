import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:songs_folk_app/models/song.dart';
import 'package:songs_folk_app/repositories/songs_repository.dart';
import 'package:songs_folk_app/services/coplas_local_store.dart';
import 'package:songs_folk_app/services/songs_local_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSongsStore extends Mock implements SongsLocalStore {}

class _MockCoplasStore extends Mock implements CoplasLocalStore {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _SongsRepoWithFailingSync extends SongsRepository {
  _SongsRepoWithFailingSync({
    required SongsLocalStore songsStore,
    required CoplasLocalStore coplasStore,
    required SupabaseClient client,
  }) : super(
         songsStore: songsStore,
         coplasStore: coplasStore,
         client: client,
         isSupabaseConfigured: true,
       );

  @override
  Future<int> syncSongsCacheFromRemote() async => throw Exception('network');
}

void main() {
  test('fallback a cache local cuando falla remoto', () async {
    final songsStore = _MockSongsStore();
    final coplasStore = _MockCoplasStore();
    final client = _MockSupabaseClient();
    when(() => songsStore.getSongs()).thenAnswer((_) async => const <Song>[]);

    final repo = _SongsRepoWithFailingSync(
      songsStore: songsStore,
      coplasStore: coplasStore,
      client: client,
    );
    final result = await repo.getSongs();
    expect(result, isEmpty);
  });

  test('si hay cache devuelve datos sin pedir remoto', () async {
    final songsStore = _MockSongsStore();
    final coplasStore = _MockCoplasStore();
    when(
      () => songsStore.getSongs(),
    ).thenAnswer((_) async => const [Song(title: 't', author: 'a', type: 'JOTA', subtype: 'S')]);

    final repo = SongsRepository(
      songsStore: songsStore,
      coplasStore: coplasStore,
      isSupabaseConfigured: false,
    );
    final result = await repo.getSongs();
    expect(result.length, 1);
    expect(result.first.title, 't');
  });

  test('sync songs retorna 0 en modo offline', () async {
    final repo = SongsRepository(isSupabaseConfigured: false);
    expect(await repo.syncSongsCacheFromRemote(), 0);
  });
}
