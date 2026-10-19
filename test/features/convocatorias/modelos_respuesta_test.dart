import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/mi_convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MiConvocatoriaModel lee la respuesta, el plazo y el partido', () {
    final c = MiConvocatoriaModel.fromJson({
      'convocatoriaId': 20,
      'jugadorId': 100,
      'jugador': 'Pablo Garcia',
      'equipoId': 5,
      'equipo': 'Cadete A',
      'rival': 'Pego C.F.',
      'fechaPartido': '2026-10-24',
      'horaPartido': '11:00',
      'campo': 'Municipal',
      'local': false,
      'cancelado': false,
      'horaConvocatoria': '09:30',
      'lugarConvocatoria': 'Vestuarios',
      'respuesta': 'NO_PUEDE',
      'motivo': 'Enfermo',
      'fechaRespuesta': '2026-10-21T10:15:30',
      'puedeResponder': true,
      'limiteRespuesta': '2026-10-24T09:30:00',
    });

    expect(c.convocatoriaId, 20);
    expect(c.respuesta, MiConvocatoriaModel.respuestaNoPuede);
    expect(c.motivo, 'Enfermo');
    expect(c.local, isFalse);
    expect(c.puedeResponder, isTrue);
    expect(c.limiteRespuesta, DateTime(2026, 10, 24, 9, 30));
    expect(c.fechaPartido, DateTime(2026, 10, 24));
  });

  test('sin respuesta ni plazo los valores por defecto son seguros', () {
    final c = MiConvocatoriaModel.fromJson({
      'convocatoriaId': 1,
      'jugadorId': 2,
    });

    expect(c.respuesta, isNull);
    expect(c.puedeResponder, isFalse);
    expect(c.limiteRespuesta, isNull);
  });

  test('ConvocatoriaJugadorModel lee la respuesta que ve el entrenador', () {
    final j = ConvocatoriaJugadorModel.fromJson({
      'jugadorId': 3,
      'jugador': 'Ana',
      'respuesta': 'VA',
      'fechaRespuesta': '2026-10-21T10:00:00',
    });

    expect(j.respuesta, 'VA');
    expect(j.motivo, isNull);
    expect(j.fechaRespuesta, DateTime(2026, 10, 21, 10));
  });

  test('MatchModel lee respuestaConvocatoria (null si falta)', () {
    expect(
      MatchModel.fromJson({
        'respuestaConvocatoria': 'VA',
      }).respuestaConvocatoria,
      'VA',
    );
    expect(MatchModel.fromJson({}).respuestaConvocatoria, isNull);
  });
}
