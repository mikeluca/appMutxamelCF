import 'package:app_mutxamel_cf/features/admin/services/admin_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../support/http_test_helpers.dart';

class _AdminFalso extends AdminService {
  @override
  Future<int> contarReportesPendientes() async => 4;
}

/// Rutas a las que se ha navegado.
final _rutas = <String>[];

Future<void> _pintar(WidgetTester tester, List<String> roles) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await AuthSession.guardarSesion(
    LoginResponse(token: 'tok', usuarioId: 1, email: 'a@b.c', roles: roles),
  );
  await AuthManager.establecerUsuario(
    AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles, nombre: 'Ana Ruiz'),
  );

  await conMockHttp(
    (request) async {
      if (request.url.path.endsWith('/comunicaciones/no-leidas/count')) {
        return http.Response('7', 200);
      }
      return http.Response('no esperado: ${request.url.path}', 404);
    },
    () async {
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
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ClubPage(adminService: _AdminFalso()),
              );
            }
            _rutas.add(settings.name!);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => Scaffold(
                appBar: AppBar(),
                body: Text('DESTINO ${settings.name}'),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
    },
  );
}

double _y(WidgetTester tester, String texto) =>
    tester.getTopLeft(find.text(texto)).dy;

void main() {
  setUp(() {
    _rutas.clear();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );
  });

  tearDown(AuthManager.olvidarUsuario);

  testWidgets('las secciones salen en su orden, con sus opciones en el '
      'suyo', (tester) async {
    await _pintar(tester, ['COORDINADOR', 'ADMIN_APP', 'RETRANSMISION']);

    final esperado = [
      'Club',
      'Comunicaciones',
      'Calendario',
      'Todos los partidos',
      'Clasificaciones',
      'Coordinación',
      'Todos los equipos',
      'Fin de semana',
      'Seguimiento de jugadores',
      'Administración',
      'Moderación',
      'Cuentas pendientes',
      'Directo y RRSS',
      'Partido en directo',
      'Imágenes para redes',
      'Mi cuenta',
      'Mi perfil',
      'Cerrar sesión',
    ];

    var anterior = -1.0;
    for (final texto in esperado) {
      // El título de la sección es "Directo y RRSS" (el chip del rol sigue siendo "Retransmisión").
      final candidatos = find.text(texto);
      expect(candidatos, findsWidgets, reason: texto);
      final y = tester
          .widgetList<Text>(candidatos)
          .map((w) => tester.getTopLeft(find.byWidget(w)).dy)
          .where((dy) => dy > anterior)
          .fold<double?>(null, (m, dy) => m == null || dy < m ? dy : m);
      expect(y, isNotNull, reason: '$texto fuera de orden');
      anterior = y!;
    }
  });

  testWidgets('la cabecera enseña el nombre y los roles como chips', (
    tester,
  ) async {
    await _pintar(tester, ['JUGADOR', 'SOCIO']);

    expect(find.text('Ana Ruiz'), findsOneWidget);
    expect(find.text('Jugador'), findsWidgets);
    expect(find.text('Socio'), findsOneWidget);
    // "Jugador" es a la vez chip y título de sección.
    expect(find.text('Mi ficha'), findsOneWidget);
    expect(_y(tester, 'Ana Ruiz'), lessThan(_y(tester, 'Socio')));
  });

  testWidgets('los contadores siguen apareciendo', (tester) async {
    await _pintar(tester, ['ADMIN_APP']);

    expect(find.text('7'), findsOneWidget); // comunicaciones sin leer
    expect(find.text('4'), findsOneWidget); // reportes pendientes
  });

  testWidgets('quien solo es SOCIO ve Club y Mi cuenta y nada más', (
    tester,
  ) async {
    await _pintar(tester, ['SOCIO']);

    expect(find.text('Club'), findsOneWidget);
    expect(find.text('Mi cuenta'), findsOneWidget);
    for (final titulo in [
      'Jugador',
      'Familia',
      'Entrenador',
      'Coordinación',
      'Administración',
      'Directo y RRSS',
    ]) {
      expect(find.text(titulo), findsNothing, reason: titulo);
    }
    expect(find.text('Clasificaciones'), findsNothing);
    expect(find.text('Mis clasificaciones'), findsNothing);
  });

  testWidgets('Mis equipos solo sale en Entrenador y no se duplica', (
    tester,
  ) async {
    await _pintar(tester, ['ENTRENADOR', 'COORDINADOR']);

    expect(find.text('Entrenador'), findsOneWidget); // solo el chip
    expect(find.text('Mis equipos'), findsNothing);
    expect(find.text('Todos los equipos'), findsOneWidget);
  });

  group('cada opción navega a la misma ruta de siempre', () {
    final casos = <String, List<Object>>{
      'Comunicaciones': ['/communication'],
      'Calendario': ['/calendar'],
      'Todos los partidos': ['/my-matches'],
      'Clasificaciones': ['/my-standings'],
      'Todos los equipos': ['/my-teams'],
      'Fin de semana': ['/coordination/weekend'],
      'Seguimiento de jugadores': ['/coordination/player-tracking'],
      'Moderación': ['/admin/moderation'],
      'Cuentas pendientes': ['/admin/pending-accounts'],
      'Partido en directo': ['/live-match'],
      'Imágenes para redes': ['/social-images'],
      'Mi perfil': ['/profile'],
    };

    for (final caso in casos.entries) {
      testWidgets(caso.key, (tester) async {
        await _pintar(tester, ['COORDINADOR', 'ADMIN_APP', 'RETRANSMISION']);

        await conMockHttp((request) async => http.Response('0', 200), () async {
          await tester.tap(find.text(caso.key).last);
          await tester.pumpAndSettle();
        });

        expect(_rutas, [caso.value.first]);
      });
    }

    final porRol = <String, List<String>>{
      'Mi ficha': ['JUGADOR', '/my-card'],
      'Mis jugadores': ['FAMILIAR', '/players'],
      'Mis equipos': ['ENTRENADOR', '/my-teams'],
      'Mis partidos': ['SOCIO', '/my-matches'],
    };

    for (final caso in porRol.entries) {
      testWidgets('${caso.key} (${caso.value[0]})', (tester) async {
        await _pintar(tester, [caso.value[0]]);

        await conMockHttp((request) async => http.Response('0', 200), () async {
          await tester.tap(find.text(caso.key));
          await tester.pumpAndSettle();
        });

        expect(_rutas, [caso.value[1]]);
      });
    }
  });

  group('Directo y RRSS según el rol', () {
    testWidgets('RETRANSMISION: solo Partido en directo', (tester) async {
      await _pintar(tester, ['RETRANSMISION']);

      expect(find.text('Directo y RRSS'), findsOneWidget);
      expect(find.text('Partido en directo'), findsOneWidget);
      expect(find.text('Imágenes para redes'), findsNothing);
    });

    testWidgets('RRSS: solo Imágenes para redes', (tester) async {
      await _pintar(tester, ['RRSS']);

      expect(find.text('Directo y RRSS'), findsOneWidget);
      expect(find.text('Imágenes para redes'), findsOneWidget);
      expect(find.text('Partido en directo'), findsNothing);
    });

    testWidgets('RETRANSMISION + RRSS sin más roles: solo Directo y RRSS y Mi '
        'cuenta, y no pide nada de comunicaciones', (tester) async {
      await _pintar(tester, ['RETRANSMISION', 'RRSS']);

      double y(String t) => tester.getTopLeft(find.text(t).first).dy;
      expect(y('Directo y RRSS'), lessThan(y('Partido en directo')));
      expect(y('Partido en directo'), lessThan(y('Imágenes para redes')));
      expect(y('Imágenes para redes'), lessThan(y('Mi cuenta')));
      expect(y('Mi cuenta'), lessThan(y('Mi perfil')));
      expect(y('Mi perfil'), lessThan(y('Cerrar sesión')));

      expect(find.text('Club'), findsNothing);
      expect(find.text('Comunicaciones'), findsNothing);
      expect(find.text('Calendario'), findsNothing);
      expect(find.text('Mis partidos'), findsNothing);
      expect(find.text('Clasificaciones'), findsNothing);
      expect(find.text('Pedir acceso a otro jugador'), findsNothing);
    });

    for (final otro in ['ENTRENADOR', 'FAMILIAR', 'ADMIN_APP']) {
      testWidgets('RETRANSMISION + $otro: sigue viendo Club', (tester) async {
        await _pintar(tester, ['RETRANSMISION', otro]);

        expect(find.text('Club'), findsOneWidget);
        expect(find.text('Comunicaciones'), findsOneWidget);
        expect(find.text('Calendario'), findsOneWidget);
        expect(find.text('Pedir acceso a otro jugador'), findsOneWidget);
        expect(find.text('Directo y RRSS'), findsOneWidget);
      });
    }

    testWidgets('ADMIN_APP: Partido en directo e Imágenes para redes', (
      tester,
    ) async {
      await _pintar(tester, ['ADMIN_APP']);

      expect(find.text('Directo y RRSS'), findsOneWidget);
      expect(find.text('Imágenes para redes'), findsOneWidget);
      expect(find.text('Partido en directo'), findsOneWidget);
    });

    testWidgets('los dos roles: las dos opciones, una sola vez', (
      tester,
    ) async {
      await _pintar(tester, ['RETRANSMISION', 'ADMIN_APP']);

      expect(find.text('Directo y RRSS'), findsOneWidget);
      expect(find.text('Partido en directo'), findsOneWidget);
      expect(find.text('Imágenes para redes'), findsOneWidget);
    });

    testWidgets('COORDINADOR no ve la sección', (tester) async {
      await _pintar(tester, ['COORDINADOR']);

      expect(find.text('Directo y RRSS'), findsNothing);
      expect(find.text('Imágenes para redes'), findsNothing);
      expect(find.text('Partido en directo'), findsNothing);
    });
  });
}
