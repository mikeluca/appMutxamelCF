import 'dart:math' as math;

import 'package:app_mutxamel_cf/features/juego/logica/atrapa_logica.dart';
import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/juego_helpers.dart';

const double _alto = 640;
const Duration _fotograma = Duration(milliseconds: 16);

AtrapaLogica _manual({math.Random? random}) =>
    AtrapaLogica(alto: _alto, soltarSolo: false, random: random);

/// Pasa [segundos] de partida sin que caiga nada por su cuenta.
void _pasar(AtrapaLogica l, double segundos) {
  for (var t = 0.0; t < segundos; t += 0.05) {
    l.tick(const Duration(milliseconds: 50));
  }
}

/// Avanza hasta que no queda nada cayendo (o pasan [maximo] segundos).
void _hastaQueCaiga(AtrapaLogica l, {double maximo = 8, bool seguir = false}) {
  final fotogramas = (maximo * 1000 / _fotograma.inMilliseconds).round();

  for (var i = 0; i < fotogramas && l.objetos.isNotEmpty && !l.terminado; i++) {
    l.tick(_fotograma);

    // Mutxigol va siguiendo al primer objeto (el que cae en curva o rebota).
    if (seguir && l.objetos.isNotEmpty) l.moverA(l.objetos.first.x);
  }
}

/// Suelta un objeto justo encima de Mutxigol y espera a que llegue.
void _atrapar(AtrapaLogica l, TipoCaida tipo) {
  l.soltar(tipo, l.x);
  _hastaQueCaiga(l);
}

/// Suelta un objeto lejos de Mutxigol (se va al suelo) y espera.
void _dejarCaer(AtrapaLogica l, TipoCaida tipo) {
  l.moverA(AtrapaLogica.margen);
  l.soltar(tipo, LogicaJuego.ancho - AtrapaLogica.margen);
  _hastaQueCaiga(l);
}

void main() {
  group('moverse', () {
    test('Mutxigol sigue al dedo y no se sale de los márgenes', () {
      final l = _manual();

      expect(l.x, LogicaJuego.ancho / 2);

      l.moverA(100);

      expect(l.x, 100);

      l.moverA(-500);

      expect(l.x, AtrapaLogica.margen);

      l.moverA(900);

      expect(l.x, LogicaJuego.ancho - AtrapaLogica.margen);
    });
  });

  group('el balón', () {
    test('un balón que cae sobre Mutxigol se atrapa: 1 punto y desaparece', () {
      final l = _manual();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      _atrapar(l, TipoCaida.balon);

      expect(l.puntos, 1);
      expect(l.vidas, 3);
      expect(l.objetos, isEmpty);
      expect(eventos, [EventoJuego.punto]);
    });

    test('también se atrapa un balón que cae a un lado, dentro del alcance', () {
      final l = _manual();

      l.soltar(TipoCaida.balon, l.x + AtrapaLogica.mitadCaptura - 2);
      _hastaQueCaiga(l);

      expect(l.puntos, 1);
    });

    test('un balón que llega al suelo se pierde y quita una vida', () {
      final l = _manual();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      l.soltar(TipoCaida.balon, l.x + AtrapaLogica.mitadCaptura + 20);

      _hastaQueCaiga(l);

      expect(l.puntos, 0);
      expect(l.vidas, 2);
      expect(eventos, [EventoJuego.fallo]);
    });

    test('moviéndose a tiempo se atrapa el balón', () {
      final l = _manual();

      l.soltar(TipoCaida.balon, 300);

      for (var i = 0; i < 400 && l.objetos.isNotEmpty; i++) {
        l.tick(_fotograma);
        l.moverA(300);
      }

      expect(l.puntos, 1);
      expect(l.vidas, 3);
    });
  });

  group('el balón con efecto', () {
    test('cae en curva (se desvía de lado) hacia el lado que le toca', () {
      for (final lado in [true, false]) {
        // nextBool = nextDouble >= 0.5
        final l = _manual(random: AleatorioFalso(reales: [lado ? 0.9 : 0.1]));
        final objeto = l.soltar(TipoCaida.balonEfecto, 180);
        final xs = <double>[];

        for (var i = 0; i < 40; i++) {
          l.tick(_fotograma);
          xs.add(objeto.x);
        }

        expect(xs.last, isNot(closeTo(180, 1)), reason: 'se desvía');
        expect((xs.last - 180) > 0, lado, reason: 'hacia el lado elegido');
        // Suave: de un fotograma al siguiente se mueve poco.
        for (var i = 1; i < xs.length; i++) {
          expect((xs[i] - xs[i - 1]).abs(), lessThan(3));
        }
      }
    });

    test('atraparlo suma 1; si llega al suelo quita una vida', () {
      final l = _manual(random: AleatorioFalso(reales: [0.9]));

      l.soltar(TipoCaida.balonEfecto, l.x);
      _hastaQueCaiga(l, seguir: true);

      expect(l.puntos, 1);
      expect(l.vidas, 3);

      _dejarCaer(l, TipoCaida.balonEfecto);

      expect(l.vidas, 2);
    });
  });

  group('el balón pinchado', () {
    test('atraparlo quita una vida y no suma', () {
      final l = _manual();

      _atrapar(l, TipoCaida.balonPinchado);

      expect(l.puntos, 0);
      expect(l.vidas, 2);
    });

    test('dejarlo caer: llega al suelo y no pasa nada', () {
      final l = _manual();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      _dejarCaer(l, TipoCaida.balonPinchado);

      expect(l.vidas, 3);
      expect(l.puntos, 0);
      expect(eventos, isEmpty);
    });
  });

  group('el balón dorado', () {
    test('atraparlo suma 5', () {
      final l = _manual();

      _atrapar(l, TipoCaida.balonDorado);

      expect(l.puntos, 5);
      expect(l.vidas, 3);
    });

    test('si llega al suelo no pasa nada', () {
      final l = _manual();

      _dejarCaer(l, TipoCaida.balonDorado);

      expect(l.vidas, 3);
      expect(l.puntos, 0);
    });
  });

  group('el escudo del club', () {
    test('da una vida si falta alguna', () {
      final l = _manual();

      _atrapar(l, TipoCaida.tarjetaRoja);
      _atrapar(l, TipoCaida.tarjetaRoja);

      expect(l.vidas, 1);

      _atrapar(l, TipoCaida.escudo);

      expect(l.vidas, 2);
      expect(l.puntos, 0);
    });

    test('nunca pasa de 3 vidas', () {
      final l = _manual();

      expect(l.vidas, 3);

      _atrapar(l, TipoCaida.escudo);

      expect(l.vidas, 3);

      _atrapar(l, TipoCaida.tarjetaRoja);
      _atrapar(l, TipoCaida.escudo);
      _atrapar(l, TipoCaida.escudo);

      expect(l.vidas, 3);
    });

    test('solo cae si falta alguna vida (y es raro)', () {
      // Con el azar en 0 lo primero que cabe es el escudo: con las 3 vidas sale otra cosa.
      final l = _manual(random: AleatorioFalso(reales: [0.0]));

      l.soltarTanda();

      expect(l.objetos.map((o) => o.tipo), isNot(contains(TipoCaida.escudo)));

      _atrapar(l, TipoCaida.tarjetaRoja);
      l.soltarTanda();

      expect(l.objetos.map((o) => o.tipo), contains(TipoCaida.escudo));
    });

    test('dejarlo caer no quita nada', () {
      final l = _manual();

      _atrapar(l, TipoCaida.tarjetaRoja);
      _dejarCaer(l, TipoCaida.escudo);

      expect(l.vidas, 2);
    });
  });

  group('la tarjeta roja', () {
    test('atraparla quita una vida y no suma', () {
      final l = _manual();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      _atrapar(l, TipoCaida.tarjetaRoja);

      expect(l.puntos, 0);
      expect(l.vidas, 2);
      expect(eventos, [EventoJuego.fallo]);
    });

    test('esquivarla (llega al suelo) no quita nada', () {
      final l = _manual();

      _dejarCaer(l, TipoCaida.tarjetaRoja);

      expect(l.vidas, 3);
      expect(l.puntos, 0);
    });

    test('con 3 tarjetas atrapadas se acaba la partida', () {
      final l = _manual();

      for (var i = 0; i < 3; i++) {
        _atrapar(l, TipoCaida.tarjetaRoja);
      }

      expect(l.vidas, 0);
      expect(l.terminado, isTrue);

      // Terminada, el tiempo no corre más.
      final tiempo = l.tiempoJugado;

      l.tick(_fotograma);

      expect(l.tiempoJugado, tiempo);
    });
  });

  group('la tarjeta amarilla', () {
    test('una sola no quita vida, pero se cuenta', () {
      final l = _manual();

      _atrapar(l, TipoCaida.tarjetaAmarilla);

      expect(l.amarillas, 1);
      expect(l.vidas, 3);
    });

    test('dos atrapadas quitan una vida y el contador vuelve a 0', () {
      final l = _manual();

      _atrapar(l, TipoCaida.tarjetaAmarilla);
      _atrapar(l, TipoCaida.tarjetaAmarilla);

      expect(l.vidas, 2);
      expect(l.amarillas, 0);

      // Y vuelven a hacer falta dos.
      _atrapar(l, TipoCaida.tarjetaAmarilla);

      expect(l.vidas, 2);
      expect(l.amarillas, 1);
    });

    test('el contador se reinicia al perder una vida por otra causa', () {
      final l = _manual();

      _atrapar(l, TipoCaida.tarjetaAmarilla);

      expect(l.amarillas, 1);

      _atrapar(l, TipoCaida.tarjetaRoja);

      expect(l.vidas, 2);
      expect(l.amarillas, 0);

      // Después de reiniciar, una amarilla no quita vida.
      _atrapar(l, TipoCaida.tarjetaAmarilla);

      expect(l.vidas, 2);
    });

    test('esquivarla no cuenta ni quita nada', () {
      final l = _manual();

      _dejarCaer(l, TipoCaida.tarjetaAmarilla);

      expect(l.amarillas, 0);
      expect(l.vidas, 3);
    });
  });

  group('la bota de tacos', () {
    test('cae más rápido que un balón y en diagonal', () {
      final l = _manual();
      final balon = l.soltar(TipoCaida.balon, 100);
      final bota = l.soltar(TipoCaida.bota, 100);

      expect(bota.velocidad, greaterThan(balon.velocidad));

      for (var i = 0; i < 10; i++) {
        l.tick(_fotograma);
      }

      expect(bota.x, isNot(closeTo(100, 1)));
      expect(balon.x, 100);
    });

    test('rebota en las paredes', () {
      final l = _manual();
      // Pegada a la pared izquierda, va hacia la derecha; desde la derecha, hacia la izquierda.
      final desdeLaIzquierda = l.soltar(TipoCaida.bota, 40);

      expect(desdeLaIzquierda.vx, greaterThan(0));

      final signos = <bool>{};

      for (var i = 0; i < 300 && l.objetos.contains(desdeLaIzquierda); i++) {
        l.tick(_fotograma);
        l.moverA(40); // sin atraparla
        signos.add(desdeLaIzquierda.vx > 0);

        expect(desdeLaIzquierda.x, inInclusiveRange(0, LogicaJuego.ancho));
      }

      expect(signos, {true, false}, reason: 'cambia de sentido al chocar con una pared');
    });

    test('atraparla quita una vida; si llega al suelo no pasa nada', () {
      final l = _manual();

      l.soltar(TipoCaida.bota, l.x);
      _hastaQueCaiga(l, seguir: true);

      expect(l.vidas, 2);
      expect(l.puntos, 0);

      // Cae en diagonal: se pone a Mutxigol en el lado contrario al que va a acabar.
      l.moverA(LogicaJuego.ancho - AtrapaLogica.margen);
      l.soltar(TipoCaida.bota, LogicaJuego.ancho - AtrapaLogica.margen);
      _hastaQueCaiga(l);

      expect(l.vidas, 2);
    });
  });

  group('el silbato', () {
    test('atraparlo deja a Mutxigol quieto 2 segundos, sin quitar vida', () {
      final l = _manual();

      l.moverA(100);
      _atrapar(l, TipoCaida.silbato);

      expect(l.congelado, isTrue);
      expect(l.congeladoRestante, closeTo(2, 0.3));
      expect(l.vidas, 3);

      l.moverA(250);

      expect(l.x, 100, reason: 'quieto, no se mueve');

      _pasar(l, 1.0);
      l.moverA(250);

      expect(l.x, 100);

      _pasar(l, 1.2);

      expect(l.congelado, isFalse);

      l.moverA(250);

      expect(l.x, 250);
    });

    test('si llega al suelo no pasa nada', () {
      final l = _manual();

      _dejarCaer(l, TipoCaida.silbato);

      expect(l.congelado, isFalse);
      expect(l.vidas, 3);
    });
  });

  group('la dificultad', () {
    test('la velocidad llega al máximo hacia el segundo 60 (y ya no sube)', () {
      final l = _manual();

      expect(l.velocidadCaida, AtrapaLogica.velocidadInicial);

      _pasar(l, 30);

      expect(l.velocidadCaida, closeTo(295, 5));

      _pasar(l, 29.9);

      expect(l.velocidadCaida, lessThan(AtrapaLogica.velocidadMaxima));
      expect(l.velocidadCaida, greaterThan(415));

      _pasar(l, 1);

      expect(l.velocidadCaida, AtrapaLogica.velocidadMaxima);

      _pasar(l, 60);

      expect(l.velocidadCaida, AtrapaLogica.velocidadMaxima);
    });

    test('el tamaño máximo de las tandas: 1, desde el segundo 15 hasta 2 y desde el 30 hasta 3', () {
      expect(AtrapaLogica.tamanoMaximoDeTanda(0), 1);
      expect(AtrapaLogica.tamanoMaximoDeTanda(14.9), 1);
      expect(AtrapaLogica.tamanoMaximoDeTanda(15), 2);
      expect(AtrapaLogica.tamanoMaximoDeTanda(29.9), 2);
      expect(AtrapaLogica.tamanoMaximoDeTanda(30), 3);
      expect(AtrapaLogica.tamanoMaximoDeTanda(90), 3);
    });

    test('las tandas sueltan 1, 2 o 3 balones a la vez según el tiempo', () {
      // enteros [5]: siempre el máximo que cabe.
      AtrapaLogica con(double segundos) {
        final l = _manual(random: AleatorioFalso(enteros: [5], reales: [0.3, 0.9, 0.6]));

        _pasar(l, segundos);

        return l..soltarTanda();
      }

      expect(con(1).objetos, hasLength(1));
      expect(con(14).objetos, hasLength(1));
      expect(con(16).objetos, hasLength(2));
      expect(con(29).objetos, hasLength(2));
      expect(con(31).objetos, hasLength(3));
      expect(con(100).objetos, hasLength(3));

      // Dentro de los márgenes del campo.
      for (final o in con(31).objetos) {
        expect(o.x, inInclusiveRange(AtrapaLogica.margen, LogicaJuego.ancho - AtrapaLogica.margen));
      }
    });

    test('entre tandas pasan al menos 0,6 s, también al final', () {
      final l = _manual();

      expect(l.intervalo, AtrapaLogica.intervaloInicial);

      _pasar(l, 20);

      expect(l.intervalo, lessThan(AtrapaLogica.intervaloInicial));

      _pasar(l, 200);

      expect(l.intervalo, 0.6);
      expect(AtrapaLogica.intervaloMinimo, 0.6);
    });

    test('las tandas de verdad respetan ese intervalo', () {
      final l = AtrapaLogica(alto: _alto, random: math.Random(3));
      final tandas = <double>[];
      var vistos = 0;

      // Un cómputo de objetos creados: cada tanda deja al menos uno nuevo.
      for (var i = 0; i < 3500 && !l.terminado; i++) {
        final antes = l.objetos.length;

        l.tick(_fotograma);
        l.moverA(l.objetos.isEmpty ? l.x : l.objetos.first.x);

        if (l.objetos.length > antes) {
          tandas.add(l.segundos);
          vistos++;
        }
      }

      expect(vistos, greaterThan(5));

      for (var i = 1; i < tandas.length; i++) {
        // El fotograma es de 16 ms: 0,6 s con un fotograma de margen.
        expect(tandas[i] - tandas[i - 1], greaterThanOrEqualTo(0.6 - 0.02));
      }
    });

    test('los objetos malos no salen antes del segundo 6 y luego son cada vez más frecuentes', () {
      expect(AtrapaLogica.probabilidadDeMalo(0), 0);
      expect(AtrapaLogica.probabilidadDeMalo(5.9), 0);
      expect(AtrapaLogica.probabilidadDeMalo(6), greaterThan(0));
      expect(
        AtrapaLogica.probabilidadDeMalo(40),
        greaterThan(AtrapaLogica.probabilidadDeMalo(10)),
      );
      expect(AtrapaLogica.probabilidadDeMalo(1000), AtrapaLogica.probabilidadMaloMaxima);

      // Con el azar a 0 (lo más "malo" posible), antes del 6 sale algo bueno y después un balón pinchado.
      final l = _manual(random: AleatorioFalso(reales: [0.0]));

      _pasar(l, 5);
      l.soltarTanda();

      expect(l.objetos.single.tipo.esMalo, isFalse);

      _pasar(l, 2);
      l.soltarTanda();

      expect(l.objetos.last.tipo, TipoCaida.balonPinchado);
    });

    test('en una partida de verdad no cae ningún objeto malo en los primeros 6 segundos', () {
      final l = AtrapaLogica(alto: _alto, random: math.Random(11));

      while (l.segundos < 5.9 && !l.terminado) {
        l.tick(_fotograma);

        expect(l.objetos.any((o) => o.tipo.esMalo), isFalse, reason: 'a los ${l.segundos} s');
      }
    });
  });
}
