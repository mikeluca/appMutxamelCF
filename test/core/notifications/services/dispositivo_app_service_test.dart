import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'package:app_mutxamel_cf/core/notifications/services/dispositivo_app_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';

import '../../../support/http_test_helpers.dart';

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  Future<void> iniciarSesion() {
    return AuthSession.guardarSesion(
      LoginResponse(token: 'tok-sesion', usuarioId: 1, email: 'a@a.com', roles: const []),
    );
  }

  group('DispositivoAppService.registrar', () {
    test('sin sesion iniciada, no hace ninguna peticion (no-op)', () async {
      await conMockHttpQueNoDebeLlamarse(
        () => DispositivoAppService.registrar(
          tokenFcm: 'fcm-token',
          plataforma: 'ANDROID',
        ),
      );
    });

    test('con sesion iniciada, hace POST /app/dispositivos con el token y la plataforma', () async {
      await iniciarSesion();

      await conMockHttp(
        (request) async {
          expect(request.method, 'POST');
          expect(request.url.path, contains('/app/dispositivos'));
          expect(request.headers['Authorization'], 'Bearer tok-sesion');
          expect(jsonDecode(request.body), {
            'tokenFcm': 'fcm-token',
            'plataforma': 'ANDROID',
          });

          return http.Response('', 200);
        },
        () => DispositivoAppService.registrar(
          tokenFcm: 'fcm-token',
          plataforma: 'ANDROID',
        ),
      );
    });
  });

  group('DispositivoAppService.desactivar', () {
    test('sin sesion iniciada, no hace ninguna peticion (no-op)', () async {
      await conMockHttpQueNoDebeLlamarse(
        () => DispositivoAppService.desactivar('fcm-token'),
      );
    });

    test('con sesion iniciada, hace DELETE con el token codificado en la URL', () async {
      await iniciarSesion();

      await conMockHttp(
        (request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, contains('/app/dispositivos'));
          expect(request.url.queryParameters['tokenFcm'], 'token con espacios/y+símbolos');
          expect(request.headers['Authorization'], 'Bearer tok-sesion');

          return http.Response('', 204);
        },
        () => DispositivoAppService.desactivar('token con espacios/y+símbolos'),
      );
    });
  });
}
