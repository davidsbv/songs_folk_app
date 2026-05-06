import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/core/supabase_config.dart';
import 'package:songs_folk_app/repositories/events_repository.dart';
import 'package:songs_folk_app/repositories/songs_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _runStagingSmoke = bool.fromEnvironment(
  'RUN_STAGING_SMOKE',
  defaultValue: false,
);
const _maxRemoteOpDuration = Duration(seconds: 8);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!_runStagingSmoke) {
    test('smoke staging desactivado por defecto', () {
      expect(true, isTrue);
    });
    return;
  }

  setUpAll(() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  });

  test('lectura remota básica de eventos responde sin error', () async {
    final repo = EventsRepository(isSupabaseConfigured: true);
    final sw = Stopwatch()..start();
    List<dynamic> result;
    try {
      result = await repo.getEventsForMonth(DateTime.now()).timeout(_maxRemoteOpDuration);
    } on TimeoutException {
      fail('Timeout en smoke de eventos: superó ${_maxRemoteOpDuration.inSeconds}s.');
    } catch (e) {
      fail('Error en smoke de eventos (auth/red/schema): $e');
    }
    sw.stop();
    debugPrint('[smoke] events_count=${result.length} duration_ms=${sw.elapsedMilliseconds}');
    expect(
      sw.elapsed <= _maxRemoteOpDuration,
      isTrue,
      reason: 'Eventos tardó más de ${_maxRemoteOpDuration.inSeconds}s',
    );
    for (final raw in result) {
      final event = raw;
      expect(event.title.trim(), isNotEmpty, reason: 'Evento sin título válido');
      expect(event.startAt is DateTime, isTrue, reason: 'Evento con startAt inválido');
      expect(event.endAt is DateTime, isTrue, reason: 'Evento con endAt inválido');
    }
  });

  test('sync y lectura básica de canciones responde sin error', () async {
    final repo = SongsRepository(isSupabaseConfigured: true);
    final sw = Stopwatch()..start();
    List<dynamic> songs;
    try {
      await repo.syncSongsCacheFromRemote().timeout(_maxRemoteOpDuration);
      songs = await repo.getSongs().timeout(_maxRemoteOpDuration);
    } on TimeoutException {
      fail('Timeout en smoke de canciones: superó ${_maxRemoteOpDuration.inSeconds}s.');
    } catch (e) {
      fail('Error en smoke de canciones (auth/red/schema): $e');
    }
    sw.stop();
    debugPrint('[smoke] songs_count=${songs.length} duration_ms=${sw.elapsedMilliseconds}');
    expect(
      sw.elapsed <= _maxRemoteOpDuration * 2,
      isTrue,
      reason: 'Sync+lectura de canciones tardó más de ${_maxRemoteOpDuration.inSeconds * 2}s',
    );
    for (final raw in songs) {
      final song = raw;
      expect(song.title.trim(), isNotEmpty, reason: 'Canción sin título válido');
      expect(song.type.trim(), isNotEmpty, reason: 'Canción sin tipo válido');
      expect(song.subtype.trim(), isNotEmpty, reason: 'Canción sin subtipo válido');
      for (final score in song.scores) {
        expect(
          score.instrument.trim(),
          isNotEmpty,
          reason: 'Score con instrumento vacío en canción ${song.title}',
        );
      }
    }
  });
}
