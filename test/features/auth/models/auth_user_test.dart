import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';

void main() {
  group('AuthUser.fromJson', () {
    test('parsea correctamente un usuario con roles', () {
      final usuario = AuthUser.fromJson({
        'usuarioId': 7,
        'email': 'entrenador@mutxamelcf.es',
        'roles': ['ENTRENADOR'],
      });

      expect(usuario.usuarioId, 7);
      expect(usuario.email, 'entrenador@mutxamelcf.es');
      expect(usuario.roles, ['ENTRENADOR']);
    });

    test('roles ausentes se convierten en lista vacia', () {
      final usuario = AuthUser.fromJson({
        'usuarioId': 7,
        'email': 'sinroles@mutxamelcf.es',
      });

      expect(usuario.roles, isEmpty);
    });
  });

  group('AuthUser.tieneRol', () {
    test('devuelve true si el rol esta entre los del usuario', () {
      final usuario = AuthUser(
        usuarioId: 1,
        email: 'familiar@mutxamelcf.es',
        roles: ['FAMILIAR', 'COORDINADOR'],
      );

      expect(usuario.tieneRol('FAMILIAR'), isTrue);
      expect(usuario.tieneRol('COORDINADOR'), isTrue);
    });

    test('devuelve false si el rol no esta entre los del usuario', () {
      final usuario = AuthUser(
        usuarioId: 1,
        email: 'familiar@mutxamelcf.es',
        roles: ['FAMILIAR'],
      );

      expect(usuario.tieneRol('ENTRENADOR'), isFalse);
    });

    test('es sensible a mayusculas/minusculas', () {
      final usuario = AuthUser(
        usuarioId: 1,
        email: 'familiar@mutxamelcf.es',
        roles: ['FAMILIAR'],
      );

      expect(usuario.tieneRol('familiar'), isFalse);
    });
  });
}
