import 'dart:convert';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/pages/notificaciones_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/auth/services/notificacion_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../support/http_test_helpers.dart';

const _textoSinSesion =
    'Inicia sesión en el Área Club para ver tus avisos personales '
    '(convocatorias, mensajes…)';
const _textoAjustes =
    'Los avisos de noticias y resultados se activan en Club → Ajustes';

Future<void> _pintar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        '/login': (_) => const Scaffold(body: Text('PANTALLA LOGIN')),
        '/settings': (_) => const Scaffold(body: Text('PANTALLA AJUSTES')),
      },
      home: const NotificacionesPage(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _iniciarSesion() => AuthSession.guardarSesion(
  LoginResponse(token: 'tok', usuarioId: 1, email: 'a@b.c', roles: const []),
);

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );
  });

  group('sin sesión', () {
    testWidgets('no llama a ningún endpoint y enseña su propio estado', (
      tester,
    ) async {
      await conMockHttpQueNoDebeLlamarse(() async {
        await _pintar(tester);
      });

      expect(find.text(_textoSinSesion), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text(_textoAjustes), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      // No es la pantalla de error ni la de "no tienes notificaciones".
      expect(find.text('Reintentar'), findsNothing);
      expect(find.text('No tienes notificaciones.'), findsNothing);
    });

    testWidgets('el botón lleva al login y el enlace a Ajustes', (
      tester,
    ) async {
      await conMockHttpQueNoDebeLlamarse(() async {
        await _pintar(tester);

        await tester.tap(find.text('Ir a Ajustes'));
        await tester.pumpAndSettle();
        expect(find.text('PANTALLA AJUSTES'), findsOneWidget);

        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
        expect(find.text('PANTALLA LOGIN'), findsOneWidget);
      });
    });

    test('el contador de la campana vale 0 sin llamar al servidor', () async {
      final cantidad = await conMockHttpQueNoDebeLlamarse(
        NotificacionService.contarNoLeidas,
      );

      expect(cantidad, 0);
    });
  });

  group('con sesión', () {
    testWidgets('carga y enseña los avisos como hasta ahora', (tester) async {
      await _iniciarSesion();
      final peticiones = <String>[];

      await conMockHttp((request) async {
        peticiones.add('${request.method} ${request.url.path}');
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'tipo': 'COMUNICACION',
              'titulo': 'Aviso del míster',
              'mensaje': 'Mañana entrenamos a las 18:00',
              'referenciaId': 5,
              'fecha': '2026-10-20T10:00:00',
              'leida': false,
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }, () => _pintar(tester));

      expect(peticiones, ['GET /api/app/notificaciones']);
      expect(find.text('Aviso del míster'), findsOneWidget);
      expect(find.text(_textoSinSesion), findsNothing);
    });

    testWidgets('un 401 con la pantalla abierta enseña el estado sin sesión, '
        'no un error', (tester) async {
      await _iniciarSesion();

      await conMockHttp(
        (request) async => http.Response('', 401),
        () => _pintar(tester),
      );

      expect(find.text(_textoSinSesion), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      // ApiClient ya ha limpiado la sesión.
      expect(await AuthSession.estaAutenticado(), isFalse);
    });

    testWidgets('un fallo de red sigue siendo un error con reintento', (
      tester,
    ) async {
      await _iniciarSesion();

      await conMockHttp(
        (request) async => http.Response('boom', 500),
        () => _pintar(tester),
      );

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text(_textoSinSesion), findsNothing);
    });
  });
}
