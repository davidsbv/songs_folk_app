import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/app_appearance.dart';

/// Lectura publica y escritura admin de la tabla `app_appearance`.
class AppAppearanceRepository {
  AppAppearanceRepository._();

  static final AppAppearanceRepository _instance = AppAppearanceRepository._();

  factory AppAppearanceRepository() => _instance;

  SupabaseClient? get _client =>
      isSupabaseConfigured ? Supabase.instance.client : null;

  Future<AppAppearance> fetchPublic() async {
    final client = _client;
    if (client == null) return AppAppearance.fallback;

    try {
      final row = await client.from('app_appearance').select().eq('id', 1).maybeSingle();
      if (row == null) return AppAppearance.fallback;
      return AppAppearance.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return AppAppearance.fallback;
    }
  }

  Future<void> upsert(AppAppearance appearance) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado.');
    }
    await client.from('app_appearance').upsert(appearance.toRemoteUpsert());
  }
}
