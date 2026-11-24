import 'dart:math' as math;

import 'package:app_mutxamel_cf/features/juego/logica/cabezazos_logica.dart';
import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:flutter_test/flutter_test.dart';

const double _alto = 640;
const Duration _fotograma = Duration(milliseconds: 16);

CabezazosLogica _logica({math.Random? random}) =>
    CabezazosLogica(alto: _alto, random: random);

/// Una partida ya empezada y con Mutxigol quieto en mitad del campo.
CabezazosLogica _enMarcha() {
  final l = _logica();

  l.tocar();
  l.colocarY(_alto * 0.4);

  return l;
}

void main() {
  group('la espera del primer toque', () {
    test('hasta el primer toque Mutxigol flota arriba y abajo: no cae, no hay barreras ni se acaba', () {
      final l = _logica();
      final alturas = <double>[];

      expect(l.esperando, isTrue);

      for (var i = 0; i < 400; i++) {
        l.tick(_fotograma);
        alturas.add(l.y);
      }

      expect(l.esperando, isTrue);
      expect(l.terminado, isFalse);
      expect(l.barreras, isEmpty);
      expect(l.puntos, 0);

      final centro = _alto * 0.4;

      // Se mueve suave alrededor de su sitio.
      expect(alturas.reduce(math.min), lessThan(centro - 5));
      expect(alturas.reduce(math.max), greaterThan(centro + 5));
      expect(
        alturas.every((y) => (y - centro).abs() <= CabezazosLogica.amplitudFlotar + 0.001),
        isTrue,
      );
    });

    test('el primer toque empieza la partida con un impulso hacia arriba', () {
      final l = _logica();

      l.tocar();

      expect(l.esperando, isFalse);
      expect(l.velocidadVertical, -CabezazosLogica.impulso);

      l.tick(_fotograma);

      expect(l.barreras, isNotEmpty, reason: 'la primera barrera entra enseguida');
    });
  });

  group('el impulso y la gravedad', () {
    test('un toque da un impulso hacia arriba y la gravedad lo va bajando', () {
      final l = _enMarcha();
      final y0 = l.y;

      l.tocar();
      l.tick(_fotograma);

      expect(l.y, lessThan(y0), reason: 'sube');

      // Sigue subiendo un rato y luego cae.
      var maxima = l.y;
      var bajaba = false;

      for (var i = 0; i < 60 && !l.terminado; i++) {
        final antes = l.y;

        l.tick(_fotograma);

        if (l.y > antes) bajaba = true;
        if (l.y < maxima) maxima = l.y;
      }

      expect(bajaba, isTrue);
      expect(l.velocidadVertical, greaterThan(-CabezazosLogica.impulso));
    });

    test('cada toque reinicia el impulso, sea cual sea la velocidad', () {
      final l = _enMarcha();

      l.colocarY(300, velocidad: 500);
      l.tocar();

      expect(l.velocidadVertical, -CabezazosLogica.impulso);
    });

    test('la gravedad acelera la caída a razón de 1500 por segundo', () {
      final l = _enMarcha();

      l.colocarY(100);
      l.tick(const Duration(milliseconds: 100));

      expect(l.velocidadVertical, closeTo(CabezazosLogica.gravedad * 0.1, 0.5));
    });

    test('la inclinación va con la velocidad: hasta 20° hacia arriba y 60° hacia abajo', () {
      final l = _enMarcha();

      l.colocarY(300, velocidad: -CabezazosLogica.impulso);

      expect(l.inclinacionGrados, closeTo(20, 0.001));

      l.colocarY(300, velocidad: -CabezazosLogica.impulso * 3);

      expect(l.inclinacionGrados, closeTo(20, 0.001));

      l.colocarY(300, velocidad: 0);

      expect(l.inclinacionGrados, 0);

      l.colocarY(300, velocidad: 300);

      expect(l.inclinacionGrados, closeTo(-30, 0.001));

      l.colocarY(300, velocidad: 600);

      expect(l.inclinacionGrados, closeTo(-60, 0.001));

      l.colocarY(300, velocidad: 2000);

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

    test('tocar el techo acaba la partida', () {
      final l = _enMarcha();

      l.colocarY(CabezazosLogica.radio - 1);
      l.tick(_fotograma);

      expect(l.terminado, isTrue);
    });

    test('tocar el suelo acaba la partida', () {
      final l = _enMarcha();

      l.colocarY(l.suelo - CabezazosLogica.radio + 1);
      l.tick(_fotograma);

      expect(l.terminado, isTrue);
    });

    test('chocar con una barrera (la parte de arriba o la de abajo) acaba la partida', () {
      for (final y in [150.0, 330.0]) {
        final l = _enMarcha();

        // El hueco está en el centro (240): a 150 choca con la columna de arriba y a 330 con la de abajo.
        l.colocarBarrera(CabezazosLogica.xMutxigol - 20, 240, 100);
        l.colocarY(y);
        l.tick(const Duration(milliseconds: 1));

        expect(l.terminado, isTrue, reason: 'y=$y');
      }
    });

    test('pasar por el hueco no choca', () {
      final l = _enMarcha();

      l.colocarBarrera(CabezazosLogica.xMutxigol - 20, 240, 100);
      l.colocarY(240);
      l.tick(const Duration(milliseconds: 1));

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
    });

    test('no tiene vidas que enseñar (una sola, clásico)', () {
      expect(_logica().vidas, isNull);
    });
  });

  group('las barreras', () {
    test('entran por la derecha a ritmo constante', () {
      final l = _enMarcha();

      l.tick(_fotograma);

      final barrera = l.barreras.first;
      final x0 = barrera.x;

      expect(x0, greaterThan(LogicaJuego.ancho - 10));

      l.colocarY(_alto * 0.4);
      l.tick(const Duration(milliseconds: 40));

      expect(x0 - barrera.x, closeTo(CabezazosLogica.velocidadBarreras * 0.04, 0.01));

      l.colocarY(_alto * 0.4);
      l.tick(const Duration(milliseconds: 40));

      expect(x0 - barrera.x, closeTo(CabezazosLogica.velocidadBarreras * 0.08, 0.01));
    });

    test('+1 punto al pasar una barrera (y solo una vez)', () {
      final l = _enMarcha();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      // Una barrera a punto de quedar detrás de Mutxigol, con el hueco justo donde está.
      l.colocarBarrera(CabezazosLogica.xMutxigol - CabezazosLogica.anchoBarrera - 10, 250, 140);

      for (var i = 0; i < 20; i++) {
        l.colocarY(250);
        l.tick(_fotograma);
      }

      expect(l.terminado, isFalse);
      expect(l.puntos, 1);
      expect(eventos.where((e) => e == EventoJuego.punto), hasLength(1));
    });

    test('el hueco se va estrechando hasta un mínimo y su altura cambia siempre dentro de límites jugables', () {
      final l = _logica(random: math.Random(4));
      final vistas = <BarreraCabezazos>[];

      l.tocar();

      // Mutxigol va siempre por el hueco de la barrera que tiene delante: nunca choca.
      for (var i = 0; i < 6000 && !l.terminado; i++) {
        final delante = l.barreras.where(
          (b) => b.x + CabezazosLogica.anchoBarrera > CabezazosLogica.xMutxigol - CabezazosLogica.radio,
        );

        l.colocarY(delante.isEmpty ? _alto * 0.4 : delante.first.centroHueco);
        l.tick(_fotograma);

        for (final b in l.barreras) {
          if (!vistas.contains(b)) vistas.add(b);
        }
      }

      expect(l.terminado, isFalse);
      expect(vistas.length, greaterThan(30));
      expect(vistas.first.hueco, CabezazosLogica.huecoInicial);

      for (var i = 0; i < vistas.length; i++) {
        final b = vistas[i];

        expect(b.hueco, lessThanOrEqualTo(CabezazosLogica.huecoInicial));
        expect(b.hueco, greaterThanOrEqualTo(CabezazosLogica.huecoMinimo));
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

      // Llega al mínimo y se queda ahí.
      expect(vistas.last.hueco, CabezazosLogica.huecoMinimo);

      // La altura del hueco sí cambia (no es siempre la misma).
      expect(vistas.map((b) => b.centroHueco.round()).toSet().length, greaterThan(10));

      // Ritmo de puntos: como mucho 1 por segundo (lo que acepta el backend).
      expect(l.puntos / l.segundos, lessThan(1));
    });
  });
}
