import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/db_factory_init.dart';
import '../models/copla.dart';

/// Almacenamiento local de coplas para uso offline.
class CoplasLocalStore {
  CoplasLocalStore._();

  static final CoplasLocalStore _instance = CoplasLocalStore._();

  factory CoplasLocalStore() => _instance;

  static const _dbName = 'songs_folk_cache.db';
  static const _dbVersion = 2;
  static const _coplasTable = 'coplas_cache';
  static const _metaTable = 'sync_meta';
  static const _metaKeyCoplasLastSync = 'coplas_last_sync_epoch_ms';
  static const _metaKeyCoplasRemoteCursor = 'coplas_remote_cursor_iso';
  static const _webCoplasJsonKey = 'web_coplas_cache_json';
  static const _webLastSyncKey = 'web_coplas_last_sync_epoch_ms';
  static const _webRemoteCursorKey = 'web_coplas_remote_cursor_iso';

  Database? _db;
  List<Copla> _webMemoryCoplas = const [];
  DateTime? _webLastSyncAt;
  DateTime? _webRemoteCursorAt;
  bool _webLoaded = false;
  bool _factoryInitialized = false;

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
        await _ensureTables(db);
      },
    );
    _db = db;
    return db;
  }

  Future<void> _ensureTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_coplasTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        type TEXT NOT NULL,
        subtype TEXT NOT NULL,
        text TEXT NOT NULL,
        author TEXT,
        source_order INTEGER NOT NULL,
        updated_at_ms INTEGER,
        deleted_at_ms INTEGER
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_coplas_remote_id ON $_coplasTable(remote_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_metaTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<List<Copla>> getCoplasByType(String typeName) async {
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      return _webMemoryCoplas.where((c) => c.type == typeName).toList();
    }
    final db = await _database();
    List<Map<String, Object?>> rows;
    try {
      rows = await db.query(
        _coplasTable,
        where: 'type = ? AND deleted_at_ms IS NULL',
        whereArgs: [typeName],
        orderBy: 'source_order ASC, id ASC',
      );
    } on DatabaseException catch (e) {
      if ((e.toString()).contains('no such table')) {
        await _ensureTables(db);
        rows = await db.query(
          _coplasTable,
          where: 'type = ? AND deleted_at_ms IS NULL',
          whereArgs: [typeName],
          orderBy: 'source_order ASC, id ASC',
        );
      } else {
        rethrow;
      }
    }

    return rows
        .map(
          (row) => Copla(
            remoteId: row['remote_id'] as String?,
            type: row['type'] as String? ?? '',
            subtype: row['subtype'] as String? ?? '',
            text: row['text'] as String? ?? '',
            author: row['author'] as String?,
            updatedAt: _dateFromMillis(row['updated_at_ms']),
            deletedAt: _dateFromMillis(row['deleted_at_ms']),
          ),
        )
        .toList();
  }

  Future<List<String>> getCachedCoplaTypes() async {
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      final types = _webMemoryCoplas
          .map((c) => c.type.trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
      types.sort();
      return types;
    }
    final db = await _database();
    List<Map<String, Object?>> rows;
    try {
      rows = await db.rawQuery('''
        SELECT DISTINCT type
        FROM $_coplasTable
        WHERE deleted_at_ms IS NULL AND TRIM(type) <> ''
        ORDER BY type ASC
      ''');
    } on DatabaseException catch (e) {
      if ((e.toString()).contains('no such table')) {
        await _ensureTables(db);
        rows = await db.rawQuery('''
          SELECT DISTINCT type
          FROM $_coplasTable
          WHERE deleted_at_ms IS NULL AND TRIM(type) <> ''
          ORDER BY type ASC
        ''');
      } else {
        rethrow;
      }
    }
    return rows
        .map((r) => (r['type'] as String? ?? '').trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<List<String>> getCachedCoplaSubtypesByType(String typeName) async {
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      final subtypes = _webMemoryCoplas
          .where((c) => c.type == typeName)
          .map((c) => c.subtype.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      subtypes.sort();
      return subtypes;
    }
    final db = await _database();
    List<Map<String, Object?>> rows;
    try {
      rows = await db.rawQuery(
        '''
        SELECT DISTINCT subtype
        FROM $_coplasTable
        WHERE type = ? AND deleted_at_ms IS NULL AND TRIM(subtype) <> ''
        ORDER BY subtype ASC
        ''',
        [typeName],
      );
    } on DatabaseException catch (e) {
      if ((e.toString()).contains('no such table')) {
        await _ensureTables(db);
        rows = await db.rawQuery(
          '''
          SELECT DISTINCT subtype
          FROM $_coplasTable
          WHERE type = ? AND deleted_at_ms IS NULL AND TRIM(subtype) <> ''
          ORDER BY subtype ASC
          ''',
          [typeName],
        );
      } else {
        rethrow;
      }
    }
    return rows
        .map((r) => (r['subtype'] as String? ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> replaceAllCoplas(List<Copla> coplas) async {
    if (kIsWeb) {
      _webMemoryCoplas = List<Copla>.from(coplas);
      _webLastSyncAt = DateTime.now();
      await _persistWebCache();
      return;
    }
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete(_coplasTable);
      for (var i = 0; i < coplas.length; i++) {
        final c = coplas[i];
        await txn.insert(_coplasTable, {
          'type': c.type,
          'subtype': c.subtype,
          'text': c.text,
          'author': c.author,
          'source_order': i,
          'remote_id': c.remoteId,
          'updated_at_ms': c.updatedAt?.millisecondsSinceEpoch,
          'deleted_at_ms': c.deletedAt?.millisecondsSinceEpoch,
        });
      }
      await txn.insert(
        _metaTable,
        {
          'key': _metaKeyCoplasLastSync,
          'value': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> applyRemoteChanges(List<Copla> changes) async {
    if (changes.isEmpty) return;
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      final byId = <String, Copla>{};
      final withoutId = <Copla>[];
      for (final c in _webMemoryCoplas) {
        if ((c.remoteId ?? '').isEmpty) {
          withoutId.add(c);
        } else {
          byId[c.remoteId!] = c;
        }
      }

      for (final c in changes) {
        final id = c.remoteId;
        if (id == null || id.isEmpty) continue;
        if (c.deletedAt != null) {
          byId.remove(id);
        } else {
          byId[id] = c;
        }
      }
      _webMemoryCoplas = [...withoutId, ...byId.values];
      await _persistWebCache();
      return;
    }

    final db = await _database();
    await db.transaction((txn) async {
      for (final c in changes) {
        final id = c.remoteId;
        if (id == null || id.isEmpty) continue;

        if (c.deletedAt != null) {
          await txn.delete(
            _coplasTable,
            where: 'remote_id = ?',
            whereArgs: [id],
          );
          continue;
        }

        await txn.insert(
          _coplasTable,
          {
            'remote_id': c.remoteId,
            'type': c.type,
            'subtype': c.subtype,
            'text': c.text,
            'author': c.author,
            'source_order': c.updatedAt?.millisecondsSinceEpoch ?? 0,
            'updated_at_ms': c.updatedAt?.millisecondsSinceEpoch,
            'deleted_at_ms': c.deletedAt?.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        _metaTable,
        {
          'key': _metaKeyCoplasLastSync,
          'value': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<DateTime?> getCoplasLastSyncAt() async {
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      return _webLastSyncAt;
    }
    final db = await _database();
    final rows = await db.query(
      _metaTable,
      where: 'key = ?',
      whereArgs: [_metaKeyCoplasLastSync],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    final millis = int.tryParse(raw ?? '');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<DateTime?> getCoplasRemoteCursorAt() async {
    if (kIsWeb) {
      await _loadWebCacheIfNeeded();
      return _webRemoteCursorAt;
    }
    final db = await _database();
    final rows = await db.query(
      _metaTable,
      where: 'key = ?',
      whereArgs: [_metaKeyCoplasRemoteCursor],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> setCoplasRemoteCursorAt(DateTime cursor) async {
    final utc = cursor.toUtc();
    if (kIsWeb) {
      _webRemoteCursorAt = utc;
      await _persistWebCache();
      return;
    }
    final db = await _database();
    await db.insert(
      _metaTable,
      {'key': _metaKeyCoplasRemoteCursor, 'value': utc.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _loadWebCacheIfNeeded() async {
    if (!kIsWeb || _webLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_webCoplasJsonKey);
    final rawSync = prefs.getString(_webLastSyncKey);
    final rawCursor = prefs.getString(_webRemoteCursorKey);

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        _webMemoryCoplas = decoded
            .whereType<Map<String, dynamic>>()
            .map(_coplaFromJson)
            .toList();
      } catch (_) {
        _webMemoryCoplas = const [];
      }
    }

    final millis = int.tryParse(rawSync ?? '');
    _webLastSyncAt = millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
    _webRemoteCursorAt =
        rawCursor == null ? null : DateTime.tryParse(rawCursor)?.toUtc();
    _webLoaded = true;
  }

  Future<void> _persistWebCache() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _webMemoryCoplas.map(_coplaToJson).toList();
    await prefs.setString(_webCoplasJsonKey, jsonEncode(payload));
    final millis = _webLastSyncAt?.millisecondsSinceEpoch;
    if (millis != null) {
      await prefs.setString(_webLastSyncKey, millis.toString());
    }
    final cursor = _webRemoteCursorAt?.toIso8601String();
    if (cursor != null) {
      await prefs.setString(_webRemoteCursorKey, cursor);
    }
    _webLoaded = true;
  }

  static Map<String, dynamic> _coplaToJson(Copla c) => {
        'type': c.type,
        'subtype': c.subtype,
        'text': c.text,
        'author': c.author,
        'remote_id': c.remoteId,
        'updated_at': c.updatedAt?.toIso8601String(),
        'deleted_at': c.deletedAt?.toIso8601String(),
      };

  static Copla _coplaFromJson(Map<String, dynamic> json) => Copla(
        remoteId: json['remote_id'] as String?,
        type: json['type'] as String? ?? '',
        subtype: json['subtype'] as String? ?? '',
        text: json['text'] as String? ?? '',
        author: json['author'] as String?,
        updatedAt: _dateFromIso(json['updated_at']),
        deletedAt: _dateFromIso(json['deleted_at']),
      );

  static DateTime? _dateFromIso(dynamic value) {
    final raw = value as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static DateTime? _dateFromMillis(dynamic value) {
    if (value == null) return null;
    final millis = value is int ? value : int.tryParse(value.toString());
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
