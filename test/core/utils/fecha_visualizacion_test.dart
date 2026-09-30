import 'package:flutter_test/flutter_test.dart';

import 'package:app_mutxamel_cf/core/utils/fecha_visualizacion.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations_es.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations_ca.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations_en.dart';

void main() {
  group('formatearFechaConDiaSemana', () {
    // Martes 29/09/2026.
    final fecha = DateTime(2026, 9, 29);

    test('en castellano', () {
      expect(
        formatearFechaConDiaSemana(fecha, AppLocalizationsEs()),
        'Martes, 29/09/2026',
      );
    });

    test('en valenciano', () {
      expect(
        formatearFechaConDiaSemana(fecha, AppLocalizationsCa()),
        'Dimarts, 29/09/2026',
      );
    });

    test('en ingles', () {
      expect(
        formatearFechaConDiaSemana(fecha, AppLocalizationsEn()),
        'Tuesday, 29/09/2026',
      );
    });

    test('rellena dia y mes con cero a la izquierda', () {
      // Domingo 01/02/2026.
      expect(
        formatearFechaConDiaSemana(DateTime(2026, 2, 1), AppLocalizationsEs()),
        'Domingo, 01/02/2026',
      );
    });
  });
}
