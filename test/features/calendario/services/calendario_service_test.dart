import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/calendario/services/calendario_service.dart';

import '../../../support/http_test_helpers.dart';

void main() {
  setUp(() async {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});

    await AuthSession.guardarSesion(
      LoginResponse(token: 'tok', usuarioId: 1, email: 'a@a.com', roles: const []),
    );
  });

  final service = CalendarioService();

  group('CalendarioService.obtenerTemporadaActiva', () {
    test('sin temporada activa (404), devuelve null en vez de lanzar', () async {
      final resultado = await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/temporadas/activa'));
          return http.Response('', 404);
        },
        () => service.obtenerTemporadaActiva(),
      );

      expect(resultado, isNull);
    });

    test('con temporada activa, mapea la fecha de inicio', () async {
      final resultado = await conMockHttp(
        (request) async => http.Response(
          jsonEncode({'id': 1, 'nombre': '2026/2027', 'fechaInicio': '2026-09-01'}),
          200,
        ),
        () => service.obtenerTemporadaActiva(),
      );

      expect(resultado?.fechaInicio, DateTime(2026, 9, 1));
    });
  });

  group('CalendarioService.obtenerCalendario', () {
    test('formatea desde/hasta como yyyy-MM-dd', () async {
      await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/calendario'));
          expect(request.url.queryParameters['equipoId'], '3');
          expect(request.url.queryParameters['desde'], '2026-01-05');
          expect(request.url.queryParameters['hasta'], '2026-03-09');
          expect(request.url.queryParameters.containsKey('jugadorId'), isFalse);

          return http.Response(jsonEncode({'sesiones': [], 'partidos': []}), 200);
        },
        () => service.obtenerCalendario(
          equipoId: 3,
          desde: DateTime(2026, 1, 5),
          hasta: DateTime(2026, 3, 9),
        ),
      );
    });

    test('incluye jugadorId cuando se indica', () async {
      await conMockHttp(
        (request) async {
          expect(request.url.queryParameters['jugadorId'], '77');
          return http.Response(jsonEncode({'sesiones': [], 'partidos': []}), 200);
        },
        () => service.obtenerCalendario(
          equipoId: 3,
          desde: DateTime(2026, 1, 1),
          hasta: DateTime(2026, 1, 2),
          jugadorId: 77,
        ),
      );
    });
  });

  group('CalendarioService.crearSesion', () {
    test('envia la fecha formateada y los datos de la sesion', () async {
      await conMockHttp(
        (request) async {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body);
          expect(body['equipoId'], 3);
          expect(body['fecha'], '2026-05-20');
          expect(body['hora'], '18:00');

          return http.Response(
            jsonEncode({
              'id': 1,
              'equipoId': 3,
              'equipo': 'Alevín A',
              'fecha': '2026-05-20',
              'hora': '18:00',
              'estado': 'PROGRAMADA',
            }),
            201,
          );
        },
        () => service.crearSesion(
          equipoId: 3,
          fecha: DateTime(2026, 5, 20),
          hora: '18:00',
        ),
      );
    });
  });

  group('CalendarioService.cancelarSesion', () {
    test('envia el motivo al endpoint de cancelacion', () async {
      await conMockHttp(
        (request) async {
          expect(request.url.path, contains('/app/sesiones-entrenamiento/9/cancelar'));
          expect(jsonDecode(request.body), {'motivo': 'Lluvia'});
          return http.Response('', 200);
        },
        () => service.cancelarSesion(9, 'Lluvia'),
      );
    });
  });
}
