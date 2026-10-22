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
    test('añade ", Alicante" si no hay Mutxamel ni coma', () {
      expect(
        consultaComoLlegar('Campo Municipal'),
        'Campo Municipal, Alicante',
      );
      expect(consultaComoLlegar('  Pabellón  '), 'Pabellón, Alicante');
    });

    test('no lo añade si ya contiene Mutxamel (sin distinguir mayúsculas)', () {
      expect(
        consultaComoLlegar('Campo Municipal de Mutxamel'),
        'Campo Municipal de Mutxamel',
      );
      expect(consultaComoLlegar('MUTXAMEL'), 'MUTXAMEL');
    });

    test('no lo añade si ya tiene una coma', () {
      expect(consultaComoLlegar('Calle Mayor 3, Pego'), 'Calle Mayor 3, Pego');
    });
  });

  group('urlComoLlegar', () {
    test('iOS abre Apple Maps con el lugar codificado', () {
      expect(
        urlComoLlegar('Campo Municipal', esIos: true).toString(),
        'https://maps.apple.com/?q=Campo%20Municipal%2C%20Alicante',
      );
    });

    test('Android abre Google Maps con el lugar codificado', () {
      expect(
        urlComoLlegar('Camp d\'Esports & Co', esIos: false).toString(),
        'https://www.google.com/maps/search/?api=1&query='
        'Camp%20d\'Esports%20%26%20Co%2C%20Alicante',
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
