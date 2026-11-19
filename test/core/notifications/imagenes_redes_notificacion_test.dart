import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/pages/notificaciones_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/pages/imagenes_redes_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/familia/soporte_familia.dart';
import '../../support/http_test_helpers.dart';

/// Los recordatorios de "Imágenes para redes" (docs/avisos.md del backend, sección 9): abren la pantalla en la pestaña
/// y el fin de semana del aviso, solo para Retransmisión y los administradores de la app.

final DateTime _viernes = DateTime(2026, 11, 13);

const Map<String, String> _datosPrevia = {
  'tipo': 'IMAGENES_REDES',
  'pantalla': 'IMAGENES_REDES',
  'desde': '2026-11-13',
  'tipoImagen': 'PREVIA',
};

RemoteMessage _push(Map<String, String> datos) => RemoteMessage(
  data: datos,
  notification: RemoteNotification(
    title: 'Imágenes de la previa pendientes',
    body: 'Genera las imágenes de los partidos de este fin de semana.',
  ),
);

void main() {
  late List<({DateTime? desde, String? tipo})> abiertas;

  setUp(() {
    prepararAlmacenamiento();

    abiertas = [];

    PushNotificationService.contarNoLeidas = () async => 1;
    PushNotificationService.restaurarSesion = () async =>
        AuthManager.estaAutenticado;
    PushNotificationService.simularMensajeInicial(null);

    AppNavigator.constructorImagenesRedes = (desde, tipo) {
      abiertas.add((desde: desde, tipo: tipo));

      return const Scaffold(body: Text('IMAGENES PARA REDES'));
    };
  });

  tearDown(() {
    AppNavigator.constructorImagenesRedes = null;
    PushNotificationService.simularMensajeInicial(null);
    AuthManager.olvidarUsuario();
  });

  Future<void> conRoles(List<String> roles) async {
    await iniciarSesionDePrueba(roles: roles);
    await AuthManager.establecerUsuario(
      AuthUser(usuarioId: 7, email: 'ana@example.com', roles: roles),
    );
  }

  group('destinos y payloads', () {
    test('Retransmisión y administradores: abre la pantalla con su pestaña y '
        'fin de semana', () async {
      for (final rol in ['RETRANSMISION', 'ADMIN_APP']) {
        await AuthManager.establecerUsuario(
          AuthUser(usuarioId: 1, email: 'a@b.c', roles: [rol]),
        );

        expect(
          destinoDeAvisoConvocatoria(
            tipo: tipoPushImagenesRedes,
            datos: _datosPrevia,
          ),
          AbrirImagenesRedes(_viernes, 'PREVIA'),
          reason: rol,
        );
        expect(
          destinoDeAvisoConvocatoria(
            tipo: tipoPushImagenesRedes,
            datos: {..._datosPrevia, 'tipoImagen': 'RESULTADOS'},
          ),
          AbrirImagenesRedes(_viernes, 'RESULTADOS'),
          reason: rol,
        );
      }
    });

    test(
      'sin permiso (coordinador, entrenador...) el aviso no abre nada',
      () async {
        for (final rol in [
          'COORDINADOR',
          'ENTRENADOR',
          'FAMILIAR',
          'JUGADOR',
        ]) {
          await AuthManager.establecerUsuario(
            AuthUser(usuarioId: 1, email: 'a@b.c', roles: [rol]),
          );

          expect(
            destinoDeAvisoConvocatoria(
              tipo: tipoPushImagenesRedes,
              datos: _datosPrevia,
            ),
            isNull,
            reason: rol,
          );
        }
      },
    );

    test('un aviso sin pestaña ni fecha (antiguo) abre la pantalla por '
        'defecto', () async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: ['RETRANSMISION']),
      );

      expect(
        destinoDeAvisoConvocatoria(tipo: tipoPushImagenesRedes),
        const AbrirImagenesRedes(),
      );
    });

    test('los payloads se escriben y se leen igual', () {
      final destino = AbrirImagenesRedes(_viernes, 'RESULTADOS');

      expect(payloadDeDestino(destino), 'IMAGENES_REDES:2026-11-13:RESULTADOS');
      expect(destinoDePayload('IMAGENES_REDES:2026-11-13:RESULTADOS'), destino);

      // Sin fecha, con pestaña
      expect(
        payloadDeDestino(const AbrirImagenesRedes(null, 'PREVIA')),
        'IMAGENES_REDES::PREVIA',
      );
      expect(
        destinoDePayload('IMAGENES_REDES::PREVIA'),
        const AbrirImagenesRedes(null, 'PREVIA'),
      );

      // Los payloads de antes siguen valiendo
      expect(
        payloadDeDestino(AbrirImagenesRedes(_viernes)),
        'IMAGENES_REDES:2026-11-13',
      );
      expect(
        destinoDePayload('IMAGENES_REDES:2026-11-13'),
        AbrirImagenesRedes(_viernes),
      );
      expect(payloadDeDestino(const AbrirImagenesRedes()), 'IMAGENES_REDES');
      expect(destinoDePayload('IMAGENES_REDES'), const AbrirImagenesRedes());
    });

    test('la referencia de la bandeja es el viernes como yyyyMMdd', () {
      expect(diaDeReferenciaImagenes(20261113), _viernes);
      expect(diaDeReferenciaImagenes(null), isNull);
      expect(diaDeReferenciaImagenes(7), isNull);
      expect(diaDeReferenciaImagenes(20261399), isNull);
    });
  });

  group('al tocar el aviso', () {
    testWidgets('Retransmisión abre la pantalla en esa pestaña y fin de '
        'semana', (tester) async {
      await conRoles(['RETRANSMISION']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      unawaited(
        PushNotificationService.procesarNotificacion(_push(_datosPrevia)),
      );
      await tester.pumpAndSettle();

      expect(find.text('IMAGENES PARA REDES'), findsOneWidget);
      expect(abiertas, [(desde: _viernes, tipo: 'PREVIA')]);
    });

    testWidgets('el recordatorio de resultados abre la pestaña Resultados', (
      tester,
    ) async {
      await conRoles(['ADMIN_APP']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      unawaited(
        PushNotificationService.procesarNotificacion(
          _push({..._datosPrevia, 'tipoImagen': 'RESULTADOS'}),
        ),
      );
      await tester.pumpAndSettle();

      expect(abiertas, [(desde: _viernes, tipo: 'RESULTADOS')]);
    });

    testWidgets('un coordinador no abre nada', (tester) async {
      await conRoles(['COORDINADOR']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      unawaited(
        PushNotificationService.procesarNotificacion(_push(_datosPrevia)),
      );
      await tester.pumpAndSettle();

      expect(find.text('IMAGENES PARA REDES'), findsNothing);
      expect(abiertas, isEmpty);
    });

    testWidgets('sin constructor de pruebas abre la pantalla real', (
      tester,
    ) async {
      AppNavigator.constructorImagenesRedes = null;

      await conRoles(['RETRANSMISION']);
      await pintarFamilia(
        tester,
        const Scaffold(body: Text('HOME')),
        navigatorKey: AppNavigator.navigatorKey,
      );

      // La pantalla real pide datos a la red: se sustituye por un servidor de pruebas que no tiene nada.
      await conMockHttp((request) async => http.Response('[]', 200), () async {
        unawaited(AppNavigator.abrirImagenesRedes(_viernes, 'RESULTADOS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      });

      expect(find.byType(ImagenesRedesPage), findsOneWidget);
    });
  });

  group('desde la bandeja', () {
    Future<http.Response> backend(http.Request request) async {
      if (request.url.path == '/api/app/notificaciones') {
        return json([
          {
            'id': 1,
            // Un aviso antiguo de "imágenes listas" o un recordatorio nuevo: misma fila.
            'tipo': 'IMAGENES_REDES',
            'titulo': 'Imágenes del fin de semana',
            'mensaje':
                'Las imágenes de partidos del fin de semana ya están listas.',
            'referenciaId': 20261113,
            'fecha': '2026-11-13T12:00:00',
            'leida': false,
          },
        ]);
      }

      return http.Response('', 204);
    }

    testWidgets('con permiso abre la pantalla en el fin de semana del aviso', (
      tester,
    ) async {
      await conRoles(['RETRANSMISION']);

      await conMockHttp(backend, () async {
        await pintarFamilia(
          tester,
          const NotificacionesPage(),
          navigatorKey: AppNavigator.navigatorKey,
        );

        await tester.tap(find.text('Imágenes del fin de semana'));
        await tester.pumpAndSettle();
      });

      expect(find.text('IMAGENES PARA REDES'), findsOneWidget);
      // La bandeja no guarda la pestaña: la elige la pantalla.
      expect(abiertas, [(desde: _viernes, tipo: null)]);
    });

    testWidgets('sin permiso (p. ej. un coordinador) no hace nada', (
      tester,
    ) async {
      await conRoles(['COORDINADOR']);

      await conMockHttp(backend, () async {
        await pintarFamilia(
          tester,
          const NotificacionesPage(),
          navigatorKey: AppNavigator.navigatorKey,
        );

        await tester.tap(find.text('Imágenes del fin de semana'));
        await tester.pumpAndSettle();
      });

      expect(find.text('IMAGENES PARA REDES'), findsNothing);
      expect(abiertas, isEmpty);
    });
  });
}
