import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/services/permiso_notificaciones.dart';
import 'package:app_mutxamel_cf/features/bienvenida/pages/bienvenida_page.dart';
import 'package:app_mutxamel_cf/features/splash/splash_page.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:app_mutxamel_cf/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Una app mínima que, como la real, vuelve a pintarse en el idioma elegido.
class _App extends StatefulWidget {
  final String idiomaInicial;
  final List<String> idiomasElegidos;
  final List<(bool, bool)> avisosAplicados;
  final bool Function() terminada;
  final VoidCallback alTerminar;
  final Brightness brillo;
  final double letra;

  const _App({
    required this.idiomaInicial,
    required this.idiomasElegidos,
    required this.avisosAplicados,
    required this.terminada,
    required this.alTerminar,
    this.brillo = Brightness.light,
    this.letra = 1,
  });

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late String _idioma = widget.idiomaInicial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: Locale(_idioma),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: widget.brillo),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(widget.letra)),
        child: child!,
      ),
      home: BienvenidaPage(
        idiomaActual: _idioma,
        onIdiomaChanged: (idioma) async {
          widget.idiomasElegidos.add(idioma);
          setState(() => _idioma = idioma);
        },
        aplicarAvisos: (resultados, noticias) async =>
            widget.avisosAplicados.add((resultados, noticias)),
        alTerminar: widget.alTerminar,
      ),
    );
  }
}

void main() {
  late EstadoPermisoAvisos estado;
  late int peticiones;
  late int ajustes;
  late List<String> idiomas;
  late List<(bool, bool)> avisos;
  late int terminadas;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    estado = EstadoPermisoAvisos.sinDecidir;
    peticiones = 0;
    ajustes = 0;
    idiomas = [];
    avisos = [];
    terminadas = 0;

    final leer = PermisoNotificaciones.leerEstado;
    final pedir = PermisoNotificaciones.pedirAlSistema;
    final abrir = PermisoNotificaciones.abrirAjustes;
    final conceder = PermisoNotificaciones.alConceder;

    PermisoNotificaciones.leerEstado = () async => estado;
    PermisoNotificaciones.pedirAlSistema = () async {
      peticiones++;
      estado = EstadoPermisoAvisos.concedido;
      return true;
    };
    PermisoNotificaciones.abrirAjustes = () async => ajustes++;
    PermisoNotificaciones.alConceder = () async {};

    addTearDown(() {
      PermisoNotificaciones.leerEstado = leer;
      PermisoNotificaciones.pedirAlSistema = pedir;
      PermisoNotificaciones.abrirAjustes = abrir;
      PermisoNotificaciones.alConceder = conceder;
    });
  });

  Future<void> pintar(
    WidgetTester tester, {
    String idioma = 'es',
    Brightness brillo = Brightness.light,
    double letra = 1,
  }) async {
    await tester.pumpWidget(
      _App(
        idiomaInicial: idioma,
        idiomasElegidos: idiomas,
        avisosAplicados: avisos,
        terminada: () => terminadas > 0,
        alTerminar: () => terminadas++,
        brillo: brillo,
        letra: letra,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> alPaso2(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('bienvenida-continuar')));
    await tester.pumpAndSettle();
  }

  group('paso 1: idioma', () {
    testWidgets(
      'ofrece Castellano, Valencià y English con el del móvil preseleccionado',
      (tester) async {
        await pintar(tester, idioma: 'ca');

        expect(find.text('Castellano'), findsOneWidget);
        expect(find.text('Valencià'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Paso 1 de 2'), findsNothing); // en valenciano
        expect(find.text('Pas 1 de 2'), findsOneWidget);

        // Solo el valenciano lleva la marca de elegido
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('bienvenida-idioma-ca')),
            matching: find.byIcon(Icons.check_circle),
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets('al elegir un idioma la app cambia al momento', (tester) async {
      await pintar(tester);

      expect(find.text('Elige tu idioma'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bienvenida-idioma-en')));
      await tester.pumpAndSettle();

      expect(idiomas, ['en']);
      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bienvenida-idioma-ca')));
      await tester.pumpAndSettle();

      expect(find.text('Tria el teu idioma'), findsOneWidget);
    });

    testWidgets('muestra el indicador de pasos y el botón Saltar', (
      tester,
    ) async {
      await pintar(tester);

      expect(
        find.byKey(const ValueKey('bienvenida-indicador')),
        findsOneWidget,
      );
      expect(find.text('Paso 1 de 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('bienvenida-saltar')), findsOneWidget);
    });
  });

  group('paso 2: avisos', () {
    testWidgets(
      'la pantalla de avisos con los interruptores activados por defecto',
      (tester) async {
        await pintar(tester);
        await alPaso2(tester);

        expect(find.text('Paso 2 de 2'), findsOneWidget);
        expect(
          find.text('No te pierdas nada del Mutxamel C.F.'),
          findsOneWidget,
        );
        expect(find.text('Goles y resultados al momento'), findsOneWidget);
        expect(find.text('Resultados'), findsOneWidget);
        expect(find.text('Noticias'), findsOneWidget);
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const ValueKey('bienvenida-resultados')),
              )
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const ValueKey('bienvenida-noticias')),
              )
              .value,
          isTrue,
        );
        // Y "Saltar" sigue a la vista
        expect(find.byKey(const ValueKey('bienvenida-saltar')), findsOneWidget);
        // Se cuenta como la primera vez que se ofrece
        expect(await AppPreferences.obtenerOfertaAvisosVeces(), 1);
      },
    );

    testWidgets(
      '"Activar notificaciones" pide el permiso y aplica los interruptores',
      (tester) async {
        await pintar(tester);
        await alPaso2(tester);

        final noticias = find.byKey(const ValueKey('bienvenida-noticias'));
        await tester.ensureVisible(noticias);
        await tester.pumpAndSettle();
        await tester.tap(noticias);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('avisos-activar')));
        await tester.pumpAndSettle();

        expect(peticiones, 1);
        expect(avisos, [(true, false)]);
        expect(terminadas, 1);
        expect(await AppPreferences.obtenerBienvenidaHecha(), isTrue);
      },
    );

    testWidgets(
      '"Ahora no" no pide el permiso y deja los interruptores apagados',
      (tester) async {
        await pintar(tester);
        await alPaso2(tester);

        await tester.tap(find.byKey(const ValueKey('avisos-ahora-no')));
        await tester.pumpAndSettle();

        expect(peticiones, 0);
        expect(avisos, isEmpty);
        expect(await AppPreferences.obtenerNotifResultados(), isFalse);
        expect(await AppPreferences.obtenerNotifNoticias(), isFalse);
        expect(terminadas, 1);
        expect(await AppPreferences.obtenerBienvenidaHecha(), isTrue);
      },
    );

    testWidgets(
      'con el permiso ya denegado del todo explica cómo activarlo y termina',
      (tester) async {
        estado = EstadoPermisoAvisos.denegado;

        await pintar(tester);
        await alPaso2(tester);
        await tester.tap(find.byKey(const ValueKey('avisos-activar')));
        await tester.pumpAndSettle();

        expect(find.text('Notificaciones desactivadas'), findsOneWidget);
        expect(peticiones, 0);

        await tester.tap(find.byKey(const ValueKey('abrir-ajustes')));
        await tester.pumpAndSettle();

        expect(ajustes, 1);
        expect(avisos, isEmpty);
        expect(terminadas, 1);
      },
    );
  });

  group('saltar', () {
    testWidgets(
      'en el paso 1 salta todo: marca la bienvenida como hecha y no pide nada',
      (tester) async {
        await pintar(tester);

        await tester.tap(find.byKey(const ValueKey('bienvenida-saltar')));
        await tester.pumpAndSettle();

        expect(terminadas, 1);
        expect(peticiones, 0);
        expect(avisos, isEmpty);
        expect(await AppPreferences.obtenerBienvenidaHecha(), isTrue);
      },
    );

    testWidgets('en el paso 2 también', (tester) async {
      await pintar(tester);
      await alPaso2(tester);

      await tester.tap(find.byKey(const ValueKey('bienvenida-saltar')));
      await tester.pumpAndSettle();

      expect(terminadas, 1);
      expect(peticiones, 0);
      expect(await AppPreferences.obtenerBienvenidaHecha(), isTrue);
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

        await pintar(tester, letra: caso.letra, brillo: caso.brillo);

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('bienvenida-continuar')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('bienvenida-saltar')), findsOneWidget);

        await alPaso2(tester);

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('avisos-activar')), findsOneWidget);
        expect(find.byKey(const ValueKey('avisos-ahora-no')), findsOneWidget);
        expect(find.byKey(const ValueKey('bienvenida-saltar')), findsOneWidget);
      });
    }
  });

  group('instalación nueva o actualización (SplashPage)', () {
    Future<void> arrancar(WidgetTester tester, {required bool nueva}) async {
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
            AppRoutes.public: (_) => const Scaffold(body: Text('PORTADA')),
            AppRoutes.welcome: (_) => const Scaffold(body: Text('BIENVENIDA')),
          },
          home: SplashPage(
            duracion: const Duration(milliseconds: 100),
            mostrarBienvenida: nueva,
            ofrecerAvisos: !nueva,
            inicializarNotificaciones: () async {},
            comprobarVersion: () async => null,
            sincronizarIdioma: () async {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'una instalación nueva ve la bienvenida y no la pantalla de avisos al arrancar',
      (tester) async {
        await arrancar(tester, nueva: true);

        expect(find.text('BIENVENIDA'), findsOneWidget);
        expect(find.text('PORTADA'), findsNothing);
        expect(find.text('No te pierdas nada del Mutxamel C.F.'), findsNothing);
      },
    );

    testWidgets(
      'una actualización va a la portada sin bienvenida; con el permiso sin decidir, solo la pantalla de avisos una vez',
      (tester) async {
        await arrancar(tester, nueva: false);

        expect(find.text('BIENVENIDA'), findsNothing);
        expect(
          find.text('No te pierdas nada del Mutxamel C.F.'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('avisos-ahora-no')));
        await tester.pumpAndSettle();

        expect(peticiones, 0);
        expect(find.text('PORTADA'), findsOneWidget);

        // En el siguiente arranque ya no se vuelve a ofrecer al arrancar
        await arrancar(tester, nueva: false);

        expect(find.text('No te pierdas nada del Mutxamel C.F.'), findsNothing);
      },
    );

    testWidgets('una actualización con el permiso ya decidido no ve nada', (
      tester,
    ) async {
      estado = EstadoPermisoAvisos.concedido;

      await arrancar(tester, nueva: false);

      expect(find.text('PORTADA'), findsOneWidget);
      expect(find.text('No te pierdas nada del Mutxamel C.F.'), findsNothing);
    });
  });
}
