import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/score.dart';
import '../models/song.dart';
import '../models/song_catalog.dart';
import '../models/partituras_catalog.dart';
import '../services/sample_songs_service.dart';

/// Repositorio de canciones: usa Supabase si está configurado, si no datos locales.
class SongsRepository {
  SongsRepository._();

  static final SongsRepository _instance = SongsRepository._();

  factory SongsRepository() => _instance;

  SupabaseClient? get _client =>
      isSupabaseConfigured ? Supabase.instance.client : null;

  /// Todas las canciones con sus partituras/tablaturas.
  Future<List<Song>> getSongs() async {
    final client = _client;
    if (client == null) {
      return List<Song>.from(SampleSongsService.sampleSongs);
    }

    final response = await client
        .from('songs')
        .select(
          'id, title, author, subtype, lyrics_text, lyrics_pdf_path, lyrics_image_path, song_types(name), scores(score_pdf_path, score_image_path, tab_pdf_path, tab_image_path, instruments(name))',
        )
        .order('title');

    final list = response as List<dynamic>? ?? [];
    return list.map((row) => _songFromJson(row as Map<String, dynamic>)).toList();
  }

  static Song _songFromJson(Map<String, dynamic> row) {
    final typeName = _stringFromJson(row['song_types'], 'name') ?? 'JOTA';
    final scoresList = row['scores'] as List<dynamic>? ?? [];
    final scores = scoresList
        .map((s) => _scoreFromJson(s as Map<String, dynamic>))
        .toList();

    return Song(
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

  /// Tipos de canción (JOTA, SEGUIDILLA) para Coplero y Partituras.
  Future<List<String>> getSongTypes() async {
    final client = _client;
    if (client == null) return List<String>.from(songTypes);

    final response = await client
        .from('song_types')
        .select('name')
        .order('sort_order');
    final list = response as List<dynamic>? ?? [];
    return list
        .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Subtipos de Song por tipo (JOTA / SEGUIDILLA). Usado en Coplero y Partituras.
  Future<List<String>> getSongSubtypesByType(String typeName) async {
    final client = _client;
    if (client == null) {
      return List<String>.from(subtypesByType[typeName] ?? []);
    }

    final typesRes = await client
        .from('song_types')
        .select('id')
        .eq('name', typeName)
        .maybeSingle();
    if (typesRes == null) return [];

    final typeId = typesRes['id'] as String?;
    if (typeId == null) return [];

    final response = await client
        .from('song_subtypes')
        .select('name')
        .eq('song_type_id', typeId)
        .order('sort_order');
    final list = response as List<dynamic>? ?? [];
    return list
        .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Instrumentos (CUERDA, DULZAINA) para Partituras.
  Future<List<String>> getInstruments() async {
    final client = _client;
    if (client == null) return ['CUERDA', 'DULZAINA'];

    final response = await client
        .from('instruments')
        .select('name')
        .order('sort_order');
    final list = response as List<dynamic>? ?? [];
    return list
        .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Opciones de subtipo de Song en Partituras, según instrumento (Cuerda/Dulzaina).
  /// Corresponde a partituras_catalog.dart: subtypesCuerda y subtypesDulzaina.
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName) async {
    final client = _client;
    if (client == null) {
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

    final instRes = await client
        .from('instruments')
        .select('id')
        .eq('name', instrumentName)
        .maybeSingle();
    if (instRes == null) return [];

    final instrumentId = instRes['id'] as String?;
    if (instrumentId == null) return [];

    final response = await client
        .from('partituras_subtypes')
        .select('name')
        .eq('instrument_id', instrumentId)
        .order('sort_order');
    final list = response as List<dynamic>? ?? [];
    return list
        .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
