import 'package:flutter_test/flutter_test.dart';

import 'package:app_mutxamel_cf/features/calendario/model/sesion_entrenamiento_model.dart';

void main() {
  group('SesionEntrenamientoModel.fromJson', () {
    Map<String, dynamic> jsonBase() => {
      'id': 1,
      'equipoId': 3,
      'equipo': 'Alevín A',
      'fecha': '2026-09-29',
      'hora': '18:00',
      'lugar': 'Campo Municipal',
      'estado': 'PROGRAMADA',
    };

    test('parsea los campos basicos', () {
      final sesion = SesionEntrenamientoModel.fromJson(jsonBase());

      expect(sesion.id, 1);
      expect(sesion.equipoId, 3);
      expect(sesion.equipo, 'Alevín A');
      expect(sesion.fecha, DateTime(2026, 9, 29));
      expect(sesion.hora, '18:00');
      expect(sesion.lugar, 'Campo Municipal');
      expect(sesion.estado, 'PROGRAMADA');
      expect(sesion.cancelada, isFalse);
    });

    test('justificado/motivoJustificacion por defecto son false/null', () {
      final sesion = SesionEntrenamientoModel.fromJson(jsonBase());

      expect(sesion.justificado, isFalse);
      expect(sesion.motivoJustificacion, isNull);
    });

    test('cancelada es true cuando estado es CANCELADA', () {
      final sesion = SesionEntrenamientoModel.fromJson({
        ...jsonBase(),
        'estado': 'CANCELADA',
        'motivoCancelacion': 'Lluvia',
      });

      expect(sesion.cancelada, isTrue);
      expect(sesion.motivoCancelacion, 'Lluvia');
    });

    group('asistencia', () {
      test('viene rellena cuando el backend la informa (sesion pasada)', () {
        final sesion = SesionEntrenamientoModel.fromJson({
          ...jsonBase(),
          'asistencia': 'FALTA_JUSTIFICADA',
        });

        expect(sesion.asistencia, 'FALTA_JUSTIFICADA');
      });

      test('es null cuando el backend no la informa (sesion futura)', () {
        final sesion = SesionEntrenamientoModel.fromJson(jsonBase());

        expect(sesion.asistencia, isNull);
      });
    });
  });
}
