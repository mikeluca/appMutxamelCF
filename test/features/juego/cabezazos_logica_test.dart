import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:app_mutxamel_cf/features/juego/logica/cabezazos_logica.dart';
import 'package:app_mutxamel_cf/features/juego/logica/formas_choque.dart';
import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:flutter_test/flutter_test.dart';

const double _alto = 640;
const Duration _fotograma = Duration(milliseconds: 16);
const Duration _instante = Duration(microseconds: 1);

CabezazosLogica _logica({math.Random? random}) =>
    CabezazosLogica(alto: _alto, random: random);

/// Una partida ya empezada y con Mutxigol quieto en mitad del campo.
CabezazosLogica _enMarcha() {
  final l = _logica();

  l.tocar();
  l.colocarY(_alto * 0.4);

  return l;
}

/// La menor distancia de borde a borde entre las formas de Mutxigol y las de los defensas de la barrera (negativa si se
/// solapan).
double _distancia(CabezazosLogica l, BarreraCabezazos b) {
  var minima = double.infinity;

  for (final c in l.circulosEnMundo) {
    for (final f in b.formas) {
      minima = math.min(minima, f.distanciaA(c));
    }
  }

  return minima;
}

/// Lo que haría un choque "de cajas": algún círculo con su caja sobre el rectángulo entero de alguna columna.
bool _chocariaConCajas(CabezazosLogica l, BarreraCabezazos b) {
  for (final c in l.circulosEnMundo) {
    final caja = Rect.fromCircle(center: c.centro, radius: c.r);

    if (b.recuadros.any((r) => r.overlaps(caja))) return true;
  }

  return false;
}

void main() {
  group('el tamaño de Mutxigol', () {
    test('la imagen mide 108 y el personaje visible unas 73 unidades de alto', () {
      expect(CabezazosLogica.tamanoImagen, 108);

      final visible = CabezazosLogica.tamanoImagen * CabezazosLogica.alturaVisibleEnImagen;

      expect(visible, closeTo(73.4, 0.5));
    });

    test('tiene 3 círculos de choque dentro de la imagen, más pequeños que el personaje entero', () {
      expect(CabezazosLogica.circulosCuerpo, hasLength(3));

      final l = _enMarcha();
      final circulos = l.circulosEnMundo;

      for (final (dx, dy, r) in CabezazosLogica.circulosCuerpo) {
        expect(dx.abs() + r, lessThan(0.5));
        expect(dy.abs() + r, lessThan(0.5));
      }

      final arriba = circulos.map((c) => c.cy - c.r).reduce(math.min);
      final abajo = circulos.map((c) => c.cy + c.r).reduce(math.max);

      expect(abajo - arriba, closeTo(CabezazosLogica.altoDeLaForma, 0.5));
      // Sin los cuernos ni los pies: menos que el personaje entero.
      expect(
        abajo - arriba,
        lessThan(CabezazosLogica.tamanoImagen * CabezazosLogica.alturaVisibleEnImagen),
      );
    });

    test('el pivote es el centro del tronco y el centro de la imagen cae a su sitio respecto a él', () {
      final (dx, dy, _) = CabezazosLogica.circulosCuerpo[1];

      expect(CabezazosLogica.pivoteDx, dx);
      expect(CabezazosLogica.pivoteDy, dy);

      final l = _enMarcha();

      l.colocarY(300);

      final tronco = l.circulosEnMundo[1];

      expect(tronco.cx, closeTo(CabezazosLogica.xMutxigol, 0.001));
      expect(tronco.cy, closeTo(300, 0.001));
    });

    test('el hueco mínimo sigue siendo jugable con el tamaño nuevo: ≥ 2,6 diámetros y holgado para la forma', () {
      expect(CabezazosLogica.huecoMinimoJugable, closeTo(2.6 * CabezazosLogica.diametro, 0.001));
      expect(CabezazosLogica.huecoMinimo, greaterThanOrEqualTo(CabezazosLogica.huecoMinimoJugable));
      // Y la forma entera cabe por él con margen.
      expect(CabezazosLogica.huecoMinimo, greaterThan(CabezazosLogica.altoDeLaForma * 1.5));
      // Proporcional al mínimo de antes (140 con la imagen de 126).
      expect(CabezazosLogica.huecoMinimo, closeTo(140 * 108 / 126, 1));
      expect(CabezazosLogica.huecoInicial, closeTo(3.5 * CabezazosLogica.diametro, 0.001));
      expect(CabezazosLogica.huecoInicial, greaterThan(CabezazosLogica.huecoMinimo));
    });
  });

  group('las formas de choque giran con la inclinación', () {
    test('sin inclinación, las formas están como en la imagen', () {
      final l = _enMarcha();

      l.colocarY(300);

      expect(l.inclinacionGrados, 0);

      final c1 = l.circulosEnMundo.first;
      final (dx, dy, r) = CabezazosLogica.circulosCuerpo.first;

      expect(
        c1.cx,
        closeTo(CabezazosLogica.xMutxigol + (dx - CabezazosLogica.pivoteDx) * 108, 0.001),
      );
      expect(c1.cy, closeTo(300 + (dy - CabezazosLogica.pivoteDy) * 108, 0.001));
      expect(c1.r, closeTo(r * 108, 0.001));
    });

    test('con la inclinación los círculos giran alrededor del pivote (como la imagen): misma distancia, otro ángulo', () {
      final l = _enMarcha();

      l.colocarY(300);

      final quietos = l.circulosEnMundo;

      for (final velocidad in [-CabezazosLogica.impulso, CabezazosLogica.velocidadMaximaDeCaida]) {
        l.colocarY(300, velocidad: velocidad);

        final giro = l.angulo;
        final girados = l.circulosEnMundo;

        expect(giro.abs(), greaterThan(0.3));

        for (var i = 0; i < 3; i++) {
          final antes = quietos[i];
          final ahora = girados[i];
          final v0 = Offset2(antes.cx - CabezazosLogica.xMutxigol, antes.cy - 300);
          final v1 = Offset2(ahora.cx - CabezazosLogica.xMutxigol, ahora.cy - 300);

          expect(v1.largo, closeTo(v0.largo, 0.001), reason: 'círculo $i');
          expect(ahora.r, antes.r);

          if (i != 1) {
            // El tronco es el pivote: no se mueve; los demás giran el ángulo de la imagen.
            var dif = v1.angulo - v0.angulo;

            while (dif > math.pi) {
              dif -= 2 * math.pi;
            }

            while (dif < -math.pi) {
              dif += 2 * math.pi;
            }

            expect(dif, closeTo(giro, 0.001), reason: 'círculo $i');
          } else {
            expect(v1.largo, closeTo(0, 0.001));
          }
        }
      }
    });

    test('el ángulo es el de la imagen: hacia arriba (−20°) y hacia abajo (+60°)', () {
      final l = _enMarcha();

      l.colocarY(300, velocidad: -CabezazosLogica.impulso);

      expect(l.angulo, closeTo(-20 * math.pi / 180, 1e-9));

      l.colocarY(300, velocidad: CabezazosLogica.velocidadMaximaDeCaida);

      expect(l.angulo, closeTo(60 * math.pi / 180, 1e-9));
    });
  });

  group('solo choca cuando de verdad se tocan', () {
    /// Una barrera con el hueco bien arriba, para tener una columna de defensas debajo, y a Mutxigol encima de ella.
    (CabezazosLogica, BarreraCabezazos) montar() {
      final l = _enMarcha();
      final b = l.colocarBarrera(0, 100, 130);

      // La cabeza de Mutxigol justo sobre el primer defensa de la columna de abajo.
      l.colocarY(100);

      final cabeza = l.circulosEnMundo.first;

      b.x = cabeza.cx - b.recuadros.first.width / 2;

      return (l, b);
    }

    /// Baja a Mutxigol hasta que la menor distancia a las defensas sea [distancia].
    double alturaConDistancia(CabezazosLogica l, BarreraCabezazos b, double distancia) {
      var alto = 100.0;
      var bajo = 500.0;

      // La distancia crece al subir: se busca por bisección el punto en que vale [distancia].
      for (var i = 0; i < 60; i++) {
        final medio = (alto + bajo) / 2;

        l.colocarY(medio);

        if (_distancia(l, b) > distancia) {
          alto = medio;
        } else {
          bajo = medio;
        }
      }

      return (alto + bajo) / 2;
    }

    test('a 3 unidades de un defensa, sin tocarse, no choca', () {
      final (l, b) = montar();

      // Nos quedamos en la columna de arriba: el hueco está en y 35–165, no estorba.
      final y = alturaConDistancia(l, b, 3);

      l.colocarY(y);

      expect(_distancia(l, b), closeTo(3, 0.05));

      l.tick(_instante);

      expect(l.terminado, isFalse);
    });

    test('solapando su forma con la del defensa, choca', () {
      final (l, b) = montar();
      final y = alturaConDistancia(l, b, -5);

      l.colocarY(y);

      expect(_distancia(l, b), closeTo(-5, 0.05));

      l.tick(_instante);

      expect(l.terminado, isTrue);
    });

    test('un roce de 2 unidades (menos que la tolerancia) no cuenta', () {
      final (l, b) = montar();
      final y = alturaConDistancia(l, b, -2);

      l.colocarY(y);

      expect(CabezazosLogica.tolerancia, inInclusiveRange(2, 3));

      l.tick(_instante);

      expect(l.terminado, isFalse);
    });

    test('en la esquina del rectángulo antiguo (caja de la columna) pero fuera de la silueta, no choca', () {
      final l = _enMarcha();
      final b = l.colocarBarrera(0, 100, 130);
      final primera = b.recuadros.firstWhere((r) => r.top >= b.sueloDelHueco - 0.001);

      // El círculo de las piernas (el más bajo) en la esquina de arriba a la izquierda de la caja del primer defensa:
      // dentro de la caja, pero a la izquierda del hombro y de la cabeza.
      l.colocarY(300);

      final piernas = l.circulosEnMundo[2];

      b.x = piernas.cx - 3;
      l.colocarY(300 + (primera.top - 0.7 - piernas.cy));

      final p = l.circulosEnMundo[2];

      expect(_chocariaConCajas(l, b), isTrue, reason: 'con cajas, la esquina contaría');
      expect(
        Rect.fromCircle(center: p.centro, radius: p.r).overlaps(b.recuadros.firstWhere((r) => r.top >= b.sueloDelHueco - 0.001)),
        isTrue,
      );
      expect(_distancia(l, b), greaterThan(CabezazosLogica.tolerancia));

      l.tick(_instante);

      expect(l.terminado, isFalse, reason: 'con la forma real, no se tocan');
    });

    test('la distancia a un rectángulo redondeado y a un círculo es exacta', () {
      const rr = RectRedondeadoChoque(Rect.fromLTRB(0, 0, 100, 50), 10);

      // A la derecha de un lado recto: 30 de borde (centro a 40 del lado, menos el radio 10).
      expect(rr.distanciaA(const CirculoChoque(140, 25, 10)), closeTo(30, 1e-9));
      // En diagonal a la esquina redondeada: el centro (120, 60) está a (30, 20) del rectángulo interior (10, 10)–(90, 40).
      expect(
        rr.distanciaA(const CirculoChoque(120, 60, 5)),
        closeTo(math.sqrt(30 * 30 + 20 * 20) - 10 - 5, 1e-9),
      );
      // Dentro: negativa.
      expect(rr.distanciaA(const CirculoChoque(50, 25, 5)), lessThan(0));
      // Dos círculos.
      expect(
        const CirculoChoque(0, 0, 3).distanciaA(const CirculoChoque(10, 0, 4)),
        closeTo(3, 1e-9),
      );
      expect(
        const CirculoChoque(0, 0, 3).distanciaA(const CirculoChoque(5, 0, 4)),
        closeTo(-2, 1e-9),
      );
    });

    test('la forma del defensa es un círculo en la cabeza y un rectángulo redondeado con el ancho de la silueta', () {
      final forma = FormaDefensa.de(const Rect.fromLTWH(100, 200, 62, 68));

      expect(forma.cabeza.cx, closeTo(131, 1e-9));
      expect(forma.cabeza.cy, closeTo(200 + 68 * 0.16, 1e-9));
      expect(forma.cabeza.r, closeTo(62 * 0.15, 1e-9));
      // El cuerpo mide 0,6 del ancho de la columna, no todo.
      expect(forma.cuerpo.rect.width, closeTo(62 * 0.6, 1e-9));
      expect(forma.cuerpo.rect.top, closeTo(200 + 68 * 0.26, 1e-9));
      expect(forma.cuerpo.rect.bottom, closeTo(200 + 68 * 0.94, 1e-9));
    });

    test('las defensas de una columna llenan del techo al hueco y del hueco al césped, sin cortes', () {
      final l = _enMarcha();
      final b = l.colocarBarrera(200, 250, 140);
      final r = b.recuadros;

      final arriba = r.where((c) => c.bottom <= b.techoDelHueco + 0.001).toList();
      final abajo = r.where((c) => c.top >= b.sueloDelHueco - 0.001).toList();

      expect(arriba.length + abajo.length, r.length);
      expect(arriba.first.top, 0);
      expect(arriba.last.bottom, closeTo(b.techoDelHueco, 0.001));
      expect(abajo.first.top, closeTo(b.sueloDelHueco, 0.001));
      expect(abajo.last.bottom, closeTo(l.suelo, 0.001));

      for (var i = 1; i < arriba.length; i++) {
        expect(arriba[i].top, closeTo(arriba[i - 1].bottom, 0.001));
      }

      for (var i = 1; i < abajo.length; i++) {
        expect(abajo[i].top, closeTo(abajo[i - 1].bottom, 0.001));
      }

      for (final c in r) {
        expect(c.height, inInclusiveRange(CabezazosLogica.altoDefensa * 0.6, CabezazosLogica.altoDefensa * 1.4));
        expect(c.width, CabezazosLogica.anchoBarrera);
      }
    });
  });

  group('el techo y el césped, también con las formas', () {
    test('tocar el techo acaba la partida', () {
      final l = _enMarcha();
      // Lo más alto del cuerpo respecto al pivote.
      final arriba = l.circulosEnMundo.map((c) => c.cy - c.r).reduce(math.min) - l.y;

      l.colocarY(-arriba - CabezazosLogica.tolerancia - 1);
      l.tick(_instante);

      expect(l.terminado, isTrue);
    });

    test('un roce con el techo menor que la tolerancia no cuenta', () {
      final l = _enMarcha();
      final arriba = l.circulosEnMundo.map((c) => c.cy - c.r).reduce(math.min) - l.y;

      l.colocarY(-arriba - 1);
      l.tick(_instante);

      expect(l.terminado, isFalse);
    });

    test('tocar el césped acaba la partida', () {
      final l = _enMarcha();
      final abajo = l.circulosEnMundo.map((c) => c.cy + c.r).reduce(math.max) - l.y;

      l.colocarY(l.suelo - abajo + CabezazosLogica.tolerancia + 1);
      l.tick(_instante);

      expect(l.terminado, isTrue);
    });
  });

  group('la espera del primer toque (sin cuenta atrás)', () {
    test('hasta el primer toque Mutxigol flota: no cae, no hay barreras ni se acaba ni corre el tiempo', () {
      final l = _logica();
      final alturas = <double>[];

      for (var i = 0; i < 400; i++) {
        l.tick(_fotograma);
        alturas.add(l.y);
      }

      expect(l.esperando, isTrue);
      expect(l.terminado, isFalse);
      expect(l.barreras, isEmpty);
      expect(l.tiempoJugado, Duration.zero);

      final centro = _alto * CabezazosLogica.alturaDeEspera;

      expect(alturas.reduce(math.min), lessThan(centro - 5));
      expect(alturas.reduce(math.max), greaterThan(centro + 5));
    });

    test('el primer toque empieza la partida (y el tiempo) con un impulso hacia arriba', () {
      final l = _logica();

      l.tick(const Duration(seconds: 3));
      l.tocar();

      expect(l.esperando, isFalse);
      expect(l.velocidadVertical, -CabezazosLogica.impulso);

      l.tick(const Duration(milliseconds: 500));

      expect(l.tiempoJugado, const Duration(milliseconds: 500));
      expect(l.barreras, isNotEmpty);
    });

    test('la primera barrera llega a Mutxigol a los ~2 s del primer toque', () {
      final l = _logica();

      l.tocar();

      var t = 0.0;

      while (l.barreras.isEmpty ||
          l.barreras.first.x > CabezazosLogica.xMutxigol + CabezazosLogica.extensionDerecha) {
        l.colocarY(_alto * 0.4);
        l.tick(_fotograma);
        t += 0.016;

        expect(t, lessThan(3));
      }

      expect(t, closeTo(CabezazosLogica.segundosHastaLaPrimera, 0.1));
    });
  });

  group('el impulso y la gravedad', () {
    test('la física: gravedad ~1100, impulso ~380 y caída máxima ~550', () {
      expect(CabezazosLogica.gravedad, 1100);
      expect(CabezazosLogica.impulso, 380);
      expect(CabezazosLogica.velocidadMaximaDeCaida, 550);
    });

    test('un toque da un impulso hacia arriba y la gravedad lo va bajando', () {
      final l = _enMarcha();
      final y0 = l.y;

      l.tocar();
      l.tick(_fotograma);

      expect(l.y, lessThan(y0));

      var bajaba = false;

      for (var i = 0; i < 60 && !l.terminado; i++) {
        final antes = l.y;

        l.tick(_fotograma);

        if (l.y > antes) bajaba = true;
      }

      expect(bajaba, isTrue);
    });

    test('la caída no pasa de 550 y desde el centro tras un salto tarda más de 0,9 s', () {
      final l = _enMarcha();
      var maxima = 0.0;

      for (var i = 0; i < 200 && !l.terminado; i++) {
        l.tick(_fotograma);
        maxima = math.max(maxima, l.velocidadVertical);
      }

      expect(maxima, CabezazosLogica.velocidadMaximaDeCaida);

      for (final alto in [640.0, 915.0]) {
        final m = CabezazosLogica(alto: alto);

        m.tocar();
        m.colocarY(m.suelo / 2, velocidad: -CabezazosLogica.impulso);

        var t = 0.0;

        while (!m.terminado && t < 5) {
          m.tick(_fotograma);
          t += 0.016;
        }

        expect(m.terminado, isTrue);
        expect(t, greaterThan(0.9), reason: 'alto $alto');
      }
    });

    test('la inclinación va con la velocidad: hasta 20° hacia arriba y 60° hacia abajo', () {
      final l = _enMarcha();

      l.colocarY(300, velocidad: -CabezazosLogica.impulso);
      expect(l.inclinacionGrados, closeTo(20, 0.001));

      l.colocarY(300, velocidad: 0);
      expect(l.inclinacionGrados, 0);

      l.colocarY(300, velocidad: CabezazosLogica.velocidadMaximaDeCaida / 2);
      expect(l.inclinacionGrados, closeTo(-30, 0.001));

      l.colocarY(300, velocidad: 5000);
      expect(l.inclinacionGrados, closeTo(-60, 0.001));
    });
  });

  group('el final', () {
    test('sin tocar nada Mutxigol cae al suelo y se acaba', () {
      final l = _enMarcha();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;

      for (var i = 0; i < 300 && !l.terminado; i++) {
        l.tick(_fotograma);
      }

      expect(l.terminado, isTrue);
      expect(eventos.last, EventoJuego.fallo);
    });

    test('chocar con las defensas (la parte de arriba o la de abajo) acaba la partida', () {
      for (final y in [60.0, 420.0]) {
        final l = _enMarcha();

        // Hueco en el centro (240, de 190 a 290) con Mutxigol de frente a la columna.
        l.colocarBarrera(CabezazosLogica.xMutxigol - 31, 240, 100);
        l.colocarY(y);
        l.tick(_instante);

        expect(l.terminado, isTrue, reason: 'y=$y');
      }
    });

    test('pasar por el hueco no choca', () {
      final l = _enMarcha();

      l.colocarBarrera(CabezazosLogica.xMutxigol - 20, 240, 130);
      l.colocarY(240);
      l.tick(_instante);

      expect(l.terminado, isFalse);
    });

    test('una vez acabada, tocar ya no hace nada y el tiempo no corre', () {
      final l = _enMarcha();

      l.colocarY(2);
      l.tick(_fotograma);

      expect(l.terminado, isTrue);

      final tiempo = l.tiempoJugado;
      final y = l.y;

      l.tocar();
      l.tick(_fotograma);

      expect(l.y, y);
      expect(l.tiempoJugado, tiempo);
      expect(l.vidas, isNull);
    });
  });

  group('las barreras', () {
    test('entran por la derecha a ritmo constante', () {
      final l = _enMarcha();

      l.tick(_fotograma);

      final barrera = l.barreras.first;
      final x0 = barrera.x;

      expect(x0, greaterThan(LogicaJuego.ancho));

      l.colocarY(_alto * 0.4);
      l.tick(const Duration(milliseconds: 40));

      expect(x0 - barrera.x, closeTo(CabezazosLogica.velocidadBarreras * 0.04, 0.01));
    });

    test('+1 punto al pasar una barrera (y solo una vez)', () {
      final l = _enMarcha();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      l.colocarBarrera(
        CabezazosLogica.xMutxigol - CabezazosLogica.anchoBarrera - CabezazosLogica.extensionIzquierda + 2,
        250,
        140,
      );

      for (var i = 0; i < 20; i++) {
        l.colocarY(250);
        l.tick(_fotograma);
      }

      expect(l.terminado, isFalse);
      expect(l.puntos, 1);
      expect(eventos.where((e) => e == EventoJuego.punto), hasLength(1));
    });

    test('el hueco se estrecha hasta un mínimo jugable y su altura cambia siempre dentro de límites', () {
      final l = _logica(random: math.Random(4));
      final vistas = <BarreraCabezazos>[];

      l.tocar();

      for (var i = 0; i < 6000 && !l.terminado; i++) {
        final delante = l.barreras.where(
          (b) => b.x + CabezazosLogica.anchoBarrera > CabezazosLogica.xMutxigol - CabezazosLogica.extensionIzquierda,
        );

        l.colocarY(delante.isEmpty ? _alto * 0.4 : delante.first.centroHueco);
        l.tick(_fotograma);

        for (final b in l.barreras) {
          if (!vistas.contains(b)) vistas.add(b);
        }
      }

      expect(l.terminado, isFalse, reason: 'pasando siempre por el centro del hueco nunca choca');
      expect(vistas.length, greaterThan(30));
      expect(vistas.first.hueco, CabezazosLogica.huecoInicial);

      for (var i = 0; i < vistas.length; i++) {
        final b = vistas[i];

        expect(b.hueco, lessThanOrEqualTo(CabezazosLogica.huecoInicial));
        expect(b.hueco, greaterThanOrEqualTo(CabezazosLogica.huecoMinimo));
        expect(b.hueco, greaterThanOrEqualTo(2.6 * CabezazosLogica.diametro));
        expect(b.techoDelHueco, greaterThanOrEqualTo(CabezazosLogica.margenHueco - 0.001));
        expect(b.sueloDelHueco, lessThanOrEqualTo(l.suelo - CabezazosLogica.margenHueco + 0.001));

        if (i > 0) {
          expect(b.hueco, lessThanOrEqualTo(vistas[i - 1].hueco));
          expect(
            (b.centroHueco - vistas[i - 1].centroHueco).abs(),
            lessThanOrEqualTo(CabezazosLogica.cambioMaximoDeAltura + 5),
          );
        }
      }

      expect(vistas.last.hueco, CabezazosLogica.huecoMinimo);
      expect(l.puntos / l.segundos, lessThan(1));
    });
  });
}

/// Un vector 2D mínimo para los ángulos.
class Offset2 {
  const Offset2(this.x, this.y);

  final double x;
  final double y;

  double get largo => math.sqrt(x * x + y * y);
  double get angulo => math.atan2(y, x);
}
