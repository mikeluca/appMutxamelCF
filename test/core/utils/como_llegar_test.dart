import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
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
}
