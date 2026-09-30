import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';

import '../../../support/http_test_helpers.dart';

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  group('AuthManager.cerrarSesion(desregistrarDispositivo: false)', () {
    // N-01: esta es la rama que usa ApiClient cuando un 401 indica que el
    // token ya no es valido. NO debe intentar avisar al backend (eso
    // volveria a dar 401 con el mismo token y desencadenaria otro
    // cierre de sesion sin fin), por eso puede probarse sin mockear
    // Firebase/HTTP en absoluto: solo debe tocar el almacen local.
    test('borra la sesion local y el usuario actual', () async {
      await AuthSession.guardarSesion(
        LoginResponse(token: 'tok', usuarioId: 1, email: 'a@a.com', roles: const []),
      );
      await AuthManager.establecerUsuario(_usuarioDePrueba());

      await AuthManager.cerrarSesion(desregistrarDispositivo: false);

      expect(await AuthSession.estaAutenticado(), isFalse);
      expect(AuthManager.estaAutenticado, isFalse);
      expect(AuthManager.usuarioActual, isNull);
    });

    test('no lanza excepcion aunque no hubiera sesion previa', () async {
      await expectLater(
        AuthManager.cerrarSesion(desregistrarDispositivo: false),
        completes,
      );
    });
  });

  group('AuthManager.establecerUsuario / usuarioActual', () {
    test('fija el usuario actual y estaAutenticado pasa a true', () async {
      final usuario = _usuarioDePrueba();

      await AuthManager.establecerUsuario(usuario);

      expect(AuthManager.usuarioActual, usuario);
      expect(AuthManager.estaAutenticado, isTrue);

      // Se limpia para no filtrar estado (AuthManager es un singleton
      // estatico) a otros tests de este archivo.
      await AuthManager.cerrarSesion(desregistrarDispositivo: false);
    });
  });

  group('AuthManager.restaurarSesion', () {
    test('sin token guardado, devuelve false y no hay usuario actual', () async {
      final restaurada = await AuthManager.restaurarSesion();

      expect(restaurada, isFalse);
      expect(AuthManager.usuarioActual, isNull);
    });

    test('con token valido, carga el usuario y devuelve true', () async {
      await AuthSession.guardarSesion(
        LoginResponse(token: 'tok-valido', usuarioId: 1, email: 'a@a.com', roles: const []),
      );

      final restaurada = await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/auth/me'));
          return http.Response(
            jsonEncode({'usuarioId': 7, 'email': 'a@a.com', 'roles': ['JUGADOR']}),
            200,
          );
        },
        () => AuthManager.restaurarSesion(),
      );

      expect(restaurada, isTrue);
      expect(AuthManager.usuarioActual?.usuarioId, 7);

      await AuthManager.cerrarSesion(desregistrarDispositivo: false);
    });

    test(
      'con token que el servidor ya no acepta, no deja al usuario '
      'autenticado pero SIN borrar el token guardado (FL-03)',
      () async {
        // FL-03: si el fallo es un 401, es ApiClient quien ya limpia la
        // sesion (ver api_client_test.dart); si el fallo es de red, el
        // token puede seguir siendo valido y no hay que expulsar al
        // usuario solo por abrir la app sin cobertura. Aqui se simula
        // ese segundo caso con un error que NO es un 401.
        await AuthSession.guardarSesion(
          LoginResponse(token: 'tok', usuarioId: 1, email: 'a@a.com', roles: const []),
        );

        final restaurada = await conMockHttp(
          (request) async => http.Response('', 500),
          () => AuthManager.restaurarSesion(),
        );

        expect(restaurada, isFalse);
        expect(AuthManager.usuarioActual, isNull);
        expect(
          await AuthSession.obtenerToken(),
          'tok',
          reason: 'un fallo que no es 401 no debe borrar el token guardado',
        );
      },
    );
  });
}

AuthUser _usuarioDePrueba() {
  return AuthUser(usuarioId: 1, email: 'a@a.com', roles: const []);
}
