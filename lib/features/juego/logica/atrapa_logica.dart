import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'logica_juego.dart';

/// Lo que cae.
enum TipoCaida { balon, tarjeta }

/// Un balón o una tarjeta roja cayendo.
class ObjetoCayendo {
  ObjetoCayendo(this.tipo, this.x, this.y, this.velocidad);

  final TipoCaida tipo;
  final double x;
  double y;
  final double velocidad;
}

/// Atrapa balones: Mutxigol se mueve abajo, a izquierda y derecha (arrastrando el dedo), y atrapa los balones que caen:
/// 1 punto cada uno. De vez en cuando cae una tarjeta roja, que hay que esquivar. 3 vidas: un balón que llega al suelo
/// o una tarjeta atrapada quita una. La velocidad y la frecuencia aumentan poco a poco.
class AtrapaLogica extends LogicaJuego {
  /// [soltarSolo] false deja de soltar objetos por su cuenta (los tests los sueltan a mano con [soltar]).
  AtrapaLogica({
    required super.alto,
    math.Random? random,
    this.soltarSolo = true,
  }) : _random = random ?? math.Random();

  final bool soltarSolo;

  final math.Random _random;

  // ---- Reglas (unidades de juego) ----

  static const int vidasIniciales = 3;

  /// La mitad del ancho de lo que atrapa Mutxigol.
  static const double mitadCaptura = 52;

  /// El margen de los lados por el que no se mueve Mutxigol ni cae nada.
  static const double margen = 40;

  static const double velocidadInicial = 170;
  static const double velocidadMaxima = 420;
  static const double aceleracion = 8;

  /// Segundos entre un objeto y el siguiente: de 1,1 a 0,5 (como mucho 2 por segundo, dentro del ritmo que acepta el
  /// backend).
  static const double intervaloInicial = 1.1;
  static const double intervaloMinimo = 0.5;
  static const double reduccionIntervalo = 0.02;

  /// Las tarjetas empiezan a caer pasados unos segundos.
  static const double segundosSinTarjetas = 6;
  static const double probabilidadTarjeta = 0.2;

  // ---- Estado ----

  double _x = LogicaJuego.ancho / 2;
  int _puntos = 0;
  int _vidas = vidasIniciales;
  double _hastaElSiguiente = 0.8;
  final List<ObjetoCayendo> _objetos = [];

  @override
  int get puntos => _puntos;

  @override
  int? get vidas => _vidas;

  @override
  bool get terminado => _vidas <= 0;

  /// La posición horizontal (el centro) de Mutxigol.
  double get x => _x;

  /// La altura a la que se atrapa.
  double get yCaptura => alto - 110;

  /// La altura del suelo: un balón que llega aquí se pierde.
  double get suelo => alto - 70;

  List<ObjetoCayendo> get objetos => List.unmodifiable(_objetos);

  double get velocidadCaida =>
      math.min(velocidadInicial + aceleracion * segundos, velocidadMaxima);

  double get intervalo => math.max(
    intervaloInicial - reduccionIntervalo * segundos,
    intervaloMinimo,
  );

  double get _probabilidadTarjeta =>
      segundos < segundosSinTarjetas ? 0 : probabilidadTarjeta;

  /// Mueve a Mutxigol hasta [nuevaX] (dentro de los márgenes).
  void moverA(double nuevaX) {
    if (terminado) return;

    _x = nuevaX.clamp(margen, LogicaJuego.ancho - margen).toDouble();
  }

  /// Suelta un objeto ya (la partida lo hace sola; los tests, para no depender del azar).
  @visibleForTesting
  void soltar(TipoCaida tipo, double x) {
    _objetos.add(ObjetoCayendo(tipo, x, -20, velocidadCaida));
  }

  @override
  void avanzar(Duration dt) {
    final s = LogicaJuego.segundosDe(dt);

    _hastaElSiguiente -= s;

    if (soltarSolo && _hastaElSiguiente <= 0) {
      _hastaElSiguiente += intervalo;

      final x =
          margen +
          _random.nextDouble() * (LogicaJuego.ancho - 2 * margen);
      final tarjeta = _random.nextDouble() < _probabilidadTarjeta;

      soltar(tarjeta ? TipoCaida.tarjeta : TipoCaida.balon, x);
    }

    for (final objeto in List.of(_objetos)) {
      objeto.y += objeto.velocidad * s;

      final enLaZonaDeCaptura =
          objeto.y >= yCaptura - 30 &&
          objeto.y <= yCaptura + 25 &&
          (objeto.x - _x).abs() <= mitadCaptura;

      if (enLaZonaDeCaptura) {
        _objetos.remove(objeto);

        if (objeto.tipo == TipoCaida.balon) {
          _puntos++;
          alEvento?.call(EventoJuego.punto);
        } else {
          _perderVida();
        }
      } else if (objeto.y >= suelo) {
        _objetos.remove(objeto);

        // Un balón que llega al suelo quita una vida; una tarjeta esquivada no pasa nada.
        if (objeto.tipo == TipoCaida.balon) _perderVida();
      }
    }
  }

  void _perderVida() {
    _vidas--;
    alEvento?.call(EventoJuego.fallo);
  }
}
