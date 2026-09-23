import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';

void main() {
  group('LoginResponse.fromJson', () {
    test('parsea correctamente una respuesta completa', () {
      final response = LoginResponse.fromJson({
        'token': 'un-token-jwt',
        'usuarioId': 42,
        'email': 'jugador@mutxamelcf.es',
        'roles': ['JUGADOR', 'FAMILIAR'],
      });

      expect(response.token, 'un-token-jwt');
      expect(response.usuarioId, 42);
      expect(response.email, 'jugador@mutxamelcf.es');
      expect(response.roles, ['JUGADOR', 'FAMILIAR']);
    });

    test('roles ausentes se convierten en lista vacia', () {
      final response = LoginResponse.fromJson({
        'token': 'un-token-jwt',
        'usuarioId': 1,
        'email': 'sinroles@mutxamelcf.es',
      });

      expect(response.roles, isEmpty);
    });

    test('roles null se convierten en lista vacia', () {
      final response = LoginResponse.fromJson({
        'token': 'un-token-jwt',
        'usuarioId': 1,
        'email': 'sinroles@mutxamelcf.es',
        'roles': null,
      });

      expect(response.roles, isEmpty);
    });
  });
}
