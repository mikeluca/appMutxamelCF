import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';

import '../../support/http_test_helpers.dart';

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  Future<void> iniciarSesion({String token = 'token-vigente'}) {
    return AuthSession.guardarSesion(
      LoginResponse(token: token, usuarioId: 1, email: 'a@a.com', roles: const []),
    );
  }

  group('ApiClient.get sin autenticacion', () {
    test('decodifica un JSON 200 correctamente', () async {
      final resultado = await conMockHttp(
        (request) async {
          expect(request.method, 'GET');
          expect(request.url.path, contains('/app/algo'));
          return http.Response(jsonEncode({'valor': 42}), 200);
        },
        () => ApiClient.get('/app/algo'),
      );

      expect(resultado, {'valor': 42});
    });

    test('una respuesta 200 con cuerpo vacio devuelve null', () async {
      final resultado = await conMockHttp(
        (request) async => http.Response('', 200),
        () => ApiClient.get('/app/algo'),
      );

      expect(resultado, isNull);
    });

    test('no añade cabecera Authorization', () async {
      await conMockHttp(
        (request) async {
          expect(request.headers.containsKey('Authorization'), isFalse);
          return http.Response('', 200);
        },
        () => ApiClient.get('/app/publico'),
      );
    });
  });

  group('ApiClient con autenticacion', () {
    test('sin sesion iniciada lanza ApiException sin llegar a la red', () async {
      await conMockHttpQueNoDebeLlamarse(() async {
        await expectLater(
          ApiClient.get('/app/privado', autenticado: true),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('sesión activa'),
            ),
          ),
        );
      });
    });

    test('con sesion iniciada añade el token como Bearer', () async {
      await iniciarSesion(token: 'abc123');

      await conMockHttp(
        (request) async {
          expect(request.headers['Authorization'], 'Bearer abc123');
          return http.Response(jsonEncode({}), 200);
        },
        () => ApiClient.get('/app/privado', autenticado: true),
      );
    });
  });

  group('ApiClient.post/put', () {
    test('post codifica el body como JSON y fija Content-Type', () async {
      final resultado = await conMockHttp(
        (request) async {
          expect(request.method, 'POST');
          expect(request.headers['Content-Type'], contains('application/json'));
          expect(jsonDecode(request.body), {'nombre': 'Ana'});
          return http.Response(jsonEncode({'id': 1}), 201);
        },
        () => ApiClient.post('/app/cosas', body: {'nombre': 'Ana'}),
      );

      expect(resultado, {'id': 1});
    });

    test('put usa el metodo PUT', () async {
      await conMockHttp(
        (request) async {
          expect(request.method, 'PUT');
          return http.Response('', 200);
        },
        () => ApiClient.put('/app/cosas/1', body: {'nombre': 'Ana'}),
      );
    });
  });

  group('ApiClient.delete', () {
    test('usa el metodo DELETE y no manda body', () async {
      await conMockHttp(
        (request) async {
          expect(request.method, 'DELETE');
          return http.Response('', 204);
        },
        () => ApiClient.delete('/app/cosas/1'),
      );
    });
  });

  group('ApiClient ante un 401 (N-01)', () {
    test('en una peticion autenticada, cierra la sesion local', () async {
      await iniciarSesion();

      await conMockHttp(
        (request) async => http.Response(jsonEncode({'message': 'Token caducado'}), 401),
        () async {
          await expectLater(
            ApiClient.get('/app/privado', autenticado: true),
            throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
          );
        },
      );

      // La sesion local queda borrada tras el 401: si no lo estuviera,
      // la app seguiria creyendose autenticada con un token que el
      // servidor ya ha rechazado.
      expect(await AuthSession.estaAutenticado(), isFalse);
    });

    test(
      'no hace ninguna otra peticion de red al cerrar la sesion (sin bucle)',
      () async {
        await iniciarSesion();

        var llamadas = 0;

        await conMockHttp(
          (request) async {
            llamadas++;
            return http.Response('', 401);
          },
          () async {
            await expectLater(
              ApiClient.get('/app/privado', autenticado: true),
              throwsA(isA<ApiException>()),
            );
          },
        );

        // Antes de N-01, cerrar la sesion tras un 401 podia intentar
        // desregistrar el dispositivo con el mismo token ya invalido,
        // lo que el servidor volveria a rechazar con 401 y desencadenaria
        // otro cierre de sesion sin fin. Debe haber exactamente UNA
        // peticion HTTP: la original.
        expect(llamadas, 1);
      },
    );

    test('en una peticion NO autenticada, no toca la sesion local', () async {
      await iniciarSesion();

      await conMockHttp(
        (request) async => http.Response('', 401),
        () async {
          await expectLater(
            ApiClient.get('/app/publico', autenticado: false),
            throwsA(isA<ApiException>()),
          );
        },
      );

      // No habia sesion "de este 401" que cerrar: la que ya existia debe
      // seguir intacta.
      expect(await AuthSession.estaAutenticado(), isTrue);
    });
  });

  group('ApiClient ante errores de red', () {
    test('un timeout se traduce en un mensaje de servidor sin respuesta', () async {
      await conMockHttp(
        (request) async => throw TimeoutException('simulado'),
        () => expectLater(
          ApiClient.get('/app/algo'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('no responde'),
            ),
          ),
        ),
      );
    });

    test('un SocketException se traduce en "sin conexion"', () async {
      await conMockHttp(
        (request) async => throw const SocketException('simulado'),
        () => expectLater(
          ApiClient.get('/app/algo'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('conexión'),
            ),
          ),
        ),
      );
    });
  });

  group('ApiClient extrayendo el mensaje de error del backend', () {
    test('de un campo "message"', () async {
      await conMockHttp(
        (request) async => http.Response(jsonEncode({'message': 'Datos inválidos'}), 400),
        () => expectLater(
          ApiClient.post('/app/algo', body: {}),
          throwsA(
            isA<ApiException>().having((e) => e.message, 'message', 'Datos inválidos'),
          ),
        ),
      );
    });

    test('de un campo "mensaje" (backend en castellano)', () async {
      await conMockHttp(
        (request) async => http.Response(jsonEncode({'mensaje': 'No autorizado'}), 403),
        () => expectLater(
          ApiClient.post('/app/algo', body: {}),
          throwsA(
            isA<ApiException>().having((e) => e.message, 'message', 'No autorizado'),
          ),
        ),
      );
    });

    test('de un mapa de errores de validacion, uniendo los valores', () async {
      await conMockHttp(
        (request) async => http.Response(
          jsonEncode({'email': 'Email invalido', 'password': 'Muy corta'}),
          422,
        ),
        () => expectLater(
          ApiClient.post('/app/algo', body: {}),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              allOf(contains('Email invalido'), contains('Muy corta')),
            ),
          ),
        ),
      );
    });

    test('de texto plano cuando el cuerpo no es JSON', () async {
      await conMockHttp(
        (request) async => http.Response('Error interno', 500),
        () => expectLater(
          ApiClient.post('/app/algo', body: {}),
          throwsA(
            isA<ApiException>().having((e) => e.message, 'message', 'Error interno'),
          ),
        ),
      );
    });

    test('mensaje generico si el cuerpo de error viene vacio', () async {
      await conMockHttp(
        (request) async => http.Response('', 500),
        () => expectLater(
          ApiClient.post('/app/algo', body: {}),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('500'),
            ),
          ),
        ),
      );
    });
  });
}
