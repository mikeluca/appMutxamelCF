import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_service.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';

import '../../../support/http_test_helpers.dart';

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
    // El idioma que la app muestra viaja en las peticiones de acceso.
    SharedPreferences.setMockInitialValues({'idioma_aplicacion': 'ca'});
  });

  group('AuthService.login', () {
    test('con credenciales validas, devuelve el LoginResponse', () async {
      final resultado = await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/auth/login'));
          expect(jsonDecode(request.body), {
            'email': 'usuario@mutxamelcf.es',
            'password': 'clave123',
            'idioma': 'ca',
          });

          return http.Response(
            jsonEncode({
              'token': 'jwt-abc',
              'usuarioId': 5,
              'email': 'usuario@mutxamelcf.es',
              'roles': ['FAMILIAR'],
            }),
            200,
          );
        },
        () => AuthService.login(
          email: 'Usuario@MutxamelCF.es',
          password: 'clave123',
        ),
      );

      expect(resultado.token, 'jwt-abc');
      expect(resultado.usuarioId, 5);
      // El backend ya conoce ese idioma: al arrancar no hace falta repetirlo.
      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), 'ca');
    });

    test('con credenciales incorrectas no anota el idioma como enviado', () async {
      await conMockHttp(
        (request) async => http.Response('', 401),
        () => expectLater(
          AuthService.login(email: 'a@a.com', password: 'mala'),
          throwsA(isA<Exception>()),
        ),
      );

      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), isNull);
    });

    test('normaliza el email a minusculas y sin espacios', () async {
      await conMockHttp(
        (request) async {
          expect(jsonDecode(request.body)['email'], 'usuario@mutxamelcf.es');
          return http.Response(
            jsonEncode({'token': 't', 'usuarioId': 1, 'email': 'e', 'roles': []}),
            200,
          );
        },
        () => AuthService.login(email: '  Usuario@MutxamelCF.es  ', password: 'x'),
      );
    });

    test('con credenciales incorrectas (401), lanza un mensaje claro', () async {
      await conMockHttp(
        (request) async => http.Response('', 401),
        () => expectLater(
          AuthService.login(email: 'a@a.com', password: 'mala'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains('Email o contraseña incorrectos'),
            ),
          ),
        ),
      );
    });

    test('con cuenta no activa (403), lanza un mensaje claro', () async {
      await conMockHttp(
        (request) async => http.Response('', 403),
        () => expectLater(
          AuthService.login(email: 'a@a.com', password: 'x'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains('cuenta no está activa'),
            ),
          ),
        ),
      );
    });

    test('ante otro error del servidor, propaga la excepcion original', () async {
      await conMockHttp(
        (request) async => http.Response('', 500),
        () => expectLater(
          AuthService.login(email: 'a@a.com', password: 'x'),
          throwsA(isA<Exception>()),
        ),
      );
    });
  });

  group('AuthService.obtenerUsuarioActual', () {
    test('pide /app/auth/me autenticado y mapea la respuesta', () async {
      await AuthSession.guardarSesion(
        LoginResponse(token: 'tok', usuarioId: 1, email: 'a@a.com', roles: const []),
      );

      final usuario = await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/auth/me'));
          expect(request.headers['Authorization'], 'Bearer tok');

          return http.Response(
            jsonEncode({
              'usuarioId': 9,
              'email': 'entrenador@mutxamelcf.es',
              'roles': ['ENTRENADOR'],
            }),
            200,
          );
        },
        () => AuthService.obtenerUsuarioActual(),
      );

      expect(usuario.usuarioId, 9);
      expect(usuario.tieneRol('ENTRENADOR'), isTrue);
    });
  });

  group('AuthService.recuperarPassword y restablecerPassword', () {
    test('recuperar manda el idioma, pero no lo anota como enviado', () async {
      await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/auth/recuperar'));
          expect(jsonDecode(request.body), {
            'email': 'ana@mutxamelcf.es',
            'idioma': 'ca',
          });

          return http.Response('', 204);
        },
        () => AuthService.recuperarPassword(email: ' Ana@MutxamelCF.es '),
      );

      // Es una petición sin sesión: el backend no guarda ese idioma.
      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), isNull);
    });

    test('restablecer manda el idioma y, al iniciar sesión, lo anota como enviado', () async {
      await AppPreferences.guardarIdioma('en');

      await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/auth/restablecer'));
          expect(jsonDecode(request.body)['idioma'], 'en');

          return http.Response(
            jsonEncode({'token': 't', 'usuarioId': 3, 'email': 'a@a.com', 'roles': []}),
            200,
          );
        },
        () => AuthService.restablecerPassword(
          email: 'a@a.com',
          codigo: '123456',
          password: 'nueva-clave-1',
        ),
      );

      expect(await AppPreferences.obtenerUltimoIdiomaEnviado(), 'en');
    });
  });

  group('AuthService.activarCuenta', () {
    test('activa la cuenta y devuelve la sesion iniciada', () async {
      final resultado = await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/auth/activar'));
          final body = jsonDecode(request.body);
          expect(body['email'], 'nuevo@mutxamelcf.es');
          expect(body['codigo'], '123456');
          expect(body['idioma'], 'ca');

          return http.Response(
            jsonEncode({'token': 't', 'usuarioId': 3, 'email': 'nuevo@mutxamelcf.es', 'roles': []}),
            200,
          );
        },
        () => AuthService.activarCuenta(
          email: '  Nuevo@MutxamelCF.es  ',
          codigo: ' 123456 ',
          password: 'nuevaClave',
        ),
      );

      expect(resultado.usuarioId, 3);
    });

    test('si el codigo ya se uso (409), propaga el mensaje del backend', () async {
      await conMockHttp(
        (request) async => http.Response(jsonEncode({'message': 'Código ya utilizado'}), 409),
        () => expectLater(
          AuthService.activarCuenta(email: 'a@a.com', codigo: '000000', password: 'x'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains('Código ya utilizado'),
            ),
          ),
        ),
      );
    });
  });
}
