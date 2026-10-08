import 'dart:convert';

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_service.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/auth/services/comunicacion_service.dart';

import '../../../support/http_test_helpers.dart';

void main() {
  setUp(() async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );

    await AuthSession.guardarSesion(
      LoginResponse(
        token: 'tok',
        usuarioId: 5,
        email: 'a@a.com',
        roles: const [],
      ),
    );
  });

  group('AuthService.eliminarCuenta', () {
    test(
      'envia DELETE /app/auth/cuenta con la contrasena y el token',
      () async {
        late http.Request recibida;

        await conMockHttp((request) async {
          recibida = request;
          return http.Response('', 204);
        }, () => AuthService.eliminarCuenta(password: 'clave123'));

        expect(recibida.method, 'DELETE');
        expect(recibida.url.path, endsWith('/app/auth/cuenta'));
        expect(recibida.headers['Authorization'], 'Bearer tok');
        expect(jsonDecode(recibida.body), {'password': 'clave123'});
      },
    );

    test('con contrasena incorrecta lanza ApiException 400', () async {
      await conMockHttp(
        (request) async => http.Response('La contraseña no es correcta', 400),
        () => expectLater(
          AuthService.eliminarCuenta(password: 'mala'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
          ),
        ),
      );
    });

    test('con demasiados intentos lanza ApiException 429', () async {
      await conMockHttp(
        (request) async => http.Response('Demasiados intentos', 429),
        () => expectLater(
          AuthService.eliminarCuenta(password: 'x'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 429),
          ),
        ),
      );
    });
  });

  group('ComunicacionService.reportarComunicacion', () {
    test('envia POST con el motivo recortado', () async {
      late http.Request recibida;

      await conMockHttp(
        (request) async {
          recibida = request;
          return http.Response('', 204);
        },
        () =>
            ComunicacionService.reportarComunicacion(40, motivo: '  Insultos '),
      );

      expect(recibida.method, 'POST');
      expect(recibida.url.path, endsWith('/app/comunicaciones/40/reportar'));
      expect(recibida.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(recibida.body), {'motivo': 'Insultos'});
    });

    test('sin motivo no envia el campo', () async {
      late http.Request recibida;

      await conMockHttp((request) async {
        recibida = request;
        return http.Response('', 204);
      }, () => ComunicacionService.reportarComunicacion(40, motivo: '   '));

      expect(jsonDecode(recibida.body), <String, dynamic>{});
    });

    test('propaga el error del servidor', () async {
      await conMockHttp(
        (request) async => http.Response('No tienes permiso', 403),
        () => expectLater(
          ComunicacionService.reportarComunicacion(40),
          throwsA(isA<ApiException>()),
        ),
      );
    });
  });
}
