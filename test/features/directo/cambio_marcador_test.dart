import 'package:app_mutxamel_cf/features/directo/models/cambio_marcador.dart';
import 'package:flutter_test/flutter_test.dart';

CambioMarcador _c(int? fa, int? ca, int? f, int? c) =>
    compararMarcador(favorAntes: fa, contraAntes: ca, favor: f, contra: c);

void main() {
  group('compararMarcador', () {
    test('igual: nada', () {
      expect(_c(1, 0, 1, 0), CambioMarcador.ninguno);
    });

    test('sube el nuestro: gol del Mutxamel', () {
      expect(_c(0, 0, 1, 0), CambioMarcador.golNuestro);
    });

    test('sube el del rival: gol del rival', () {
      expect(_c(1, 0, 1, 1), CambioMarcador.golRival);
    });

    test('dos goles a la vez: uno solo, con el del Mutxamel primero', () {
      expect(_c(0, 0, 2, 0), CambioMarcador.golNuestro);
      expect(_c(0, 0, 0, 2), CambioMarcador.golRival);
      expect(_c(0, 0, 1, 1), CambioMarcador.golNuestro);
    });

    test('si baja (gol anulado) no se celebra', () {
      expect(_c(2, 1, 1, 1), CambioMarcador.baja);
      expect(_c(1, 1, 1, 0), CambioMarcador.baja);
      // Aunque el otro suba, un marcador que baja es una corrección.
      expect(_c(1, 1, 2, 0), CambioMarcador.baja);
    });

    test('sin marcador cuenta como 0-0: el primer gol se ve como subida', () {
      expect(_c(null, null, 1, 0), CambioMarcador.golNuestro);
      expect(_c(null, null, 0, 0), CambioMarcador.ninguno);
      expect(_c(null, null, null, null), CambioMarcador.ninguno);
    });
  });
}
