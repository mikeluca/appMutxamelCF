import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/reloj_directo.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_cabecera.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/reloj_en_directo.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../directo/harness.dart';

final DateTime _movil = DateTime(2026, 11, 22, 12);

RelojDirecto _reloj(FaseReloj fase, {int minutoBase = 0}) => RelojDirecto(
  fase: fase,
  inicioParteEpochMs: fase == FaseReloj.descanso
      ? null
      : _movil.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
  minutoBase: minutoBase,
  ahoraServidorEpochMs: _movil.millisecondsSinceEpoch,
  recibidoEn: _movil,
);

MatchModel _partido(RelojDirecto? reloj, {bool descanso = false}) => MatchModel(
  id: 5,
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'Pego',
  enJuego: true,
  fase: descanso ? 'DESCANSO' : 'PRIMERA_PARTE',
  golesFavor: 1,
  golesContra: 0,
  reloj: reloj,
);

CabeceraFicha _cabecera(RelojDirecto reloj, EstadoFicha estado) =>
    CabeceraFicha(
      partidoId: 5,
      equipoLocal: 'Mutxamel CF',
      equipoVisitante: 'Pego',
      dia: DateTime(2026, 11, 22),
      hora: '12:00',
      estado: estado,
      competicion: 'Liga',
      reloj: reloj,
    );

void main() {
  group('el reloj en directo con la parte', () {
    testWidgets('1T en la primera parte y 2T en la segunda', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          RelojEnDirecto(
            reloj: _reloj(FaseReloj.primeraParte),
            conParte: true,
            ahora: () => _movil,
          ),
        ),
      );
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('1T'), findsOneWidget);
      expect(find.text('2T'), findsNothing);

      await tester.pumpWidget(
        appCon(
          RelojEnDirecto(
            reloj: _reloj(FaseReloj.segundaParte, minutoBase: 45),
            conParte: true,
            ahora: () => _movil,
          ),
        ),
      );
      expect(find.text('55:00'), findsOneWidget);
      expect(find.text('2T'), findsOneWidget);
      expect(find.text('1T'), findsNothing);
    });

    testWidgets('en inglés, 1H y 2H', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          RelojEnDirecto(
            reloj: _reloj(FaseReloj.segundaParte, minutoBase: 45),
            conParte: true,
            ahora: () => _movil,
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('2H'), findsOneWidget);
    });

    testWidgets('en el descanso, "Descanso" sin reloj ni etiqueta de parte', (
      tester,
    ) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          RelojEnDirecto(
            reloj: _reloj(FaseReloj.descanso, minutoBase: 45),
            conParte: true,
            ahora: () => _movil,
          ),
        ),
      );

      expect(find.text('Descanso'), findsOneWidget);
      expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);
      expect(find.byKey(const ValueKey('reloj-parte')), findsNothing);
    });

    testWidgets('sin pedirla (el panel del retransmisor) no sale la parte', (
      tester,
    ) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          RelojEnDirecto(
            reloj: _reloj(FaseReloj.primeraParte),
            ahora: () => _movil,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('reloj-parte')), findsNothing);
    });
  });

  group(
    'la tarjeta de Inicio y la cabecera de la ficha llevan la misma etiqueta',
    () {
      testWidgets(
        'tarjeta de Inicio: reloj con 1T en la primera parte y 2T en la segunda',
        (tester) async {
          pantalla(tester);

          await tester.pumpWidget(
            appCon(
              SingleChildScrollView(
                child: MatchCard(
                  match: _partido(_reloj(FaseReloj.primeraParte)),
                  mostrarPrimerEquipo: true,
                  ahora: () => _movil,
                ),
              ),
            ),
          );
          expect(find.text('1T'), findsOneWidget);

          await tester.pumpWidget(
            appCon(
              SingleChildScrollView(
                child: MatchCard(
                  match: _partido(
                    _reloj(FaseReloj.segundaParte, minutoBase: 45),
                  ),
                  mostrarPrimerEquipo: true,
                  ahora: () => _movil,
                ),
              ),
            ),
          );
          expect(find.text('2T'), findsOneWidget);
        },
      );

      testWidgets(
        'tarjeta de Inicio en el descanso: "Descanso" como hoy, sin reloj ni parte',
        (tester) async {
          pantalla(tester);

          await tester.pumpWidget(
            appCon(
              SingleChildScrollView(
                child: MatchCard(
                  match: _partido(
                    _reloj(FaseReloj.descanso, minutoBase: 45),
                    descanso: true,
                  ),
                  mostrarPrimerEquipo: true,
                  ahora: () => _movil,
                ),
              ),
            ),
          );

          expect(find.byKey(const ValueKey('reloj-parte')), findsNothing);
          expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);
        },
      );

      testWidgets('cabecera de la ficha: 1T / 2T junto al reloj', (
        tester,
      ) async {
        pantalla(tester);

        await tester.pumpWidget(
          appCon(
            FichaCabecera(
              cabecera: _cabecera(
                _reloj(FaseReloj.primeraParte),
                EstadoFicha.enJuego,
              ),
              ahora: () => _movil,
            ),
          ),
        );
        expect(find.text('1T'), findsOneWidget);

        await tester.pumpWidget(
          appCon(
            FichaCabecera(
              cabecera: _cabecera(
                _reloj(FaseReloj.segundaParte, minutoBase: 45),
                EstadoFicha.enJuego,
              ),
              ahora: () => _movil,
            ),
          ),
        );
        expect(find.text('2T'), findsOneWidget);
      });
    },
  );
}
