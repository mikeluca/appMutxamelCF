import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/admin/models/admin_model.dart';
import 'package:app_mutxamel_cf/features/admin/pages/cuentas_pendientes_page.dart';
import 'package:app_mutxamel_cf/features/admin/pages/moderacion_page.dart';
import 'package:app_mutxamel_cf/features/admin/services/admin_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdmin extends AdminService {
  List<ReporteModel> pendientes = [_reporte(1), _reporte(2, otros: 2)];
  List<ReporteModel> resueltos = [
    _reporte(3, estado: estadoReporteDescartado, nota: 'Era una broma'),
  ];
  List<UsuarioPendienteModel> usuarios = [
    _usuario(1, 'pablo@x.es', 'Pablo Garcia', caducado: true),
    _usuario(2, 'ana@x.es', 'Ana Ruiz'),
  ];

  final List<String> llamadas = [];
  Object? fallo;
  int contador = 4;

  @override
  Future<List<ReporteModel>> obtenerReportes({bool resueltos = false}) async =>
      resueltos ? this.resueltos : pendientes;

  @override
  Future<int> contarReportesPendientes() async => contador;

  @override
  Future<void> descartar(int reporteId, {String? nota}) async {
    llamadas.add('descartar:$reporteId:$nota');
    if (fallo != null) throw fallo!;
  }

  @override
  Future<void> borrarMensaje(int reporteId, {String? nota}) async {
    llamadas.add('borrar:$reporteId:$nota');
  }

  @override
  Future<void> desactivarAutor(
    int reporteId, {
    String? nota,
    required bool borrarMensaje,
  }) async {
    llamadas.add('desactivar:$reporteId:$nota:$borrarMensaje');
  }

  @override
  Future<List<UsuarioPendienteModel>> obtenerUsuariosPendientes() async =>
      usuarios;

  @override
  Future<String> reenviarActivacion(int usuarioId) async {
    llamadas.add('reenviar:$usuarioId');
    if (fallo != null) throw fallo!;
    return usuarios.firstWhere((u) => u.id == usuarioId).email;
  }
}

ReporteModel _reporte(
  int id, {
  int otros = 0,
  String estado = estadoReportePendiente,
  String? nota,
  bool autorEsAdmin = false,
}) => ReporteModel(
  id: id,
  fechaReporte: DateTime(2026, 10, 21, 12, 30),
  motivo: 'Insultos',
  reportador: 'Reportador $id',
  autorId: 20,
  autor: 'Autor $id',
  autorActivo: true,
  autorEsAdmin: autorEsAdmin,
  titulo: 'Título $id',
  contenido: 'Texto reportado $id ${'muy largo ' * 40}',
  fechaMensaje: DateTime(2026, 10, 20, 9, 0),
  estado: estado,
  resueltoPor: estado == estadoReportePendiente ? null : 'Admin Uno',
  fechaResolucion: estado == estadoReportePendiente
      ? null
      : DateTime(2026, 10, 21, 13, 0),
  nota: nota,
  otrosReportesDelAutor: otros,
);

UsuarioPendienteModel _usuario(
  int id,
  String email,
  String nombre, {
  bool caducado = false,
}) => UsuarioPendienteModel(
  id: id,
  email: email,
  nombre: null,
  apellidos: null,
  roles: const ['JUGADOR'],
  vinculos: [nombre],
  fechaAlta: DateTime(2026, 10, 18),
  tokenCaducado: caducado,
  intentosActivacion: 0,
);

Widget _app(Widget home, {GlobalKey<NavigatorState>? navigatorKey}) =>
    MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Moderación', () {
    testWidgets('muestra pestañas y la tarjeta con mensaje, autor, reportador, '
        'motivo, fechas y reportes del autor', (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(_app(ModeracionPage(servicio: _FakeAdmin())));
      await tester.pumpAndSettle();

      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Resueltos'), findsOneWidget);
      expect(find.text('Autor: Autor 1'), findsOneWidget);
      expect(find.text('Reportado por: Reportador 1'), findsOneWidget);
      expect(find.text('Motivo: Insultos'), findsNWidgets(2));
      expect(find.textContaining('21/10/2026 12:30'), findsNWidgets(2));
      // Solo el reporte 2 tiene otros reportes (2 más + este = 3).
      expect(find.text('El autor tiene 3 reportes'), findsOneWidget);
    });

    testWidgets('el texto del mensaje se despliega', (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(_app(ModeracionPage(servicio: _FakeAdmin())));
      await tester.pumpAndSettle();

      Text texto() => tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('reporte-1')),
          matching: find.textContaining('Texto reportado 1'),
        ),
      );

      expect(texto().maxLines, 3);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('reporte-1')),
          matching: find.text('Ver más'),
        ),
      );
      await tester.pumpAndSettle();

      expect(texto().maxLines, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reporte-1')),
          matching: find.text('Ver menos'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Descartar pide confirmación con nota opcional y solo actúa '
        'si se confirma', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeAdmin();

      await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
      await tester.pumpAndSettle();

      Finder boton(String texto) => find.descendant(
        of: find.byKey(const ValueKey('reporte-1')),
        matching: find.text(texto),
      );

      // Cancelar: no se llama al servicio.
      await tester.tap(boton('Descartar'));
      await tester.pumpAndSettle();

      expect(
        find.text('¿Descartar este reporte? El mensaje se queda como está.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, isEmpty);

      // Confirmar con una nota.
      await tester.tap(boton('Descartar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Era una broma');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['descartar:1:Era una broma']);
      expect(find.text('Reporte resuelto'), findsOneWidget);
    });

    testWidgets('Borrar mensaje pide confirmación', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeAdmin();

      await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('reporte-2')),
          matching: find.text('Borrar mensaje'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('¿Borrar el mensaje para todos los usuarios?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['borrar:2:']);
    });

    testWidgets('Desactivar autor lleva el check "Borrar también el mensaje" '
        'marcado por defecto y se puede desmarcar', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeAdmin();

      await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
      await tester.pumpAndSettle();

      Finder desactivar(int id) => find.descendant(
        of: find.byKey(ValueKey('reporte-$id')),
        matching: find.text('Desactivar autor'),
      );

      // Por defecto marcado.
      await tester.tap(desactivar(1));
      await tester.pumpAndSettle();

      expect(find.text('Borrar también el mensaje'), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Desmarcado.
      await tester.tap(desactivar(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['desactivar:1::true', 'desactivar:2::false']);
    });

    testWidgets('si el servidor rechaza la acción se muestra su mensaje', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeAdmin()
        ..fallo = const ApiException(
          'No se puede desactivar a un administrador',
          statusCode: 400,
        );

      await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('reporte-1')),
          matching: find.text('Descartar'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se puede desactivar a un administrador'),
        findsOneWidget,
      );
    });

    testWidgets('la pestaña Resueltos muestra el estado, quién y la nota, sin '
        'acciones', (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(_app(ModeracionPage(servicio: _FakeAdmin())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resueltos'));
      await tester.pumpAndSettle();

      expect(find.text('Descartado'), findsOneWidget);
      expect(
        find.text('Resuelto por Admin Uno el 21/10/2026 13:00'),
        findsOneWidget,
      );
      expect(find.text('Era una broma'), findsOneWidget);
      expect(find.text('Borrar mensaje'), findsNothing);
    });

    testWidgets('sin reportes pendientes muestra el estado vacío', (
      tester,
    ) async {
      final servicio = _FakeAdmin()..pendientes = [];

      await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('No hay reportes pendientes'), findsOneWidget);
    });
  });

  group('Moderación: autor administrador, petición en curso y permisos', () {
    testWidgets(
      'no ofrece "Desactivar autor" si el autor es un administrador',
      (tester) async {
        _pantallaGrande(tester);

        final servicio = _FakeAdmin()
          ..pendientes = [_reporte(1, autorEsAdmin: true), _reporte(2)];

        await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
        await tester.pumpAndSettle();

        Finder desactivar(int id) => find.descendant(
          of: find.byKey(ValueKey('reporte-$id')),
          matching: find.text('Desactivar autor'),
        );

        expect(desactivar(1), findsNothing);
        expect(desactivar(2), findsOneWidget);
        // Las otras dos acciones siguen disponibles.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('reporte-1')),
            matching: find.text('Descartar'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('mientras hay una petición en curso los botones quedan '
        'deshabilitados', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeAdminLento();

      await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
      await tester.pumpAndSettle();

      Finder boton(String texto, int id) => find.ancestor(
        of: find.descendant(
          of: find.byKey(ValueKey('reporte-$id')),
          matching: find.text(texto),
        ),
        matching: find.bySubtype<ButtonStyleButton>(),
      );

      await tester.tap(boton('Descartar', 1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pump();

      // La petición no ha terminado.
      expect(
        tester.widget<ButtonStyleButton>(boton('Descartar', 2)).onPressed,
        isNull,
      );
      expect(
        tester.widget<ButtonStyleButton>(boton('Borrar mensaje', 2)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(boton('Desactivar autor', 2))
            .onPressed,
        isNull,
      );

      servicio.terminar.complete();
      await tester.pumpAndSettle();

      expect(
        tester.widget<ButtonStyleButton>(boton('Descartar', 2)).onPressed,
        isNotNull,
      );
    });

    testWidgets('un 403 al cargar o al actuar muestra "No tienes permiso"', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeAdmin()
        ..pendientes = [_reporte(1)]
        ..fallo = const ApiException('prohibido', statusCode: 403);

      await tester.pumpWidget(_app(ModeracionPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('reporte-1')),
          matching: find.text('Descartar'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.textContaining('No se ha podido conectar'), findsNothing);
    });
  });

  group('Avisos locales de REPORTE y PASAR_LISTA', () {
    test('sin permiso para el destino el payload es null y no cae en '
        'COMUNICACION:<id>', () {
      AuthManager.olvidarUsuario();

      for (final tipo in ['REPORTE', 'PASAR_LISTA']) {
        expect(
          LocalNotificationService.payloadDeAviso(
            comunicacionId: 90,
            titulo: 'Aviso',
            datos: {'tipo': tipo, 'reporteId': '5'},
          ),
          isNull,
          reason: tipo,
        );
      }

      // Un aviso normal sigue abriendo su comunicación.
      expect(
        LocalNotificationService.payloadDeAviso(
          comunicacionId: 90,
          titulo: 'Hola',
          datos: const {'tipo': 'COMUNICACION'},
        ),
        'COMUNICACION:90',
      );
    });

    test('un administrador sí tiene payload de REPORTE', () async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['ADMIN_APP']),
      );
      addTearDown(AuthManager.olvidarUsuario);

      expect(
        LocalNotificationService.payloadDeAviso(
          comunicacionId: 5,
          titulo: 'Nuevo mensaje reportado',
          datos: const {'tipo': 'REPORTE'},
        ),
        'REPORTE',
      );
    });

    test('REPORTE y PASAR_LISTA usan un espacio de ids distinto del de las '
        'comunicaciones', () {
      const reporte = {'tipo': 'REPORTE'};
      const lista = {'tipo': 'PASAR_LISTA'};
      const normal = {'tipo': 'COMUNICACION'};

      final ids = {
        LocalNotificationService.idDeNotificacion(5, reporte),
        LocalNotificationService.idDeNotificacion(5, lista),
        LocalNotificationService.idDeNotificacion(5, normal),
      };

      // Mismo número, tres notificaciones distintas.
      expect(ids, hasLength(3));
      expect(LocalNotificationService.idDeNotificacion(5, normal), 5);
      expect(
        LocalNotificationService.idDeNotificacion(5, reporte),
        isNot(LocalNotificationService.idDeNotificacion(6, reporte)),
      );
      // Dentro del rango de un entero de 32 bits.
      expect(
        LocalNotificationService.idDeNotificacion(99999999, lista),
        lessThan(2147483647),
      );
    });
  });

  group('Cuentas pendientes', () {
    testWidgets('lista nombre, email, roles, fecha de invitación y la etiqueta '
        '"Código caducado" solo si corresponde', (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(
        _app(CuentasPendientesPage(servicio: _FakeAdmin())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pablo Garcia'), findsWidgets);
      expect(find.text('pablo@x.es'), findsOneWidget);
      expect(find.text('JUGADOR'), findsNWidgets(2));
      expect(find.text('Invitado el 18/10'), findsNWidgets(2));
      expect(find.text('Código caducado'), findsOneWidget);
    });

    testWidgets('el buscador filtra por nombre o email', (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(
        _app(CuentasPendientesPage(servicio: _FakeAdmin())),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ana@');
      await tester.pumpAndSettle();

      expect(find.text('ana@x.es'), findsOneWidget);
      expect(find.text('pablo@x.es'), findsNothing);

      await tester.enterText(find.byType(TextField), 'PABLO');
      await tester.pumpAndSettle();

      expect(find.text('pablo@x.es'), findsOneWidget);
      expect(find.text('ana@x.es'), findsNothing);
    });

    testWidgets('reenviar pide confirmación, avisa con SnackBar y refresca', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeAdmin();

      await tester.pumpWidget(_app(CuentasPendientesPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('pendiente-1')),
          matching: find.text('Reenviar activación'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('¿Reenviar la invitación de activación a pablo@x.es?'),
        findsOneWidget,
      );

      // Cancelar no envía nada.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('pendiente-1')),
          matching: find.text('Reenviar activación'),
        ),
      );
      await tester.pumpAndSettle();

      // El tercero es el botón del diálogo.
      await tester.tap(
        find.widgetWithText(FilledButton, 'Reenviar activación'),
      );
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['reenviar:1']);
      expect(find.text('Invitación reenviada a pablo@x.es'), findsOneWidget);
    });

    testWidgets(
      'si el servidor limita el reenvío (429) se muestra su mensaje',
      (tester) async {
        _pantallaGrande(tester);

        final servicio = _FakeAdmin()
          ..fallo = const ApiException(
            'Ya se reenvió la activación a este usuario hace poco. '
            'Inténtalo de nuevo en 10 minutos.',
            statusCode: 429,
          );

        await tester.pumpWidget(
          _app(CuentasPendientesPage(servicio: servicio)),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('pendiente-2')),
            matching: find.text('Reenviar activación'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Reenviar activación'),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('en 10 minutos'), findsOneWidget);
      },
    );

    testWidgets('sin cuentas pendientes muestra el estado vacío', (
      tester,
    ) async {
      final servicio = _FakeAdmin()..usuarios = [];

      await tester.pumpWidget(_app(CuentasPendientesPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('No hay cuentas pendientes'), findsOneWidget);
    });
  });

  group('Menú del Área club por rol', () {
    Future<void> pintarClub(WidgetTester tester, List<String> roles) async {
      _pantallaGrande(tester);

      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
      );

      await tester.pumpWidget(_app(ClubPage(adminService: _FakeAdmin())));
      await tester.pumpAndSettle();
    }

    tearDown(AuthManager.olvidarUsuario);

    testWidgets(
      'ADMIN_APP ve Moderación con su contador y Cuentas pendientes',
      (tester) async {
        await pintarClub(tester, ['ADMIN_APP']);

        expect(find.text('Moderación'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('Cuentas pendientes'), findsOneWidget);
        expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      },
    );

    for (final rol in ['COORDINADOR', 'ENTRENADOR', 'FAMILIAR', 'JUGADOR']) {
      testWidgets('$rol no las ve', (tester) async {
        await pintarClub(tester, [rol]);

        expect(find.text('Moderación'), findsNothing);
        expect(find.text('Cuentas pendientes'), findsNothing);
      });
    }
  });

  group('Push REPORTE', () {
    late int sesiones;

    RemoteMessage push() => RemoteMessage(
      data: {
        'tipo': 'REPORTE',
        'referenciaId': '5',
        'reporteId': '5',
        'esPrivada': 'true',
        'autorId': '10',
      },
      notification: RemoteNotification(
        title: 'Nuevo mensaje reportado',
        body: 'Hay un mensaje pendiente de revisar en Moderación.',
      ),
    );

    Future<void> pintarApp(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(body: Text('HOME')),
          navigatorKey: AppNavigator.navigatorKey,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> conRol(String rol) => AuthManager.establecerUsuario(
      AuthUser(usuarioId: 1, email: 'a@b.c', roles: [rol]),
    );

    setUp(() {
      sesiones = 0;

      AuthManager.olvidarUsuario();
      PushNotificationService.simularMensajeInicial(null);
      PushNotificationService.restaurarSesion = () async {
        sesiones++;
        return AuthManager.estaAutenticado;
      };
      AppNavigator.constructorModeracion = () =>
          const Scaffold(body: Text('MODERACION'));
    });

    tearDown(() {
      AppNavigator.constructorModeracion = null;
      PushNotificationService.simularMensajeInicial(null);
      AuthManager.olvidarUsuario();
    });

    test(
      'el destino y el payload de REPORTE se leen y se escriben igual',
      () async {
        await conRol('ADMIN_APP');

        expect(
          destinoDeAvisoConvocatoria(tipo: 'REPORTE'),
          const AbrirModeracion(),
        );
        expect(payloadDeDestino(const AbrirModeracion()), 'REPORTE');
        expect(destinoDePayload('REPORTE'), const AbrirModeracion());
        expect(esAvisoDeConvocatoria(tipo: 'REPORTE'), isTrue);
      },
    );

    testWidgets('al tocar el push (app en segundo plano) abre Moderación', (
      tester,
    ) async {
      await conRol('ADMIN_APP');
      await pintarApp(tester);

      unawaited(PushNotificationService.procesarNotificacion(push()));
      await tester.pumpAndSettle();

      expect(find.text('MODERACION'), findsOneWidget);
    });

    testWidgets('quien no es administrador no abre nada (ni un chat ni una '
        'comunicación con el id del reporte)', (tester) async {
      await conRol('COORDINADOR');
      await pintarApp(tester);

      unawaited(PushNotificationService.procesarNotificacion(push()));
      await tester.pumpAndSettle();

      expect(find.text('MODERACION'), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('arranque en frío: espera a la sesión y abre Moderación', (
      tester,
    ) async {
      await conRol('ADMIN_APP');
      await pintarApp(tester);

      PushNotificationService.simularMensajeInicial(push());

      await PushNotificationService.procesarNotificacionInicial();
      await tester.pumpAndSettle();

      expect(sesiones, 0);
      expect(find.text('MODERACION'), findsNothing);

      unawaited(PushNotificationService.procesarAvisoPendiente());
      await tester.pumpAndSettle();

      expect(sesiones, 1);
      expect(find.text('MODERACION'), findsOneWidget);
    });
  });
}

/// Un servicio cuya acción de descartar no termina hasta que el test lo decide.
class _FakeAdminLento extends _FakeAdmin {
  final Completer<void> terminar = Completer<void>();

  @override
  Future<void> descartar(int reporteId, {String? nota}) => terminar.future;
}
