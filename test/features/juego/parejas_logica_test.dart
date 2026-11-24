import 'dart:math' as math;

import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:app_mutxamel_cf/features/juego/logica/parejas_logica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/juego_helpers.dart';

ParejasLogica _logica({math.Random? random, int escudos = 8}) => ParejasLogica(
  alto: 640,
  escudos: escudosDePrueba(escudos),
  random: random ?? math.Random(1),
);

/// Las dos cartas de un club.
List<int> _pareja(ParejasLogica l, int id) =>
    l.cartas.where((c) => c.escudo.id == id).map((c) => c.posicion).toList();

/// Dos cartas de clubes distintos.
(int, int) _distintas(ParejasLogica l) {
  final a = l.cartas.first;
  final b = l.cartas.firstWhere((c) => c.escudo.id != a.escudo.id);

  return (a.posicion, b.posicion);
}

void main() {
  group('el tablero', () {
    test('4×4 con 8 parejas: cada club sale dos veces y todas empiezan boca abajo', () {
      final l = _logica();

      expect(ParejasLogica.columnas * ParejasLogica.filas, 16);
      expect(l.cartas, hasLength(16));
      expect(l.cartas.every((c) => c.estado == EstadoCarta.oculta), isTrue);

      for (var id = 1; id <= 8; id++) {
        expect(_pareja(l, id), hasLength(2), reason: 'club $id');
      }
    });

    test('el reparto es al azar (y el azar se puede inyectar)', () {
      List<int> ids(math.Random r) => _logica(random: r).cartas.map((c) => c.escudo.id).toList();

      expect(ids(math.Random(1)), ids(math.Random(1)));
      expect(ids(math.Random(1)), isNot(ids(math.Random(2))));
    });

    test('con más de 8 escudos usa solo 8', () {
      final l = _logica(escudos: 12);

      expect(l.cartas.map((c) => c.escudo.id).toSet(), hasLength(8));
    });
  });

  group('la pareja correcta', () {
    test('se quedan descubiertas, se cuenta el intento y suena el aviso de punto', () {
      final l = _logica();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;

      final par = _pareja(l, 3);

      expect(l.tocar(par[0]), isTrue);
      expect(l.cartas[par[0]].estado, EstadoCarta.descubierta);
      expect(l.tocar(par[1]), isTrue);

      expect(l.cartas[par[0]].estado, EstadoCarta.emparejada);
      expect(l.cartas[par[1]].estado, EstadoCarta.emparejada);
      expect(l.encontradas, 1);
      expect(l.intentos, 1);
      expect(l.esperandoGiro, isFalse);
      expect(eventos, [EventoJuego.punto]);

      // Y se quedan así.
      l.tick(const Duration(seconds: 5));

      expect(l.cartas[par[0]].estado, EstadoCarta.emparejada);
    });

    test('una carta emparejada ya no se puede tocar', () {
      final l = _logica();
      final par = _pareja(l, 1);

      l.tocar(par[0]);
      l.tocar(par[1]);

      expect(l.tocar(par[0]), isFalse);
      expect(l.intentos, 1);
    });
  });

  group('la pareja incorrecta', () {
    test('se vuelven a girar a los 0,8 s y cuenta como intento', () {
      final l = _logica();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;

      final (a, b) = _distintas(l);

      l.tocar(a);
      l.tocar(b);

      expect(l.intentos, 1);
      expect(l.encontradas, 0);
      expect(l.esperandoGiro, isTrue);
      expect(l.cartas[a].estado, EstadoCarta.descubierta);
      expect(l.cartas[b].estado, EstadoCarta.descubierta);
      expect(eventos, [EventoJuego.fallo]);

      l.tick(const Duration(milliseconds: 700));

      expect(l.cartas[a].estado, EstadoCarta.descubierta, reason: 'aún no');

      l.tick(const Duration(milliseconds: 150));

      expect(l.cartas[a].estado, EstadoCarta.oculta);
      expect(l.cartas[b].estado, EstadoCarta.oculta);
      expect(l.esperandoGiro, isFalse);

      // Y se pueden volver a tocar.
      expect(l.tocar(a), isTrue);
    });

    test('mientras esperan para girarse no se puede tocar otra carta', () {
      final l = _logica();
      final (a, b) = _distintas(l);
      final otra = l.cartas.firstWhere((c) => c.posicion != a && c.posicion != b).posicion;

      l.tocar(a);
      l.tocar(b);

      expect(l.tocar(otra), isFalse);
      expect(l.cartas[otra].estado, EstadoCarta.oculta);
      expect(l.intentos, 1);
    });

    test('tocar dos veces la misma carta no la empareja consigo misma', () {
      final l = _logica();

      l.tocar(0);

      expect(l.tocar(0), isFalse);
      expect(l.intentos, 0);
      expect(l.cartas[0].estado, EstadoCarta.descubierta);
    });

    test('fuera del tablero no hace nada', () {
      final l = _logica();

      expect(l.tocar(-1), isFalse);
      expect(l.tocar(16), isFalse);
      expect(l.empezada, isFalse);
    });
  });

  group('el cronómetro', () {
    test('no corre hasta la primera carta', () {
      final l = _logica();

      l.tick(const Duration(seconds: 5));

      expect(l.empezada, isFalse);
      expect(l.tiempoJugado, Duration.zero);

      l.tocar(0);

      expect(l.empezada, isTrue);
      expect(l.tiempoJugado, Duration.zero);

      l.tick(const Duration(milliseconds: 1500));

      expect(l.tiempoJugado, const Duration(milliseconds: 1500));
    });

    test('se para con la última pareja', () {
      final l = _logica();

      l.tocar(_pareja(l, 1)[0]);
      l.tick(const Duration(milliseconds: 2500));

      for (var id = 1; id <= 8; id++) {
        final par = _pareja(l, id);

        if (id > 1) l.tocar(par[0]);
        l.tocar(par[1]);
      }

      expect(l.terminado, isTrue);
      expect(l.tiempoJugado, const Duration(milliseconds: 2500));

      l.tick(const Duration(seconds: 10));

      expect(l.tiempoJugado, const Duration(milliseconds: 2500));
    });
  });

  group('el final', () {
    test('con las 8 parejas la partida acaba con 8 puntos y sus intentos', () {
      final l = _logica();

      expect(l.terminado, isFalse);
      expect(l.puntos, 0);

      // Un fallo por el camino.
      final (a, b) = _distintas(l);

      l.tocar(a);
      l.tocar(b);
      l.tick(const Duration(seconds: 1));

      for (var id = 1; id <= 8; id++) {
        final par = _pareja(l, id);

        l.tocar(par[0]);
        l.tocar(par[1]);

        expect(l.encontradas, id);
      }

      expect(l.terminado, isTrue);
      expect(l.puntos, 8);
      expect(l.intentos, 9);
      expect(l.vidas, isNull);
      expect(l.cartas.every((c) => c.estado == EstadoCarta.emparejada), isTrue);
      expect(l.tocar(0), isFalse);
    });

    test('con menos de 8 escudos no se puede jugar (el tablero lo exige)', () {
      expect(
        () => ParejasLogica(alto: 640, escudos: escudosDePrueba(5)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  test('es una lógica de juego como las demás (ancho del campo y sin vidas)', () {
    expect(LogicaJuego.ancho, 360);
    expect(_logica().puntos, 0);
  });
}
