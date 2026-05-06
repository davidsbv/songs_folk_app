import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/copla.dart';
import 'package:songs_folk_app/services/coplas_local_store.dart';

void main() {
  final store = CoplasLocalStore();

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() async {
    await store.replaceAllCoplas(const []);
    await store.setCoplasRemoteCursorAt(DateTime.utc(2020, 1, 1));
  });

  test('primer sync en limpio persiste snapshot y metadatos', () async {
    final snapshot = [
      Copla(
        remoteId: 'c1',
        type: 'JOTA',
        subtype: 'MAYO',
        text: 'Copla inicial',
        updatedAt: DateTime.utc(2026, 5, 1, 10, 0),
      ),
      Copla(
        remoteId: 'c2',
        type: 'SEGUIDILLA',
        subtype: 'RONDA',
        text: 'Otra copla',
        updatedAt: DateTime.utc(2026, 5, 1, 10, 5),
      ),
    ];

    await store.replaceAllCoplas(snapshot);

    final jotas = await store.getCoplasByType('JOTA');
    final seguidillas = await store.getCoplasByType('SEGUIDILLA');
    final lastSyncAt = await store.getCoplasLastSyncAt();
    final types = await store.getCachedCoplaTypes();

    expect(jotas.length, 1);
    expect(jotas.first.text, 'Copla inicial');
    expect(seguidillas.length, 1);
    expect(lastSyncAt, isNotNull);
    expect(types, containsAll(['JOTA', 'SEGUIDILLA']));
  });

  test('sync incremental aplica altas y ediciones sin perder caché', () async {
    await store.replaceAllCoplas([
      Copla(
        remoteId: 'c1',
        type: 'JOTA',
        subtype: 'MAYO',
        text: 'Versión v1',
        updatedAt: DateTime.utc(2026, 5, 1, 9, 0),
      ),
    ]);
    await store.setCoplasRemoteCursorAt(DateTime.utc(2026, 5, 1, 9, 0));

    await store.applyRemoteChanges([
      Copla(
        remoteId: 'c1',
        type: 'JOTA',
        subtype: 'MAYO',
        text: 'Versión v2',
        updatedAt: DateTime.utc(2026, 5, 1, 9, 30),
      ),
      Copla(
        remoteId: 'c3',
        type: 'JOTA',
        subtype: 'ENTRADA',
        text: 'Nueva incremental',
        updatedAt: DateTime.utc(2026, 5, 1, 9, 45),
      ),
    ]);
    await store.setCoplasRemoteCursorAt(DateTime.utc(2026, 5, 1, 9, 45));

    final jotas = await store.getCoplasByType('JOTA');
    final cursor = await store.getCoplasRemoteCursorAt();
    final byId = {for (final item in jotas) item.remoteId: item};

    expect(jotas.length, 2);
    expect(byId['c1']?.text, 'Versión v2');
    expect(byId['c3']?.text, 'Nueva incremental');
    expect(cursor, DateTime.utc(2026, 5, 1, 9, 45));
  });

  test('sync incremental elimina cache local en borrado lógico', () async {
    await store.replaceAllCoplas([
      Copla(
        remoteId: 'c10',
        type: 'JOTA',
        subtype: 'MAYO',
        text: 'Se borrará',
        updatedAt: DateTime.utc(2026, 5, 1, 8, 0),
      ),
    ]);

    await store.applyRemoteChanges([
      Copla(
        remoteId: 'c10',
        type: 'JOTA',
        subtype: 'MAYO',
        text: 'Se borrará',
        updatedAt: DateTime.utc(2026, 5, 1, 10, 0),
        deletedAt: DateTime.utc(2026, 5, 1, 10, 0),
      ),
    ]);

    final jotas = await store.getCoplasByType('JOTA');
    final subtypes = await store.getCachedCoplaSubtypesByType('JOTA');

    expect(jotas, isEmpty);
    expect(subtypes, isEmpty);
  });
}
