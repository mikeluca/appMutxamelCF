import 'package:app_mutxamel_cf/features/directo/widgets/marcador_que_late.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

class _Estado {
  final int partido;
  final int? favor;
  final int? contra;

  const _Estado(this.partido, this.favor, this.contra);
}

Widget _marcador(ValueNotifier<_Estado> estado, {bool local = true}) {
  return ValueListenableBuilder<_Estado>(
    valueListenable: estado,
    builder: (context, e, _) => Center(
      child: MarcadorQueLate(
        partidoId: e.partido,
        golesFavor: e.favor,
        golesContra: e.contra,
        mutxamelEsLocal: local,
        estilo: const TextStyle(fontSize: 30),
      ),
    ),
  );
}

const _verde = ValueKey('destello-verde');
const _rojo = ValueKey('destello-rojo');

/// La escala con la que entra el número [clave] (1 si no está animándose).
double _escala(WidgetTester tester, String clave) {
  final escalas = find.ancestor(
    of: find.byKey(ValueKey(clave)),
    matching: find.byType(ScaleTransition),
  );

  if (escalas.evaluate().isEmpty) return 1;

  return tester.widget<ScaleTransition>(escalas.first).scale.value;
}

Future<void> _cambiar(
  WidgetTester tester,
  ValueNotifier<_Estado> estado,
  _Estado nuevo,
) async {
  estado.value = nuevo;
  await tester.pump();
}

void main() {
  testWidgets('pinta el marcador con el local a la izquierda y "-" sin goles', (
    tester,
  ) async {
    pantalla(tester);

    await tester.pumpWidget(
      appCon(_marcador(ValueNotifier(const _Estado(30, 2, 1)), local: false)),
    );

    expect(tester.widget<Text>(find.byKey(const ValueKey('marcador-local'))).data, '1');
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('marcador-visitante'))).data,
      '2',
    );

    await tester.pumpWidget(
      appCon(_marcador(ValueNotifier(const _Estado(30, null, null)))),
    );

    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('al abrir no hay animación ni destello', (tester) async {
    pantalla(tester);

    await tester.pumpWidget(
      appCon(_marcador(ValueNotifier(const _Estado(30, 2, 1)))),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(_verde), findsNothing);
    expect(find.byKey(_rojo), findsNothing);
    expect(_escala(tester, 'marcador-local'), 1);
  });

  testWidgets(
    'gol nuestro: el número entra de 1,4 a 1 en 400 ms con destello verde, que se apaga',
    (tester) async {
      pantalla(tester);
      final estado = ValueNotifier(const _Estado(30, 1, 0));

      await tester.pumpWidget(appCon(_marcador(estado)));
      await _cambiar(tester, estado, const _Estado(30, 2, 0));

      // Justo al empezar: escala 1,4 y destello verde.
      expect(find.byKey(_verde), findsOneWidget);
      expect(find.byKey(_rojo), findsNothing);
      expect(_escala(tester, 'marcador-local'), closeTo(1.4, 0.001));
      // El que no cambia no se anima.
      expect(_escala(tester, 'marcador-visitante'), 1);

      await tester.pump(const Duration(milliseconds: 200));
      expect(_escala(tester, 'marcador-local'), inExclusiveRange(1.0, 1.4));

      await tester.pump(const Duration(milliseconds: 220));
      expect(_escala(tester, 'marcador-local'), closeTo(1, 0.001));
      expect(find.byKey(_verde), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(_verde), findsNothing);
    },
  );

  testWidgets('gol del rival: el número del rival entra con destello rojo', (
    tester,
  ) async {
    pantalla(tester);
    final estado = ValueNotifier(const _Estado(30, 1, 0));

    await tester.pumpWidget(appCon(_marcador(estado)));
    await _cambiar(tester, estado, const _Estado(30, 1, 1));

    expect(find.byKey(_rojo), findsOneWidget);
    expect(find.byKey(_verde), findsNothing);
    expect(_escala(tester, 'marcador-visitante'), closeTo(1.4, 0.001));
    expect(_escala(tester, 'marcador-local'), 1);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(_rojo), findsNothing);
  });

  testWidgets('de visitante, el número nuestro entra por la derecha', (
    tester,
  ) async {
    pantalla(tester);
    final estado = ValueNotifier(const _Estado(30, 0, 1));

    await tester.pumpWidget(appCon(_marcador(estado, local: false)));
    await _cambiar(tester, estado, const _Estado(30, 1, 1));

    expect(find.byKey(_verde), findsOneWidget);
    expect(_escala(tester, 'marcador-visitante'), closeTo(1.4, 0.001));
    expect(_escala(tester, 'marcador-local'), 1);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('si baja (gol anulado) no hay destello ni animación', (
    tester,
  ) async {
    pantalla(tester);
    final estado = ValueNotifier(const _Estado(30, 2, 1));

    await tester.pumpWidget(appCon(_marcador(estado)));
    await _cambiar(tester, estado, const _Estado(30, 1, 1));

    expect(find.byKey(_verde), findsNothing);
    expect(find.byKey(_rojo), findsNothing);
    expect(_escala(tester, 'marcador-local'), 1);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('marcador-local'))).data,
      '1',
    );
  });

  testWidgets('con la animación reducida el número cambia sin movimiento ni destello', (
    tester,
  ) async {
    pantalla(tester);
    final estado = ValueNotifier(const _Estado(30, 1, 0));

    await tester.pumpWidget(appCon(_marcador(estado), reducirAnimaciones: true));
    await _cambiar(tester, estado, const _Estado(30, 2, 0));

    expect(find.byKey(_verde), findsNothing);
    expect(_escala(tester, 'marcador-local'), 1);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('marcador-local'))).data,
      '2',
    );
  });

  testWidgets('con la app en segundo plano solo se actualiza', (tester) async {
    pantalla(tester);
    final estado = ValueNotifier(const _Estado(30, 1, 0));

    await tester.pumpWidget(appCon(_marcador(estado)));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _cambiar(tester, estado, const _Estado(30, 2, 0));

    expect(find.byKey(_verde), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('marcador-local'))).data,
      '2',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });

  testWidgets('si cambia el partido, el marcador del otro no late', (
    tester,
  ) async {
    pantalla(tester);
    final estado = ValueNotifier(const _Estado(30, 0, 0));

    await tester.pumpWidget(appCon(_marcador(estado)));
    await _cambiar(tester, estado, const _Estado(31, 3, 1));

    expect(find.byKey(_verde), findsNothing);
    expect(find.byKey(_rojo), findsNothing);
  });
}
