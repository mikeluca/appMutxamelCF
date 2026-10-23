import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/core/version/control_version.dart';
import 'package:app_mutxamel_cf/core/version/pantalla_version_obsoleta.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_partido_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_partido_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Con la versión obsoleta la app queda en PantallaVersionObsoleta: ningún push
/// puede abrir nada encima. Además, el aviso de una convocatoria muestra una
/// carga mientras se piden el perfil y las convocatorias.

class _ServicioLento extends ConvocatoriaPartidoService {
  final Completer<ConvocatoriaPartidoModel> respuesta = Completer();
  int consultas = 0;

  @override
  Future<ConvocatoriaPartidoModel> obtener({
    required int partidoId,
    required int jugadorId,
  }) {
    consultas++;

    return respuesta.future;
  }
}

ConvocatoriaPartidoModel _convocatoria() => ConvocatoriaPartidoModel(
  convocatoriaId: 20,
  rival: 'Pego C.F.',
  fecha: DateTime(2026, 10, 24),
  hora: '11:00',
  campo: 'Campo Municipal',
  local: true,
  horaCitacion: '09:30',
  lugarCitacion: 'Vestuarios',
  convocado: true,
  convocados: const [],
);

PerfilApp _perfil() => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: const ['FAMILIAR'],
  jugadores: [
    PerfilJugador(
      id: 100,
      nombre: 'Pablo',
      apellidos: 'Garcia',
      equipo: 'Cadete A',
      equipoId: 5,
    ),
  ],
  equipos: const [],
);

Future<void> _pintar(WidgetTester tester) async {
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

Future<void> _bloquear(WidgetTester tester) async {
  ControlVersion.reiniciar();
  ControlVersion.obtenerInstalada = () async => '1.0.0';
  ControlVersion.esIos = () => false;
  ControlVersion.obtenerRemota = () async => const VersionRemota(
    minimaAndroid: '2.0.0',
    minimaIos: '2.0.0',
    recomendadaAndroid: '2.0.0',
    recomendadaIos: '2.0.0',
    urlAndroid: '',
    urlIos: '',
  );

  await tester.runAsync(ControlVersion.comprobar);
  await tester.pumpAndSettle();

  expect(ControlVersion.bloqueada, isTrue);
  expect(find.byType(PantallaVersionObsoleta), findsOneWidget);
}

RemoteMessage _pushEditar({String titulo = 'Aviso'}) => RemoteMessage(
  data: {
    'tipo': 'CONVOCATORIA_EDITAR',
    'referenciaId': '77',
    'convocatoriaId': '20',
  },
  notification: RemoteNotification(title: titulo, body: 'Texto'),
);

void main() {
  late List<String> abiertas;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    abiertas = [];

    AppNavigator.constructorCalendario = (dia) {
      abiertas.add('calendario');
      return const Scaffold(body: Text('CALENDARIO'));
    };
    AppNavigator.constructorEdicion = (c) {
      abiertas.add('edicion');
      return const Scaffold(body: Text('EDICION'));
    };
    AppNavigator.constructorAsistencia = (e) {
      abiertas.add('asistencia');
      return const Scaffold(body: Text('ASISTENCIA'));
    };
    AppNavigator.constructorModeracion = () {
      abiertas.add('moderacion');
      return const Scaffold(body: Text('MODERACION'));
    };
    AppNavigator.constructorFormularioConvocatoria = (id, e) {
      abiertas.add('formulario-convocatoria');
      return const Scaffold(body: Text('FORM CONVOCATORIA'));
    };
    AppNavigator.constructorFormularioResultado = (p) {
      abiertas.add('formulario-resultado');
      return const Scaffold(body: Text('FORM RESULTADO'));
    };
    AuthManager.olvidarUsuario();
  });

  tearDown(() {
    AppNavigator.constructorCalendario = null;
    AppNavigator.constructorEdicion = null;
    AppNavigator.constructorAsistencia = null;
    AppNavigator.constructorModeracion = null;
    AppNavigator.constructorFormularioConvocatoria = null;
    AppNavigator.constructorFormularioResultado = null;
    AppNavigator.cargarPerfilParaAviso = null;
    AppNavigator.fabricaConvocatoriaPartidoService = null;
    AppNavigator.constructorConvocatoriaFamilia = null;
    PushNotificationService.simularMensajeInicial(null);
    ControlVersion.reiniciar();
    AuthManager.olvidarUsuario();
  });

  group('con la versión bloqueada ningún destino se abre', () {
    testWidgets('abrirDestinoConvocatoria, todos los destinos', (tester) async {
      await _pintar(tester);
      await _bloquear(tester);

      final destinos = <DestinoConvocatoria>[
        AbrirCalendario(DateTime(2026, 10, 24)),
        AbrirDetalleConvocatoria(30, DateTime(2026, 10, 24)),
        const AbrirFormularioConvocatoria(
          partidoId: 30,
          equipoId: 5,
          equipo: 'Cadete A',
        ),
        const EditarConvocatoria(20),
        const PasarLista(7),
        const AbrirModeracion(),
      ];

      for (final destino in destinos) {
        await AppNavigator.abrirDestinoConvocatoria(destino);
      }

      await tester.pumpAndSettle();

      expect(abiertas, isEmpty);
      expect(find.byType(PantallaVersionObsoleta), findsOneWidget);
      expect(find.text('CALENDARIO'), findsNothing);
    });

    testWidgets('los abrir* sueltos tampoco', (tester) async {
      await _pintar(tester);
      await _bloquear(tester);

      await AppNavigator.abrirCalendario();
      await AppNavigator.abrirModeracion();
      await AppNavigator.abrirEdicionConvocatoria(20);
      await AppNavigator.abrirAsistenciaEntrenamiento(7);
      await AppNavigator.abrirFormularioConvocatoria(30, 5, 'Cadete A');
      await AppNavigator.abrirChatPrivado(9);
      await AppNavigator.abrirComunicacion(11);
      await tester.pumpAndSettle();

      expect(abiertas, isEmpty);
      expect(find.byType(PantallaVersionObsoleta), findsOneWidget);
    });

    testWidgets('un push (procesarNotificacion) no abre nada', (tester) async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['ENTRENADOR']),
      );
      await _pintar(tester);
      await _bloquear(tester);

      await PushNotificationService.procesarNotificacion(_pushEditar());
      await tester.pumpAndSettle();

      expect(abiertas, isEmpty);
      expect(find.byType(PantallaVersionObsoleta), findsOneWidget);
    });

    testWidgets('procesarAvisoPendiente no navega ni restaura la sesión', (
      tester,
    ) async {
      var sesiones = 0;
      PushNotificationService.restaurarSesion = () async {
        sesiones++;
        return true;
      };

      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['ENTRENADOR']),
      );
      await _pintar(tester);

      PushNotificationService.simularMensajeInicial(
        _pushEditar(titulo: 'Convocado con ausencia justificada'),
      );
      await PushNotificationService.procesarNotificacionInicial();
      await _bloquear(tester);

      await PushNotificationService.procesarAvisoPendiente();
      await tester.pumpAndSettle();

      expect(sesiones, 0);
      expect(abiertas, isEmpty);
      expect(find.byType(PantallaVersionObsoleta), findsOneWidget);
    });
  });

  group('indicador de carga del aviso de una convocatoria', () {
    testWidgets('se ve mientras se hacen las peticiones y desaparece', (
      tester,
    ) async {
      await _pintar(tester);

      final servicio = _ServicioLento();
      AppNavigator.fabricaConvocatoriaPartidoService = () => servicio;
      AppNavigator.cargarPerfilParaAviso = () async => _perfil();
      AppNavigator.constructorConvocatoriaFamilia = (partidoId, jugador) =>
          const Scaffold(body: Text('PANTALLA'));

      unawaited(
        AppNavigator.abrirDetalleConvocatoria(30, DateTime(2026, 10, 24)),
      );
      await tester.pump();
      await tester.pump();

      expect(servicio.consultas, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('PANTALLA'), findsNothing);

      servicio.respuesta.complete(_convocatoria());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('PANTALLA'), findsOneWidget);
    });

    testWidgets('si falla, la carga se quita y se abre el calendario', (
      tester,
    ) async {
      await _pintar(tester);

      AppNavigator.cargarPerfilParaAviso = () async =>
          throw Exception('sin red');

      unawaited(
        AppNavigator.abrirDetalleConvocatoria(30, DateTime(2026, 10, 24)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('CALENDARIO'), findsOneWidget);
    });
  });
}
