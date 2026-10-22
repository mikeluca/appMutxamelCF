import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/pages/comunicacion_detail_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los avisos "recuerda publicar la convocatoria" y "falta el resultado" que envía
/// coordinación: en primer plano, en segundo plano y en arranque en frío abren el
/// formulario de convocatoria (con el partido preseleccionado) o el de resultado.

const _datosConvocatoria = {
  'tipo': 'CONVOCATORIA_PENDIENTE',
  'referenciaId': '90',
  'partidoId': '30',
  'equipoId': '5',
  'equipo': 'Cadete A',
};

const _datosResultado = {
  'tipo': 'RESULTADO_PENDIENTE',
  'referenciaId': '91',
  'partidoId': '31',
  'equipoId': '5',
  'equipo': 'Cadete A',
  'rival': 'Pego C.F.',
  'fecha': '2026-10-18',
  'hora': '11:00',
  'local': 'false',
};

RemoteMessage _push(Map<String, dynamic> data, {String titulo = 'Aviso'}) =>
    RemoteMessage(
      data: data,
      notification: RemoteNotification(title: titulo, body: 'Texto'),
    );

void _tocar(RemoteMessage mensaje) =>
    unawaited(PushNotificationService.procesarNotificacion(mensaje));

Future<void> _conUsuario(List<String> roles) => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
);

Future<void> _pintarApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('HOME')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late List<({int partidoId, PerfilEquipo equipo})> formulariosConvocatoria;
  late List<MatchModel> formulariosResultado;
  late List<
    ({int comunicacionId, String titulo, Map<String, dynamic> datos})
  >
  mostradas;

  setUp(() {
    formulariosConvocatoria = [];
    formulariosResultado = [];
    mostradas = [];

    AuthManager.olvidarUsuario();

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
          mostradas.add((
            comunicacionId: comunicacionId,
            titulo: titulo,
            datos: datos,
          ));
        };
    PushNotificationService.restaurarSesion = () async =>
        AuthManager.estaAutenticado;
    PushNotificationService.simularMensajeInicial(null);

    AppNavigator.constructorFormularioConvocatoria = (partidoId, equipo) {
      formulariosConvocatoria.add((partidoId: partidoId, equipo: equipo));
      return const Scaffold(body: Text('FORM CONVOCATORIA'));
    };
    AppNavigator.constructorFormularioResultado = (partido) {
      formulariosResultado.add(partido);
      return const Scaffold(body: Text('FORM RESULTADO'));
    };
  });

  tearDown(() {
    AppNavigator.constructorFormularioConvocatoria = null;
    AppNavigator.constructorFormularioResultado = null;
    PushNotificationService.simularMensajeInicial(null);
    AuthManager.olvidarUsuario();
  });

  group('destino del aviso', () {
    test('CONVOCATORIA_PENDIENTE lleva al formulario con el partido', () {
      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA_PENDIENTE',
          datos: _datosConvocatoria,
        ),
        const AbrirFormularioConvocatoria(
          partidoId: 30,
          equipoId: 5,
          equipo: 'Cadete A',
        ),
      );
    });

    test('RESULTADO_PENDIENTE lleva al formulario de resultado', () {
      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'RESULTADO_PENDIENTE',
          datos: _datosResultado,
        ),
        AbrirFormularioResultado(
          partidoId: 31,
          equipoId: 5,
          equipo: 'Cadete A',
          rival: 'Pego C.F.',
          dia: DateTime(2026, 10, 18),
          hora: '11:00',
          local: false,
        ),
      );
    });

    test('sin partido o equipo válidos no hay destino', () {
      for (final tipo in ['CONVOCATORIA_PENDIENTE', 'RESULTADO_PENDIENTE']) {
        for (final datos in <Map<String, dynamic>>[
          {},
          {'partidoId': '30'},
          {'partidoId': 'abc', 'equipoId': '5'},
          {'partidoId': '0', 'equipoId': '5'},
          {'partidoId': '30', 'equipoId': '-1'},
        ]) {
          expect(
            destinoDeAvisoConvocatoria(tipo: tipo, datos: datos),
            isNull,
            reason: '$tipo $datos',
          );
        }
      }
    });

    test('son avisos con destino propio (esperan a la sesión en frío)', () {
      expect(esAvisoDeConvocatoria(tipo: 'CONVOCATORIA_PENDIENTE'), isTrue);
      expect(esAvisoDeConvocatoria(tipo: 'RESULTADO_PENDIENTE'), isTrue);
    });

    test('el payload de la notificación local ida y vuelta', () {
      for (final destino in <DestinoConvocatoria>[
        const AbrirFormularioConvocatoria(
          partidoId: 30,
          equipoId: 5,
          equipo: 'Cadete A | "B"',
        ),
        AbrirFormularioResultado(
          partidoId: 31,
          equipoId: 5,
          equipo: 'Cadete A',
          rival: 'Pego | C.F.',
          dia: DateTime(2026, 10, 18),
          hora: '11:00',
          local: false,
        ),
        const AbrirFormularioResultado(
          partidoId: 31,
          equipoId: 5,
          equipo: 'Cadete A',
          rival: 'Elx',
        ),
      ]) {
        expect(destinoDePayload(payloadDeDestino(destino)), destino);
      }

      expect(destinoDePayload('CONVOCATORIA_PENDIENTE:abc|5|x'), isNull);
      expect(destinoDePayload('RESULTADO_PENDIENTE:'), isNull);
    });
  });

  group('con la app abierta (onMessage)', () {
    testWidgets('CONVOCATORIA_PENDIENTE sale como notificación local y, al '
        'tocarla, abre el formulario de convocatoria', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      await PushNotificationService.mostrarEnPrimerPlano(
        _push(_datosConvocatoria, titulo: 'Convocatoria pendiente'),
      );

      expect(mostradas, hasLength(1));
      expect(mostradas.single.comunicacionId, 90);

      final payload = LocalNotificationService.payloadDeAviso(
        comunicacionId: mostradas.single.comunicacionId,
        titulo: mostradas.single.titulo,
        datos: mostradas.single.datos,
      );

      expect(payload, startsWith('CONVOCATORIA_PENDIENTE:'));

      LocalNotificationService.procesarPayload(payload);
      await tester.pumpAndSettle();

      expect(find.text('FORM CONVOCATORIA'), findsOneWidget);
      expect(formulariosConvocatoria.single.partidoId, 30);
      expect(formulariosConvocatoria.single.equipo.id, 5);
    });

    testWidgets('RESULTADO_PENDIENTE sale como notificación local y, al '
        'tocarla, abre el formulario de resultado', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      await PushNotificationService.mostrarEnPrimerPlano(
        _push(_datosResultado, titulo: 'Resultado pendiente'),
      );

      expect(mostradas, hasLength(1));

      final payload = LocalNotificationService.payloadDeAviso(
        comunicacionId: mostradas.single.comunicacionId,
        titulo: mostradas.single.titulo,
        datos: mostradas.single.datos,
      );

      LocalNotificationService.procesarPayload(payload);
      await tester.pumpAndSettle();

      expect(find.text('FORM RESULTADO'), findsOneWidget);

      final partido = formulariosResultado.single;
      expect(partido.id, 31);
      expect(partido.equipoId, 5);
      expect(partido.rival, 'Pego C.F.');
      expect(partido.dia, DateTime(2026, 10, 18));
      expect(partido.hora, '11:00');
      expect(partido.local, isFalse);
    });
  });

  group('con la app en segundo plano (onMessageOpenedApp)', () {
    testWidgets('CONVOCATORIA_PENDIENTE abre el formulario con el partido '
        'preseleccionado', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      _tocar(_push(_datosConvocatoria));
      await tester.pumpAndSettle();

      expect(find.text('FORM CONVOCATORIA'), findsOneWidget);
      expect(formulariosConvocatoria.single.partidoId, 30);
    });

    testWidgets('RESULTADO_PENDIENTE abre el formulario de resultado', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      _tocar(_push(_datosResultado));
      await tester.pumpAndSettle();

      expect(find.text('FORM RESULTADO'), findsOneWidget);
      expect(formulariosResultado.single.id, 31);
    });

    testWidgets('sin los datos del partido no se abre ningún formulario: se abre '
        'como una comunicación', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      _tocar(_push({'tipo': 'CONVOCATORIA_PENDIENTE', 'referenciaId': '90'}));
      // La comunicación se pide a la red: no termina de animar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ComunicacionDetallePage), findsOneWidget);
      expect(find.text('FORM CONVOCATORIA'), findsNothing);
      expect(formulariosConvocatoria, isEmpty);
    });
  });

  group('arranque en frío', () {
    for (final caso in [
      (datos: _datosConvocatoria, pantalla: 'FORM CONVOCATORIA'),
      (datos: _datosResultado, pantalla: 'FORM RESULTADO'),
    ]) {
      testWidgets('${caso.datos['tipo']} se guarda y se abre cuando hay '
          'sesión y home', (tester) async {
        await _conUsuario(['ENTRENADOR']);
        await _pintarApp(tester);

        PushNotificationService.simularMensajeInicial(_push(caso.datos));

        await PushNotificationService.procesarNotificacionInicial();
        await tester.pumpAndSettle();

        // Todavía nada: espera al splash y a la sesión.
        expect(find.text(caso.pantalla), findsNothing);

        unawaited(PushNotificationService.procesarAvisoPendiente());
        await tester.pumpAndSettle();

        expect(find.text(caso.pantalla), findsOneWidget);
      });
    }
  });
}
