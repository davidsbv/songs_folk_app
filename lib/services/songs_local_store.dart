import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/db_factory_init.dart';
import '../models/score.dart';
import '../models/song.dart';

/// Almacenamiento local de canciones para Partituras (offline-first).
class SongsLocalStore {
  SongsLocalStore._();

  static final SongsLocalStore _instance = SongsLocalStore._();

  factory SongsLocalStore() => _instance;

  static const _dbName = 'songs_folk_cache.db';
  static const _dbVersion = 2;
  static const _songsTable = 'songs_cache';
  static const _scoresTable = 'scores_cache';
  static const _metaTable = 'sync_meta_songs';
  static const _metaKeySongsLastSync = 'songs_last_sync_epoch_ms';
  static const _webSongsJsonKey = 'web_songs_cache_json';
  static const _webLastSyncKey = 'web_songs_last_sync_epoch_ms';

  Database? _db;
  bool _factoryInitialized = false;
  bool _webLoaded = false;
  List<Song> _webSongs = const [];
  DateTime? _webLastSyncAt;

  void _ensureDatabaseFactoryInitialized() {
    if (_factoryInitialized) return;
    initDatabaseFactory();
    _factoryInitialized = true;
  }

  Future<Database> _database() async {
    _ensureDatabaseFactoryInitialized();
    final current = _db;
    if (current != null) return current;

    final path = p.join(await getDatabasesPath(), _dbName);
    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _ensureTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureTables(db);
      },
      onOpen: (db) async {
        // Asegura esquema aunque la DB ya existiera creada por otro store.
        await _ensureTables(db);
      },
    );
    _db = db;
    return db;
  }

  Future<void> _ensureTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_songsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        type TEXT NOT NULL,
        subtype TEXT NOT NULL,
        lyrics_text TEXT,
        lyrics_pdf_path TEXT,
        lyrics_image_path TEXT,
        source_order INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_scoresTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        instrument TEXT NOT NULL,
        score_pdf_path TEXT,
        score_image_path TEXT,
        tab_pdf_path TEXT,
        tab_image_path TEXT,
        source_order INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_metaTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<List<Song>> getSongs() async {
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      return _webSongs;
    }

    final db = await _database();
    List<Map<String, Object?>> songRows;
    try {
      songRows = await db.query(
        _songsTable,
        orderBy: 'source_order ASC, id ASC',
      );
    } on DatabaseException catch (e) {
      // Recuperación automática de esquema para instalaciones con BD previa incompleta.
      if ((e.toString()).contains('no such table')) {
        await _ensureTables(db);
        songRows = await db.query(
          _songsTable,
          orderBy: 'source_order ASC, id ASC',
        );
      } else {
        rethrow;
      }
    }
    if (songRows.isEmpty) return const [];

    List<Map<String, Object?>> scoreRows;
    try {
      scoreRows = await db.query(
        _scoresTable,
        orderBy: 'source_order ASC, id ASC',
      );
    } on DatabaseException catch (e) {
      if ((e.toString()).contains('no such table')) {
        await _ensureTables(db);
        scoreRows = await db.query(
          _scoresTable,
          orderBy: 'source_order ASC, id ASC',
        );
      } else {
        rethrow;
      }
    }
    final scoresBySongId = <int, List<Score>>{};
    for (final row in scoreRows) {
      final songId = row['song_id'] as int? ?? 0;
      scoresBySongId.putIfAbsent(songId, () => []).add(
            Score(
              instrument: row['instrument'] as String? ?? '',
              scorePdfPath: row['score_pdf_path'] as String?,
              scoreImagePath: row['score_image_path'] as String?,
              tabPdfPath: row['tab_pdf_path'] as String?,
              tabImagePath: row['tab_image_path'] as String?,
            ),
          );
    }

    return songRows
        .map(
          (row) => Song(
            title: row['title'] as String? ?? '',
            author: row['author'] as String? ?? '',
            type: row['type'] as String? ?? '',
            subtype: row['subtype'] as String? ?? '',
            lyricsText: row['lyrics_text'] as String?,
            lyricsPdfPath: row['lyrics_pdf_path'] as String?,
            lyricsImagePath: row['lyrics_image_path'] as String?,
            scores: scoresBySongId[row['id'] as int? ?? 0] ?? const [],
          ),
        )
        .toList();
  }

  Future<void> replaceAllSongs(List<Song> songs) async {
    if (kIsWeb) {
      _webSongs = List<Song>.from(songs);
      _webLastSyncAt = DateTime.now();
      await _persistWebCache();
      return;
    }

    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete(_scoresTable);
      await txn.delete(_songsTable);

      for (var i = 0; i < songs.length; i++) {
        final song = songs[i];
        final songId = await txn.insert(_songsTable, {
          'title': song.title,
          'author': song.author,
          'type': song.type,
          'subtype': song.subtype,
          'lyrics_text': song.lyricsText,
          'lyrics_pdf_path': song.lyricsPdfPath,
          'lyrics_image_path': song.lyricsImagePath,
          'source_order': i,
        });

        for (var j = 0; j < song.scores.length; j++) {
          final score = song.scores[j];
          await txn.insert(_scoresTable, {
            'song_id': songId,
            'instrument': score.instrument,
            'score_pdf_path': score.scorePdfPath,
            'score_image_path': score.scoreImagePath,
            'tab_pdf_path': score.tabPdfPath,
            'tab_image_path': score.tabImagePath,
            'source_order': j,
          });
        }
      }

      await txn.insert(
        _metaTable,
        {
          'key': _metaKeySongsLastSync,
          'value': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<DateTime?> getSongsLastSyncAt() async {
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      return _webLastSyncAt;
    }
    final db = await _database();
    final rows = await db.query(
      _metaTable,
      where: 'key = ?',
      whereArgs: [_metaKeySongsLastSync],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    final millis = int.tryParse(raw ?? '');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> _loadWebCacheIfNeeded() async {
    if (!kIsWeb || _webLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_webSongsJsonKey);
    final rawSync = prefs.getString(_webLastSyncKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        _webSongs = decoded
            .whereType<Map<String, dynamic>>()
            .map(_songFromJson)
            .toList();
      } catch (_) {
        _webSongs = const [];
      }
    }
    final millis = int.tryParse(rawSync ?? '');
    _webLastSyncAt = millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
    _webLoaded = true;
  }

  Future<void> _persistWebCache() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _webSongs.map(_songToJson).toList();
    await prefs.setString(_webSongsJsonKey, jsonEncode(payload));
    final millis = _webLastSyncAt?.millisecondsSinceEpoch;
    if (millis != null) {
      await prefs.setString(_webLastSyncKey, millis.toString());
    }
    _webLoaded = true;
  }

  static Map<String, dynamic> _songToJson(Song song) => {
        'remote_id': song.remoteId,
        'title': song.title,
        'author': song.author,
        'type': song.type,
        'subtype': song.subtype,
        'lyrics_text': song.lyricsText,
        'lyrics_pdf_path': song.lyricsPdfPath,
        'lyrics_image_path': song.lyricsImagePath,
        'scores': song.scores
            .map(
              (s) => {
                'instrument': s.instrument,
                'score_pdf_path': s.scorePdfPath,
                'score_image_path': s.scoreImagePath,
                'tab_pdf_path': s.tabPdfPath,
                'tab_image_path': s.tabImagePath,
              },
            )
            .toList(),
      };

  static Song _songFromJson(Map<String, dynamic> json) {
    final scoresRaw = json['scores'] as List<dynamic>? ?? const [];
    return Song(
      remoteId: json['remote_id'] as String?,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      type: json['type'] as String? ?? '',
      subtype: json['subtype'] as String? ?? '',
      lyricsText: json['lyrics_text'] as String?,
      lyricsPdfPath: json['lyrics_pdf_path'] as String?,
      lyricsImagePath: json['lyrics_image_path'] as String?,
      scores: scoresRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (s) => Score(
              instrument: s['instrument'] as String? ?? '',
              scorePdfPath: s['score_pdf_path'] as String?,
              scoreImagePath: s['score_image_path'] as String?,
              tabPdfPath: s['tab_pdf_path'] as String?,
              tabImagePath: s['tab_image_path'] as String?,
            ),
          )
          .toList(),
    );
  }
}
