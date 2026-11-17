import 'dart:async';

import 'package:app_mutxamel_cf/features/directo/widgets/celebra_goles.dart';
import 'package:app_mutxamel_cf/features/directo/widgets/partido_visible.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// El marcador que recibe la pantalla: el partido y (favor, contra).
class _Estado {
  final int partido;
  final int? favor;
  final int? contra;

  const _Estado(this.partido, this.favor, this.contra);
}

Widget _pantalla(
  ValueNotifier<_Estado> estado, {
  bool local = true,
  String? goleador = 'Pepe',
  int? dorsal,
}) {
  return ValueListenableBuilder<_Estado>(
    valueListenable: estado,
    builder: (context, e, _) => CelebraGoles(
      partidoId: e.partido,
      golesFavor: e.favor,
      golesContra: e.contra,
      mutxamelEsLocal: local,
      goleador: goleador,
      dorsalRival: dorsal,
      child: const Text('contenido'),
    ),
  );
}

/// Cambia el marcador y deja pintar la celebración.
Future<void> _cambiar(
  WidgetTester tester,
  ValueNotifier<_Estado> estado,
  _Estado nuevo,
) async {
  estado.value = nuevo;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

String _marcadorCelebracion(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('celebracion-marcador')))
    .data!;

const _celebracion = ValueKey('celebracion-gol');
const _avisoRival = ValueKey('aviso-gol-rival');
const _avisoNuestro = ValueKey('aviso-gol-nuestro');

void main() {
  group('gol del Mutxamel', () {
    testWidgets('al abrir la pantalla no se celebra nada', (tester) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);

      await tester.pumpWidget(
        appCon(_pantalla(ValueNotifier(const _Estado(30, 2, 1)))),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(_avisoRival), findsNothing);
      expect(vibraciones, isEmpty);
    });

    testWidgets(
      'sube el marcador visto: "¡GOOOL!", escudo, marcador nuevo y goleador, 3 s y vibración fuerte',
      (tester) async {
        pantalla(tester);
        final vibraciones = anotarVibraciones(tester);
        final estado = ValueNotifier(const _Estado(30, 1, 0));

        await tester.pumpWidget(appCon(_pantalla(estado)));
        await _cambiar(tester, estado, const _Estado(30, 2, 0));

        expect(find.byKey(_celebracion), findsOneWidget);
        expect(find.text('¡GOOOL!'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('celebracion-escudo')),
          findsOneWidget,
        );
        expect(_marcadorCelebracion(tester), '2-0');
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('celebracion-goleador')))
              .data,
          'Pepe',
        );
        expect(vibraciones, ['HapticFeedbackType.heavyImpact']);

        // Unos 3 segundos y se va sola.
        await tester.pump(const Duration(seconds: 2));
        expect(find.byKey(_celebracion), findsOneWidget);

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        expect(find.byKey(_celebracion), findsNothing);
      },
    );

    testWidgets('el marcador va con el local a la izquierda (de visitante)', (
      tester,
    ) async {
      pantalla(tester);
      anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 1));

      await tester.pumpWidget(appCon(_pantalla(estado, local: false)));
      await _cambiar(tester, estado, const _Estado(30, 1, 1));

      expect(_marcadorCelebracion(tester), '1-1');

      await _cambiar(tester, estado, const _Estado(30, 2, 1));

      // Visitante: primero los goles del rival (el local).
      expect(_marcadorCelebracion(tester), '1-2');
    });

    testWidgets('tocarla la cierra antes de los 3 s', (tester) async {
      pantalla(tester);
      anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(appCon(_pantalla(estado)));
      await _cambiar(tester, estado, const _Estado(30, 1, 0));
      expect(find.byKey(_celebracion), findsOneWidget);

      await tester.tap(find.byKey(_celebracion));
      await tester.pump();

      expect(find.byKey(_celebracion), findsNothing);

      // Y el temporizador cancelado no la vuelve a quitar ni falla.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('sin goleador conocido (la portada) no lo muestra', (
      tester,
    ) async {
      pantalla(tester);
      anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(appCon(_pantalla(estado, goleador: null)));
      await _cambiar(tester, estado, const _Estado(30, 1, 0));

      expect(find.byKey(_celebracion), findsOneWidget);
      expect(find.byKey(const ValueKey('celebracion-goleador')), findsNothing);
    });

    testWidgets(
      'si llegan dos goles a la vez, una sola celebración con el marcador final',
      (tester) async {
        pantalla(tester);
        final vibraciones = anotarVibraciones(tester);
        final estado = ValueNotifier(const _Estado(30, 0, 0));

        await tester.pumpWidget(appCon(_pantalla(estado)));
        await _cambiar(tester, estado, const _Estado(30, 2, 0));

        expect(find.byKey(_celebracion), findsOneWidget);
        expect(_marcadorCelebracion(tester), '2-0');
        expect(vibraciones, hasLength(1));
      },
    );

    testWidgets('si el marcador baja (gol anulado) solo se actualiza', (
      tester,
    ) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 2, 0));

      await tester.pumpWidget(appCon(_pantalla(estado)));
      await _cambiar(tester, estado, const _Estado(30, 1, 0));

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(_avisoRival), findsNothing);
      expect(vibraciones, isEmpty);

      // Y la línea base es la nueva: volver a 2-0 sí es un gol.
      await _cambiar(tester, estado, const _Estado(30, 2, 0));
      expect(find.byKey(_celebracion), findsOneWidget);
    });

    testWidgets('con la animación reducida solo hay aviso y vibración', (
      tester,
    ) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(
        appCon(_pantalla(estado), reducirAnimaciones: true),
      );
      await _cambiar(tester, estado, const _Estado(30, 1, 0));

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(_avisoNuestro), findsOneWidget);
      expect(find.text('¡Gol del Mutxamel! · 1-0'), findsOneWidget);
      expect(vibraciones, ['HapticFeedbackType.heavyImpact']);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.byKey(_avisoNuestro), findsNothing);
    });
  });

  group('gol del rival', () {
    testWidgets('aviso corto arriba y vibración suave, sin pantalla completa', (
      tester,
    ) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 2, 0));

      await tester.pumpWidget(appCon(_pantalla(estado)));
      await _cambiar(tester, estado, const _Estado(30, 2, 1));

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(_avisoRival), findsOneWidget);
      expect(find.text('Gol del rival · 2-1'), findsOneWidget);
      expect(vibraciones, ['HapticFeedbackType.lightImpact']);

      // Está arriba del todo.
      expect(tester.getTopLeft(find.byKey(_avisoRival)).dy, lessThan(100));

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.byKey(_avisoRival), findsNothing);
    });

    testWidgets('con el dorsal, lo dice', (tester) async {
      pantalla(tester);
      anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 2, 0));

      await tester.pumpWidget(appCon(_pantalla(estado, dorsal: 9)));
      await _cambiar(tester, estado, const _Estado(30, 2, 1));

      expect(find.text('Gol del rival · 2-1 · Dorsal 9'), findsOneWidget);
    });

    testWidgets('en inglés', (tester) async {
      pantalla(tester);
      anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(
        appCon(_pantalla(estado), locale: const Locale('en')),
      );
      await _cambiar(tester, estado, const _Estado(30, 0, 1));

      expect(find.text('Opponent goal · 0-1'), findsOneWidget);
    });

    testWidgets('con la animación reducida sigue siendo el mismo aviso', (
      tester,
    ) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(
        appCon(_pantalla(estado), reducirAnimaciones: true),
      );
      await _cambiar(tester, estado, const _Estado(30, 0, 1));

      expect(find.byKey(_avisoRival), findsOneWidget);
      expect(vibraciones, ['HapticFeedbackType.lightImpact']);
    });
  });

  group('cuándo NO se celebra', () {
    testWidgets('con la app en segundo plano solo se actualiza', (
      tester,
    ) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(appCon(_pantalla(estado)));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _cambiar(tester, estado, const _Estado(30, 1, 0));

      expect(find.byKey(_celebracion), findsNothing);
      expect(vibraciones, isEmpty);

      // Al volver, lo que cambió estando fuera no se celebra; el siguiente gol sí.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byKey(_celebracion), findsNothing);

      await _cambiar(tester, estado, const _Estado(30, 2, 0));
      expect(find.byKey(_celebracion), findsOneWidget);
    });

    testWidgets('con otra pantalla encima no se celebra', (tester) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final navegador = GlobalKey<NavigatorState>();
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(appCon(_pantalla(estado), navegador: navegador));

      unawaited(
        navegador.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      await tester.pumpAndSettle();

      await _cambiar(tester, estado, const _Estado(30, 1, 0));

      expect(find.byKey(_celebracion), findsNothing);
      expect(vibraciones, isEmpty);
    });

    testWidgets('si cambia el partido, el marcador del otro no es un gol', (
      tester,
    ) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(appCon(_pantalla(estado)));
      await _cambiar(tester, estado, const _Estado(31, 3, 2));

      expect(find.byKey(_celebracion), findsNothing);
      expect(vibraciones, isEmpty);

      // Del nuevo partido, sí.
      await _cambiar(tester, estado, const _Estado(31, 4, 2));
      expect(find.byKey(_celebracion), findsOneWidget);
    });

    testWidgets('sin partido conocido no hay celebración', (tester) async {
      pantalla(tester);
      final vibraciones = anotarVibraciones(tester);
      final estado = ValueNotifier<_Estado>(const _Estado(0, 0, 0));

      await tester.pumpWidget(
        appCon(
          ValueListenableBuilder<_Estado>(
            valueListenable: estado,
            builder: (_, e, _) => CelebraGoles(
              partidoId: null,
              golesFavor: e.favor,
              golesContra: e.contra,
              mutxamelEsLocal: true,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await _cambiar(tester, estado, const _Estado(0, 1, 0));

      expect(find.byKey(_celebracion), findsNothing);
      expect(vibraciones, isEmpty);
    });
  });

  group('partido a la vista (no repetir la notificación local del push)', () {
    testWidgets('se registra mientras se ve y se quita al taparse o cerrarse', (
      tester,
    ) async {
      pantalla(tester);
      final navegador = GlobalKey<NavigatorState>();
      final estado = ValueNotifier(const _Estado(30, 0, 0));

      await tester.pumpWidget(appCon(_pantalla(estado), navegador: navegador));
      expect(PartidoVisible.estaVisible(30), isTrue);
      expect(PartidoVisible.estaVisible(31), isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(PartidoVisible.estaVisible(30), isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(PartidoVisible.estaVisible(30), isTrue);

      unawaited(
        navegador.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      await tester.pumpAndSettle();
      expect(PartidoVisible.estaVisible(30), isFalse);

      navegador.currentState!.pop();
      await tester.pumpAndSettle();
      expect(PartidoVisible.estaVisible(30), isTrue);

      await tester.pumpWidget(const SizedBox());
      expect(PartidoVisible.estaVisible(30), isFalse);
    });
  });
}
