import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:songs_folk_app/repositories/events_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  test('getEventsForMonth usa datos fallback si falla remoto', () async {
    final client = _MockSupabaseClient();
    when(() => client.from(any())).thenThrow(Exception('SocketException'));
    final repo = EventsRepository(client: client, isSupabaseConfigured: true);

    final result = await repo.getEventsForMonth(DateTime(2026, 5, 1));
    expect(result, isNotEmpty);
    expect(result.first.title, isNotEmpty);
  });

  test('getEventsForMonth tolera payload roto y mantiene fallback local', () async {
    final client = _MockSupabaseClient();
    when(
      () => client.from(any()),
    ).thenThrow(Exception('PostgrestException: unexpected payload shape'));
    final repo = EventsRepository(client: client, isSupabaseConfigured: true);

    final result = await repo.getEventsForMonth(DateTime(2026, 7, 1));
    expect(result, isNotEmpty);
    expect(result.every((event) => event.title.trim().isNotEmpty), isTrue);
  });
}
