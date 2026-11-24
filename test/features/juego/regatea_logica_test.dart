import 'dart:math' as math;

import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:app_mutxamel_cf/features/juego/logica/regatea_logica.dart';
import 'package:flutter_test/flutter_test.dart';

const double _alto = 640;
const Duration _fotograma = Duration(milliseconds: 16);

RegateaLogica _manual({math.Random? random}) =>
    RegateaLogica(alto: _alto, generarSolo: false, random: random);

/// Pasa [segundos] de partida.
void _pasar(RegateaLogica l, double segundos) {
  final fotogramas = (segundos * 1000 / _fotograma.inMilliseconds).round();

  for (var i = 0; i < fotogramas && !l.terminado; i++) {
    l.tick(_fotograma);
  }
}

void main() {
  group('cambiar de carril', () {
    test('empieza en el carril central y se mueve de uno en uno sin salirse del campo', () {
      final l = _manual();

      expect(l.carril, 1);

      l.cambiarCarril(-1);

      expect(l.carril, 0);

      l.cambiarCarril(-1);

      expect(l.carril, 0);

      l.cambiarCarril(1);
      l.cambiarCarril(1);
      l.cambiarCarril(1);

      expect(l.carril, 2);
    });

    test('la transición dura unos 150 ms', () {
      final l = _manual();

      l.cambiarCarril(-1);
      l.tick(const Duration(milliseconds: 75));

      expect(l.posicionCarril, closeTo(0.5, 0.05));

      l.tick(const Duration(milliseconds: 60));

      expect(l.posicionCarril, greaterThan(0));
      expect(l.posicionCarril, lessThan(0.2));

      l.tick(const Duration(milliseconds: 30));

      expect(l.posicionCarril, 0);
    });
  });

  group('los obstáculos', () {
    for (final tipo in [TipoPista.defensa, TipoPista.cono]) {
      test('chocar con un ${tipo.name} quita una vida y da 1 s de invulnerabilidad', () {
        final l = _manual();
        final eventos = <EventoJuego>[];

        l.alEvento = eventos.add;
        l.colocar(tipo, 1, 100);

        _pasar(l, 0.6);

        expect(l.vidas, 2);
        expect(l.invulnerable, isTrue);
        expect(l.puntos, 0, reason: 'un obstáculo con el que se choca no cuenta como superado');
        expect(eventos, [EventoJuego.fallo]);

        // Dura 1 s.
        _pasar(l, 0.9);

        expect(l.invulnerable, isFalse);
      });
    }

    test('durante la invulnerabilidad otro choque no quita vida; después sí', () {
      final l = _manual();

      l.colocar(TipoPista.defensa, 1, 100);
      l.colocar(TipoPista.cono, 1, 300); // llega unos 0,7 s después
      l.colocar(TipoPista.cono, 1, 900); // llega ya sin invulnerabilidad

      _pasar(l, 1.2);

      expect(l.vidas, 2, reason: 'el segundo, con parpadeo, no cuenta');

      _pasar(l, 3.0);

      expect(l.vidas, 1);
    });

    test('con 3 choques se acaba la partida', () {
      final l = _manual();

      for (var i = 0; i < 3; i++) {
        l.colocar(TipoPista.defensa, 1, 100);
        _pasar(l, 1.6);
      }

      expect(l.vidas, 0);
      expect(l.terminado, isTrue);
    });

    test('esquivarlo cambiando de carril suma 1 y no quita vida', () {
      final l = _manual();

      l.colocar(TipoPista.defensa, 1, 600);
      l.cambiarCarril(-1);

      _pasar(l, 2.5);

      expect(l.vidas, 3);
      expect(l.puntos, 1);
    });

    test('cada obstáculo superado suma 1 (también el charco)', () {
      final l = _manual();

      l.colocar(TipoPista.defensa, 0, 200);
      l.colocar(TipoPista.cono, 2, 300);
      l.colocar(TipoPista.charco, 0, 400);

      _pasar(l, 2.5);

      expect(l.puntos, 3);
      expect(l.vidas, 3);
    });

    test('el charco frena 1,5 s a la mitad de velocidad y no quita vida', () {
      final l = _manual();

      final antes = l.velocidad;

      l.colocar(TipoPista.charco, 1, 100);
      _pasar(l, 0.6);

      expect(l.vidas, 3);
      expect(l.frenado, isTrue);
      expect(l.velocidad, closeTo(l.velocidadBase * RegateaLogica.factorFrenado, 0.001));
      expect(l.velocidad, lessThan(antes + 20));
      expect(l.puntos, 0, reason: 'un charco pisado no cuenta como superado');

      // A los 1,5 s de frenado se acaba.
      _pasar(l, 1.6);

      expect(l.frenado, isFalse);
      expect(l.velocidad, l.velocidadBase);
    });

    test('el campo no se acaba: la velocidad sube poco a poco hasta un máximo', () {
      final l = _manual();

      expect(l.velocidadBase, RegateaLogica.velocidadInicial);

      _pasar(l, 20);

      expect(l.velocidadBase, greaterThan(RegateaLogica.velocidadInicial + 100));

      _pasar(l, 100);

      expect(l.velocidadBase, RegateaLogica.velocidadMaxima);
    });
  });

  group('recoger', () {
    test('un balón en tu carril suma 1 y uno dorado, 5', () {
      final l = _manual();

      l.colocar(TipoPista.balon, 1, 100);
      l.colocar(TipoPista.balonDorado, 1, 300);

      _pasar(l, 1.5);

      expect(l.puntos, 6);
      expect(l.vidas, 3);
    });

    test('un balón en otro carril no se recoge', () {
      final l = _manual();

      l.colocar(TipoPista.balon, 0, 100);
      l.colocar(TipoPista.balonDorado, 2, 200);

      _pasar(l, 1.5);

      expect(l.puntos, 0);
    });

    test('cambiando de carril a tiempo se recoge', () {
      final l = _manual();

      l.colocar(TipoPista.balon, 2, 500);
      l.cambiarCarril(1);

      _pasar(l, 2);

      expect(l.puntos, 1);
    });
  });

  group('nunca se bloquean los 3 carriles', () {
    test('en ninguna fila, con cualquier azar y a cualquier hora de la partida', () {
      for (var semilla = 0; semilla < 300; semilla++) {
        for (final segundos in [0.0, 12.0, 80.0]) {
          final l = _manual(random: math.Random(semilla));

          _pasar(l, segundos);
          l.soltarFila();

          final obstaculos = l.objetos.where((o) => o.tipo.esObstaculo).toList();
          final carriles = obstaculos.map((o) => o.carril).toSet();

          expect(obstaculos, isNotEmpty);
          expect(carriles.length, lessThanOrEqualTo(2), reason: 'semilla $semilla a los $segundos s');
          expect(carriles.length, obstaculos.length, reason: 'un solo obstáculo por carril');

          // Y lo que no es obstáculo va en carriles libres.
          for (final o in l.objetos.where((o) => !o.tipo.esObstaculo)) {
            expect(carriles, isNot(contains(o.carril)));
          }
        }
      }
    });

    test('una partida entera genera filas sola y siempre deja un carril libre', () {
      final l = RegateaLogica(alto: _alto, random: math.Random(5));
      final filas = <double, int>{};

      for (var i = 0; i < 6000 && !l.terminado; i++) {
        l.tick(_fotograma);

        // Esquiva siempre: va al carril que no tiene obstáculo más cercano.
        final proximos = l.objetos.where((o) => o.distancia > 0).toList()
          ..sort((a, b) => a.distancia.compareTo(b.distancia));

        if (proximos.isNotEmpty) {
          final primero = proximos.first;
          final fila = proximos.where((o) => (o.distancia - primero.distancia).abs() < 1);
          final bloqueados = fila.where((o) => o.tipo.esObstaculo).map((o) => o.carril).toSet();

          filas[primero.distancia] = bloqueados.length;

          expect(bloqueados.length, lessThan(3));

          final libre = [0, 1, 2].firstWhere((c) => !bloqueados.contains(c));

          if (libre < l.carril) l.cambiarCarril(-1);
          if (libre > l.carril) l.cambiarCarril(1);
        }
      }

      expect(filas.length, greaterThan(20));
      expect(l.terminado, isFalse, reason: 'esquivando siempre se puede seguir corriendo');
      expect(l.puntos, greaterThan(20));
    });
  });

  group('correr', () {
    test('las imágenes alternan corriendo 1, 2, 3 y 2', () {
      final l = _manual();
      final vistas = <int>[];

      for (var i = 0; i < 200; i++) {
        l.tick(_fotograma);

        if (vistas.isEmpty || vistas.last != l.cuadroDeCarrera) vistas.add(l.cuadroDeCarrera);
      }

      expect(vistas.take(8), [0, 1, 2, 1, 0, 1, 2, 1]);
    });

    test('empieza a unas 8 imágenes por segundo y corre más rápido con la velocidad', () {
      int cambios(RegateaLogica l, double segundos) {
        var n = 0;
        var anterior = l.cuadroDeCarrera;

        for (var t = 0.0; t < segundos; t += 0.016) {
          l.tick(_fotograma);

          if (l.cuadroDeCarrera != anterior) n++;

          anterior = l.cuadroDeCarrera;
        }

        return n;
      }

      final l = _manual();
      final alPrincipio = cambios(l, 2);

      expect(alPrincipio, inInclusiveRange(14, 20), reason: '≈ 8 por segundo');

      _pasar(l, 60);

      final despues = cambios(l, 2);

      expect(despues, greaterThan(alPrincipio));
    });
  });

  test('el campo avanza a la velocidad de la carrera (recorrido)', () {
    final l = _manual();

    _pasar(l, 1);

    expect(l.recorrido, greaterThan(250));
    expect(l.tiempoJugado.inMilliseconds, closeTo(1000, 20));
    expect(l.segundos, closeTo(1, 0.02));
    expect(LogicaJuego.ancho, 360);
  });
}
