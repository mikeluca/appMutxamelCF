import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/pages/comunicacion_detail_page.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/splash/splash_page.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:app_mutxamel_cf/routing/app_routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flujo completo de un push de convocatoria, no solo sus funciones de
/// destino: onMessage (app abierta -> notificación local -> tocarla),
/// onMessageOpenedApp (app en segundo plano) y arranque en frío (splash).

class _FakeConvocatoriaService extends ConvocatoriaService {
  final List<int> pedidas = [];
  Object? fallo;

  @override
  Future<ConvocatoriaModel> obtenerPorId(int convocatoriaId) async {
    pedidas.add(convocatoriaId);

    if (fallo != null) {
      throw fallo!;
    }

    return ConvocatoriaModel(
      id: convocatoriaId,
      equipoId: 5,
      equipo: 'Cadete A',
      partidoId: 30,
      rival: 'Pego C.F.',
      campo: 'Campo Municipal',
      fechaPartido: '2026-10-24',
      horaPartido: '11:00',
      horaConvocatoria: '09:30',
      lugarConvocatoria: 'Vestuarios',
      usuarioEntrenadorId: 1,
      jugadores: const [],
    );
  }
}

/// Abrir una pantalla espera a que se cierre: en los tests no se aguarda.
void _tocar(RemoteMessage mensaje) =>
    unawaited(PushNotificationService.procesarNotificacion(mensaje));

void _abrirPendiente() =>
    unawaited(PushNotificationService.procesarAvisoPendiente());

typedef _Local = ({
  int comunicacionId,
  String titulo,
  String mensaje,
  bool esPrivada,
  int? autorId,
  Map<String, dynamic> datos,
});

RemoteMessage _push({
  required Map<String, dynamic> data,
  String titulo = 'Aviso',
  String cuerpo = 'Texto del aviso',
}) => RemoteMessage(
  data: data,
  notification: RemoteNotification(title: titulo, body: cuerpo),
);

RemoteMessage _pushEditar({String convocatoriaId = '20'}) => _push(
  titulo: 'Convocado con ausencia justificada',
  data: {
    'tipo': 'CONVOCATORIA_EDITAR',
    'referenciaId': '77',
    'convocatoriaId': convocatoriaId,
  },
);

RemoteMessage _pushConvocatoria({String fecha = '2026-10-24'}) => _push(
  titulo: 'Nueva convocatoria',
  data: {
    'tipo': 'CONVOCATORIA',
    'referenciaId': '78',
    'convocatoriaId': '20',
    'fechaPartido': fecha,
  },
);

Future<void> _conUsuario(List<String> roles) => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
);

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
      routes: {AppRoutes.public: (_) => const Scaffold(body: Text('HOME'))},
      home: home ?? const Scaffold(body: Text('HOME')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late List<_Local> mostradas;
  late _FakeConvocatoriaService convocatorias;
  late List<ConvocatoriaModel> ediciones;
  late List<DateTime?> calendarios;
  late int sesionesRestauradas;

  setUp(() {
    mostradas = [];
    ediciones = [];
    calendarios = [];
    sesionesRestauradas = 0;
    convocatorias = _FakeConvocatoriaService();

    AuthManager.olvidarUsuario();

    PushNotificationService.contarNoLeidas = () async => 3;
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
            mensaje: mensaje,
            esPrivada: esPrivada,
            autorId: autorId,
            datos: datos,
          ));
        };
    PushNotificationService.restaurarSesion = () async {
      sesionesRestauradas++;
      return AuthManager.estaAutenticado;
    };
    PushNotificationService.simularMensajeInicial(null);

    AppNavigator.fabricaConvocatoriaService = () => convocatorias;
    AppNavigator.constructorEdicion = (convocatoria) {
      ediciones.add(convocatoria);
      return const Scaffold(body: Text('EDICION'));
    };
    AppNavigator.constructorCalendario = (dia) {
      calendarios.add(dia);
      return const Scaffold(body: Text('CALENDARIO'));
    };
  });

  tearDown(() {
    AppNavigator.fabricaConvocatoriaService = null;
    AppNavigator.constructorEdicion = null;
    AppNavigator.constructorCalendario = null;
    PushNotificationService.simularMensajeInicial(null);
    AuthManager.olvidarUsuario();
  });

  // ---- app abierta (onMessage) -------------------------------------------------------------

  group('con la app abierta (onMessage)', () {
    testWidgets('CONVOCATORIA_EDITAR sale como notificación local y, al '
        'tocarla, abre la edición de esa convocatoria', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      await PushNotificationService.mostrarEnPrimerPlano(_pushEditar());

      // Antes de este arreglo se descartaba como "tipo no reconocido".
      expect(mostradas, hasLength(1));
      expect(mostradas.single.comunicacionId, 77);
      expect(mostradas.single.titulo, 'Convocado con ausencia justificada');
      expect(mostradas.single.datos['convocatoriaId'], '20');

      final payload = LocalNotificationService.payloadDeAviso(
        comunicacionId: mostradas.single.comunicacionId,
        titulo: mostradas.single.titulo,
        esPrivada: mostradas.single.esPrivada,
        autorId: mostradas.single.autorId,
        datos: mostradas.single.datos,
      );

      expect(payload, 'CONVOCATORIA_EDITAR:20');

      // Tocar la notificación local.
      LocalNotificationService.procesarPayload(payload);
      await tester.pumpAndSettle();

      expect(find.text('EDICION'), findsOneWidget);
      expect(convocatorias.pedidas, [20]);
      expect(ediciones.single.id, 20);
    });

    testWidgets('CONVOCATORIA sale como notificación local y, al tocarla, '
        'abre el calendario en el día del partido', (tester) async {
      await _conUsuario(['JUGADOR']);
      await _pintarApp(tester);

      await PushNotificationService.mostrarEnPrimerPlano(_pushConvocatoria());

      expect(mostradas, hasLength(1));

      final payload = LocalNotificationService.payloadDeAviso(
        comunicacionId: mostradas.single.comunicacionId,
        titulo: mostradas.single.titulo,
        datos: mostradas.single.datos,
      );

      expect(payload, 'CALENDARIO:2026-10-24');

      LocalNotificationService.procesarPayload(payload);
      await tester.pumpAndSettle();

      expect(find.text('CALENDARIO'), findsOneWidget);
      expect(calendarios, [DateTime(2026, 10, 24)]);
    });

    testWidgets('el recuento de no leídas viaja con la notificación local', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);

      final cantidades = <int>[];
      final anterior = PushNotificationService.mostrarNotificacionLocal;

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
            cantidades.add(cantidadNoLeidas);
          };

      await PushNotificationService.mostrarEnPrimerPlano(_pushEditar());

      expect(cantidades, [3]);

      PushNotificationService.mostrarNotificacionLocal = anterior;
    });

    testWidgets('un tipo desconocido, RESULTADO o un CONVOCATORIA_EDITAR sin '
        'referenciaId no abren ninguna notificación local', (tester) async {
      await PushNotificationService.mostrarEnPrimerPlano(
        _push(data: {'tipo': 'OTRO', 'referenciaId': '5'}),
      );
      await PushNotificationService.mostrarEnPrimerPlano(
        _push(data: {'tipo': 'RESULTADO'}),
      );
      await PushNotificationService.mostrarEnPrimerPlano(
        _push(data: {'tipo': 'CONVOCATORIA_EDITAR', 'convocatoriaId': '20'}),
      );

      expect(mostradas, isEmpty);
    });

    testWidgets('una comunicación normal sigue igual', (tester) async {
      await PushNotificationService.mostrarEnPrimerPlano(
        _push(
          titulo: 'Entrenamiento',
          data: {'tipo': 'COMUNICACION', 'referenciaId': '9'},
        ),
      );

      expect(mostradas.single.comunicacionId, 9);
      expect(
        LocalNotificationService.payloadDeAviso(
          comunicacionId: 9,
          titulo: 'Entrenamiento',
          datos: mostradas.single.datos,
        ),
        'COMUNICACION:9',
      );
    });
  });

  // ---- app en segundo plano (onMessageOpenedApp) -------------------------------------------------

  group('con la app en segundo plano (onMessageOpenedApp)', () {
    testWidgets('CONVOCATORIA_EDITAR abre la edición de esa convocatoria', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      _tocar(_pushEditar());
      await tester.pumpAndSettle();

      expect(find.text('EDICION'), findsOneWidget);
      expect(convocatorias.pedidas, [20]);
    });

    testWidgets('CONVOCATORIA abre el calendario en el día del partido', (
      tester,
    ) async {
      await _conUsuario(['FAMILIAR']);
      await _pintarApp(tester);

      _tocar(_pushConvocatoria(fecha: '2026-11-03'));
      await tester.pumpAndSettle();

      expect(find.text('CALENDARIO'), findsOneWidget);
      expect(calendarios, [DateTime(2026, 11, 3)]);
    });

    testWidgets('un push antiguo (tipo COMUNICACION) se reconoce por el '
        'título', (tester) async {
      await _conUsuario(['JUGADOR']);
      await _pintarApp(tester);

      _tocar(
        _push(
          titulo: 'Nueva convocatoria',
          data: {'tipo': 'COMUNICACION', 'referenciaId': '12'},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CALENDARIO'), findsOneWidget);
      expect(calendarios, [null]);
    });

    testWidgets('CONVOCATORIA_EDITAR sin convocatoriaId no abre nada', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      _tocar(_push(data: {'tipo': 'CONVOCATORIA_EDITAR'}));
      await tester.pumpAndSettle();

      expect(find.text('EDICION'), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      expect(convocatorias.pedidas, isEmpty);
    });

    testWidgets('si la convocatoria ya no está disponible, se avisa', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      convocatorias.fallo = const ApiException('Prohibido', statusCode: 403);

      _tocar(_pushEditar());
      await tester.pumpAndSettle();

      expect(find.text('EDICION'), findsNothing);
      expect(
        find.text('Esta convocatoria ya no está disponible'),
        findsOneWidget,
      );
    });
  });

  // ---- arranque en frío -------------------------------------------------------------------------

  group('arranque en frío desde un push', () {
    testWidgets('el aviso se guarda y NO se abre hasta que hay sesión y home', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      PushNotificationService.simularMensajeInicial(_pushEditar());

      await PushNotificationService.procesarNotificacionInicial();
      await tester.pumpAndSettle();

      // Todavía nada: ni sesión restaurada ni pantalla abierta.
      expect(sesionesRestauradas, 0);
      expect(find.text('EDICION'), findsNothing);
      expect(convocatorias.pedidas, isEmpty);

      _abrirPendiente();
      await tester.pumpAndSettle();

      expect(sesionesRestauradas, 1);
      expect(find.text('EDICION'), findsOneWidget);
      expect(convocatorias.pedidas, [20]);
    });

    testWidgets('el aviso pendiente se abre una sola vez', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      PushNotificationService.simularMensajeInicial(_pushEditar());

      await PushNotificationService.procesarNotificacionInicial();
      _abrirPendiente();
      _abrirPendiente();
      await tester.pumpAndSettle();

      expect(sesionesRestauradas, 1);
      expect(convocatorias.pedidas, [20]);
    });

    testWidgets(
      'sin aviso pendiente no se restaura la sesión ni se abre nada',
      (tester) async {
        await _pintarApp(tester);

        _abrirPendiente();

        expect(sesionesRestauradas, 0);
        expect(find.text('HOME'), findsOneWidget);
      },
    );

    testWidgets('el destino de CONVOCATORIA se decide con el rol de la sesión '
        'restaurada, no con el de antes de restaurarla', (tester) async {
      await _pintarApp(tester);

      // Al arrancar en frío todavía no hay usuario...
      expect(AuthManager.usuarioActual, isNull);

      // ...la sesión se restaura y resulta ser de un jugador.
      PushNotificationService.restaurarSesion = () async {
        sesionesRestauradas++;
        await _conUsuario(['JUGADOR']);
        return true;
      };

      PushNotificationService.simularMensajeInicial(_pushConvocatoria());

      await PushNotificationService.procesarNotificacionInicial();
      _abrirPendiente();
      await tester.pumpAndSettle();

      expect(find.text('CALENDARIO'), findsOneWidget);
      expect(calendarios, [DateTime(2026, 10, 24)]);
    });

    testWidgets('sin sesión válida el aviso se descarta y no se navega a nada', (
      tester,
    ) async {
      await _pintarApp(tester);

      // Un push CONVOCATORIA real, con su referenciaId (la comunicación 78): sin
      // el descarte, al no resolverse el rol acabaría abriendo esa comunicación.
      PushNotificationService.simularMensajeInicial(_pushConvocatoria());

      await PushNotificationService.procesarNotificacionInicial();
      _abrirPendiente();
      await tester.pumpAndSettle();

      expect(sesionesRestauradas, 1);
      expect(find.text('CALENDARIO'), findsNothing);
      expect(find.text('EDICION'), findsNothing);
      expect(find.byType(ComunicacionDetallePage), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      expect(calendarios, isEmpty);
      expect(convocatorias.pedidas, isEmpty);

      // Y el aviso no se queda guardado para más tarde.
      _abrirPendiente();
      await tester.pumpAndSettle();

      expect(sesionesRestauradas, 1);
      expect(find.byType(ComunicacionDetallePage), findsNothing);
    });

    testWidgets('con sesión inválida se descarta aunque quedara un usuario en '
        'memoria', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      // restaurarSesion() dice que la sesión ya no vale (devuelve false).
      PushNotificationService.restaurarSesion = () async {
        sesionesRestauradas++;
        return false;
      };
      PushNotificationService.simularMensajeInicial(_pushEditar());

      await PushNotificationService.procesarNotificacionInicial();
      _abrirPendiente();
      await tester.pumpAndSettle();

      expect(sesionesRestauradas, 1);
      expect(find.text('EDICION'), findsNothing);
      expect(convocatorias.pedidas, isEmpty);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('si falla la restauración de la sesión también se descarta', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);
      await _pintarApp(tester);

      PushNotificationService.restaurarSesion = () async =>
          throw Exception('sin red');
      PushNotificationService.simularMensajeInicial(_pushEditar());

      await PushNotificationService.procesarNotificacionInicial();
      _abrirPendiente();
      await tester.pumpAndSettle();

      expect(find.text('EDICION'), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  // ---- el splash no tapa el destino --------------------------------------------------------------

  group('splash', () {
    List<String> eventos = [];

    Future<void> pintarSplash(WidgetTester tester) async {
      eventos = [];

      PushNotificationService.restaurarSesion = () async {
        eventos.add('sesion');
        await _conUsuario(['JUGADOR']);
        return true;
      };

      AppNavigator.constructorCalendario = (dia) {
        eventos.add('calendario');
        return const Scaffold(body: Text('CALENDARIO'));
      };

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
          routes: {
            AppRoutes.public: (_) {
              eventos.add('home');
              return const Scaffold(body: Text('HOME'));
            },
          },
          home: SplashPage(
            duracion: const Duration(milliseconds: 200),
            inicializarNotificaciones: () async {
              eventos.add('notificaciones');
              await PushNotificationService.procesarNotificacionInicial();
            },
          ),
        ),
      );
    }

    testWidgets(
      'el aviso se abre sobre home, después de restaurar la sesión, y '
      'el splash no lo tapa',
      (tester) async {
        PushNotificationService.simularMensajeInicial(_pushConvocatoria());

        await pintarSplash(tester);
        await tester.pump(const Duration(milliseconds: 50));

        // Mientras dura el splash no se abre nada.
        expect(find.text('CALENDARIO'), findsNothing);
        expect(eventos, ['notificaciones']);

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Primero home, luego la sesión, luego el destino.
        expect(eventos, ['notificaciones', 'home', 'sesion', 'calendario']);
        expect(find.text('CALENDARIO'), findsOneWidget);

        // Debajo del calendario está home (no lo ha reemplazado el splash).
        AppNavigator.navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();

        expect(find.text('HOME'), findsOneWidget);
      },
    );

    testWidgets('sin aviso, el splash solo pasa a home', (tester) async {
      await pintarSplash(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(eventos, ['notificaciones', 'home']);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('si la inicialización de notificaciones falla, el splash pasa '
        'a home igualmente', (tester) async {
      eventos = [];

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
          routes: {AppRoutes.public: (_) => const Scaffold(body: Text('HOME'))},
          home: SplashPage(
            duracion: const Duration(milliseconds: 100),
            inicializarNotificaciones: () async => throw Exception('sin FCM'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
