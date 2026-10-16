import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/core/utils/marcador.dart';

void main() {
  group('marcadorLocalVisitante', () {
    test('local: se deja tal cual', () {
      expect(marcadorLocalVisitante('1-2', local: true), '1-2');
      expect(marcadorLocalVisitante(' 1-2 ', local: true), '1-2');
    });

    test('visitante: se da la vuelta', () {
      expect(marcadorLocalVisitante('1-2', local: false), '2-1');
      expect(marcadorLocalVisitante(' 3 - 0 ', local: false), '0-3');
      expect(marcadorLocalVisitante('10-2', local: false), '2-10');
    });

    test('sin resultado devuelve null', () {
      expect(marcadorLocalVisitante(null, local: false), isNull);
      expect(marcadorLocalVisitante('', local: false), isNull);
      expect(marcadorLocalVisitante('   ', local: true), isNull);
    });

    test('texto que no es X-Y se devuelve tal cual', () {
      expect(marcadorLocalVisitante('-', local: false), '-');
      expect(marcadorLocalVisitante(' - ', local: false), '-');
      expect(marcadorLocalVisitante('Aplazado', local: false), 'Aplazado');
      expect(marcadorLocalVisitante('1-2-3', local: false), '1-2-3');
    });
  });
}
