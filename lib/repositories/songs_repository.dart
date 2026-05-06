import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/copla.dart';
import '../models/score.dart';
import '../models/song.dart';
import '../models/song_catalog.dart';
import '../models/partituras_catalog.dart';
import '../services/sample_coplas_service.dart';
import '../services/coplas_local_store.dart';
import '../services/sample_songs_service.dart';
import '../services/songs_local_store.dart';

/// Repositorio de canciones: usa Supabase si está configurado, si no datos locales.
class SongsRepository {
  SongsRepository({
    CoplasLocalStore? coplasStore,
    SongsLocalStore? songsStore,
    SupabaseClient? client,
    bool? isSupabaseConfigured,
  }) : _coplasStore = coplasStore ?? CoplasLocalStore(),
       _songsStore = songsStore ?? SongsLocalStore(),
       _clientOverride = client,
       _isSupabaseConfiguredOverride = isSupabaseConfigured;

  final CoplasLocalStore _coplasStore;
  final SongsLocalStore _songsStore;
  final SupabaseClient? _clientOverride;
  final bool? _isSupabaseConfiguredOverride;
  static const String _otherSongTypeName = 'OTRO';

  SupabaseClient? get _client =>
      _clientOverride ??
      ((_isSupabaseConfiguredOverride ?? isSupabaseConfigured)
          ? Supabase.instance.client
          : null);

  /// Todas las canciones con sus partituras/tablaturas.
  Future<List<Song>> getSongs({bool forceRefresh = false}) async {
    final client = _client;
    if (forceRefresh && client != null) {
      await syncSongsCacheFromRemote();
    }

    final cached = await _songsStore.getSongs();
    if (cached.isNotEmpty) {
      return cached;
    }

    if (client == null) {
      return List<Song>.from(SampleSongsService.sampleSongs);
    }

    try {
      await syncSongsCacheFromRemote();
      return _songsStore.getSongs();
    } catch (_) {
      // Con Supabase configurado no usamos datos de ejemplo para evitar confusión.
      return cached;
    }
  }

  Future<List<String>> getCoplaTypes() async {
    final client = _client;
    if (client == null) {
      final cached = await _coplasStore.getCachedCoplaTypes();
      if (cached.isNotEmpty) return cached;
      throw Exception(
        'Catálogo de coplas no disponible sin conexión. Sincroniza con Supabase.',
      );
    }
    List<String> localFallback() {
      final fromSample = SampleCoplasService.sampleCoplas
          .map((c) => c.type.trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
      fromSample.sort();
      return fromSample;
    }

    try {
      final response = await client
          .from('copla_types')
          .select('name')
          .order('sort_order');
      final list = response as List<dynamic>? ?? [];
      final result = list
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (result.isEmpty) {
        final cached = await _coplasStore.getCachedCoplaTypes();
        if (cached.isNotEmpty) return cached;
        return localFallback();
      }
      return result;
    } catch (_) {
      final cached = await _coplasStore.getCachedCoplaTypes();
      if (cached.isNotEmpty) return cached;
      return localFallback();
    }
  }

  Future<List<String>> getCoplaSubtypesByType(String typeName) async {
    final client = _client;
    if (client == null) {
      final cached = await _coplasStore.getCachedCoplaSubtypesByType(typeName);
      if (cached.isNotEmpty) return cached;
      throw Exception(
        'Subtipos no disponibles sin conexión para $typeName. Sincroniza con Supabase.',
      );
    }
    List<String> localFallback() {
      final fromSample = SampleCoplasService.sampleCoplas
          .where((c) => c.type == typeName)
          .map((c) => c.subtype.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      fromSample.sort();
      return fromSample;
    }

    try {
      final typeRes = await client
          .from('copla_types')
          .select('id')
          .eq('name', typeName)
          .maybeSingle();
      final typeId = typeRes?['id'] as String?;
      if (typeId == null) {
        final cached = await _coplasStore.getCachedCoplaSubtypesByType(typeName);
        if (cached.isNotEmpty) return cached;
        return localFallback();
      }
      final response = await client
          .from('copla_subtypes')
          .select('name')
          .eq('copla_type_id', typeId)
          .order('sort_order');
      final list = response as List<dynamic>? ?? [];
      final result = list
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (result.isEmpty) {
        final cached = await _coplasStore.getCachedCoplaSubtypesByType(typeName);
        if (cached.isNotEmpty) return cached;
        return localFallback();
      }
      return result;
    } catch (_) {
      final cached = await _coplasStore.getCachedCoplaSubtypesByType(typeName);
      if (cached.isNotEmpty) return cached;
      return localFallback();
    }
  }

  /// Coplas de un tipo (JOTA/SEGUIDILLA) en orden natural de incorporación.
  Future<List<Copla>> getCoplasByType(
    String typeName, {
    bool forceRefresh = false,
  }) async {
    final client = _client;
    if (forceRefresh && client != null) {
      await syncCoplasCacheFromRemote();
    }

    final cached = await _coplasStore.getCoplasByType(typeName);
    if (cached.isNotEmpty) {
      return cached;
    }

    if (client == null) {
      return SampleCoplasService.sampleCoplas
          .where((c) => c.type == typeName)
          .toList();
    }

    try {
      await syncCoplasCacheFromRemote();
      return _coplasStore.getCoplasByType(typeName);
    } catch (_) {
      // Con Supabase configurado devolvemos caché real (aunque esté vacía).
      return cached;
    }
  }

  Future<int> syncCoplasCacheFromRemote() async {
    final client = _client;
    if (client == null) return 0;

    final cursor = await _coplasStore.getCoplasRemoteCursorAt();
    try {
      final changes = await _fetchCoplaChangesIncremental(cursor);
      if (cursor == null) {
        await _coplasStore.replaceAllCoplas(changes);
      } else {
        await _coplasStore.applyRemoteChanges(changes);
      }
      if (changes.isNotEmpty) {
        var maxUpdated = cursor;
        for (final c in changes) {
          final updated = c.updatedAt;
          if (updated == null) continue;
          if (maxUpdated == null || updated.isAfter(maxUpdated)) {
            maxUpdated = updated;
          }
        }
        if (maxUpdated != null) {
          await _coplasStore.setCoplasRemoteCursorAt(maxUpdated);
        }
      }
      return changes.length;
    } catch (_) {
      final full = await _fetchCoplasFullSnapshot();
      await _coplasStore.replaceAllCoplas(full);
      await _coplasStore.setCoplasRemoteCursorAt(DateTime.now().toUtc());
      return full.length;
    }
  }

  Future<int> syncSongsCacheFromRemote() async {
    final client = _client;
    if (client == null) return 0;
    final cachedBefore = await _songsStore.getSongs();
    final songs = await _fetchSongsRemoteSnapshot();
    final changedCount = _countChangedSongs(cachedBefore, songs);
    await _songsStore.replaceAllSongs(songs);
    return changedCount;
  }

  Future<DateTime?> getSongsLastSyncAt() {
    return _songsStore.getSongsLastSyncAt();
  }

  Future<DateTime?> getCoplasLastSyncAt() {
    return _coplasStore.getCoplasLastSyncAt();
  }

  Future<void> createSong(Song song) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }

    final typeId = await _resolveSongTypeId(song.type);
    if (typeId == null) {
      throw Exception(
        'No hay tipos de canción disponibles en song_types para guardar.',
      );
    }

    final inserted = await client
        .from('songs')
        .insert({
          'title': song.title,
          'author': song.author,
          'subtype': song.subtype,
          'song_type_id': typeId,
          'lyrics_text': song.lyricsText,
          'lyrics_pdf_path': song.lyricsPdfPath,
          'lyrics_image_path': song.lyricsImagePath,
        })
        .select('id')
        .single();
    final songId = inserted['id'] as String?;
    if (songId == null) {
      throw Exception('No se pudo obtener el ID de la canción creada.');
    }

    for (final score in song.scores) {
      final instrumentId = await _getInstrumentIdByName(score.instrument);
      if (instrumentId == null) {
        throw Exception('Instrumento no encontrado: ${score.instrument}');
      }
      await client.from('scores').insert({
        'song_id': songId,
        'instrument_id': instrumentId,
        'score_pdf_path': score.scorePdfPath,
        'score_image_path': score.scoreImagePath,
        'tab_pdf_path': score.tabPdfPath,
        'tab_image_path': score.tabImagePath,
      });
    }
  }

  Future<void> createCopla(Copla copla) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }

    final typeId = await _getCoplaTypeIdByName(copla.type);
    if (typeId == null) {
      throw Exception('Tipo de copla no encontrado: ${copla.type}');
    }
    final subtypeId = await _getCoplaSubtypeIdByName(copla.subtype, typeId);
    if (subtypeId == null) {
      throw Exception('Subtipo de copla no encontrado: ${copla.subtype}');
    }

    await client.from('coplas').insert({
      'copla_type_id': typeId,
      'copla_subtype_id': subtypeId,
      'text': copla.text,
      'author': copla.author,
    });
  }

  Future<void> updateCopla(Copla copla) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }
    final remoteId = copla.remoteId;
    if (remoteId == null || remoteId.isEmpty) {
      throw Exception('La copla no tiene id remoto para poder editarse.');
    }

    final typeId = await _getCoplaTypeIdByName(copla.type);
    if (typeId == null) {
      throw Exception('Tipo de copla no encontrado: ${copla.type}');
    }
    final subtypeId = await _getCoplaSubtypeIdByName(copla.subtype, typeId);
    if (subtypeId == null) {
      throw Exception('Subtipo de copla no encontrado: ${copla.subtype}');
    }

    await client
        .from('coplas')
        .update({
          'copla_type_id': typeId,
          'copla_subtype_id': subtypeId,
          'text': copla.text,
          'author': copla.author,
        })
        .eq('id', remoteId);
  }

  Future<void> updateSong(Song song) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }
    final remoteId = song.remoteId;
    if (remoteId == null || remoteId.isEmpty) {
      throw Exception('La canción no tiene id remoto para poder editarse.');
    }

    final typeId = await _resolveSongTypeId(song.type);
    if (typeId == null) {
      throw Exception(
        'No hay tipos de canción disponibles en song_types para guardar.',
      );
    }

    await client
        .from('songs')
        .update({
          'title': song.title,
          'author': song.author,
          'subtype': song.subtype,
          'song_type_id': typeId,
          'lyrics_text': song.lyricsText,
          'lyrics_pdf_path': song.lyricsPdfPath,
          'lyrics_image_path': song.lyricsImagePath,
        })
        .eq('id', remoteId);

    await client.from('scores').delete().eq('song_id', remoteId);
    for (final score in song.scores) {
      final instrumentId = await _getInstrumentIdByName(score.instrument);
      if (instrumentId == null) {
        throw Exception('Instrumento no encontrado: ${score.instrument}');
      }
      await client.from('scores').insert({
        'song_id': remoteId,
        'instrument_id': instrumentId,
        'score_pdf_path': score.scorePdfPath,
        'score_image_path': score.scoreImagePath,
        'tab_pdf_path': score.tabPdfPath,
        'tab_image_path': score.tabImagePath,
      });
    }
  }

  Future<void> deleteCopla(String remoteId) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }
    await client
        .from('coplas')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', remoteId);
  }

  Future<void> deleteSong(String remoteId) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }
    await client.from('scores').delete().eq('song_id', remoteId);
    await client.from('songs').delete().eq('id', remoteId);
  }

  Future<List<Copla>> getAdminCoplas() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }
    final response = await client
        .from('coplas')
        .select(
          'id, author, text, updated_at, deleted_at, copla_types(name), copla_subtypes(name)',
        )
        .isFilter('deleted_at', null)
        .order('updated_at', ascending: false);
    final list = response as List<dynamic>? ?? [];
    return list.map((row) => _coplaFromRemoteRow(row as Map<String, dynamic>)).toList();
  }

  Future<List<Song>> getAdminSongs() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado en esta ejecución.');
    }
    return _fetchSongsRemoteSnapshot();
  }

  Future<List<Copla>> _fetchCoplaChangesIncremental(DateTime? cursor) async {
    final client = _client!;
    var query = client
        .from('coplas')
        .select(
          'id, author, text, updated_at, deleted_at, copla_types(name), copla_subtypes(name)',
        );
    if (cursor != null) {
      query = query.gt('updated_at', cursor.toIso8601String());
    }
    final response = await query.order('updated_at', ascending: true);
    final list = response as List<dynamic>? ?? [];
    return list.map((row) => _coplaFromRemoteRow(row as Map<String, dynamic>)).toList();
  }

  Future<List<Song>> _fetchSongsRemoteSnapshot() async {
    final client = _client!;
    final response = await client
        .from('songs')
        .select(
          'id, title, author, subtype, lyrics_text, lyrics_pdf_path, lyrics_image_path, song_types(name), scores(score_pdf_path, score_image_path, tab_pdf_path, tab_image_path, instruments(name))',
        )
        .order('title');
    final list = response as List<dynamic>? ?? [];
    return list.map((row) => _songFromJson(row as Map<String, dynamic>)).toList();
  }

  Future<List<Copla>> _fetchCoplasFullSnapshot() async {
    final client = _client!;
    try {
      final response = await client
          .from('coplas')
          .select(
            'id, author, text, updated_at, deleted_at, copla_types(name), copla_subtypes(name)',
          )
          .order('updated_at', ascending: true);
      final list = response as List<dynamic>? ?? [];
      return list
          .map((row) => _coplaFromRemoteRow(row as Map<String, dynamic>))
          .where((c) => c.deletedAt == null && c.text.isNotEmpty)
          .toList();
    } catch (_) {
      final response = await client
          .from('songs')
          .select(
            'id, author, subtype, lyrics_text, updated_at, song_types(name)',
          )
          .not('lyrics_text', 'is', null)
          .neq('lyrics_text', '')
          .order('updated_at', ascending: true);
      final list = response as List<dynamic>? ?? [];
      return list
          .map((row) => _coplaFromLegacySongRow(row as Map<String, dynamic>))
          .where((c) => c.deletedAt == null && c.text.isNotEmpty)
          .toList();
    }
  }

  Copla _coplaFromRemoteRow(Map<String, dynamic> row) {
    final text = (row['text'] as String? ?? '').trim();
    return Copla(
      remoteId: row['id'] as String?,
      type: _stringFromJson(row['copla_types'], 'name') ?? 'JOTA',
      subtype: _stringFromJson(row['copla_subtypes'], 'name') ?? '',
      text: text,
      author: (row['author'] as String?)?.trim().isEmpty ?? true
          ? null
          : row['author'] as String?,
      updatedAt: _parseRemoteDate(row['updated_at']) ?? DateTime.now().toUtc(),
      deletedAt: _parseRemoteDate(row['deleted_at']),
    );
  }

  Copla _coplaFromLegacySongRow(Map<String, dynamic> row) {
    final text = (row['lyrics_text'] as String? ?? '').trim();
    return Copla(
      remoteId: row['id'] as String?,
      type: _stringFromJson(row['song_types'], 'name') ?? 'JOTA',
      subtype: row['subtype'] as String? ?? '',
      text: text,
      author: (row['author'] as String?)?.trim().isEmpty ?? true
          ? null
          : row['author'] as String?,
      updatedAt: _parseRemoteDate(row['updated_at']) ?? DateTime.now().toUtc(),
      deletedAt: _parseRemoteDate(row['deleted_at']),
    );
  }

  DateTime? _parseRemoteDate(dynamic raw) {
    final v = raw as String?;
    if (v == null || v.isEmpty) return null;
    return DateTime.tryParse(v)?.toUtc();
  }

  Future<String?> _getSongTypeIdByName(String typeName) async {
    final client = _client!;
    final row = await client
        .from('song_types')
        .select('id')
        .eq('name', typeName)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<String?> _resolveSongTypeId(String preferredTypeName) async {
    final normalizedPreferred = preferredTypeName.trim().isEmpty
        ? _otherSongTypeName
        : preferredTypeName;
    final exact = await _getSongTypeIdByName(normalizedPreferred);
    if (exact != null) return exact;
    final other = await _getSongTypeIdByName(_otherSongTypeName);
    if (other != null) return other;
    final client = _client!;
    final fallback = await client
        .from('song_types')
        .select('id')
        .order('sort_order')
        .limit(1)
        .maybeSingle();
    return fallback?['id'] as String?;
  }

  Future<String?> _getInstrumentIdByName(String instrumentName) async {
    final client = _client!;
    final row = await client
        .from('instruments')
        .select('id')
        .eq('name', instrumentName)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<String?> _getCoplaTypeIdByName(String typeName) async {
    final client = _client!;
    final row = await client
        .from('copla_types')
        .select('id')
        .eq('name', typeName)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<String?> _getCoplaSubtypeIdByName(
    String subtypeName,
    String typeId,
  ) async {
    final client = _client!;
    final row = await client
        .from('copla_subtypes')
        .select('id')
        .eq('copla_type_id', typeId)
        .eq('name', subtypeName)
        .maybeSingle();
    return row?['id'] as String?;
  }

  static Song _songFromJson(Map<String, dynamic> row) {
    final typeName = _stringFromJson(row['song_types'], 'name') ?? 'JOTA';
    final scoresList = row['scores'] as List<dynamic>? ?? [];
    final scores = scoresList
        .map((s) => _scoreFromJson(s as Map<String, dynamic>))
        .toList();

    return Song(
      remoteId: row['id'] as String?,
      title: row['title'] as String? ?? '',
      author: row['author'] as String? ?? '',
      type: typeName,
      subtype: row['subtype'] as String? ?? '',
      lyricsText: row['lyrics_text'] as String?,
      lyricsPdfPath: row['lyrics_pdf_path'] as String?,
      lyricsImagePath: row['lyrics_image_path'] as String?,
      scores: scores,
    );
  }

  static String? _stringFromJson(dynamic obj, String key) {
    if (obj is Map<String, dynamic>) return obj[key] as String?;
    return null;
  }

  static Score _scoreFromJson(Map<String, dynamic> row) {
    final instrumentName =
        _stringFromJson(row['instruments'], 'name') ?? '';

    return Score(
      instrument: instrumentName,
      scorePdfPath: row['score_pdf_path'] as String?,
      scoreImagePath: row['score_image_path'] as String?,
      tabPdfPath: row['tab_pdf_path'] as String?,
      tabImagePath: row['tab_image_path'] as String?,
    );
  }

  int _countChangedSongs(List<Song> local, List<Song> remote) {
    final maxLen = local.length > remote.length ? local.length : remote.length;
    var changed = 0;
    for (var i = 0; i < maxLen; i++) {
      if (i >= local.length || i >= remote.length) {
        changed++;
        continue;
      }
      if (_songFingerprint(local[i]) != _songFingerprint(remote[i])) {
        changed++;
      }
    }
    return changed;
  }

  String _songFingerprint(Song song) {
    final scoreParts = song.scores
        .map(
          (s) =>
              '${s.instrument}|${s.scorePdfPath ?? ''}|${s.scoreImagePath ?? ''}|${s.tabPdfPath ?? ''}|${s.tabImagePath ?? ''}',
        )
        .join('||');
    return [
      song.title,
      song.author,
      song.type,
      song.subtype,
      song.lyricsText ?? '',
      song.lyricsPdfPath ?? '',
      song.lyricsImagePath ?? '',
      scoreParts,
    ].join('###');
  }

  /// Tipos de canción (JOTA, SEGUIDILLA) para Coplero y Partituras.
  Future<List<String>> getSongTypes() async {
    final client = _client;
    if (client == null) return List<String>.from(songTypes);

    try {
      final response = await client
          .from('song_types')
          .select('name')
          .order('sort_order');
      final list = response as List<dynamic>? ?? [];
      final result = list
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (result.isEmpty) return List<String>.from(songTypes);
      return result;
    } catch (_) {
      return List<String>.from(songTypes);
    }
  }

  /// Subtipos de Song por tipo (JOTA / SEGUIDILLA). Usado en Coplero y Partituras.
  Future<List<String>> getSongSubtypesByType(String typeName) async {
    final client = _client;
    if (client == null) {
      return List<String>.from(subtypesByType[typeName] ?? []);
    }

    try {
      final typesRes = await client
          .from('song_types')
          .select('id')
          .eq('name', typeName)
          .maybeSingle();
      if (typesRes == null) {
        return List<String>.from(subtypesByType[typeName] ?? []);
      }

      final typeId = typesRes['id'] as String?;
      if (typeId == null) {
        return List<String>.from(subtypesByType[typeName] ?? []);
      }

      final response = await client
          .from('song_subtypes')
          .select('name')
          .eq('song_type_id', typeId)
          .order('sort_order');
      final list = response as List<dynamic>? ?? [];
      final result = list
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (result.isEmpty) return List<String>.from(subtypesByType[typeName] ?? []);
      return result;
    } catch (_) {
      return List<String>.from(subtypesByType[typeName] ?? []);
    }
  }

  /// Instrumentos (CUERDA, DULZAINA) para Partituras.
  Future<List<String>> getInstruments() async {
    final client = _client;
    if (client == null) return ['CUERDA', 'DULZAINA'];

    try {
      final response = await client
          .from('instruments')
          .select('name')
          .order('sort_order');
      final list = response as List<dynamic>? ?? [];
      final result = list
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (result.isEmpty) return ['CUERDA', 'DULZAINA'];
      return result;
    } catch (_) {
      return ['CUERDA', 'DULZAINA'];
    }
  }

  /// Opciones de subtipo de Song en Partituras, según instrumento (Cuerda/Dulzaina).
  /// Corresponde a partituras_catalog.dart: subtypesCuerda y subtypesDulzaina.
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName) async {
    List<String> localFallback() {
      switch (instrumentName) {
        case 'CUERDA':
          return List<String>.from(subtypesCuerda);
        case 'DULZAINA':
          return List<String>.from(subtypesDulzaina);
        default:
          final combined = [...subtypesCuerda, ...subtypesDulzaina];
          final result = List<String>.from(combined.toSet());
          result.sort();
          return result;
      }
    }

    final client = _client;
    if (client == null) {
      return localFallback();
    }
    try {
      final instRes = await client
          .from('instruments')
          .select('id')
          .eq('name', instrumentName)
          .maybeSingle();
      if (instRes == null) return localFallback();

      final instrumentId = instRes['id'] as String?;
      if (instrumentId == null) return localFallback();

      final response = await client
          .from('partituras_subtypes')
          .select('name')
          .eq('instrument_id', instrumentId)
          .order('sort_order');
      final list = response as List<dynamic>? ?? [];
      final result = list
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (result.isEmpty) return localFallback();
      return result;
    } catch (_) {
      return localFallback();
    }
  }
}
