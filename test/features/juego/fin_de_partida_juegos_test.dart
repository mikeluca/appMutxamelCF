import 'package:app_mutxamel_cf/core/widget/escudo_rival.dart';
import 'package:app_mutxamel_cf/features/juego/estado_mutxigol.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/partida_juego_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

/// Cada juego jugado hasta el final con su lógica de verdad y a dos tamaños de pantalla: nada lanza excepciones (la
/// pantalla roja era un ErrorWidget por claves duplicadas en la escena de Cabezazos), el fin sale sobre la escena
/// oscurecida (negro al 50 %, nunca rojo), "Otra vez" y "Salir" funcionan.
const _tamanos = [Size(360, 640), Size(412, 915)];

Future<void> _avanzar(WidgetTester tester, double segundos) async {
  for (var i = 0; i < (segundos * 1000 / 16).round(); i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<Map<int, String>> _descubrir(WidgetTester tester) async {
  final posiciones = <int, String>{};

  for (var i = 0; i < 16; i++) {
    await tester.tap(find.byKey(ValueKey('carta-$i')));
    await _avanzar(tester, 0.4);

    final carta = find.descendant(
      of: find.byKey(ValueKey('carta-$i')),
      matching: find.textContaining('Club '),
    );

    if (carta.evaluate().isNotEmpty) {
      posiciones[i] = (carta.evaluate().single.widget as Text).data!;
    }

    if (i.isOdd) await _avanzar(tester, 1.4);
  }

  return posiciones;
}

/// Juega la partida de [juego] hasta que sale el fin de partida.
Future<void> _jugarHastaElFin(WidgetTester tester, Juego juego) async {
  switch (juego) {
    case Juego.atrapa:
      // Sin mover a Mutxigol: los balones llegan al suelo y se pierden las 3 vidas.
      for (var i = 0; i < 4000; i++) {
        await tester.pump(const Duration(milliseconds: 16));

        if (find.byKey(const ValueKey('fin-puntos')).evaluate().isNotEmpty) break;
      }
    case Juego.cabezazos:
      // Unos toques (con las barreras ya dentro) y luego se deja caer.
      await tester.tapAt(const Offset(180, 300));

      for (var i = 0; i < 4000; i++) {
        await tester.pump(const Duration(milliseconds: 16));

        if (i < 200 && i % 25 == 0) await tester.tapAt(const Offset(180, 300));
        if (find.byKey(const ValueKey('fin-puntos')).evaluate().isNotEmpty) break;
      }
    case Juego.parejas:
      await _avanzar(tester, 0.2);

      final posiciones = await _descubrir(tester);

      for (final nombre in posiciones.values.toSet()) {
        final pareja = [for (final e in posiciones.entries) if (e.value == nombre) e.key];

        await tester.tap(find.byKey(ValueKey('carta-${pareja[0]}')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('carta-${pareja[1]}')));
        await _avanzar(tester, 1.5);
      }

      await _avanzar(tester, 0.5);
  }
}

void main() {
  setUp(() {
    EstadoMutxigol.reiniciar();
    EstadoMutxigol.leyendaAtrapaVista = true;

    EscudoRival.constructorDeRed = (url, tamano, generico) =>
        SizedBox(width: tamano, height: tamano, child: generico);
    EscudoRival.precargadorDeRed = (contexto, url) async => true;
  });

  tearDown(() {
    EstadoMutxigol.reiniciar();
    EscudoRival.constructorDeRed = null;
    EscudoRival.precargadorDeRed = null;
  });

  for (final juego in Juego.values) {
    for (final tam in _tamanos) {
      testWidgets(
        '${juego.codigo} en ${tam.width.toInt()}×${tam.height.toInt()}: se juega hasta el fin sin excepciones, "Otra vez" y "Salir" también',
        (tester) async {
          tester.view.physicalSize = tam;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(12);

          await tester.pumpWidget(
            appDePrueba(
              Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartidaJuegoPage(juego: juego, servicio: servicio),
                      ),
                    ),
                    child: const Text('Jugar'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Jugar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump();

          await _jugarHastaElFin(tester, juego);

          expect(tester.takeException(), isNull, reason: 'durante la partida');
          expect(find.byKey(const ValueKey('fin-puntos')), findsOneWidget);
          expect(find.byType(ErrorWidget), findsNothing);

          // El fin va sobre la escena congelada y oscurecida (negro al 50 %), no sobre rojo.
          final capas = tester
              .widgetList<ColoredBox>(find.byType(ColoredBox))
              .where((c) => c.color == const Color(0x80000000));

          expect(capas, isNotEmpty);

          for (final c in tester.widgetList<ColoredBox>(find.byType(ColoredBox))) {
            // Ninguna capa a pantalla completa es roja.
            final esRoja = c.color.r > 0.6 && c.color.g < 0.3 && c.color.b < 0.3;

            expect(esRoja && c.color.a > 0.25, isFalse, reason: 'color ${c.color}');
          }

          // Otra vez.
          await tester.tap(find.byKey(const ValueKey('otra-vez')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await _avanzar(tester, 3.5);

          expect(tester.takeException(), isNull, reason: 'tras "Otra vez"');
          expect(find.byKey(const ValueKey('fin-puntos')), findsNothing);

          // Y se vuelve a jugar hasta el final y se sale.
          await _jugarHastaElFin(tester, juego);

          expect(tester.takeException(), isNull, reason: 'segunda partida');
          expect(find.byKey(const ValueKey('fin-puntos')), findsOneWidget);

          await tester.tap(find.byKey(const ValueKey('salir-fin')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'tras "Salir"');
          expect(find.byType(PartidaJuegoPage), findsNothing);
        },
      );
    }
  }
}
