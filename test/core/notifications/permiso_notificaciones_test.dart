import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/notifications/services/permiso_notificaciones.dart';
import 'package:app_mutxamel_cf/core/notifications/widgets/pantalla_avisos.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(
  Widget hijo, {
  Brightness brillo = Brightness.light,
  double letra = 1,
}) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(brightness: brillo),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(letra)),
      child: child!,
    ),
    home: hijo,
  );
}

void main() {
  late EstadoPermisoAvisos estado;
  late int peticionesDelSistema;
  late bool sistemaConcede;
  late int ajustesAbiertos;
  late int concedidos;
  late DateTime reloj;
  bool? resultado;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    estado = EstadoPermisoAvisos.sinDecidir;
    peticionesDelSistema = 0;
    sistemaConcede = true;
    ajustesAbiertos = 0;
    concedidos = 0;
    reloj = DateTime(2026, 11, 20, 10);
    resultado = null;

    final leer = PermisoNotificaciones.leerEstado;
    final pedir = PermisoNotificaciones.pedirAlSistema;
    final abrir = PermisoNotificaciones.abrirAjustes;
    final ahora = PermisoNotificaciones.ahora;
    final conceder = PermisoNotificaciones.alConceder;

    PermisoNotificaciones.leerEstado = () async => estado;
    PermisoNotificaciones.pedirAlSistema = () async {
      peticionesDelSistema++;
      if (sistemaConcede) estado = EstadoPermisoAvisos.concedido;
      return sistemaConcede;
    };
    PermisoNotificaciones.abrirAjustes = () async => ajustesAbiertos++;
    PermisoNotificaciones.ahora = () => reloj;
    PermisoNotificaciones.alConceder = () async => concedidos++;

    addTearDown(() {
      PermisoNotificaciones.leerEstado = leer;
      PermisoNotificaciones.pedirAlSistema = pedir;
      PermisoNotificaciones.abrirAjustes = abrir;
      PermisoNotificaciones.ahora = ahora;
      PermisoNotificaciones.alConceder = conceder;
    });
  });

  Future<void> pintar(WidgetTester tester, MotivoPermiso motivo) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado = await PermisoNotificaciones.asegurar(
                    context,
                    motivo,
                  );
                },
                child: const Text('Pedir'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pedir(WidgetTester tester) async {
    await tester.tap(find.text('Pedir'));
    await tester.pumpAndSettle();
  }

  group('pantalla previa', () {
    testWidgets(
      'sin decidir sale la pantalla con el escudo, el título y las tres ventajas',
      (tester) async {
        await pintar(tester, MotivoPermiso.inicioSesion);
        await pedir(tester);

        expect(find.byType(PantallaAvisos), findsOneWidget);
        expect(
          find.text('No te pierdas nada del Mutxamel C.F.'),
          findsOneWidget,
        );
        expect(find.text('Goles y resultados al momento'), findsOneWidget);
        expect(find.text('Convocatorias y cambios de horario'), findsOneWidget);
        expect(find.text('Noticias y avisos del club'), findsOneWidget);
        expect(find.text('Activar notificaciones'), findsOneWidget);
        expect(find.text('Ahora no'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        // Todavía no se ha lanzado la petición del sistema
        expect(peticionesDelSistema, 0);
      },
    );

    testWidgets('"Activar notificaciones" lanza la petición del sistema', (
      tester,
    ) async {
      await pintar(tester, MotivoPermiso.inicioSesion);
      await pedir(tester);

      await tester.tap(find.byKey(const ValueKey('avisos-activar')));
      await tester.pumpAndSettle();

      expect(peticionesDelSistema, 1);
      expect(concedidos, 1);
      expect(resultado, isTrue);
      expect(find.byType(PantallaAvisos), findsNothing);
    });

    testWidgets('si el sistema la rechaza, no se da por concedido', (
      tester,
    ) async {
      sistemaConcede = false;

      await pintar(tester, MotivoPermiso.inicioSesion);
      await pedir(tester);
      await tester.tap(find.byKey(const ValueKey('avisos-activar')));
      await tester.pumpAndSettle();

      expect(peticionesDelSistema, 1);
      expect(concedidos, 0);
      expect(resultado, isFalse);
    });

    testWidgets('"Ahora no" no pide el permiso del sistema', (tester) async {
      await pintar(tester, MotivoPermiso.inicioSesion);
      await pedir(tester);

      await tester.tap(find.byKey(const ValueKey('avisos-ahora-no')));
      await tester.pumpAndSettle();

      expect(peticionesDelSistema, 0);
      expect(resultado, isFalse);
      expect(await AppPreferences.obtenerOfertaAvisosVeces(), 1);
    });

    testWidgets('con el permiso ya concedido no sale nada', (tester) async {
      estado = EstadoPermisoAvisos.concedido;

      await pintar(tester, MotivoPermiso.seguirPartido);
      await pedir(tester);

      expect(find.byType(PantallaAvisos), findsNothing);
      expect(resultado, isTrue);
      expect(peticionesDelSistema, 0);
    });
  });

  group('cuántas veces se ofrece', () {
    Future<void> ahoraNo(WidgetTester tester) async {
      await pedir(tester);
      await tester.tap(find.byKey(const ValueKey('avisos-ahora-no')));
      await tester.pumpAndSettle();
    }

    testWidgets('como mucho dos veces en total y nunca antes de 7 días', (
      tester,
    ) async {
      await pintar(tester, MotivoPermiso.inicioSesion);

      // 1.ª vez
      await ahoraNo(tester);
      expect(await AppPreferences.obtenerOfertaAvisosVeces(), 1);

      // Al día siguiente: todavía no
      reloj = reloj.add(const Duration(days: 1));
      await pedir(tester);
      expect(find.byType(PantallaAvisos), findsNothing);
      expect(resultado, isFalse);

      // A los 6 días 23 h: todavía no
      reloj = reloj.add(const Duration(days: 5, hours: 23));
      await pedir(tester);
      expect(find.byType(PantallaAvisos), findsNothing);

      // Pasados 7 días: una vez más
      reloj = reloj.add(const Duration(hours: 1));
      await ahoraNo(tester);
      expect(await AppPreferences.obtenerOfertaAvisosVeces(), 2);

      // Y nunca más
      reloj = reloj.add(const Duration(days: 60));
      await pedir(tester);
      expect(find.byType(PantallaAvisos), findsNothing);
      expect(await AppPreferences.obtenerOfertaAvisosVeces(), 2);
      expect(peticionesDelSistema, 0);
    });

    testWidgets('también al pulsar "Seguir este partido"', (tester) async {
      await pintar(tester, MotivoPermiso.seguirPartido);

      await ahoraNo(tester);

      reloj = reloj.add(const Duration(days: 8));
      await pedir(tester);

      expect(find.byType(PantallaAvisos), findsOneWidget);
    });

    testWidgets('al arrancar solo se ofrece si nunca se había ofrecido', (
      tester,
    ) async {
      await pintar(tester, MotivoPermiso.arranque);
      await pedir(tester);
      expect(find.byType(PantallaAvisos), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('avisos-ahora-no')));
      await tester.pumpAndSettle();

      reloj = reloj.add(const Duration(days: 30));
      await pedir(tester);

      expect(find.byType(PantallaAvisos), findsNothing);
    });

    testWidgets('si la bienvenida ya la ofreció, al arrancar no se repite', (
      tester,
    ) async {
      await PermisoNotificaciones.registrarOferta();

      await pintar(tester, MotivoPermiso.arranque);
      await pedir(tester);

      expect(find.byType(PantallaAvisos), findsNothing);
    });
  });

  group('permiso denegado del todo', () {
    testWidgets(
      'al seguir un partido avisa con "Abrir ajustes" que abre los ajustes',
      (tester) async {
        estado = EstadoPermisoAvisos.denegado;

        await pintar(tester, MotivoPermiso.seguirPartido);
        await pedir(tester);

        expect(find.text('Notificaciones desactivadas'), findsOneWidget);
        expect(find.byType(PantallaAvisos), findsNothing);

        await tester.tap(find.byKey(const ValueKey('abrir-ajustes')));
        await tester.pumpAndSettle();

        expect(ajustesAbiertos, 1);
        expect(resultado, isFalse);
        expect(peticionesDelSistema, 0);
      },
    );

    testWidgets('en los ajustes de avisos también avisa', (tester) async {
      estado = EstadoPermisoAvisos.denegado;

      await pintar(tester, MotivoPermiso.ajustes);
      await pedir(tester);

      expect(find.text('Abrir ajustes'), findsOneWidget);
    });

    testWidgets('al iniciar sesión o al arrancar no molesta', (tester) async {
      estado = EstadoPermisoAvisos.denegado;

      await pintar(tester, MotivoPermiso.inicioSesion);
      await pedir(tester);
      expect(find.text('Notificaciones desactivadas'), findsNothing);

      await pintar(tester, MotivoPermiso.arranque);
      await pedir(tester);
      expect(find.text('Notificaciones desactivadas'), findsNothing);
      expect(resultado, isFalse);
    });

    testWidgets('"Cancelar" en el aviso no abre los ajustes', (tester) async {
      estado = EstadoPermisoAvisos.denegado;

      await pintar(tester, MotivoPermiso.seguirPartido);
      await pedir(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(ajustesAbiertos, 0);
    });
  });

  group('se ve bien', () {
    for (final caso in [
      (
        nombre: 'iPhone pequeño con letra grande',
        tamano: const Size(320, 568),
        letra: 2.0,
        brillo: Brightness.light,
      ),
      (
        nombre: 'iPad',
        tamano: const Size(1024, 1366),
        letra: 1.0,
        brillo: Brightness.light,
      ),
      (
        nombre: 'modo oscuro',
        tamano: const Size(390, 844),
        letra: 1.0,
        brillo: Brightness.dark,
      ),
    ]) {
      testWidgets(caso.nombre, (tester) async {
        tester.view.physicalSize = caso.tamano;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(const PantallaAvisos(), brillo: caso.brillo, letra: caso.letra),
        );
        await tester.pumpAndSettle();

        // Sin desbordamientos, y los dos botones siempre a la vista
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('avisos-activar')), findsOneWidget);
        expect(find.byKey(const ValueKey('avisos-ahora-no')), findsOneWidget);

        final botones = tester.getRect(
          find.byKey(const ValueKey('avisos-ahora-no')),
        );
        expect(botones.bottom, lessThanOrEqualTo(caso.tamano.height));
      });
    }
  });
}
