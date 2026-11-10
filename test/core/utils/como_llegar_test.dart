import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('urlComoLlegar', () {
    test('iOS abre Apple Maps con el nombre exacto codificado', () {
      expect(
        urlComoLlegar('Campo Municipal', esIos: true).toString(),
        'https://maps.apple.com/?q=Campo%20Municipal',
      );
    });

    test('Android abre Google Maps con el nombre exacto codificado', () {
      expect(
        urlComoLlegar('Camp d\'Esports & Co', esIos: false).toString(),
        'https://www.google.com/maps/search/?api=1&query='
        'Camp%20d\'Esports%20%26%20Co',
      );
    });

    test('con coma no se añade nada y la coma se codifica', () {
      expect(
        urlComoLlegar('Calle Mayor 3, Pego', esIos: false).toString(),
        'https://www.google.com/maps/search/?api=1&query='
        'Calle%20Mayor%203%2C%20Pego',
      );
    });

    test('con Mutxamel no se añade nada', () {
      expect(
        urlComoLlegar('Campo de Mutxamel', esIos: true).toString(),
        'https://maps.apple.com/?q=Campo%20de%20Mutxamel',
      );
    });

    test('codifica acentos, "&" y paréntesis', () {
      expect(
        urlComoLlegar(' Pabellón Camí (B) & Co ', esIos: true).toString(),
        'https://maps.apple.com/?q=Pabell%C3%B3n%20Cam%C3%AD%20(B)%20%26%20Co',
      );
    });
  });

  group('abrirComoLlegar y BotonComoLlegar', () {
    testWidgets('abre la URL de la plataforma en una aplicación externa', (
      tester,
    ) async {
      final abiertas = <Uri>[];
      ComoLlegar.esIos = () => true;
      ComoLlegar.abrirUrl = (url) async {
        abiertas.add(url);
        return true;
      };

      await _pintar(tester, const BotonComoLlegar(lugar: 'Campo Municipal'));

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pump();

      expect(abiertas.single.host, 'maps.apple.com');
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
