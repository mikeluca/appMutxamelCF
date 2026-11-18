import 'dart:async';
import 'dart:convert';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/pages/notificaciones_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../features/familia/soporte_familia.dart';
import '../../support/http_test_helpers.dart';

/// Los avisos de las solicitudes de familia: SOLICITUD_FAMILIA (a quien revisa: abre "Solicitudes de familia") y
/// SOLICITUD_FAMILIA_RESPUESTA (a la familia: recarga los roles y abre Mis jugadores o el estado de su solicitud).

RemoteMessage _pushNueva() => RemoteMessage(
  data: {
    'tipo': 'SOLICITUD_FAMILIA',
    'pantalla': 'SOLICITUDES_FAMILIA',
    'referenciaId': '12',
    'solicitudId': '12',
  },
  notification: RemoteNotification(
    title: 'Nueva solicitud de acceso',
    body: 'Nueva solicitud de acceso de una familia',
  ),
);

// El recordatorio diario no lleva referencia.
RemoteMessage _pushRecordatorio() => RemoteMessage(
  data: {'tipo': 'SOLICITUD_FAMILIA', 'pantalla': 'SOLICITUDES_FAMILIA'},
  notification: RemoteNotification(
    title: 'Solicitudes de familia pendientes',
    body:
        'Hay solicitudes de acceso de familias sin revisar desde hace más de 2 días.',
  ),
);

RemoteMessage _pushRespuesta() => RemoteMessage(
  data: {
    'tipo': 'SOLICITUD_FAMILIA_RESPUESTA',
    'pantalla': 'MI_SOLICITUD_FAMILIA',
    'referenciaId': '12',
    'solicitudId': '12',
  },
  notification: RemoteNotification(
    title: 'Acceso aprobado',
    body: 'Ya puedes ver la información de Luis Pérez Gómez.',
  ),
);

void main() {
  late List<Map<String, dynamic>> mostradas;
  late List<String> peticiones;
  late List<String> rolesDelBackend;

  setUp(() {
    prepararAlmacenamiento();

    mostradas = [];
    peticiones = [];
    rolesDelBackend = ['FAMILIAR'];

    PushNotificationService.contarNoLeidas = () async => 1;
    PushNotificationService.mostrarNotificacionLocal =
        ({
          required int comunicacionId,
          required String titulo,
          required String mensaje,
          int cantidadNoLeidas = 1,
          bool esPrivada = false,
          int? autorId,
          Map<String, dynamic> datos = const {},
        }) async {
          mostradas.add(datos);
        };
    PushNotificationService.restaurarSesion = () async =>
        AuthManager.estaAutenticado;
    PushNotificationService.simularMensajeInicial(null);

    AppNavigator.constructorSolicitudesFamilia = () =>
        const Scaffold(body: Text('SOLICITUDES'));
    AppNavigator.constructorMiSolicitudFamilia = () =>
        const Scaffold(body: Text('MI SOLICITUD'));
    AppNavigator.constructorBandeja = () =>
        const Scaffold(body: Text('BANDEJA'));
  });

  tearDown(() {
    AppNavigator.constructorSolicitudesFamilia = null;
    AppNavigator.constructorMiSolicitudFamilia = null;
    AppNavigator.constructorBandeja = null;
    PushNotificationService.simularMensajeInicial(null);
    AuthManager.olvidarUsuario();
  });

  Future<void> conSesion(List<String> roles) async {
    await iniciarSesionDePrueba(roles: roles);
    await AuthManager.establecerUsuario(
      AuthUser(usuarioId: 7, email: 'ana@example.com', roles: roles),
    );
  }

  Future<http.Response> backend(http.Request request) async {
    peticiones.add('${request.method} ${request.url.path}');

    if (request.url.path == '/api/app/auth/me') {
      return json({
        'usuarioId': 7,
        'email': 'ana@example.com',
        'roles': rolesDelBackend,
      });
    }

    if (request.method == 'PUT') {
      return http.Response('', 204);
    }

    if (request.url.path == '/api/app/notificaciones') {
      return json([
        {
          'id': 1,
          'tipo': 'SOLICITUD_FAMILIA_RESPUESTA',
          'titulo': 'Acceso aprobado',
          'mensaje': 'Ya puedes ver la información de Luis.',
          'referenciaId': 12,
          'fecha': '2026-11-19T09:00:00',
          'leida': false,
        },
        {
          'id': 2,
          'tipo': 'SOLICITUD_FAMILIA',
          'titulo': 'Nueva solicitud de acceso',
          'mensaje':
              'Una familia ha pedido acceso a la información de su hijo o hija.',
          'referenciaId': 12,
          'fecha': '2026-11-19T09:00:00',
          'leida': false,
        },
      ]);
    }

    return http.Response('no esperado', 404);
  }

  group('destinos y payloads', () {
    test('a quien revisa le abre las solicitudes; al resto, nada', () async {
      for (final rol in ['COORDINADOR', 'ADMIN_APP', 'ENTRENADOR']) {
        await AuthManager.establecerUsuario(
          AuthUser(usuarioId: 1, email: 'a@b.c', roles: [rol]),
        );

        expect(
          destinoDeAvisoConvocatoria(tipo: 'SOLICITUD_FAMILIA'),
          const AbrirSolicitudesFamilia(),
          reason: rol,
        );
      }

      for (final rol in ['FAMILIAR', 'JUGADOR', 'RETRANSMISION']) {
        await AuthManager.establecerUsuario(
          AuthUser(usuarioId: 1, email: 'a@b.c', roles: [rol]),
        );

        expect(
          destinoDeAvisoConvocatoria(tipo: 'SOLICITUD_FAMILIA'),
          isNull,
          reason: rol,
        );
      }
    });

    test(
      'a la familia le abre su solicitud, tenga o no roles todavía',
      () async {
        expect(
          destinoDeAvisoConvocatoria(tipo: 'SOLICITUD_FAMILIA_RESPUESTA'),
          const AbrirMiSolicitudFamilia(),
        );
      },
    );

    test('los payloads se escriben y se leen igual', () {
      expect(
        payloadDeDestino(const AbrirSolicitudesFamilia()),
        'SOLICITUDES_FAMILIA',
      );
      expect(
        payloadDeDestino(const AbrirMiSolicitudFamilia()),
        'MI_SOLICITUD_FAMILIA',
      );
      expect(
        destinoDePayload('SOLICITUDES_FAMILIA'),
        const AbrirSolicitudesFamilia(),
      );
      expect(
        destinoDePayload('MI_SOLICITUD_FAMILIA'),
        const AbrirMiSolicitudFamilia(),
      );
      expect(esAvisoDeConvocatoria(tipo: 'SOLICITUD_FAMILIA'), isTrue);
      expect(
        esAvisoDeConvocatoria(tipo: 'SOLICITUD_FAMILIA_RESPUESTA'),
        isTrue,
      );
    });

    test('la notificación local lleva su destino y un id propio', () async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: ['COORDINADOR']),
      );

      expect(
        LocalNotificationService.payloadDeAviso(
          comunicacionId: 12,
          titulo: 'Nueva solicitud de acceso',
          datos: _pushNueva().data,
        ),
        'SOLICITUDES_FAMILIA',
      );
      expect(
        LocalNotificationService.payloadDeAviso(
          comunicacionId: 12,
          titulo: 'Acceso aprobado',
          datos: _pushRespuesta().data,
        ),
        'MI_SOLICITUD_FAMILIA',
      );

      // No pisa la notificación de una comunicación con el mismo número.
      expect(
        LocalNotificationService.idDeNotificacion(12, _pushNueva().data),
        isNot(12),
      );
    });
  });

  group('push con la app abierta', () {
    testWidgets(
      'la nueva solicitud sale como notificación local y, al tocarla, abre la pantalla',
      (tester) async {
        await conSesion(['COORDINADOR']);
        await pintarFamilia(
          tester,
          const Scaffold(body: Text('HOME')),
          navigatorKey: AppNavigator.navigatorKey,
        );

        await PushNotificationService.mostrarEnPrimerPlano(_pushNueva());

        expect(mostradas, hasLength(1));

        LocalNotificationService.procesarPayload(
          LocalNotificationService.payloadDeAviso(
            comunicacionId: 12,
            titulo: 'Nueva solicitud de acceso',
            datos: mostradas.single,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SOLICITUDES'), findsOneWidget);
      },
    );

    testWidgets('el recordatorio diario (sin referencia) también se enseña', (
      tester,
    ) async {
      await conSesion(['COORDINADOR']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      await PushNotificationService.mostrarEnPrimerPlano(_pushRecordatorio());

      expect(mostradas, hasLength(1));
      expect(mostradas.single['tipo'], 'SOLICITUD_FAMILIA');
    });

    testWidgets('el aviso de aprobación recarga los roles de la cuenta', (
      tester,
    ) async {
      await conSesion([]);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      final antes = AuthManager.cambios.value;

      await conMockHttp(backend, () async {
        await PushNotificationService.mostrarEnPrimerPlano(_pushRespuesta());
      });

      expect(peticiones, contains('GET /api/app/auth/me'));
      expect(AuthManager.usuarioActual?.roles, ['FAMILIAR']);
      // El Área Club, que escucha AuthManager.cambios, se reconstruye sin cerrar sesión.
      expect(AuthManager.cambios.value, greaterThan(antes));
      expect(mostradas, hasLength(1));
    });

    testWidgets('el aviso a quien revisa NO recarga los roles', (tester) async {
      await conSesion(['COORDINADOR']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      await conMockHttp(backend, () async {
        await PushNotificationService.mostrarEnPrimerPlano(_pushNueva());
      });

      expect(peticiones, isEmpty);
    });
  });

  group('al tocar el aviso', () {
    testWidgets('quien revisa abre las solicitudes; un familiar no abre nada', (
      tester,
    ) async {
      await conSesion(['ENTRENADOR']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      unawaited(PushNotificationService.procesarNotificacion(_pushNueva()));
      await tester.pumpAndSettle();

      expect(find.text('SOLICITUDES'), findsOneWidget);

      await conSesion(['FAMILIAR']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('OTRA')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      unawaited(PushNotificationService.procesarNotificacion(_pushNueva()));
      await tester.pumpAndSettle();

      expect(find.text('SOLICITUDES'), findsNothing);
    });

    testWidgets('la aprobación recarga los roles y abre Mis jugadores', (
      tester,
    ) async {
      await conSesion([]);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
        rutas: {'/players': (_) => const Scaffold(body: Text('MIS JUGADORES'))},
      );

      await conMockHttp(backend, () async {
        unawaited(
          PushNotificationService.procesarNotificacion(_pushRespuesta()),
        );
        await tester.pumpAndSettle();
      });

      expect(peticiones, contains('GET /api/app/auth/me'));
      expect(find.text('MIS JUGADORES'), findsOneWidget);
      expect(find.text('MI SOLICITUD'), findsNothing);
    });

    testWidgets(
      'si todavía no tiene acceso (rechazo) abre el estado de su solicitud',
      (tester) async {
        rolesDelBackend = [];
        await conSesion([]);
        await pintarFamilia(
          tester,
          const Scaffold(body: Text('HOME')),
          navigatorKey: AppNavigator.navigatorKey,
          rutas: {
            '/players': (_) => const Scaffold(body: Text('MIS JUGADORES')),
          },
        );

        await conMockHttp(backend, () async {
          unawaited(
            PushNotificationService.procesarNotificacion(_pushRespuesta()),
          );
          await tester.pumpAndSettle();
        });

        expect(find.text('MI SOLICITUD'), findsOneWidget);
        expect(find.text('MIS JUGADORES'), findsNothing);
      },
    );
  });

  group('desde la bandeja', () {
    testWidgets(
      'tocar el aviso de la respuesta abre lo que toca; el de nueva solicitud, las solicitudes',
      (tester) async {
        await conSesion(['COORDINADOR']);

        await conMockHttp(backend, () async {
          await pintarFamilia(
            tester,
            const NotificacionesPage(),
            navigatorKey: AppNavigator.navigatorKey,
            rutas: {
              '/players': (_) => const Scaffold(body: Text('MIS JUGADORES')),
            },
          );

          await tester.tap(find.text('Nueva solicitud de acceso'));
          await tester.pumpAndSettle();

          expect(find.text('SOLICITUDES'), findsOneWidget);

          Navigator.of(tester.element(find.text('SOLICITUDES'))).pop();
          await tester.pumpAndSettle();

          await tester.tap(find.text('Acceso aprobado'));
          await tester.pumpAndSettle();

          // La respuesta recarga los roles: el backend ya la tiene como familiar con acceso.
          expect(peticiones, contains('GET /api/app/auth/me'));
          expect(jsonEncode(rolesDelBackend), contains('FAMILIAR'));
          expect(find.text('MIS JUGADORES'), findsOneWidget);
        });
      },
    );
  });
}
