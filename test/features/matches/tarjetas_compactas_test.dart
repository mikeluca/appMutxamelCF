import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../directo/harness.dart';

/// Domingo 22/11/2026.
final DateTime _domingo = DateTime(2026, 11, 22);

MatchModel _partido({String? hora = '17:30', int? equipoId = 7}) => MatchModel(
  id: 5,
  equipoId: equipoId,
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'C.D. Salesianos Alicante',
  dia: _domingo,
  hora: hora,
  campo: 'Campo municipal',
);

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('la tarjeta del partido en Inicio', () {
    testWidgets('fecha y hora en una sola línea y el rival sin siglas', (
      tester,
    ) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: _partido(),
              mostrarPrimerEquipo: true,
              ahora: () => DateTime.utc(2026, 11, 20, 10),
            ),
          ),
        ),
      );

      expect(find.text('Domingo 22/11/2026 · 17:30'), findsOneWidget);
      // Ya no hay una fila aparte para la hora.
      expect(find.text('17:30'), findsNothing);
      expect(find.text('Salesianos Alicante'), findsOneWidget);
      expect(find.text('C.D. Salesianos Alicante'), findsNothing);
    });

    testWidgets('sin hora, solo el día; en catalán y en inglés, sus días', (
      tester,
    ) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: _partido(hora: null),
              mostrarPrimerEquipo: true,
            ),
          ),
        ),
      );
      expect(find.text('Domingo 22/11/2026'), findsOneWidget);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: _partido(),
              mostrarPrimerEquipo: true,
              ahora: () => DateTime.utc(2026, 11, 20, 10),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('Sunday 22/11/2026 · 17:30'), findsOneWidget);
    });

    testWidgets(
      'es más baja que antes y se lee con letra grande en un iPhone pequeño',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          appCon(
            SingleChildScrollView(
              child: MatchCard(
                match: _partido(),
                mostrarPrimerEquipo: true,
                ahora: () => DateTime.utc(2026, 11, 20, 10),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Domingo 22/11/2026 · 17:30'), findsOneWidget);
      },
    );
  });

  group('la tarjeta de la pestaña Partidos', () {
    testWidgets('fecha y hora en una sola línea, sin la fila de la hora', (
      tester,
    ) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(child: PartidoListaCard(partido: _partido())),
        ),
      );

      expect(find.text('Domingo 22/11/2026 · 17:30'), findsOneWidget);
      expect(find.text('17:30'), findsNothing);
      expect(find.text('Salesianos Alicante'), findsOneWidget);
    });

    testWidgets(
      'el botón es "Clasificación" (ca: Classificació, en: Standings)',
      (tester) async {
        pantalla(tester);

        await tester.pumpWidget(
          appCon(
            SingleChildScrollView(child: PartidoListaCard(partido: _partido())),
          ),
        );
        expect(find.text('Clasificación'), findsOneWidget);
        expect(find.text('Ver clasificación'), findsNothing);
        // Se mantiene la fila con "Añadir a mi calendario".
        expect(
          find.byKey(const ValueKey('fila-calendario-clasificacion')),
          findsOneWidget,
        );

        await tester.pumpWidget(
          appCon(
            SingleChildScrollView(child: PartidoListaCard(partido: _partido())),
            locale: const Locale('ca'),
          ),
        );
        expect(find.text('Classificació'), findsOneWidget);

        await tester.pumpWidget(
          appCon(
            SingleChildScrollView(child: PartidoListaCard(partido: _partido())),
            locale: const Locale('en'),
          ),
        );
        expect(find.text('Standings'), findsOneWidget);
      },
    );
  });
}
