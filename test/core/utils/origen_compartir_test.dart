import 'package:app_mutxamel_cf/core/utils/origen_compartir.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('es el rectángulo del botón que lanza el menú de compartir', (
    tester,
  ) async {
    Rect? origen;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: Builder(
              builder: (contexto) => ElevatedButton(
                onPressed: () => origen = origenDeCompartir(contexto),
                child: const Text('Compartir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    expect(origen, tester.getRect(find.byType(ElevatedButton)));
    expect(origen!.isEmpty, isFalse);
  });

  testWidgets('sin poder medir el botón, un punto en el centro de la pantalla', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late BuildContext contexto;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            contexto = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // El contexto de la pantalla entera no tiene tamaño medible útil (es 0x0): se usa el centro.
    final origen = origenDeCompartir(contexto);

    expect(origen.center, const Offset(400, 500));
  });

  test('sin contexto, un punto cualquiera (nunca nulo)', () {
    expect(origenDeCompartir(null).isEmpty, isFalse);
  });
}
