import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

abstract class AdminAuthGateway {
  Future<void> signInAdmin({
    required String email,
    required String password,
  });
}

class AdminAuthService implements AdminAuthGateway {
  AdminAuthService._({
    SupabaseClient? clientOverride,
    bool? isSupabaseConfiguredOverride,
  }) : _clientOverride = clientOverride,
       _isSupabaseConfiguredOverride = isSupabaseConfiguredOverride;

  static final AdminAuthService _instance = AdminAuthService._();

  factory AdminAuthService() => _instance;

  AdminAuthService.withDependencies({
    SupabaseClient? client,
    bool? isSupabaseConfigured,
  }) : this._(
         clientOverride: client,
         isSupabaseConfiguredOverride: isSupabaseConfigured,
       );

  final SupabaseClient? _clientOverride;
  final bool? _isSupabaseConfiguredOverride;

  SupabaseClient? get _client =>
      _clientOverride ??
      ((_isSupabaseConfiguredOverride ?? isSupabaseConfigured)
          ? Supabase.instance.client
          : null);

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado.');
    }
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      final ok = await hasAdminAccess();
      if (!ok) {
        await client.auth.signOut();
        throw Exception('Usuario autenticado sin permisos de administrador.');
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('Failed host lookup') ||
          message.contains('SocketException') ||
          message.contains('No address associated with hostname')) {
        throw Exception(
          'No hay conexión con Supabase (error DNS/red). Verifica Internet en el móvil e inténtalo de nuevo.',
        );
      }
      rethrow;
    }
  }

  Future<bool> hasAdminAccess() async {
    final client = _client;
    if (client == null) return false;
    final user = client.auth.currentUser;
    if (user == null) return false;

    final row = await client
        .from('admin_users')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();
    return row != null;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }
}
