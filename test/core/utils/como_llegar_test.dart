import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pintar(WidgetTester tester, Widget hijo) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: hijo)),
    ),
  );
}

void main() {
  tearDown(() {
    ComoLlegar.esIos = () => false;
  });

  group('consultaComoLlegar', () {
    test('sin coma ni Mutxamel no añade nada, solo hace trim', () {
      expect(consultaComoLlegar('Campo Municipal'), 'Campo Municipal');
      expect(consultaComoLlegar('  Pabellón  '), 'Pabellón');
    });

    test('con Mutxamel (sin distinguir mayúsculas) lo deja igual', () {
      expect(
        consultaComoLlegar('Campo Municipal de Mutxamel'),
        'Campo Municipal de Mutxamel',
      );
      expect(consultaComoLlegar('MUTXAMEL'), 'MUTXAMEL');
    });

    test('con coma lo deja igual', () {
      expect(consultaComoLlegar('Calle Mayor 3, Pego'), 'Calle Mayor 3, Pego');
    });

    test('conserva acentos, "&" y paréntesis', () {
      expect(
        consultaComoLlegar(' Camp d\'Esports & Co (Camí Vell) '),
        'Camp d\'Esports & Co (Camí Vell)',
      );
    });
  });

  group('consultaAppleMaps', () {
    test('quita los identificadores de campo', () {
      expect(
        consultaAppleMaps('Polideportivo Mpal. El Vincle F-11 El Campello'),
        'Polideportivo Mpal. El Vincle El Campello',
      );
      expect(consultaAppleMaps('Campo X F11'), 'Campo X');
      expect(
        consultaAppleMaps('Ciudad Deportiva f-8 Alicante'),
        'Ciudad Deportiva Alicante',
      );
      expect(consultaAppleMaps('Estadio F-7'), 'Estadio');
      expect(consultaAppleMaps('Estadio F5 Norte'), 'Estadio Norte');
      expect(consultaAppleMaps('Municipal Campo 2 Pego'), 'Municipal Pego');
      expect(consultaAppleMaps('Municipal campo3 Pego'), 'Municipal Pego');
      expect(consultaAppleMaps('Municipal CAMPO 1'), 'Municipal');
    });

    test('no toca textos sin identificadores ni números de portal', () {
      expect(consultaAppleMaps('Calle Mayor 3, Pego'), 'Calle Mayor 3, Pego');
      expect(consultaAppleMaps('Avinguda F-110'), 'Avinguda F-110');
      expect(consultaAppleMaps('  Campo Municipal  '), 'Campo Municipal');
    });

    test('si al limpiar queda vacío, usa el texto original', () {
      expect(consultaAppleMaps('F-11'), 'F-11');
      expect(consultaAppleMaps(' Campo 2 '), 'Campo 2');
    });
  });

  group('urlComoLlegar', () {
    test('Google Maps recibe el texto completo codificado', () {
      expect(
        urlComoLlegar(
          'Camp d\'Esports & Co F-11',
          mapa: MapaComoLlegar.google,
        ).toString(),
        'https://www.google.com/maps/search/?api=1&query='
        'Camp%20d\'Esports%20%26%20Co%20F-11',
      );
      expect(
        urlComoLlegar(
          'Calle Mayor 3, Pego',
          mapa: MapaComoLlegar.google,
        ).toString(),
        'https://www.google.com/maps/search/?api=1&query='
        'Calle%20Mayor%203%2C%20Pego',
      );
    });

    test('Apple Maps recibe el texto limpio codificado', () {
      expect(
        urlComoLlegar(
          'Polideportivo Mpal. El Vincle F-11 El Campello',
          mapa: MapaComoLlegar.apple,
        ).toString(),
        'https://maps.apple.com/?q='
        'Polideportivo%20Mpal.%20El%20Vincle%20El%20Campello',
      );
      expect(
        urlComoLlegar(
          ' Pabellón Camí (B) & Co ',
          mapa: MapaComoLlegar.apple,
        ).toString(),
        'https://maps.apple.com/?q=Pabell%C3%B3n%20Cam%C3%AD%20(B)%20%26%20Co',
      );
    });
  });

  group('abrirComoLlegar y BotonComoLlegar', () {
    final abiertas = <Uri>[];

    setUp(() {
      abiertas.clear();
      SharedPreferences.setMockInitialValues({});
      ComoLlegar.abrirUrl = (url) async {
        abiertas.add(url);
        return true;
      };
    });

    List<String> textosHoja(WidgetTester tester) => [
      for (final t in tester.widgetList<CupertinoActionSheetAction>(
        find.byType(CupertinoActionSheetAction),
      ))
        (t.child as Text).data!,
    ];

    testWidgets('en iOS muestra la hoja con Google, Apple y Cancelar', (
      tester,
    ) async {
      ComoLlegar.esIos = () => true;

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo F-11 Pego'));
      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();

      expect(textosHoja(tester), ['Google Maps', 'Apple Maps', 'Cancelar']);
      expect(abiertas, isEmpty);
    });

    testWidgets('en iOS, Google abre el texto completo y se recuerda', (
      tester,
    ) async {
      ComoLlegar.esIos = () => true;

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo F-11 Pego'));
      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google Maps'));
      await tester.pumpAndSettle();

      expect(
        abiertas.single.toString(),
        'https://www.google.com/maps/search/?api=1&query=Campo%20F-11%20Pego',
      );
      expect(await AppPreferences.obtenerMapaPreferido(), 'google');
    });

    testWidgets('en iOS, Apple abre la URL limpia y pasa a ir primero', (
      tester,
    ) async {
      ComoLlegar.esIos = () => true;

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo F-11 Pego'));
      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple Maps'));
      await tester.pumpAndSettle();

      expect(
        abiertas.single.toString(),
        'https://maps.apple.com/?q=Campo%20Pego',
      );
      expect(await AppPreferences.obtenerMapaPreferido(), 'apple');

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();

      expect(textosHoja(tester), ['Apple Maps', 'Google Maps', 'Cancelar']);
    });

    testWidgets('en iOS, Cancelar no abre nada ni guarda nada', (tester) async {
      ComoLlegar.esIos = () => true;

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo'));
      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(abiertas, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(await AppPreferences.obtenerMapaPreferido(), isNull);
    });

    testWidgets('en Android abre Google Maps directamente, sin hoja', (
      tester,
    ) async {
      ComoLlegar.esIos = () => false;

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo F-11 Pego'));
      await tester.tap(find.byIcon(Icons.directions));
      await tester.pump();

      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(
        abiertas.single.toString(),
        'https://www.google.com/maps/search/?api=1&query=Campo%20F-11%20Pego',
      );
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('si no se puede abrir, avisa con un SnackBar', (tester) async {
      ComoLlegar.abrirUrl = (url) async => false;

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo Municipal'));

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pump();

      expect(find.text('No se ha podido abrir el mapa.'), findsOneWidget);
    });

    testWidgets('si el lanzador lanza una excepción, también avisa', (
      tester,
    ) async {
      ComoLlegar.abrirUrl = (url) async => throw Exception('sin mapas');

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo Municipal'));

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('con el texto vacío o nulo no se pinta el botón', (
      tester,
    ) async {
      await _pintar(tester, const BotonComoLlegar(lugar: null));
      expect(find.byIcon(Icons.directions), findsNothing);

      await _pintar(tester, const BotonComoLlegar(lugar: '   '));
      expect(find.byIcon(Icons.directions), findsNothing);
    });

    testWidgets('tiene el tooltip "Cómo llegar"', (tester) async {
      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo'));

      expect(find.byTooltip('Cómo llegar'), findsOneWidget);
    });
  });

  group('campo de casa', () {
    test('las constantes son únicas', () {
      expect(campoCasaTexto, 'Camp Nou Los Olmos Mutxamel');
      expect(campoCasaMapas, 'Poliesportiu Municipal de Mutxamel');
    });

    test('destinoCampoPartido: en casa siempre el campo de mapas', () {
      expect(
        destinoCampoPartido('Camp Nou Los Olmos Mutxamel', local: true),
        campoCasaMapas,
      );
      expect(destinoCampoPartido('Otro campo', local: true), campoCasaMapas);
      expect(
        destinoCampoPartido('Campo Pego F-11', local: false),
        'Campo Pego F-11',
      );
      expect(destinoCampoPartido('Campo Pego', local: null), 'Campo Pego');
      expect(destinoCampoPartido('  ', local: true), '');
      expect(destinoCampoPartido(null, local: true), '');
    });

    test('destinoLugarCitacion: Camp Nou Los Olmos, en casa y fuera', () {
      expect(
        destinoLugarCitacion(
          'Camp Nou Los Olmos Mutxamel',
          campo: 'Pego',
          local: true,
        ),
        campoCasaMapas,
      );
      expect(
        destinoLugarCitacion(
          '  CAMP NOU  los olmos   mutxamel ',
          campo: 'Pego',
          local: false,
        ),
        campoCasaMapas,
      );
      expect(
        destinoLugarCitacion(
          'Camp Nou Los Olmos Mutxamel',
          campo: null,
          local: null,
        ),
        campoCasaMapas,
      );
    });

    test(
      'destinoLugarCitacion: igual al campo o vacío, solo si es de local',
      () {
        expect(
          destinoLugarCitacion(
            'Camp Municipal Pégo',
            campo: 'camp municipal pego',
            local: true,
          ),
          campoCasaMapas,
        );
        expect(
          destinoLugarCitacion(
            'Camp Municipal Pego',
            campo: 'Camp Municipal Pego',
            local: false,
          ),
          'Camp Municipal Pego',
        );
        expect(
          destinoLugarCitacion(
            'Camp Municipal Pego',
            campo: 'Camp Municipal Pego',
          ),
          'Camp Municipal Pego',
        );
        expect(
          destinoLugarCitacion('', campo: 'Pego', local: true),
          campoCasaMapas,
        );
        expect(
          destinoLugarCitacion(null, campo: 'Pego', local: true),
          campoCasaMapas,
        );
        expect(destinoLugarCitacion('', campo: 'Pego', local: false), '');
        expect(destinoLugarCitacion(null, campo: 'Pego'), '');
      },
    );

    test('destinoLugarCitacion: otro sitio, tal cual', () {
      expect(
        destinoLugarCitacion(' Bar Manolo ', campo: 'Camp Nou', local: true),
        'Bar Manolo',
      );
    });
  });

  group('BotonComoLlegar con local', () {
    final abiertas = <Uri>[];

    setUp(() {
      abiertas.clear();
      SharedPreferences.setMockInitialValues({});
      ComoLlegar.abrirUrl = (url) async {
        abiertas.add(url);
        return true;
      };
    });

    Future<void> tocar(
      WidgetTester tester,
      Widget boton, {
      String? apple,
    }) async {
      ComoLlegar.esIos = () => apple != null;
      await _pintar(tester, boton);
      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();

      if (apple != null) {
        await tester.tap(find.text(apple));
        await tester.pumpAndSettle();
      }
    }

    final casaMapas = Uri.encodeComponent(campoCasaMapas);

    testWidgets('local, Google: el campo de mapas', (tester) async {
      await tocar(
        tester,
        const BotonComoLlegar(
          lugar: 'Camp Nou Los Olmos Mutxamel',
          local: true,
        ),
      );

      expect(
        abiertas.single.toString(),
        contains('google.com/maps/search/?api=1&query=$casaMapas'),
      );
    });

    testWidgets('local, Apple: el campo de mapas', (tester) async {
      await tocar(
        tester,
        const BotonComoLlegar(
          lugar: 'Camp Nou Los Olmos Mutxamel',
          local: true,
        ),
        apple: 'Apple Maps',
      );

      expect(
        abiertas.single.toString(),
        'https://maps.apple.com/?q=$casaMapas',
      );
    });

    testWidgets('visitante, Google: el texto completo', (tester) async {
      await tocar(
        tester,
        const BotonComoLlegar(lugar: 'Campo Pego F-11', local: false),
      );

      expect(
        abiertas.single.toString(),
        contains('query=${Uri.encodeComponent('Campo Pego F-11')}'),
      );
    });

    testWidgets('visitante, Apple: el texto limpio', (tester) async {
      await tocar(
        tester,
        const BotonComoLlegar(lugar: 'Campo Pego F-11', local: false),
        apple: 'Apple Maps',
      );

      expect(
        abiertas.single.toString(),
        'https://maps.apple.com/?q=${Uri.encodeComponent('Campo Pego')}',
      );
    });

    testWidgets('sin "local", como siempre', (tester) async {
      await tocar(
        tester,
        const BotonComoLlegar(lugar: 'Camp Nou Los Olmos Mutxamel'),
      );

      expect(
        abiertas.single.toString(),
        contains('query=${Uri.encodeComponent('Camp Nou Los Olmos Mutxamel')}'),
      );
    });

    testWidgets('citación: Camp Nou Los Olmos va a mapas, en casa y fuera', (
      tester,
    ) async {
      await tocar(
        tester,
        const BotonComoLlegar.citacion(
          lugar: 'Camp Nou Los Olmos Mutxamel',
          campo: 'Pego',
          local: false,
        ),
      );

      expect(abiertas.single.toString(), contains('query=$casaMapas'));
    });

    testWidgets('citación igual al campo y en casa: a mapas; fuera, tal cual', (
      tester,
    ) async {
      await tocar(
        tester,
        const BotonComoLlegar.citacion(
          lugar: 'Camp de Pego',
          campo: 'camp de pego',
          local: true,
        ),
      );
      expect(abiertas.single.toString(), contains('query=$casaMapas'));

      abiertas.clear();
      await tocar(
        tester,
        const BotonComoLlegar.citacion(
          lugar: 'Camp de Pego',
          campo: 'Camp de Pego',
          local: false,
        ),
      );
      expect(
        abiertas.single.toString(),
        contains('query=${Uri.encodeComponent('Camp de Pego')}'),
      );
    });

    testWidgets('citación vacía y en casa: botón a mapas; fuera, sin botón', (
      tester,
    ) async {
      await tocar(
        tester,
        const BotonComoLlegar.citacion(lugar: '', campo: 'Pego', local: true),
      );
      expect(abiertas.single.toString(), contains('query=$casaMapas'));

      await _pintar(
        tester,
        const BotonComoLlegar.citacion(lugar: '', campo: 'Pego', local: false),
      );
      expect(find.byIcon(Icons.directions), findsNothing);
    });

    testWidgets('citación en otro sitio: tal cual', (tester) async {
      await tocar(
        tester,
        const BotonComoLlegar.citacion(
          lugar: 'Bar Manolo',
          campo: 'Pego',
          local: true,
        ),
      );

      expect(
        abiertas.single.toString(),
        contains('query=${Uri.encodeComponent('Bar Manolo')}'),
      );
    });
  });
}
