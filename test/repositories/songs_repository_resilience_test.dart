import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:songs_folk_app/models/partituras_catalog.dart';
import 'package:songs_folk_app/models/song_catalog.dart';
import 'package:songs_folk_app/repositories/songs_repository.dart';
import 'package:songs_folk_app/services/coplas_local_store.dart';
import 'package:songs_folk_app/services/songs_local_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockCoplasStore extends Mock implements CoplasLocalStore {}

class _MockSongsStore extends Mock implements SongsLocalStore {}

void main() {
  group('SongsRepository resiliencia', () {
    test('getSongTypes usa fallback local si hay error de red', () async {
      final client = _MockSupabaseClient();
      when(() => client.from(any())).thenThrow(Exception('SocketException'));

      final repo = SongsRepository(
        client: client,
        isSupabaseConfigured: true,
        coplasStore: _MockCoplasStore(),
        songsStore: _MockSongsStore(),
      );

      final result = await repo.getSongTypes();
      expect(result, songTypes);
    });

    test('getInstruments usa fallback local si falla remoto', () async {
      final client = _MockSupabaseClient();
      when(() => client.from(any())).thenThrow(Exception('timeout'));

      final repo = SongsRepository(
        client: client,
        isSupabaseConfigured: true,
        coplasStore: _MockCoplasStore(),
        songsStore: _MockSongsStore(),
      );

      final result = await repo.getInstruments();
      expect(result, ['CUERDA', 'DULZAINA']);
    });

    test('getPartiturasSubtypesByInstrument usa catálogo local ante error', () async {
      final client = _MockSupabaseClient();
      when(() => client.from(any())).thenThrow(Exception('dns'));

      final repo = SongsRepository(
        client: client,
        isSupabaseConfigured: true,
        coplasStore: _MockCoplasStore(),
        songsStore: _MockSongsStore(),
      );

      final result = await repo.getPartiturasSubtypesByInstrument('CUERDA');
      expect(result, subtypesCuerda);
    });

    test('getCoplaTypes usa cache local cuando remoto falla', () async {
      final client = _MockSupabaseClient();
      final coplasStore = _MockCoplasStore();
      when(() => client.from(any())).thenThrow(Exception('empty response'));
      when(() => coplasStore.getCachedCoplaTypes()).thenAnswer((_) async => ['JOTA']);

      final repo = SongsRepository(
        client: client,
        isSupabaseConfigured: true,
        coplasStore: coplasStore,
        songsStore: _MockSongsStore(),
      );

      final result = await repo.getCoplaTypes();
      expect(result, ['JOTA']);
    });

    test('getCoplaTypes usa muestra local si remoto viene roto y no hay cache', () async {
      final client = _MockSupabaseClient();
      final coplasStore = _MockCoplasStore();
      when(
        () => client.from(any()),
      ).thenThrow(Exception('payload inválido: name ausente'));
      when(() => coplasStore.getCachedCoplaTypes()).thenAnswer((_) async => const []);

      final repo = SongsRepository(
        client: client,
        isSupabaseConfigured: true,
        coplasStore: coplasStore,
        songsStore: _MockSongsStore(),
      );

      final result = await repo.getCoplaTypes();
      expect(result, isNotEmpty);
      expect(result.contains('JOTA') || result.contains('SEGUIDILLA'), isTrue);
    });

    test('getCoplaSubtypesByType usa cache local cuando remoto falla', () async {
      final client = _MockSupabaseClient();
      final coplasStore = _MockCoplasStore();
      when(() => client.from(any())).thenThrow(Exception('timeout'));
      when(
        () => coplasStore.getCachedCoplaSubtypesByType('JOTA'),
      ).thenAnswer((_) async => ['ENTRADAS']);

      final repo = SongsRepository(
        client: client,
        isSupabaseConfigured: true,
        coplasStore: coplasStore,
        songsStore: _MockSongsStore(),
      );

      final result = await repo.getCoplaSubtypesByType('JOTA');
      expect(result, ['ENTRADAS']);
    });
  });
}
