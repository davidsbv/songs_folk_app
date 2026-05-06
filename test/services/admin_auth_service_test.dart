import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:songs_folk_app/services/admin_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _TestAdminAuthService extends AdminAuthService {
  _TestAdminAuthService({
    required SupabaseClient client,
    required this.adminAccess,
  }) : super.withDependencies(client: client, isSupabaseConfigured: true);

  final bool adminAccess;

  @override
  Future<bool> hasAdminAccess() async => adminAccess;
}

void main() {
  group('AdminAuthService', () {
    test('lanza error si Supabase no está configurado', () async {
      final service = AdminAuthService.withDependencies(
        isSupabaseConfigured: false,
      );

      expect(
        () => service.signInAdmin(email: 'admin@test.com', password: 'secret'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('Supabase no está configurado'),
          ),
        ),
      );
    });

    test('mapea errores de red a mensaje amigable', () async {
      final client = _MockSupabaseClient();
      final auth = _MockGoTrueClient();
      when(() => client.auth).thenReturn(auth);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final service = _TestAdminAuthService(client: client, adminAccess: true);

      expect(
        () => service.signInAdmin(email: 'admin@test.com', password: 'secret'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('No hay conexión con Supabase'),
          ),
        ),
      );
    });
  });
}
