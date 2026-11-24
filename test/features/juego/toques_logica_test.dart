import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:app_mutxamel_cf/features/juego/logica/toques_logica.dart';
import 'package:flutter_test/flutter_test.dart';

const double _alto = 640;
const Duration _fotograma = Duration(milliseconds: 16);

/// Juega [segundos] tocando el balón cada vez que baja de [alturaDeToque].
void _sobrevivir(ToquesLogica l, double segundos, {double alturaDeToque = 250}) {
  final fotogramas = (segundos * 1000 / _fotograma.inMilliseconds).round();

  for (var i = 0; i < fotogramas && !l.terminado; i++) {
    l.tick(_fotograma);

    if (l.balon.dy > alturaDeToque && l.velocidad.dy > 0) l.tocar(l.balon);
  }
}

void main() {
  test('el balón cae con gravedad y, si toca el suelo, se acaba', () {
    final l = ToquesLogica(alto: _alto);
    final eventos = <EventoJuego>[];

    l.alEvento = eventos.add;

    final inicial = l.balon.dy;

    l.tick(const Duration(milliseconds: 300));

    expect(l.balon.dy, greaterThan(inicial));
    expect(l.velocidad.dy, greaterThan(0));
    expect(l.terminado, isFalse);

    l.tick(const Duration(seconds: 2));

    expect(l.terminado, isTrue);
    expect(l.puntos, 0);
    expect(eventos, [EventoJuego.fallo]);
    expect(l.balon.dy + ToquesLogica.radioBalon, greaterThanOrEqualTo(l.suelo));
  });

  group('un toque', () {
    test('en el centro del balón lo hace subir, sin desviarlo, y suma un punto', () {
      final l = ToquesLogica(alto: _alto);
      final eventos = <EventoJuego>[];

      l.alEvento = eventos.add;

      expect(l.tocar(l.balon), isTrue);

      expect(l.puntos, 1);
      expect(l.velocidad.dy, lessThan(0));
      expect(l.velocidad.dx, closeTo(0, 1e-9));
      expect(eventos, [EventoJuego.punto]);
    });

    test('a la izquierda del centro lo manda a la derecha, y al revés', () {
      final izquierda = ToquesLogica(alto: _alto);

      izquierda.tocar(izquierda.balon + const Offset(-25, 5));

      expect(izquierda.velocidad.dx, greaterThan(0));

      final derecha = ToquesLogica(alto: _alto);

      derecha.tocar(derecha.balon + const Offset(25, 5));

      expect(derecha.velocidad.dx, lessThan(0));
    });

    test('cuanto más lejos del centro, más lateral, hasta un máximo', () {
      final cerca = ToquesLogica(alto: _alto)..tocar(const Offset(170, 150));
      final lejos = ToquesLogica(alto: _alto)..tocar(const Offset(135, 150));

      expect(lejos.velocidad.dx.abs(), greaterThan(cerca.velocidad.dx.abs()));
      expect(lejos.velocidad.dx.abs(), lessThanOrEqualTo(ToquesLogica.empujeLateral));
    });

    test('lejos del balón no cuenta', () {
      final l = ToquesLogica(alto: _alto);

      expect(l.tocar(l.balon + const Offset(0, 120)), isFalse);
      expect(l.puntos, 0);
      expect(l.velocidad.dy, 0);
    });

    test('el balón sube siempre a la misma altura, caiga con la gravedad que caiga', () {
      final l = ToquesLogica(alto: _alto);

      l.tocar(l.balon);

      final subida =
          l.velocidad.dy * l.velocidad.dy / (2 * l.gravedad);

      expect(subida, closeTo(ToquesLogica.alturaToque, 0.01));
    });

    test('dos toques casi a la vez cuentan uno solo (ritmo máximo del backend)', () {
      final l = ToquesLogica(alto: _alto);

      expect(l.tocar(l.balon), isTrue);
      expect(l.tocar(l.balon), isFalse);

      l.tick(const Duration(milliseconds: 100));

      expect(l.tocar(l.balon), isFalse);

      l.tick(const Duration(milliseconds: 100));

      expect(l.tocar(l.balon), isTrue);
      expect(l.puntos, 2);
    });

    test('con el juego acabado ya no se puede tocar', () {
      final l = ToquesLogica(alto: _alto);

      l.tick(const Duration(seconds: 3));

      expect(l.terminado, isTrue);
      expect(l.tocar(l.balon), isFalse);
    });
  });

  group('rebotes', () {
    test('rebota en la pared lateral y vuelve hacia dentro', () {
      final l = ToquesLogica(alto: _alto);

      // Un toque en el lado derecho del balón lo manda a la izquierda, hacia la pared.
      l.tocar(l.balon + const Offset(ToquesLogica.radioToque - 2, 0));

      expect(l.velocidad.dx, lessThan(0));

      var rebote = false;

      for (var i = 0; i < 80 && !l.terminado; i++) {
        l.tick(_fotograma);

        expect(l.balon.dx, greaterThanOrEqualTo(ToquesLogica.radioBalon));

        if (l.velocidad.dx > 0) {
          rebote = true;
          break;
        }
      }

      expect(rebote, isTrue);
    });

    test('rebota también en la pared derecha', () {
      final l = ToquesLogica(alto: _alto);

      l.tocar(l.balon + const Offset(-(ToquesLogica.radioToque - 2), 0));

      expect(l.velocidad.dx, greaterThan(0));

      var rebote = false;

      for (var i = 0; i < 80 && !l.terminado; i++) {
        l.tick(_fotograma);

        expect(
          l.balon.dx,
          lessThanOrEqualTo(LogicaJuego.ancho - ToquesLogica.radioBalon),
        );

        if (l.velocidad.dx < 0) {
          rebote = true;
          break;
        }
      }

      expect(rebote, isTrue);
    });

    test('rebota en el techo y no se sale por arriba', () {
      final l = ToquesLogica(alto: _alto);

      l.tocar(l.balon);

      for (var i = 0; i < 60 && !l.terminado; i++) {
        l.tick(_fotograma);

        expect(l.balon.dy, greaterThanOrEqualTo(ToquesLogica.radioBalon));
      }
    });
  });

  group('dificultad', () {
    test('la gravedad aumenta poco a poco hasta un máximo', () {
      final l = ToquesLogica(alto: _alto);

      expect(l.gravedad, ToquesLogica.gravedadInicial);

      _sobrevivir(l, 10);

      expect(l.terminado, isFalse);

      final aLos10 = l.gravedad;

      expect(aLos10, greaterThan(ToquesLogica.gravedadInicial));

      _sobrevivir(l, 20);

      expect(l.gravedad, greaterThan(aLos10));
      expect(l.gravedad, lessThanOrEqualTo(ToquesLogica.gravedadMaxima));
      expect(l.puntos, greaterThan(20));
    });

    test('el ritmo de toques no pasa del máximo que acepta el backend (6 por segundo con margen)', () {
      final l = ToquesLogica(alto: _alto);

      _sobrevivir(l, 15);

      final porSegundo = l.puntos / l.segundos;

      expect(porSegundo, lessThanOrEqualTo(6));
    });
  });
}
