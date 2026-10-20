import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/model/entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/services/entrenamiento_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Push PASAR_LISTA: app abierta (onMessage), en segundo plano
/// (onMessageOpenedApp) y arranque en frío; todos abren la asistencia de ese
/// entrenamiento.

class _FakeEntrenamientoService extends EntrenamientoService {
  final List<int> pedidos = [];
  Object? fallo;

  @override
  Future<EntrenamientoModel> obtenerPorId(int entrenamientoId) async {
    pedidos.add(entrenamientoId);

    if (fallo != null) {
      throw fallo!;
    }

    return EntrenamientoModel(
      id: entrenamientoId,
      equipoId: 5,
      equipo: 'Cadete A',
      fecha: '2026-10-21',
      usuarioEntrenadorId: 1,
      asistencias: const [],
      listaRevisada: false,
    );
  }
}

void _tocar(RemoteMessage mensaje) =>
    unawaited(PushNotificationService.procesarNotificacion(mensaje));

void _abrirPendiente() =>
    unawaited(PushNotificationService.procesarAvisoPendiente());

RemoteMessage _pushPasarLista({String entrenamientoId = '42'}) => RemoteMessage(
  data: {
    'tipo': 'PASAR_LISTA',
    'referenciaId': '90',
    'esPrivada': 'true',
    'autorId': '30',
    'entrenamientoId': entrenamientoId,
  },
  notification: RemoteNotification(
    title: 'Pasar lista',
    body: '¿Has pasado lista del entrenamiento de hoy (18:00)?',
  ),
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
  late _FakeEntrenamientoService entrenamientos;
  late List<EntrenamientoModel> asistencias;
  late List<Map<String, dynamic>> mostradas;
  late int sesionesRestauradas;

  setUp(() {
    entrenamientos = _FakeEntrenamientoService();
    asistencias = [];
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

    AppNavigator.fabricaEntrenamientoService = () => entrenamientos;
    AppNavigator.constructorAsistencia = (entrenamiento) {
      asistencias.add(entrenamiento);
      return const Scaffold(body: Text('ASISTENCIA'));
    };
  });

  tearDown(() {
    AppNavigator.fabricaEntrenamientoService = null;
    AppNavigator.constructorAsistencia = null;
    PushNotificationService.simularMensajeInicial(null);
    AuthManager.olvidarUsuario();
  });

  Future<void> conEntrenador() => AuthManager.establecerUsuario(
    AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['ENTRENADOR']),
  );

  test(
    'el destino y el payload de PASAR_LISTA se leen y se escriben igual',
    () {
      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'PASAR_LISTA',
          datos: {'entrenamientoId': '42'},
        ),
        const PasarLista(42),
      );
      expect(
        destinoDeAvisoConvocatoria(tipo: 'PASAR_LISTA', datos: const {}),
        isNull,
      );
      expect(payloadDeDestino(const PasarLista(42)), 'PASAR_LISTA:42');
      expect(destinoDePayload('PASAR_LISTA:42'), const PasarLista(42));
      expect(destinoDePayload('PASAR_LISTA:x'), isNull);
      expect(esAvisoDeConvocatoria(tipo: 'PASAR_LISTA'), isTrue);
    },
  );

  testWidgets('con la app abierta sale como notificación local y, al tocarla, '
      'abre la asistencia de ese entrenamiento', (tester) async {
    await conEntrenador();
    await _pintarApp(tester);

    await PushNotificationService.mostrarEnPrimerPlano(_pushPasarLista());

    expect(mostradas, hasLength(1));

    final payload = LocalNotificationService.payloadDeAviso(
      comunicacionId: 90,
      titulo: 'Pasar lista',
      esPrivada: true,
      autorId: 30,
      datos: mostradas.single,
    );

    // Pasar lista tiene prioridad sobre abrir el chat privado del remitente.
    expect(payload, 'PASAR_LISTA:42');

    LocalNotificationService.procesarPayload(payload);
    await tester.pumpAndSettle();

    expect(find.text('ASISTENCIA'), findsOneWidget);
    expect(entrenamientos.pedidos, [42]);
    expect(asistencias.single.id, 42);
  });

  testWidgets('con la app en segundo plano abre la asistencia', (tester) async {
    await conEntrenador();
    await _pintarApp(tester);

    _tocar(_pushPasarLista(entrenamientoId: '77'));
    await tester.pumpAndSettle();

    expect(find.text('ASISTENCIA'), findsOneWidget);
    expect(entrenamientos.pedidos, [77]);
  });

  testWidgets('sin entrenamientoId no abre nada', (tester) async {
    await conEntrenador();
    await _pintarApp(tester);

    _tocar(
      RemoteMessage(
        data: {'tipo': 'PASAR_LISTA'},
        notification: RemoteNotification(title: 'Pasar lista'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ASISTENCIA'), findsNothing);
    expect(entrenamientos.pedidos, isEmpty);
  });

  testWidgets('si el entrenamiento ya no está disponible, se avisa', (
    tester,
  ) async {
    await conEntrenador();
    await _pintarApp(tester);

    entrenamientos.fallo = const ApiException('No existe', statusCode: 404);

    _tocar(_pushPasarLista());
    await tester.pumpAndSettle();

    expect(find.text('ASISTENCIA'), findsNothing);
    expect(
      find.text('Este entrenamiento ya no está disponible'),
      findsOneWidget,
    );
  });

  testWidgets('arranque en frío: el aviso espera a la sesión y luego abre la '
      'asistencia', (tester) async {
    await conEntrenador();
    await _pintarApp(tester);

    PushNotificationService.simularMensajeInicial(_pushPasarLista());

    await PushNotificationService.procesarNotificacionInicial();
    await tester.pumpAndSettle();

    expect(sesionesRestauradas, 0);
    expect(find.text('ASISTENCIA'), findsNothing);

    _abrirPendiente();
    await tester.pumpAndSettle();

    expect(sesionesRestauradas, 1);
    expect(find.text('ASISTENCIA'), findsOneWidget);
    expect(entrenamientos.pedidos, [42]);
  });

  testWidgets('arranque en frío sin sesión válida: se descarta', (
    tester,
  ) async {
    await _pintarApp(tester);

    PushNotificationService.simularMensajeInicial(_pushPasarLista());

    await PushNotificationService.procesarNotificacionInicial();
    _abrirPendiente();
    await tester.pumpAndSettle();

    expect(find.text('ASISTENCIA'), findsNothing);
    expect(entrenamientos.pedidos, isEmpty);
    expect(find.text('HOME'), findsOneWidget);
  });
}
