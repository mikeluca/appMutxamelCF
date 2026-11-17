import 'package:app_mutxamel_cf/features/directo/widgets/barra_momentos.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_cabecera.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_detalle.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Faltan 3 h 15 min para las 18:00 de Madrid del 14-11-2026 (17:00 UTC).
final DateTime _ahora = DateTime.utc(2026, 11, 14, 13, 45);

CabeceraFicha _cabecera({String? hora = '18:00', EstadoFicha estado = EstadoFicha.proximo}) =>
    CabeceraFicha(
      partidoId: 30,
      equipoLocal: 'Mutxamel CF',
      equipoVisitante: 'Pego C.F.',
      dia: DateTime(2026, 11, 14),
      hora: hora,
      estado: estado,
      competicion: 'Liga',
    );

String _cuenta(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('cuenta-atras'))).data!;

void main() {
  group('la cabecera de la ficha', () {
    testWidgets('antes del partido con día y hora: cuenta atrás', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(FichaCabecera(cabecera: _cabecera(), ahora: () => _ahora)),
      );

      expect(_cuenta(tester), 'Empieza en 3 h 15 min');
      // La fecha y hora de siempre siguen arriba.
      expect(find.text('14/11/2026 • 18:00'), findsOneWidget);
    });

    testWidgets('sin hora: solo el día, como antes, sin cuenta atrás', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(FichaCabecera(cabecera: _cabecera(hora: null), ahora: () => _ahora)),
      );

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(find.text('14/11/2026'), findsOneWidget);
    });

    testWidgets('en juego ya no hay cuenta atrás', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          FichaCabecera(
            cabecera: _cabecera(estado: EstadoFicha.enJuego),
            ahora: () => _ahora,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
    });

    testWidgets('pasada la hora y sin inicio: "A punto de empezar"', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          FichaCabecera(
            cabecera: _cabecera(),
            ahora: () => DateTime.utc(2026, 11, 14, 17, 30),
          ),
        ),
      );

      expect(_cuenta(tester), 'A punto de empezar');
    });
  });

  group('la tarjeta de la portada', () {
    MatchModel partido({String equipo = 'Primer Equipo', String? hora = '18:00'}) =>
        MatchModel(
          id: 30,
          categoria: equipo,
          equipo: equipo,
          rival: 'Pego C.F.',
          dia: DateTime(2026, 11, 14),
          hora: hora,
        );

    testWidgets('el Primer Equipo muestra la cuenta atrás', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: partido(),
              mostrarPrimerEquipo: true,
              ahora: () => _ahora,
            ),
          ),
        ),
      );

      expect(_cuenta(tester), 'Empieza en 3 h 15 min');
    });

    testWidgets('sin hora, solo el día', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: partido(hora: null),
              mostrarPrimerEquipo: true,
              ahora: () => _ahora,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
    });

    testWidgets('las tarjetas de los demás equipos no cambian', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: partido(equipo: 'Cadete A'),
              ahora: () => _ahora,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
    });
  });

  group('la pestaña Detalle', () {
    testWidgets('lleva arriba la barra de momentos si hay hechos con minuto', (
      tester,
    ) async {
      pantalla(tester);

      FichaPartido ficha(List<EventoFicha> eventos) => FichaPartido(
        cabecera: _cabecera(estado: EstadoFicha.finalizado),
        eventos: eventos,
      );

      await tester.pumpWidget(
        appCon(
          FichaDetalle(
            ficha: ficha(const [
              EventoFicha(
                tipo: EventoFicha.golFavor,
                minuto: 23,
                jugador: 'Pepe',
                golesFavor: 1,
                golesContra: 0,
              ),
            ]),
          ),
        ),
      );

      expect(find.byType(BarraMomentos), findsOneWidget);
      expect(find.byKey(const ValueKey('barra-momentos')), findsOneWidget);
      // Debajo, la lista de siempre.
      expect(find.byKey(const ValueKey('evento-0')), findsOneWidget);

      // Sin eventos: el mensaje de siempre y sin barra.
      await tester.pumpWidget(appCon(FichaDetalle(ficha: ficha(const []))));

      expect(find.byType(BarraMomentos), findsNothing);
      expect(find.byKey(const ValueKey('ficha-sin-eventos')), findsOneWidget);
    });
  });
}
