import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';

void main() {
  // AuthSession usa un FlutterSecureStorage estatico; se sustituye el
  // backend de plataforma por el fake que el propio paquete
  // flutter_secure_storage distribuye para pruebas (en memoria), sin
  // tocar canales de plataforma reales.
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  LoginResponse loginDeEjemplo({
    String token = 'token-abc',
    int usuarioId = 42,
    String email = 'familiar@mutxamelcf.es',
    List<String> roles = const ['FAMILIAR', 'JUGADOR'],
  }) {
    return LoginResponse(
      token: token,
      usuarioId: usuarioId,
      email: email,
      roles: roles,
    );
  }

  group('AuthSession sin sesion guardada', () {
    test('estaAutenticado es false', () async {
      expect(await AuthSession.estaAutenticado(), isFalse);
    });

    test('obtenerToken/obtenerUsuarioId/obtenerEmail son null', () async {
      expect(await AuthSession.obtenerToken(), isNull);
      expect(await AuthSession.obtenerUsuarioId(), isNull);
      expect(await AuthSession.obtenerEmail(), isNull);
    });

    test('obtenerRoles devuelve una lista vacia', () async {
      expect(await AuthSession.obtenerRoles(), isEmpty);
    });
  });

  group('AuthSession.guardarSesion', () {
    test('persiste token, usuarioId, email y roles', () async {
      await AuthSession.guardarSesion(loginDeEjemplo());

      expect(await AuthSession.obtenerToken(), 'token-abc');
      expect(await AuthSession.obtenerUsuarioId(), 42);
      expect(await AuthSession.obtenerEmail(), 'familiar@mutxamelcf.es');
      expect(await AuthSession.obtenerRoles(), ['FAMILIAR', 'JUGADOR']);
      expect(await AuthSession.estaAutenticado(), isTrue);
    });

    test('una sesion nueva sustituye a la anterior', () async {
      await AuthSession.guardarSesion(loginDeEjemplo(usuarioId: 1, email: 'a@a.com'));
      await AuthSession.guardarSesion(loginDeEjemplo(usuarioId: 2, email: 'b@b.com'));

      expect(await AuthSession.obtenerUsuarioId(), 2);
      expect(await AuthSession.obtenerEmail(), 'b@b.com');
    });
  });

  group('AuthSession.cerrarSesion', () {
    test('borra token, usuarioId, email y roles', () async {
      await AuthSession.guardarSesion(loginDeEjemplo());

      await AuthSession.cerrarSesion();

      expect(await AuthSession.obtenerToken(), isNull);
      expect(await AuthSession.obtenerUsuarioId(), isNull);
      expect(await AuthSession.obtenerEmail(), isNull);
      expect(await AuthSession.obtenerRoles(), isEmpty);
      expect(await AuthSession.estaAutenticado(), isFalse);
    });

    test('no lanza excepcion si no habia sesion guardada', () async {
      await expectLater(AuthSession.cerrarSesion(), completes);
    });
  });

  group('AuthSession.estaAutenticado', () {
    test('es false si el token guardado es una cadena vacia', () async {
      await AuthSession.guardarSesion(loginDeEjemplo(token: ''));

      expect(await AuthSession.estaAutenticado(), isFalse);
    });
  });
}
