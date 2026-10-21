import 'dart:convert';
import 'dart:io';

import 'package:app_mutxamel_cf/features/auth/pages/activar_cuenta_page.dart';
import 'package:app_mutxamel_cf/features/auth/pages/login_page.dart';
import 'package:app_mutxamel_cf/features/auth/pages/recuperar_password_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/http_test_helpers.dart';

const _mensajeEnviado =
    'Si el email tiene una cuenta en el club, recibirás un código en unos '
    'minutos. Revisa también la carpeta de spam.';

Future<void> _pintar(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
      routes: {'/club': (_) => const Scaffold(body: Text('AREA CLUB'))},
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

http.Response _json(Object cuerpo, [int estado = 200]) => http.Response(
  jsonEncode(cuerpo),
  estado,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Backend simulado: registra las peticiones y responde según [restablecer].
class _Backend {
  final peticiones = <String>[];
  final cuerpos = <Map<String, dynamic>>[];
  http.Response Function() restablecer;
  Object? errorRed;
  bool meFalla = false;

  _Backend({http.Response Function()? restablecer})
    : restablecer =
          restablecer ??
          (() => _json({
            'token': 'jwt-nuevo',
            'usuarioId': 7,
            'email': 'ana@example.com',
            'roles': ['JUGADOR'],
          }));

  Future<http.Response> responder(http.Request request) async {
    peticiones.add('${request.method} ${request.url.path}');

    if (request.body.isNotEmpty) {
      cuerpos.add(jsonDecode(request.body) as Map<String, dynamic>);
    }

    if (errorRed != null) {
      throw errorRed!;
    }

    switch (request.url.path) {
      case '/api/app/auth/recuperar':
        return http.Response('', 204);
      case '/api/app/auth/restablecer':
        return restablecer();
      case '/api/app/auth/me':
        if (meFalla) {
          return http.Response('boom', 500);
        }

        return _json({
          'usuarioId': 7,
          'email': 'ana@example.com',
          'roles': ['JUGADOR'],
        });
    }

    return http.Response('no esperado: ${request.url.path}', 404);
  }

  int veces(String ruta) => peticiones.where((p) => p.endsWith(ruta)).length;
}

Future<void> _rellenarYEnviarEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField), email);
  await tester.tap(find.text('Enviar código'));
  await tester.pumpAndSettle();
}

Future<void> _rellenarPantalla2(
  WidgetTester tester, {
  String codigo = '123456',
  String password = 'nueva-clave-1',
  String confirmar = 'nueva-clave-1',
}) async {
  await tester.enterText(find.byKey(const Key('recuperar_codigo')), codigo);
  await tester.enterText(find.byKey(const Key('recuperar_password')), password);
  await tester.enterText(
    find.byKey(const Key('recuperar_confirmar')),
    confirmar,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );
    AuthManager.olvidarUsuario();
  });

  group('enlace en el login', () {
    testWidgets('está bajo el botón de entrar y prerrellena el email', (
      tester,
    ) async {
      await _pintar(tester, const LoginPage());

      expect(find.text('¿Has olvidado tu contraseña?'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'ana@example.com',
      );
      await tester.tap(find.text('¿Has olvidado tu contraseña?'));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar contraseña'), findsWidgets);
      expect(find.text('ana@example.com'), findsOneWidget);
    });
  });

  group('flujo completo', () {
    testWidgets('pide el código, cambia la contraseña y entra al Área Club', (
      tester,
    ) async {
      final backend = _Backend();

      await conMockHttp(backend.responder, () async {
        await _pintar(
          tester,
          const RecuperarPasswordPage(emailInicial: 'Ana@Example.com'),
        );

        // Prerrellenado con el del login.
        expect(find.text('Ana@Example.com'), findsOneWidget);

        await tester.tap(find.text('Enviar código'));
        await tester.pumpAndSettle();

        // Pantalla 2: siempre el mismo mensaje, email fijo y sin editar.
        expect(find.text(_mensajeEnviado), findsOneWidget);
        expect(find.text('ana@example.com'), findsOneWidget);
        expect(backend.cuerpos.first, {'email': 'ana@example.com'});

        await _rellenarPantalla2(tester);
        await tester.tap(find.text('Cambiar contraseña'));
        await tester.pumpAndSettle();

        expect(backend.cuerpos[1], {
          'email': 'ana@example.com',
          'codigo': '123456',
          'password': 'nueva-clave-1',
        });
      });

      // Sesión guardada como en el login y pila limpia en el Área Club.
      expect(await AuthSession.obtenerToken(), 'jwt-nuevo');
      expect(AuthManager.estaAutenticado, isTrue);
      expect(find.text('AREA CLUB'), findsOneWidget);
      expect(find.text('Contraseña cambiada'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('un código incorrecto enseña el error y no inicia sesión', (
      tester,
    ) async {
      final backend = _Backend(
        restablecer: () => http.Response('Código incorrecto o caducado', 400),
      );

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');
        await _rellenarPantalla2(tester, codigo: '000000');
        await tester.tap(find.text('Cambiar contraseña'));
        await tester.pumpAndSettle();
      });

      expect(find.text('Código incorrecto o caducado'), findsOneWidget);
      expect(find.text('AREA CLUB'), findsNothing);
      expect(await AuthSession.estaAutenticado(), isFalse);
    });

    testWidgets('un error de red enseña el mensaje de conexión, nunca la '
        'excepción', (tester) async {
      final backend = _Backend();

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');
        await _rellenarPantalla2(tester);

        backend.errorRed = const SocketException('sin red');
        await tester.tap(find.text('Cambiar contraseña'));
        await tester.pumpAndSettle();
      });

      expect(
        find.text(
          'No se ha podido conectar. Comprueba tu conexión e inténtalo de '
          'nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('SocketException'), findsNothing);
      expect(find.textContaining('sin red'), findsNothing);
    });

    testWidgets('si falla el envío del código no pasa a la pantalla 2', (
      tester,
    ) async {
      final backend = _Backend()..errorRed = const SocketException('sin red');

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');
      });

      expect(find.text(_mensajeEnviado), findsNothing);
      expect(find.textContaining('No se ha podido conectar'), findsOneWidget);
    });

    testWidgets('valida las mismas reglas que activar la cuenta', (
      tester,
    ) async {
      final backend = _Backend();

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');

        await _rellenarPantalla2(
          tester,
          codigo: '12',
          password: 'corta',
          confirmar: 'otra',
        );
        await tester.tap(find.text('Cambiar contraseña'));
        await tester.pumpAndSettle();
      });

      expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(backend.veces('/restablecer'), 0);
    });
  });

  group('demasiados intentos (429)', () {
    final textoLimite =
        'Demasiados intentos. Espera unos minutos y vuelve a probar.';

    http.Response limite() => _json({
      'codigo': 'DEMASIADOS_INTENTOS',
      'mensaje':
          'Demasiados intentos fallidos. Inténtalo de nuevo en unos minutos.',
    }, 429);

    testWidgets('en /restablecer se traduce a la clave l10n', (tester) async {
      final backend = _Backend(restablecer: limite);

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');
        await _rellenarPantalla2(tester);
        await tester.tap(find.text('Cambiar contraseña'));
        await tester.pumpAndSettle();
      });

      expect(find.text(textoLimite), findsOneWidget);
      expect(find.textContaining('Inténtalo de nuevo'), findsNothing);
    });

    testWidgets('en /recuperar se traduce a la clave l10n', (tester) async {
      await conMockHttp((request) async => limite(), () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');
      });

      expect(find.text(textoLimite), findsOneWidget);
      expect(find.text(_mensajeEnviado), findsNothing);
    });
  });

  group('contraseña cambiada pero sin poder dejar la sesión lista', () {
    testWidgets('lleva al login con el email relleno y el aviso', (
      tester,
    ) async {
      final backend = _Backend();

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');
        await _rellenarPantalla2(tester);

        backend.meFalla = true;
        await tester.tap(find.text('Cambiar contraseña'));
        await tester.pumpAndSettle();
      });

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(
        find.text(
          'Tu contraseña se ha cambiado. Entra con la nueva contraseña.',
        ),
        findsOneWidget,
      );
      expect(find.text('AREA CLUB'), findsNothing);
      // No se queda una sesión a medias.
      expect(await AuthSession.estaAutenticado(), isFalse);
      expect(AuthManager.estaAutenticado, isFalse);
    });
  });

  group('cuenta sin activar', () {
    testWidgets('la pantalla 2 enlaza a Activar cuenta con el email', (
      tester,
    ) async {
      final backend = _Backend();

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'nuevo@example.com');
      });

      expect(
        find.textContaining('¿Aún no has activado tu cuenta?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Activar cuenta'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivarCuentaPage), findsOneWidget);
      expect(find.text('nuevo@example.com'), findsOneWidget);
    });
  });

  group('reenviar código', () {
    testWidgets('se habilita a los 2 minutos con cuenta atrás', (tester) async {
      final backend = _Backend();

      await conMockHttp(backend.responder, () async {
        await _pintar(tester, const RecuperarPasswordPage());
        await _rellenarYEnviarEmail(tester, 'ana@example.com');

        TextButton enlace() => tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Reenviar código (2:00)'),
        );

        // Al llegar: deshabilitado y a 2:00.
        expect(enlace().onPressed, isNull);

        await tester.pump(const Duration(seconds: 61));
        expect(find.text('Reenviar código (0:59)'), findsOneWidget);

        await tester.pump(const Duration(seconds: 58));
        expect(find.text('Reenviar código (0:01)'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, 'Reenviar código (0:01)'),
              )
              .onPressed,
          isNull,
        );

        // A los 2 minutos exactos queda habilitado.
        await tester.pump(const Duration(seconds: 1));
        final habilitado = find.widgetWithText(TextButton, 'Reenviar código');
        expect(tester.widget<TextButton>(habilitado).onPressed, isNotNull);

        // Reenviar pide otro código y reinicia la cuenta atrás.
        expect(backend.veces('/recuperar'), 1);
        await tester.tap(habilitado);
        await tester.pump();
        await tester.pump();
        expect(backend.veces('/recuperar'), 2);
        expect(find.text('Reenviar código (2:00)'), findsOneWidget);
      });
    });
  });
}
