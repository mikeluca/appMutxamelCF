import 'dart:convert';

import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/topics_anonimos.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/directo/services/seguir_partido_service.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/http_test_helpers.dart';

/// Al iniciar y al cerrar sesión se sincronizan los partidos seguidos (sin esperar a que termine y sin que un fallo
/// rompa el acceso), para no recibir avisos duplicados si la cuenta ya tiene activados los resultados.
void main() {
  late Map<int, DateTime> guardados;
  late List<String> bajas;
  late bool? recibe;
  late int lecturas;
  late bool falla;

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );
    SharedPreferences.setMockInitialValues({});

    guardados = {7: DateTime.now()};
    bajas = [];
    recibe = false;
    lecturas = 0;
    falla = false;

    PushNotificationService.seguirPartidos = SeguirPartidoService(
      suscribir: (_) async {},
      desuscribir: (topic) async => bajas.add(topic),
      obtenerIdioma: () async => 'es',
      leer: () async {
        lecturas++;

        if (falla) throw Exception('sin disco');

        return Map.of(guardados);
      },
      guardar: (seguidos) async {
        guardados
          ..clear()
          ..addAll(seguidos);
      },
      recibeResultados: () async => recibe,
    );
    PushNotificationService.topicsAnonimos = TopicsAnonimos(
      suscribir: (_) async {},
      desuscribir: (_) async {},
    );

    AuthManager.olvidarUsuario();
  });

  tearDown(AuthManager.olvidarUsuario);

  /// Deja correr lo que el acceso lanza sin esperar.
  Future<void> dejarCorrer() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> iniciarSesion() => conMockHttp(
    (request) async {
      return http.Response(
        jsonEncode({
          'usuarioId': 7,
          'email': 'a@a.com',
          'roles': ['JUGADOR'],
        }),
        200,
      );
    },
    () async {
      await AuthManager.completarAcceso(
        LoginResponse(
          token: 'tok',
          usuarioId: 7,
          email: 'a@a.com',
          roles: const [],
        ),
      );
    },
  );

  group('al iniciar sesión', () {
    test('sincroniza los partidos seguidos', () async {
      await iniciarSesion();
      await dejarCorrer();

      expect(lecturas, greaterThan(0));
      expect(AuthManager.estaAutenticado, isTrue);
    });

    test(
      'si la cuenta ya recibe los resultados, se da de baja de los partidos seguidos',
      () async {
        recibe = true;

        await iniciarSesion();
        await dejarCorrer();

        expect(bajas, contains('partido_7_es'));
        expect(guardados, isEmpty);
      },
    );

    test(
      'si no recibe los resultados, sigue con los partidos que seguía',
      () async {
        await iniciarSesion();
        await dejarCorrer();

        expect(bajas, isEmpty);
        expect(guardados.keys, [7]);
      },
    );

    test('un fallo al sincronizar no rompe el acceso', () async {
      falla = true;

      await iniciarSesion();
      await dejarCorrer();

      expect(AuthManager.estaAutenticado, isTrue);
    });
  });

  group('al cerrar sesión', () {
    test('sincroniza los partidos seguidos', () async {
      await AuthManager.cerrarSesion(desregistrarDispositivo: false);
      await dejarCorrer();

      expect(lecturas, greaterThan(0));
    });

    test(
      'si el dispositivo ya recibe los resultados, se da de baja de los partidos seguidos',
      () async {
        recibe = true;

        await AuthManager.cerrarSesion(desregistrarDispositivo: false);
        await dejarCorrer();

        expect(bajas, contains('partido_7_es'));
        expect(guardados, isEmpty);
      },
    );

    test('un fallo al sincronizar no rompe el cierre de sesión', () async {
      falla = true;

      await expectLater(
        AuthManager.cerrarSesion(desregistrarDispositivo: false),
        completes,
      );
      await dejarCorrer();

      expect(AuthManager.estaAutenticado, isFalse);
    });

    test('no espera a que termine la sincronización', () async {
      var terminada = false;

      PushNotificationService.seguirPartidos = SeguirPartidoService(
        suscribir: (_) async {},
        desuscribir: (_) async {},
        obtenerIdioma: () async => 'es',
        leer: () async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          terminada = true;
          return {};
        },
        guardar: (_) async {},
      );

      await AuthManager.cerrarSesion(desregistrarDispositivo: false);

      // El cierre ya ha vuelto y la sincronización sigue en marcha.
      expect(terminada, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(terminada, isTrue);
    });
  });
}
