import 'package:app_mutxamel_cf/features/juego/logica/atrapa_logica.dart';
import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/juego_helpers.dart';

const double _alto = 640;
const Duration _fotograma = Duration(milliseconds: 16);

AtrapaLogica _manual() => AtrapaLogica(alto: _alto, soltarSolo: false);

/// Avanza hasta que no queda nada cayendo (o pasan [maximo] segundos).
void _hastaQueCaiga(AtrapaLogica l, {double maximo = 8}) {
  final fotogramas = (maximo * 1000 / _fotograma.inMilliseconds).round();

  for (var i = 0; i < fotogramas && l.objetos.isNotEmpty && !l.terminado; i++) {
    l.tick(_fotograma);
  }
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

  group('atrapar', () {
    test('un balón que cae sobre Mutxigol se atrapa: 1 punto y desaparece', () {
      final l = _manual();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      l.soltar(TipoCaida.balon, l.x);

      _hastaQueCaiga(l);

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

    test('un balón que cae fuera del alcance llega al suelo: se pierde y quita una vida', () {
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

  group('la tarjeta roja', () {
    test('atraparla quita una vida y no suma', () {
      final l = _manual();
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;
      l.soltar(TipoCaida.tarjeta, l.x);

      _hastaQueCaiga(l);

      expect(l.puntos, 0);
      expect(l.vidas, 2);
      expect(eventos, [EventoJuego.fallo]);
    });

    test('esquivarla no cuesta nada', () {
      final l = _manual();

      l.soltar(TipoCaida.tarjeta, l.x + 120);

      _hastaQueCaiga(l);

      expect(l.vidas, 3);
      expect(l.puntos, 0);
      expect(l.objetos, isEmpty);
    });

    test('no cae ninguna en los primeros segundos; después, de vez en cuando', () {
      // Los números alternan: la posición (0,5 = justo donde está Mutxigol) y la decisión (0,0 = tarjeta, si toca).
      final l = AtrapaLogica(
        alto: _alto,
        random: AleatorioFalso(reales: [0.5, 0.0]),
      );

      var tarjetaAntes = false;
      var tarjetaDespues = false;

      for (var i = 0; i < 700 && !l.terminado; i++) {
        l.tick(_fotograma);

        final hayTarjeta = l.objetos.any((o) => o.tipo == TipoCaida.tarjeta);

        if (l.segundos < AtrapaLogica.segundosSinTarjetas) {
          tarjetaAntes |= hayTarjeta;
        } else {
          tarjetaDespues |= hayTarjeta;
        }
      }

      expect(tarjetaAntes, isFalse);
      expect(tarjetaDespues, isTrue);
    });
  });

  group('las vidas', () {
    test('son 3: tres balones perdidos acaban la partida', () {
      final l = _manual();

      for (var i = 0; i < 3; i++) {
        expect(l.terminado, isFalse);

        l.soltar(TipoCaida.balon, 340);
        _hastaQueCaiga(l);
      }

      expect(l.vidas, 0);
      expect(l.terminado, isTrue);
    });

    test('balones perdidos y tarjetas atrapadas se suman', () {
      final l = _manual();

      l.soltar(TipoCaida.balon, 340);
      _hastaQueCaiga(l);
      l.soltar(TipoCaida.tarjeta, l.x);
      _hastaQueCaiga(l);
      l.soltar(TipoCaida.tarjeta, l.x);
      _hastaQueCaiga(l);

      expect(l.vidas, 0);
      expect(l.terminado, isTrue);
    });

    test('con la partida acabada nada se mueve ni se atrapa', () {
      final l = _manual();

      for (var i = 0; i < 3; i++) {
        l.soltar(TipoCaida.balon, 340);
        _hastaQueCaiga(l);
      }

      final x = l.x;
      final tiempo = l.tiempoJugado;

      l.moverA(60);
      l.tick(const Duration(seconds: 3));

      expect(l.x, x);
      expect(l.tiempoJugado, tiempo);
    });
  });

  group('dificultad', () {
    test('la velocidad aumenta poco a poco hasta un máximo', () {
      final l = _manual();

      expect(l.velocidadCaida, AtrapaLogica.velocidadInicial);

      for (var i = 0; i < 625; i++) {
        l.tick(_fotograma);
      }

      final a10 = l.velocidadCaida;

      expect(a10, greaterThan(AtrapaLogica.velocidadInicial));

      for (var i = 0; i < 6000; i++) {
        l.tick(_fotograma);
      }

      expect(l.velocidadCaida, AtrapaLogica.velocidadMaxima);
      expect(l.velocidadCaida, greaterThan(a10));
    });

    test('los balones caen cada vez más seguidos, hasta un mínimo', () {
      final l = _manual();

      expect(l.intervalo, AtrapaLogica.intervaloInicial);

      for (var i = 0; i < 625; i++) {
        l.tick(_fotograma);
      }

      final a10 = l.intervalo;

      expect(a10, lessThan(AtrapaLogica.intervaloInicial));

      for (var i = 0; i < 6000; i++) {
        l.tick(_fotograma);
      }

      expect(l.intervalo, AtrapaLogica.intervaloMinimo);
      expect(l.intervalo, lessThan(a10));
    });

    test('suelta balones por su cuenta, y no más de 2 por segundo', () {
      final l = AtrapaLogica(
        alto: _alto,
        random: AleatorioFalso(reales: [0.5, 0.9]),
      );

      // Los balones caen sobre Mutxigol (0,5 es el centro) y se atrapan: así dura toda la partida.
      for (var i = 0; i < 3750 && !l.terminado; i++) {
        l.tick(_fotograma);
      }

      expect(l.terminado, isFalse);
      expect(l.puntos, greaterThan(40));
      expect(l.puntos / l.segundos, lessThanOrEqualTo(2.01));
    });
  });
}
