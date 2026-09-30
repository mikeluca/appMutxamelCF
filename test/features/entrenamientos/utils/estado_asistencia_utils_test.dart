import 'package:flutter_test/flutter_test.dart';

import 'package:app_mutxamel_cf/features/entrenamientos/utils/estado_asistencia_utils.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations_es.dart';

void main() {
  final t = AppLocalizationsEs();

  group('labelEstadoAsistencia', () {
    test('traduce cada estado reconocido', () {
      expect(labelEstadoAsistencia(t, 'PRESENTE'), t.attendanceStatusPresent);
      expect(labelEstadoAsistencia(t, 'FALTA'), t.attendanceStatusAbsent);
      expect(labelEstadoAsistencia(t, 'RETRASO'), t.attendanceStatusLate);
      expect(
        labelEstadoAsistencia(t, 'FALTA_JUSTIFICADA'),
        t.attendanceStatusJustifiedAbsence,
      );
      expect(
        labelEstadoAsistencia(t, 'MAL_COMPORTAMIENTO'),
        t.attendanceStatusMisconduct,
      );
    });

    test('un estado no reconocido devuelve el propio codigo, no una cadena vacia', () {
      expect(labelEstadoAsistencia(t, 'ESTADO_INVENTADO'), 'ESTADO_INVENTADO');
    });
  });

  group('colorEstadoAsistencia', () {
    test('cada estado reconocido tiene un color distinto', () {
      final colores = {
        colorEstadoAsistencia('PRESENTE'),
        colorEstadoAsistencia('FALTA'),
        colorEstadoAsistencia('RETRASO'),
        colorEstadoAsistencia('FALTA_JUSTIFICADA'),
        colorEstadoAsistencia('MAL_COMPORTAMIENTO'),
      };

      expect(colores, hasLength(5));
    });

    test('un estado no reconocido no lanza excepcion', () {
      expect(() => colorEstadoAsistencia('ESTADO_INVENTADO'), returnsNormally);
    });
  });
}
