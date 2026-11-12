import 'dart:async';
import 'dart:convert';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/pages/notificaciones_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/services/ficha_partido_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

/// Avisos del partido en directo (tipo RESULTADO con partidoId): app en segundo plano, notificación local con la
/// app abierta, arranque en frío y bandeja abren la ficha de ese partido; sin partido, como siempre.

class _ServicioFalso extends FichaPartidoService {
  final List<int> llamadas = [];

  @override
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) async {
    llamadas.add(partidoId);

    return FichaPartido(
      cabecera: CabeceraFicha(
        partidoId: partidoId,
        equipoLocal: 'Mutxamel CF',
        equipoVisitante: 'Pego C.F.',
        dia: DateTime(2026, 11, 11),
        hora: '21:00',
        estado: EstadoFicha.proximo,
        competicion: 'Segona FFCV',
      ),
      eventos: const [],
      alineacion: const AlineacionFicha(),
      forma: const [],
    );
  }
}

RemoteMessage _push({Map<String, String>? data}) => RemoteMessage(
  data:
      data ??
      {
        'tipo': 'RESULTADO',
        'pantalla': 'FICHA_PARTIDO',
        'partidoId': '30',
        'referenciaId': '30',
      },
  notification: RemoteNotification(
    title: '⚽ ¡GOOOL del Mutxamel CF!',
    body: '1 - 0',
  ),
);

void _tocar(RemoteMessage mensaje) =>
    unawaited(PushNotificationService.procesarNotificacion(mensaje));

Future<void> _pintarApp(WidgetTester tester, {Widget? home}) async {
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
      home: home ?? const Scaffold(body: Text('HOME')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _ServicioFalso servicio;
  late List<Map<String, dynamic>> mostradas;
  late int sesionesRestauradas;

  setUp(() {
    servicio = _ServicioFalso();
    mostradas = [];
    sesionesRestauradas = 0;

    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );
    AuthManager.olvidarUsuario();

    AppNavigator.servicioFichaPartido = servicio;
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
  });

  tearDown(() {
    AppNavigator.servicioFichaPartido = null;
    PushNotificationService.simularMensajeInicial(null);
    AuthManager.olvidarUsuario();
  });

  test('partidoDeAviso: solo RESULTADO con un partidoId válido', () {
    expect(
      PushNotificationService.partidoDeAviso({
        'tipo': 'RESULTADO',
        'partidoId': '30',
      }),
      30,
    );
    expect(
      PushNotificationService.partidoDeAviso({'tipo': 'RESULTADO'}),
      isNull,
    );
    expect(
      PushNotificationService.partidoDeAviso({
        'tipo': 'RESULTADO',
        'partidoId': '',
      }),
      isNull,
    );
    expect(
      PushNotificationService.partidoDeAviso({
        'tipo': 'RESULTADO',
        'partidoId': '0',
      }),
      isNull,
    );
    expect(
      PushNotificationService.partidoDeAviso({
        'tipo': 'RESULTADO',
        'partidoId': 'x',
      }),
      isNull,
    );
    expect(
      PushNotificationService.partidoDeAviso({
        'tipo': 'NOTICIA',
        'partidoId': '30',
      }),
      isNull,
    );
    expect(PushNotificationService.partidoDeAviso({'partidoId': '30'}), isNull);
  });

  testWidgets('en segundo plano: tocar el push abre la ficha de ese partido', (
    tester,
  ) async {
    await _pintarApp(tester);

    _tocar(_push());
    await tester.pumpAndSettle();

    expect(find.byType(FichaPartidoPage), findsOneWidget);
    expect(find.byKey(const ValueKey('ficha-cabecera')), findsOneWidget);
    expect(servicio.llamadas, [30]);
  });

  testWidgets('el push de un topic (sin referenciaId) también abre la ficha', (
    tester,
  ) async {
    await _pintarApp(tester);

    _tocar(
      _push(
        data: {
          'tipo': 'RESULTADO',
          'pantalla': 'FICHA_PARTIDO',
          'partidoId': '31',
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FichaPartidoPage), findsOneWidget);
    expect(servicio.llamadas, [31]);
  });

  testWidgets(
    'sin partidoId (aviso antiguo) no abre nada: se queda en el inicio',
    (tester) async {
      await _pintarApp(tester);

      _tocar(_push(data: {'tipo': 'RESULTADO', 'referenciaId': '30'}));
      await tester.pumpAndSettle();

      expect(find.byType(FichaPartidoPage), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      expect(servicio.llamadas, isEmpty);
    },
  );

  testWidgets(
    'con la app abierta: notificación local que, al tocarla, abre la ficha, '
    'y la portada se refresca igual',
    (tester) async {
      await _pintarApp(tester);

      var refrescos = 0;
      final suscripcion = PushNotificationService.avisosDeResultados.listen(
        (_) => refrescos++,
      );

      await PushNotificationService.mostrarEnPrimerPlano(_push());
      await tester.pump();

      expect(refrescos, 1);
      expect(mostradas, hasLength(1));

      final payload = LocalNotificationService.payloadDeAviso(
        comunicacionId: 30,
        titulo: '⚽ ¡GOOOL del Mutxamel CF!',
        datos: mostradas.single,
      );
      expect(payload, 'FICHA_PARTIDO:30');

      LocalNotificationService.procesarPayload(payload);
      await tester.pumpAndSettle();

      expect(find.byType(FichaPartidoPage), findsOneWidget);
      expect(servicio.llamadas, [30]);

      unawaited(suscripcion.cancel());
    },
  );

  testWidgets(
    'con la ficha de ese partido a la vista no sale la notificación local: solo se recarga',
    (tester) async {
      await _pintarApp(tester);

      _tocar(_push());
      await tester.pumpAndSettle();
      expect(servicio.llamadas, [30]);

      await PushNotificationService.mostrarEnPrimerPlano(_push());
      await tester.pumpAndSettle();

      expect(mostradas, isEmpty);
    },
  );

  testWidgets(
    'con la ficha de otro partido a la vista, o la de ese pero tapada, sí sale la notificación local',
    (tester) async {
      await _pintarApp(tester);

      _tocar(_push(data: {'tipo': 'RESULTADO', 'partidoId': '31'}));
      await tester.pumpAndSettle();

      await PushNotificationService.mostrarEnPrimerPlano(_push());
      expect(mostradas, hasLength(1));

      // La ficha del 30 abierta pero con otra pantalla encima: tampoco está a la vista.
      _tocar(_push());
      await tester.pumpAndSettle();
      unawaited(
        AppNavigator.navigator!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('OTRA')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await PushNotificationService.mostrarEnPrimerPlano(_push());
      expect(mostradas, hasLength(2));
    },
  );

  testWidgets(
    'con la app abierta y sin partidoId solo se refresca, sin notificación local',
    (tester) async {
      await _pintarApp(tester);

      var refrescos = 0;
      final suscripcion = PushNotificationService.avisosDeResultados.listen(
        (_) => refrescos++,
      );

      await PushNotificationService.mostrarEnPrimerPlano(
        _push(data: {'tipo': 'RESULTADO'}),
      );
      await tester.pump();

      expect(refrescos, 1);
      expect(mostradas, isEmpty);

      unawaited(suscripcion.cancel());
    },
  );

  testWidgets('payload de partido mal formado: no abre nada', (tester) async {
    await _pintarApp(tester);

    LocalNotificationService.procesarPayload('FICHA_PARTIDO:x');
    LocalNotificationService.procesarPayload('FICHA_PARTIDO:0');
    await tester.pumpAndSettle();

    expect(find.byType(FichaPartidoPage), findsNothing);
    expect(servicio.llamadas, isEmpty);
  });

  testWidgets(
    'arranque en frío: espera a home y abre la ficha, también sin sesión',
    (tester) async {
      await _pintarApp(tester);

      PushNotificationService.simularMensajeInicial(_push());

      await PushNotificationService.procesarNotificacionInicial();
      await tester.pumpAndSettle();

      // Aún no: el splash lo taparía.
      expect(find.byType(FichaPartidoPage), findsNothing);
      expect(servicio.llamadas, isEmpty);

      unawaited(PushNotificationService.procesarAvisoPendiente());
      await tester.pumpAndSettle();

      expect(sesionesRestauradas, 0);
      expect(find.byType(FichaPartidoPage), findsOneWidget);
      expect(servicio.llamadas, [30]);
    },
  );

  testWidgets('arranque en frío con un aviso sin partidoId: no abre nada', (
    tester,
  ) async {
    await _pintarApp(tester);

    PushNotificationService.simularMensajeInicial(
      _push(data: {'tipo': 'RESULTADO'}),
    );

    await PushNotificationService.procesarNotificacionInicial();
    unawaited(PushNotificationService.procesarAvisoPendiente());
    await tester.pumpAndSettle();

    expect(find.byType(FichaPartidoPage), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets(
    'si la ficha de ese partido ya está abierta no se apila otra: se refresca',
    (tester) async {
      await _pintarApp(tester);

      _tocar(_push());
      await tester.pumpAndSettle();
      expect(servicio.llamadas, [30]);

      _tocar(_push());
      await tester.pumpAndSettle();

      expect(find.byType(FichaPartidoPage), findsOneWidget);
      expect(servicio.llamadas, [30, 30]);

      // Atrás lleva directamente al inicio: no había otra ficha debajo.
      AppNavigator.navigator!.pop();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    },
  );

  testWidgets(
    'si la ficha está abierta pero con otra pantalla encima, se vuelve a ella '
    'y se refresca',
    (tester) async {
      await _pintarApp(tester);

      _tocar(_push());
      await tester.pumpAndSettle();

      unawaited(
        AppNavigator.navigator!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('OTRA')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('OTRA'), findsOneWidget);

      _tocar(_push());
      await tester.pumpAndSettle();

      expect(find.text('OTRA'), findsNothing);
      expect(find.byType(FichaPartidoPage), findsOneWidget);
      expect(servicio.llamadas, [30, 30]);
    },
  );

  testWidgets('la ficha de otro partido sí se apila', (tester) async {
    await _pintarApp(tester);

    _tocar(_push());
    await tester.pumpAndSettle();

    _tocar(_push(data: {'tipo': 'RESULTADO', 'partidoId': '31'}));
    await tester.pumpAndSettle();

    expect(
      find.byType(FichaPartidoPage, skipOffstage: false),
      findsNWidgets(2),
    );
    expect(servicio.llamadas, [30, 31]);
  });

  group('bandeja', () {
    Future<void> pintarBandeja(
      WidgetTester tester,
      Map<String, dynamic> aviso,
    ) async {
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@b.c',
          roles: const [],
        ),
      );

      await conMockHttp((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'titulo': '⚽ ¡GOOOL del Mutxamel CF!',
              'mensaje': '1 - 0',
              'fecha': '2026-11-11T21:10:00',
              'leida': false,
              ...aviso,
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }, () => _pintarApp(tester, home: const NotificacionesPage()));
    }

    Future<void> tocarAviso(WidgetTester tester) {
      return conMockHttp((_) async => http.Response('[]', 200), () async {
        await tester.tap(find.text('⚽ ¡GOOOL del Mutxamel CF!'));
        await tester.pumpAndSettle();
      });
    }

    testWidgets(
      'una notificación RESULTADO con referenciaId abre la ficha de ese partido',
      (tester) async {
        await pintarBandeja(tester, {'tipo': 'RESULTADO', 'referenciaId': 30});

        await tocarAviso(tester);

        expect(find.byType(FichaPartidoPage), findsOneWidget);
        expect(servicio.llamadas, [30]);
      },
    );

    testWidgets('sin referenciaId (aviso antiguo) no abre nada', (
      tester,
    ) async {
      await pintarBandeja(tester, {'tipo': 'RESULTADO'});

      await tocarAviso(tester);

      expect(find.byType(FichaPartidoPage), findsNothing);
      expect(servicio.llamadas, isEmpty);
    });
  });
}
