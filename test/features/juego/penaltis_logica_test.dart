
import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:app_mutxamel_cf/features/juego/logica/penaltis_logica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/juego_helpers.dart';

const double _alto = 640;

/// El deslizamiento (de inicio a fin) con el que el balón llega a [objetivo].
(Offset, Offset) _gestoHacia(PenaltisLogica l, Offset objetivo) {
  final inicio = l.balonReposo;

  return (inicio, inicio + (objetivo - inicio) / PenaltisLogica.alcance);
}

/// Pasa el vuelo del balón y el resultado, hasta poder tirar otra vez.
void _acabarTiro(PenaltisLogica l) {
  l.tick(PenaltisLogica.duracionDisparo);
  l.tick(PenaltisLogica.duracionResultado);
}

void main() {
  group('zonas de la portería', () {
    test('son 6: 3 columnas × 2 alturas, la fila 0 es la de arriba', () {
      const p = PenaltisLogica.porteria;

      expect(PenaltisLogica.zonaDe(Offset(p.left + 5, p.top + 5)), 0);
      expect(PenaltisLogica.zonaDe(Offset(p.center.dx, p.top + 5)), 1);
      expect(PenaltisLogica.zonaDe(Offset(p.right - 5, p.top + 5)), 2);
      expect(PenaltisLogica.zonaDe(Offset(p.left + 5, p.bottom - 5)), 3);
      expect(PenaltisLogica.zonaDe(Offset(p.center.dx, p.bottom - 5)), 4);
      expect(PenaltisLogica.zonaDe(Offset(p.right - 5, p.bottom - 5)), 5);
    });

    test('un punto fuera de la portería no tiene zona', () {
      const p = PenaltisLogica.porteria;

      expect(PenaltisLogica.zonaDe(Offset(p.left - 1, p.center.dy)), isNull);
      expect(PenaltisLogica.zonaDe(Offset(p.right + 1, p.center.dy)), isNull);
      expect(PenaltisLogica.zonaDe(Offset(p.center.dx, p.top - 1)), isNull);
      expect(PenaltisLogica.zonaDe(Offset(p.center.dx, p.bottom + 1)), isNull);
    });

    test('el centro de cada zona cae en esa zona', () {
      for (var z = 0; z < 6; z++) {
        expect(PenaltisLogica.zonaDe(PenaltisLogica.centroDeZona(z)), z);
      }
    });

    for (var zona = 0; zona < 6; zona++) {
      test('un tiro al centro de la zona $zona va a esa zona', () {
        // El portero nunca acierta (0,99 > cualquier probabilidad): el tiro es gol.
        final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
        final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(zona));

        expect(l.disparar(inicio, fin), isTrue);
        expect(l.zonaTiro, zona);
        expect(l.fase, FasePenalti.disparo);

        _acabarTiro(l);

        expect(l.resultado, ResultadoTiro.gol);
        expect(l.puntos, 1);
        expect(l.zonaPortero, isNot(zona));
      });
    }
  });

  group('un tiro', () {
    test('solo empieza si el dedo toca el balón', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      final lejos = l.balonReposo + const Offset(0, -200);

      expect(l.disparar(lejos, lejos + const Offset(0, -100)), isFalse);
      expect(l.fase, FasePenalti.apuntando);
      expect(l.tiros, 0);
    });

    test('mientras el balón vuela no se puede tirar otra vez', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(1));

      expect(l.disparar(inicio, fin), isTrue);
      expect(l.disparar(inicio, fin), isFalse);
      expect(l.tiros, 1);
    });

    test('un tiro flojo (deslizamiento corto) es fallo y quita una vida', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      final inicio = l.balonReposo;

      expect(l.disparar(inicio, inicio + const Offset(0, -40)), isTrue);

      _acabarTiro(l);

      expect(l.resultado, ResultadoTiro.flojo);
      expect(l.zonaTiro, isNull);
      expect(l.puntos, 0);
      expect(l.vidas, 2);
    });

    test('un tiro hacia abajo o de lado también es flojo', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      final inicio = l.balonReposo;

      l.disparar(inicio, inicio + const Offset(150, 20));

      expect(l.resultado, ResultadoTiro.flojo);
    });

    test('un tiro que no llega a la portería es flojo aunque sea largo', () {
      // Con la pantalla alta el balón está lejos de la portería: 62 de deslizamiento alcanzan 248, y no llegan.
      final l = PenaltisLogica(alto: 800, random: AleatorioFalso());
      final inicio = l.balonReposo;

      l.disparar(inicio, inicio + const Offset(0, -62));

      expect(l.resultado, ResultadoTiro.flojo);
    });

    test('un tiro fuera de la portería (a un lado o por encima) es fallo', () {
      final lado = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      var (inicio, fin) = _gestoHacia(lado, const Offset(10, 200));

      lado.disparar(inicio, fin);

      expect(lado.resultado, ResultadoTiro.fuera);

      final alto = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      (inicio, fin) = _gestoHacia(alto, const Offset(180, 100));

      alto.disparar(inicio, fin);
      _acabarTiro(alto);

      expect(alto.resultado, ResultadoTiro.fuera);
      expect(alto.vidas, 2);
    });

    test('un deslizamiento larguísimo no pasa del alcance máximo (y va fuera)', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      final inicio = l.balonReposo;

      l.disparar(inicio, inicio + const Offset(0, -2000));

      expect(
        (l.destino - l.balonReposo).distance,
        closeTo(PenaltisLogica.longitudMaxima * PenaltisLogica.alcance, 0.001),
      );
      expect(l.resultado, ResultadoTiro.fuera);
    });

    test('el balón recorre el camino del reposo al destino', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(1));

      expect(l.balon, l.balonReposo);

      l.disparar(inicio, fin);
      l.tick(PenaltisLogica.duracionDisparo ~/ 2);

      expect(l.progresoVuelo, closeTo(0.5, 0.001));
      expect(l.balon.dy, lessThan(l.balonReposo.dy));

      l.tick(PenaltisLogica.duracionDisparo ~/ 2);

      expect(l.balon.dx, closeTo(l.destino.dx, 0.001));
      expect(l.balon.dy, closeTo(l.destino.dy, 0.001));
    });

    test('el resultado se aplica al acabar el vuelo y el siguiente tiro, al acabar el resultado', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());
      final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(0));

      l.disparar(inicio, fin);
      l.tick(const Duration(milliseconds: 449));

      expect(l.puntos, 0);
      expect(l.fase, FasePenalti.disparo);

      l.tick(const Duration(milliseconds: 1));

      expect(l.puntos, 1);
      expect(l.fase, FasePenalti.resultado);

      l.tick(PenaltisLogica.duracionResultado);

      expect(l.fase, FasePenalti.apuntando);
    });

    test('cada tiro dura al menos 1,25 s (el ritmo máximo que acepta el backend)', () {
      final duracion = PenaltisLogica.duracionDisparo + PenaltisLogica.duracionResultado;

      expect(duracion.inMilliseconds, greaterThanOrEqualTo(1250));
    });
  });

  group('el portero y la dificultad', () {
    test('si acierta la zona, para el tiro: no hay gol y se pierde una vida', () {
      // 0,0 < 0,2: acierta la zona del tiro.
      final l = PenaltisLogica(
        alto: _alto,
        random: AleatorioFalso(reales: [0.0]),
      );
      final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(4));

      l.disparar(inicio, fin);

      expect(l.zonaPortero, 4);

      _acabarTiro(l);

      expect(l.resultado, ResultadoTiro.parada);
      expect(l.puntos, 0);
      expect(l.vidas, 2);
    });

    test('si no acierta, se tira a otra zona (nunca a la del tiro) y es gol', () {
      for (var zona = 0; zona < 6; zona++) {
        for (var azar = 0; azar < 5; azar++) {
          final l = PenaltisLogica(
            alto: _alto,
            random: AleatorioFalso(reales: [0.99], enteros: [azar]),
          );
          final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(zona));

          l.disparar(inicio, fin);

          expect(l.zonaPortero, isNot(zona), reason: 'zona $zona, azar $azar');
          expect(l.zonaPortero, inInclusiveRange(0, 5));
        }
      }
    });

    test('acierta más cada vez: del 20 % al 60 %', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());

      expect(l.probabilidadParada, closeTo(0.2, 1e-9));

      final probabilidades = <double>[];

      for (var i = 0; i < 20; i++) {
        probabilidades.add(l.probabilidadParada);

        // Los tiros flojos no puntúan pero cuentan como tiro y no acaban la partida si se cambia la vida.
        final inicio = l.balonReposo;
        l.disparar(inicio, inicio + const Offset(0, -10));
        l.tick(PenaltisLogica.duracionDisparo);
        l.tick(PenaltisLogica.duracionResultado);

        if (l.terminado) break;
      }

      // Sube en cada tiro hasta el tope.
      for (var i = 1; i < probabilidades.length; i++) {
        expect(probabilidades[i], greaterThanOrEqualTo(probabilidades[i - 1]));
      }
    });

    test('la probabilidad sube un 2,5 % por tiro y se queda en el 60 %', () {
      final l = PenaltisLogica(alto: 640, random: AleatorioFalso(reales: [0.99]));

      // Con un portero que nunca para, se hacen goles seguidos sin perder vidas.
      for (var i = 0; i < 8; i++) {
        final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(1));
        l.disparar(inicio, fin);
        _acabarTiro(l);
      }

      expect(l.tiros, 8);
      expect(l.probabilidadParada, closeTo(0.4, 1e-9));

      for (var i = 0; i < 12; i++) {
        final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(1));
        l.disparar(inicio, fin);
        _acabarTiro(l);
      }

      expect(l.probabilidadParada, closeTo(0.6, 1e-9));
      expect(l.puntos, 20);
    });

    test('el primer tiro lo para con un azar menor de 0,2 y no con uno mayor', () {
      for (final (azar, para) in [(0.19, true), (0.21, false)]) {
        final l = PenaltisLogica(
          alto: _alto,
          random: AleatorioFalso(reales: [azar]),
        );
        final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(2));

        l.disparar(inicio, fin);
        _acabarTiro(l);

        expect(l.resultado, para ? ResultadoTiro.parada : ResultadoTiro.gol);
      }
    });

    test('el segundo tiro usa la probabilidad subida (22,5 %)', () {
      final l = PenaltisLogica(
        alto: _alto,
        random: AleatorioFalso(reales: [0.99, 0.22]),
      );

      var (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(2));
      l.disparar(inicio, fin);
      _acabarTiro(l);

      expect(l.resultado, ResultadoTiro.gol);

      (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(2));
      l.disparar(inicio, fin);
      _acabarTiro(l);

      // 0,22 < 0,225: con la probabilidad subida lo para (con la inicial del 20 % habría sido gol).
      expect(l.resultado, ResultadoTiro.parada);
    });
  });

  group('las vidas', () {
    test('son 3: tres fallos o paradas acaban la partida, después de enseñar el último', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());

      expect(l.vidas, 3);

      for (var i = 0; i < 3; i++) {
        expect(l.terminado, isFalse);

        final inicio = l.balonReposo;
        l.disparar(inicio, inicio + const Offset(0, -10));
        l.tick(PenaltisLogica.duracionDisparo);

        expect(l.vidas, 2 - i);

        if (i < 2) {
          l.tick(PenaltisLogica.duracionResultado);
        }
      }

      // Con la última vida perdida, el resultado se sigue enseñando y entonces acaba.
      expect(l.terminado, isFalse);

      l.tick(PenaltisLogica.duracionResultado);

      expect(l.terminado, isTrue);
      expect(l.puntos, 0);
    });

    test('un gol no quita vidas y los goles suman puntos', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());

      for (var i = 0; i < 3; i++) {
        final (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(i));
        l.disparar(inicio, fin);
        _acabarTiro(l);
      }

      expect(l.puntos, 3);
      expect(l.vidas, 3);
      expect(l.terminado, isFalse);
    });

    test('acabada la partida ya no se puede tirar ni avanzar', () {
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());

      for (var i = 0; i < 3; i++) {
        final inicio = l.balonReposo;
        l.disparar(inicio, inicio + const Offset(0, -10));
        _acabarTiro(l);
      }

      expect(l.terminado, isTrue);
      expect(l.disparar(l.balonReposo, l.balonReposo + const Offset(0, -100)), isFalse);

      final tiempo = l.tiempoJugado;
      l.tick(const Duration(seconds: 5));

      expect(l.tiempoJugado, tiempo);
    });

    test('avisa de cada gol y de cada fallo', () {
      final eventos = <EventoJuego>[];
      final l = PenaltisLogica(alto: _alto, random: AleatorioFalso())
        ..alEvento = eventos.add;

      var (inicio, fin) = _gestoHacia(l, PenaltisLogica.centroDeZona(0));
      l.disparar(inicio, fin);
      _acabarTiro(l);

      inicio = l.balonReposo;
      l.disparar(inicio, inicio + const Offset(0, -10));
      _acabarTiro(l);

      expect(eventos, [EventoJuego.punto, EventoJuego.fallo]);
    });
  });

  test('el tiempo jugado suma lo que se avanza (es la duración que se envía)', () {
    final l = PenaltisLogica(alto: _alto, random: AleatorioFalso());

    l.tick(const Duration(seconds: 2));
    l.tick(const Duration(milliseconds: 500));

    expect(l.tiempoJugado, const Duration(milliseconds: 2500));
  });
}
