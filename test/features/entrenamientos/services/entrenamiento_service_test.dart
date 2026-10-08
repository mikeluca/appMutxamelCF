import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/services/entrenamiento_service.dart';

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

  group('EntrenamientoService.obtenerPorEquipo', () {
    test('sin rango pide solo el equipo', () async {
      late http.Request recibida;

      await conMockHttp((request) async {
        recibida = request;
        return http.Response('[]', 200);
      }, () => EntrenamientoService().obtenerPorEquipo(7));

      expect(recibida.url.queryParameters, {'equipoId': '7'});
    });

    test('con rango envia desde y hasta como yyyy-MM-dd', () async {
      late http.Request recibida;

      await conMockHttp(
        (request) async {
          recibida = request;
          return http.Response('[]', 200);
        },
        () => EntrenamientoService().obtenerPorEquipo(
          7,
          desde: DateTime(2026, 10, 8),
          hasta: DateTime(2026, 10, 22),
        ),
      );

      expect(recibida.url.queryParameters, {
        'equipoId': '7',
        'desde': '2026-10-08',
        'hasta': '2026-10-22',
      });
    });

    test('solo hasta (entrenamientos pasados) omite desde', () async {
      late http.Request recibida;

      await conMockHttp(
        (request) async {
          recibida = request;
          return http.Response('[]', 200);
        },
        () => EntrenamientoService().obtenerPorEquipo(
          7,
          hasta: DateTime(2026, 1, 5),
        ),
      );

      expect(recibida.url.queryParameters, {
        'equipoId': '7',
        'hasta': '2026-01-05',
      });
    });
  });
}
