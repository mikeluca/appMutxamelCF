import 'package:flutter_test/flutter_test.dart';

import 'package:app_mutxamel_cf/core/utils/backend_date.dart';

void main() {
  group('parseFechaBackend', () {
    test('null devuelve null', () {
      expect(parseFechaBackend(null), isNull);
    });

    test('texto ISO-8601 (formato actual, post N-06)', () {
      expect(parseFechaBackend('2026-09-29'), DateTime(2026, 9, 29));
    });

    test('array [year, month, day] (formato antiguo, pre N-06)', () {
      expect(parseFechaBackend([2026, 9, 29]), DateTime(2026, 9, 29));
    });

    test('array con hora/minuto/segundo', () {
      expect(
        parseFechaBackend([2026, 9, 29, 18, 30, 0]),
        DateTime(2026, 9, 29, 18, 30, 0),
      );
    });

    test('lista vacia devuelve null', () {
      expect(parseFechaBackend(<dynamic>[]), isNull);
    });

    test('un tipo no reconocido devuelve null', () {
      expect(parseFechaBackend(42), isNull);
    });
  });

  group('parseFechaTextoBackend', () {
    // Regresión: tras N-06 el backend serializa LocalDate como texto
    // ISO ("2026-09-29") en vez del array antiguo; los modelos que ya
    // convertían el valor a String con json['fecha']?.toString() antes
    // de llegar aquí (EntrenamientoModel.fecha, ConvocatoriaModel.
    // fechaPartido) dejaron de reconocer la fecha porque su regex solo
    // entendía el "[year, month, day]" que resultaba de aplicar
    // toString() al array antiguo.
    test('texto ISO-8601 (formato actual)', () {
      expect(parseFechaTextoBackend('2026-09-29'), DateTime(2026, 9, 29));
    });

    test('texto "[year, month, day]" (List.toString() del array antiguo)', () {
      expect(parseFechaTextoBackend('[2026, 9, 29]'), DateTime(2026, 9, 29));
    });

    test('null o vacio devuelve null', () {
      expect(parseFechaTextoBackend(null), isNull);
      expect(parseFechaTextoBackend(''), isNull);
    });

    test('un texto que no es ninguna fecha reconocida devuelve null', () {
      expect(parseFechaTextoBackend('no es una fecha'), isNull);
    });
  });
}
