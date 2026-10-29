import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Push CONTINUIDAD (abre la pantalla de continuidad de la familia) y
/// CONTINUIDAD_RESPUESTA (abre la bandeja: la revisión se hace en el panel web),
/// y el push de la nueva temporada, que llega como NOTICIA sin noticia asociada.

RemoteMessage _pushContinuidad() => RemoteMessage(
  data: {
    'tipo': 'CONTINUIDAD',
    'referenciaId': '7',
    'pantalla': 'CONTINUIDAD',
    'accion': 'PREGUNTA',
    'temporadaId': '7',
    'jugadorIds': '1,2',
  },
  notification: RemoteNotification(
    title: 'Continuidad en 2027/2028',
    body: '¿Seguirán Pablo y Luis en la temporada 2027/2028?',
  ),
);

RemoteMessage _pushRespuesta() => RemoteMessage(
  data: {
    'tipo': 'CONTINUIDAD_RESPUESTA',
    'referenciaId': '1',
    'pantalla': 'CONTINUIDAD_COORDINADOR',
    'temporadaId': '7',
    'jugadorId': '1',
    'respuesta': 'NO_SIGUE',
  },
  notification: RemoteNotification(
    title: 'No seguirá: Pablo Pérez (Alevín)',
    body: 'Su familia ha respondido que no seguirá.',
  ),
);

// El push "Empieza la temporada" del cierre: tipo NOTICIA y referenciaId vacío.
RemoteMessage _pushNuevaTemporada() => RemoteMessage(
  data: {'tipo': 'NOTICIA', 'referenciaId': ''},
  notification: RemoteNotification(
    title: 'Nueva temporada',
    body: 'Empieza la temporada 2027/2028. Los equipos se publicarán en septiembre.',
  ),
);

void _tocar(RemoteMessage mensaje) =>
    unawaited(PushNotificationService.procesarNotificacion(mensaje));

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
  late List<Map<String, dynamic>> mostradas;
  late int sesionesRestauradas;

  setUp(() {
    mostradas = [];
    sesionesRestauradas = 0;

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
          mostradas.add(datos);
        };
    PushNotificationService.restaurarSesion = () async {
      sesionesRestauradas++;
      return AuthManager.estaAutenticado;
    };
    PushNotificationService.simularMensajeInicial(null);

    AppNavigator.constructorContinuidad = () =>
        const Scaffold(body: Text('CONTINUIDAD'));
    AppNavigator.constructorBandeja = () =>
        const Scaffold(body: Text('BANDEJA'));
  });

  tearDown(() {
    AppNavigator.constructorContinuidad = null;
    AppNavigator.constructorBandeja = null;
    PushNotificationService.simularMensajeInicial(null);
    AuthManager.olvidarUsuario();
  });

  Future<void> conSesion(List<String> roles) => AuthManager.establecerUsuario(
    AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
  );

  test('los destinos y los payloads de continuidad se leen y se escriben igual', () {
    expect(destinoDeAvisoConvocatoria(tipo: 'CONTINUIDAD'), const AbrirContinuidad());
    expect(
      destinoDeAvisoConvocatoria(tipo: 'CONTINUIDAD_RESPUESTA'),
      const AbrirBandeja(),
    );
    expect(payloadDeDestino(const AbrirContinuidad()), 'CONTINUIDAD');
    expect(payloadDeDestino(const AbrirBandeja()), 'CONTINUIDAD_RESPUESTA');
    expect(destinoDePayload('CONTINUIDAD'), const AbrirContinuidad());
    expect(destinoDePayload('CONTINUIDAD_RESPUESTA'), const AbrirBandeja());
    expect(esAvisoDeConvocatoria(tipo: 'CONTINUIDAD'), isTrue);
    expect(esAvisoDeConvocatoria(tipo: 'CONTINUIDAD_RESPUESTA'), isTrue);
    expect(esAvisoDeConvocatoria(tipo: 'NOTICIA'), isFalse);
  });

  test('la notificación local lleva el destino de continuidad y su propio id', () {
    final datos = _pushContinuidad().data;

    expect(
      LocalNotificationService.payloadDeAviso(
        comunicacionId: 7,
        titulo: 'Continuidad en 2027/2028',
        datos: datos,
      ),
      'CONTINUIDAD',
    );
    expect(
      LocalNotificationService.payloadDeAviso(
        comunicacionId: 1,
        titulo: 'No seguirá',
        datos: _pushRespuesta().data,
      ),
      'CONTINUIDAD_RESPUESTA',
    );

    // No pisa la notificación de una comunicación con el mismo número.
    expect(LocalNotificationService.idDeNotificacion(7, datos), isNot(7));
    expect(
      LocalNotificationService.idDeNotificacion(7, datos),
      LocalNotificationService.idDeNotificacion(7, _pushContinuidad().data),
    );
  });

  testWidgets('con la app abierta CONTINUIDAD sale como notificación local y, al '
      'tocarla, abre la pantalla de continuidad', (tester) async {
    await conSesion(['FAMILIAR']);
    await _pintarApp(tester);

    await PushNotificationService.mostrarEnPrimerPlano(_pushContinuidad());

    expect(mostradas, hasLength(1));

    LocalNotificationService.procesarPayload(
      LocalNotificationService.payloadDeAviso(
        comunicacionId: 7,
        titulo: 'Continuidad en 2027/2028',
        datos: mostradas.single,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONTINUIDAD'), findsOneWidget);
  });

  testWidgets('con la app en segundo plano CONTINUIDAD abre la pantalla de '
      'continuidad', (tester) async {
    await conSesion(['FAMILIAR']);
    await _pintarApp(tester);

    _tocar(_pushContinuidad());
    await tester.pumpAndSettle();

    expect(find.text('CONTINUIDAD'), findsOneWidget);
    expect(find.text('BANDEJA'), findsNothing);
  });

  testWidgets('CONTINUIDAD_RESPUESTA abre la bandeja, no una pantalla propia', (
    tester,
  ) async {
    await conSesion(['COORDINADOR']);
    await _pintarApp(tester);

    _tocar(_pushRespuesta());
    await tester.pumpAndSettle();

    expect(find.text('BANDEJA'), findsOneWidget);
    expect(find.text('CONTINUIDAD'), findsNothing);
  });

  testWidgets('arranque en frío: CONTINUIDAD espera a la sesión y luego abre la '
      'pantalla', (tester) async {
    await conSesion(['FAMILIAR']);
    await _pintarApp(tester);

    PushNotificationService.simularMensajeInicial(_pushContinuidad());

    await PushNotificationService.procesarNotificacionInicial();
    await tester.pumpAndSettle();

    expect(sesionesRestauradas, 0);
    expect(find.text('CONTINUIDAD'), findsNothing);

    unawaited(PushNotificationService.procesarAvisoPendiente());
    await tester.pumpAndSettle();

    expect(sesionesRestauradas, 1);
    expect(find.text('CONTINUIDAD'), findsOneWidget);
  });

  testWidgets('arranque en frío: CONTINUIDAD_RESPUESTA también espera y abre la '
      'bandeja', (tester) async {
    await conSesion(['COORDINADOR']);
    await _pintarApp(tester);

    PushNotificationService.simularMensajeInicial(_pushRespuesta());

    await PushNotificationService.procesarNotificacionInicial();
    unawaited(PushNotificationService.procesarAvisoPendiente());
    await tester.pumpAndSettle();

    expect(find.text('BANDEJA'), findsOneWidget);
  });

  testWidgets('arranque en frío sin sesión válida: se descarta', (tester) async {
    await _pintarApp(tester);

    PushNotificationService.simularMensajeInicial(_pushContinuidad());

    await PushNotificationService.procesarNotificacionInicial();
    unawaited(PushNotificationService.procesarAvisoPendiente());
    await tester.pumpAndSettle();

    expect(find.text('CONTINUIDAD'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  group('"Empieza la temporada" (NOTICIA sin noticia asociada)', () {
    testWidgets('al tocarla con la app abierta o en segundo plano no navega ni '
        'falla: se queda en el inicio', (tester) async {
      await conSesion(['FAMILIAR']);
      await _pintarApp(tester);

      await PushNotificationService.mostrarEnPrimerPlano(_pushNuevaTemporada());
      _tocar(_pushNuevaTemporada());
      await tester.pumpAndSettle();

      expect(mostradas, isEmpty);
      expect(find.text('HOME'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('al abrir la app en frío tampoco falla ni deja un aviso '
        'pendiente', (tester) async {
      await conSesion(['FAMILIAR']);
      await _pintarApp(tester);

      PushNotificationService.simularMensajeInicial(_pushNuevaTemporada());

      await PushNotificationService.procesarNotificacionInicial();
      unawaited(PushNotificationService.procesarAvisoPendiente());
      await tester.pumpAndSettle();

      expect(sesionesRestauradas, 0);
      expect(find.text('HOME'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
