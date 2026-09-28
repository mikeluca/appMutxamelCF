import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/matches/models/partido_estadisticas_model.dart';

void main() {
  group('EstadisticaJugadorModel.fromJson', () {
    test('parsea una fila completa de la respuesta del backend', () {
      final estadistica = EstadisticaJugadorModel.fromJson({
        'jugadorId': 7,
        'jugador': 'Juan Pérez',
        'goles': 2,
        'asistencias': 1,
        'tarjetasAmarillas': 1,
        'tarjetaRoja': false,
      });

      expect(estadistica.jugadorId, 7);
      expect(estadistica.jugador, 'Juan Pérez');
      expect(estadistica.goles, 2);
      expect(estadistica.asistencias, 1);
      expect(estadistica.tarjetasAmarillas, 1);
      expect(estadistica.tarjetaRoja, isFalse);
    });
  });

  group('EstadisticaJugadorModel.toJson', () {
    test('serializa el cuerpo esperado por el backend, sin el nombre', () {
      const estadistica = EstadisticaJugadorModel(
        jugadorId: 7,
        jugador: 'Juan Pérez',
        goles: 2,
        asistencias: 1,
        tarjetasAmarillas: 1,
        tarjetaRoja: true,
      );

      expect(estadistica.toJson(), {
        'jugadorId': 7,
        'goles': 2,
        'asistencias': 1,
        'tarjetasAmarillas': 1,
        'tarjetaRoja': true,
      });
    });
  });

  group('PartidoEstadisticasModel.fromJson', () {
    test('parsea una respuesta con resultado ya guardado', () {
      final estadisticas = PartidoEstadisticasModel.fromJson({
        'partidoId': 10,
        'golesFavor': 3,
        'golesContra': 1,
        'resultado': '3-1',
        'jugadores': [
          {
            'jugadorId': 1,
            'jugador': 'Ana',
            'goles': 2,
            'asistencias': 0,
            'tarjetasAmarillas': 0,
            'tarjetaRoja': false,
          },
        ],
      });

      expect(estadisticas.partidoId, 10);
      expect(estadisticas.golesFavor, 3);
      expect(estadisticas.golesContra, 1);
      expect(estadisticas.resultado, '3-1');
      expect(estadisticas.jugadores, hasLength(1));
      expect(estadisticas.jugadores.first.jugador, 'Ana');
    });

    test(
        'resultado todavía no introducido: golesFavor/golesContra/resultado '
        'nulos y jugadores vacío', () {
      final estadisticas = PartidoEstadisticasModel.fromJson({
        'partidoId': 10,
        'golesFavor': null,
        'golesContra': null,
        'resultado': null,
        'jugadores': [],
      });

      expect(estadisticas.golesFavor, isNull);
      expect(estadisticas.golesContra, isNull);
      expect(estadisticas.resultado, isNull);
      expect(estadisticas.jugadores, isEmpty);
    });
  });

  group('fusionarRosterConEstadisticas', () {
    test(
        'un jugador de la plantilla sin estadística guardada se rellena a '
        '0/false', () {
      final combinadas = fusionarRosterConEstadisticas(
        roster: const [RosterJugadorModel(jugadorId: 1, jugador: 'Ana')],
        guardadas: const [],
      );

      expect(combinadas, hasLength(1));
      expect(combinadas.first.jugadorId, 1);
      expect(combinadas.first.jugador, 'Ana');
      expect(combinadas.first.goles, 0);
      expect(combinadas.first.asistencias, 0);
      expect(combinadas.first.tarjetasAmarillas, 0);
      expect(combinadas.first.tarjetaRoja, isFalse);
    });

    test('casa por jugadorId, no por posición en la lista', () {
      final combinadas = fusionarRosterConEstadisticas(
        roster: const [
          RosterJugadorModel(jugadorId: 1, jugador: 'Ana'),
          RosterJugadorModel(jugadorId: 2, jugador: 'Bea'),
        ],
        // Deliberadamente en orden inverso al roster.
        guardadas: const [
          EstadisticaJugadorModel(
            jugadorId: 2,
            jugador: 'Bea (nombre antiguo)',
            goles: 5,
            asistencias: 0,
            tarjetasAmarillas: 0,
            tarjetaRoja: false,
          ),
          EstadisticaJugadorModel(
            jugadorId: 1,
            jugador: 'Ana (nombre antiguo)',
            goles: 1,
            asistencias: 2,
            tarjetasAmarillas: 1,
            tarjetaRoja: true,
          ),
        ],
      );

      final ana = combinadas.firstWhere((e) => e.jugadorId == 1);
      final bea = combinadas.firstWhere((e) => e.jugadorId == 2);

      // El nombre mostrado es el de la plantilla actual (roster), no el
      // que pudiera venir en la estadística ya guardada.
      expect(ana.jugador, 'Ana');
      expect(ana.goles, 1);
      expect(ana.asistencias, 2);
      expect(ana.tarjetasAmarillas, 1);
      expect(ana.tarjetaRoja, isTrue);

      expect(bea.jugador, 'Bea');
      expect(bea.goles, 5);
    });

    test(
        'una estadística guardada de un jugador que ya no está en la '
        'plantilla actual se descarta', () {
      final combinadas = fusionarRosterConEstadisticas(
        roster: const [RosterJugadorModel(jugadorId: 1, jugador: 'Ana')],
        guardadas: const [
          EstadisticaJugadorModel(
            jugadorId: 1,
            jugador: 'Ana',
            goles: 1,
            asistencias: 0,
            tarjetasAmarillas: 0,
            tarjetaRoja: false,
          ),
          EstadisticaJugadorModel(
            jugadorId: 99,
            jugador: 'Ya no está en el equipo',
            goles: 4,
            asistencias: 4,
            tarjetasAmarillas: 2,
            tarjetaRoja: true,
          ),
        ],
      );

      expect(combinadas, hasLength(1));
      expect(combinadas.single.jugadorId, 1);
    });

    test('roster vacío produce una lista vacía', () {
      final combinadas = fusionarRosterConEstadisticas(
        roster: const [],
        guardadas: const [
          EstadisticaJugadorModel(
            jugadorId: 1,
            jugador: 'Ana',
            goles: 1,
            asistencias: 0,
            tarjetasAmarillas: 0,
            tarjetaRoja: false,
          ),
        ],
      );

      expect(combinadas, isEmpty);
    });
  });
}
