import 'dart:convert';

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/auth/services/idioma_service.dart';

import '../../../support/http_test_helpers.dart';

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> iniciarSesion() {
    return AuthSession.guardarSesion(
      LoginResponse(
        token: 'tok-sesion',
        usuarioId: 1,
        email: 'a@a.com',
        roles: const [],
      ),
    );
  }

  group('IdiomaService.enviar', () {
    test('sin sesión no hace ninguna petición', () async {
      await conMockHttpQueNoDebeLlamarse(() => IdiomaService.enviar('ca'));

      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), isNull);
    });

    test('con sesión hace PUT /app/preferencias/idioma y anota el idioma enviado', () async {
      await iniciarSesion();

      await conMockHttp(
        (request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, contains('/app/preferencias/idioma'));
          expect(request.headers['Authorization'], 'Bearer tok-sesion');
          expect(jsonDecode(request.body), {'idioma': 'ca'});

          return http.Response(jsonEncode({'idioma': 'ca'}), 200);
        },
        () => IdiomaService.enviar('ca'),
      );

      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), 'ca');
    });
  });

  group('IdiomaService.alCambiarIdioma', () {
    test('si la llamada falla no lanza y no anota el idioma como enviado', () async {
      await iniciarSesion();

      await conMockHttp(
        (request) async => http.Response('', 500),
        () => IdiomaService.alCambiarIdioma('en'),
      );

      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), isNull);
    });

    test('si no hay red tampoco lanza', () async {
      await iniciarSesion();

      await conMockHttp(
        (request) async => throw http.ClientException('sin red'),
        () => IdiomaService.alCambiarIdioma('en'),
      );
    });
  });

  group('IdiomaService.sincronizarAlArrancar', () {
    test('sin sesión no hace nada', () async {
      await AppPreferences.guardarIdioma('ca');

      await conMockHttpQueNoDebeLlamarse(IdiomaService.sincronizarAlArrancar);
    });

    test('si el idioma no ha cambiado desde el último envío, no repite la llamada', () async {
      await iniciarSesion();
      await AppPreferences.guardarIdioma('ca');
      await AppPreferences.guardarUltimoIdiomaEnviado('ca');

      await conMockHttpQueNoDebeLlamarse(IdiomaService.sincronizarAlArrancar);
    });

    test('si ha cambiado (p. ej. el idioma del móvil), lo envía y lo anota', () async {
      await iniciarSesion();
      await AppPreferences.guardarIdioma('en');
      await AppPreferences.guardarUltimoIdiomaEnviado('es');

      var llamadas = 0;

      await conMockHttp(
        (request) async {
          llamadas++;
          expect(jsonDecode(request.body), {'idioma': 'en'});

          return http.Response(jsonEncode({'idioma': 'en'}), 200);
        },
        IdiomaService.sincronizarAlArrancar,
      );

      expect(llamadas, 1);
      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), 'en');
    });

    test('si nunca se ha enviado, lo envía', () async {
      await iniciarSesion();

      var llamadas = 0;

      await conMockHttp((request) async {
        llamadas++;
        return http.Response('{}', 200);
      }, IdiomaService.sincronizarAlArrancar);

      expect(llamadas, 1);
    });

    test('si falla no bloquea y se reintenta en el siguiente arranque', () async {
      await iniciarSesion();
      await AppPreferences.guardarIdioma('ca');
      await AppPreferences.guardarUltimoIdiomaEnviado('es');

      await conMockHttp(
        (request) async => http.Response('', 503),
        IdiomaService.sincronizarAlArrancar,
      );

      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), 'es');

      var reintento = 0;

      await conMockHttp((request) async {
        reintento++;
        return http.Response('{}', 200);
      }, IdiomaService.sincronizarAlArrancar);

      expect(reintento, 1);
      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), 'ca');
    });
  });
}
