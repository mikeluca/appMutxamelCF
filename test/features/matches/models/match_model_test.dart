import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';

void main() {
  group('MatchModel.fromJson', () {
    test('parsea un partido completo, incluyendo id, equipoId y tipo', () {
      final partido = MatchModel.fromJson({
        'id': 123,
        'equipoId': 45,
        'categoria': 'Senior',
        'equipo': 'Senior A',
        'rival': 'Rival CF',
        'resultado': '2-1',
        'dia': '2026-10-05',
        'diaFormateado': '05/10/2026',
        'hora': '18:00',
        'campo': 'Campo Municipal',
        'tipo': 'LIGA',
      });

      expect(partido.id, 123);
      expect(partido.equipoId, 45);
      expect(partido.categoria, 'Senior');
      expect(partido.equipo, 'Senior A');
      expect(partido.rival, 'Rival CF');
      expect(partido.resultado, '2-1');
      expect(partido.dia, DateTime.parse('2026-10-05'));
      expect(partido.diaFormateado, '05/10/2026');
      expect(partido.hora, '18:00');
      expect(partido.campo, 'Campo Municipal');
      expect(partido.tipo, 'LIGA');
    });

    test('id, equipoId y tipo son nulos cuando no vienen en el JSON '
        '(endpoints legacy /public/resultados)', () {
      final partido = MatchModel.fromJson({
        'categoria': 'Senior',
        'equipo': 'Senior A',
        'rival': 'Rival CF',
      });

      expect(partido.id, isNull);
      expect(partido.equipoId, isNull);
      expect(partido.tipo, isNull);
    });

    test('campos opcionales ausentes se convierten en null', () {
      final partido = MatchModel.fromJson({
        'equipo': 'Senior A',
        'rival': 'DESCANSA',
      });

      expect(partido.resultado, isNull);
      expect(partido.dia, isNull);
      expect(partido.diaFormateado, isNull);
      expect(partido.hora, isNull);
      expect(partido.campo, isNull);
    });
  });

  group('MatchModel getters', () {
    test('esProximoPartido es true si no hay resultado y no descansa', () {
      const partido = MatchModel(
        categoria: 'Senior',
        equipo: 'Senior A',
        rival: 'Rival CF',
      );

      expect(partido.esProximoPartido, isTrue);
      expect(partido.estaJugado, isFalse);
      expect(partido.estaDescansando, isFalse);
    });

    test('estaJugado es true si hay resultado informado', () {
      const partido = MatchModel(
        categoria: 'Senior',
        equipo: 'Senior A',
        rival: 'Rival CF',
        resultado: '2-1',
      );

      expect(partido.estaJugado, isTrue);
      expect(partido.esProximoPartido, isFalse);
    });

    test('estaDescansando es true si el rival es DESCANSA', () {
      const partido = MatchModel(
        categoria: 'Senior',
        equipo: 'Senior A',
        rival: 'Descansa',
      );

      expect(partido.estaDescansando, isTrue);
      expect(partido.esProximoPartido, isFalse);
    });
  });
}
