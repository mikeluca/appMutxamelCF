import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'logica_juego.dart';

/// Una barrera: una columna de defensas arriba y otra abajo, con un hueco entre ellas. [x] es su borde izquierdo.
class BarreraCabezazos {
  BarreraCabezazos(this.x, this.centroHueco, this.hueco);

  double x;

  /// La altura del centro del hueco y lo que mide.
  final double centroHueco;
  final double hueco;

  /// Ya se ha superado (puntúa una sola vez).
  bool superada = false;

  double get techoDelHueco => centroHueco - hueco / 2;
  double get sueloDelHueco => centroHueco + hueco / 2;
}

/// Cabezazos (estilo Flappy Bird): Mutxigol, de perfil, a un tercio del ancho. Tocar en cualquier sitio le da un impulso
/// hacia arriba y la gravedad lo baja. Entran barreras por la derecha a ritmo constante, con un hueco que se va
/// estrechando. +1 por barrera superada. 1 vida: tocar una barrera, el suelo o el techo acaba la partida. Hasta el primer
/// toque, Mutxigol flota y no pasa nada.
class CabezazosLogica extends LogicaJuego {
  CabezazosLogica({required super.alto, math.Random? random})
    : _random = random ?? math.Random(),
      _y = alto * 0.4;

  final math.Random _random;

  // ---- Reglas (unidades de juego) ----

  /// La posición horizontal de Mutxigol (un tercio del ancho).
  static const double xMutxigol = LogicaJuego.ancho / 3;

  /// El radio de su "caja" (un poco menor que la imagen, para que sea justo).
  static const double radio = 22;

  static const double gravedad = 1500;

  /// El impulso de cada toque (velocidad vertical, hacia arriba).
  static const double impulso = 440;

  /// La velocidad con la que entran las barreras (constante) y la distancia entre ellas.
  static const double velocidadBarreras = 150;
  static const double separacionBarreras = 210;
  static const double anchoBarrera = 62;

  /// El hueco: empieza en 200, se estrecha 4 por barrera y no baja de 140.
  static const double huecoInicial = 200;
  static const double huecoMinimo = 140;
  static const double estrechamiento = 4;

  /// Lo que puede cambiar la altura del hueco de una barrera a la siguiente (que siempre sea alcanzable).
  static const double cambioMaximoDeAltura = 150;

  /// El suelo (el césped de abajo mide esto) y el margen mínimo del hueco con el techo y el suelo.
  static const double alturaCesped = 70;
  static const double margenHueco = 40;

  /// La inclinación de la imagen: hasta 20° hacia arriba y 60° hacia abajo.
  static const double inclinacionMaximaArriba = 20;
  static const double inclinacionMaximaAbajo = 60;
  static const double velocidadParaInclinacionMaxima = 600;

  /// El movimiento de flotar mientras se espera el primer toque.
  static const double amplitudFlotar = 14;
  static const double frecuenciaFlotar = 2.4;

  // ---- Estado ----

  double _y;
  double _vy = 0;
  bool _esperando = true;
  bool _muerto = false;
  int _puntos = 0;
  double _recorrido = 0;
  double _hastaLaSiguiente = 0;
  double? _ultimoCentro;
  int _creadas = 0;
  final List<BarreraCabezazos> _barreras = [];

  @override
  int get puntos => _puntos;

  /// Una sola vida (clásico): no se enseñan corazones.
  @override
  int? get vidas => null;

  @override
  bool get terminado => _muerto;

  /// true hasta el primer toque: Mutxigol flota y todavía no hay barreras.
  bool get esperando => _esperando;

  /// La altura del centro de Mutxigol.
  double get y => _y;

  double get velocidadVertical => _vy;

  /// Lo que se ha desplazado el fondo (para el paralaje).
  double get recorrido => _recorrido;

  List<BarreraCabezazos> get barreras => List.unmodifiable(_barreras);

  /// La altura del suelo (donde empieza el césped).
  double get suelo => alto - alturaCesped;

  /// Cuánto mide el hueco de la siguiente barrera que se cree.
  double get huecoActual =>
      math.max(huecoMinimo, huecoInicial - estrechamiento * _creadas);

  /// La inclinación de la imagen en grados: positiva hacia arriba (hasta 20°), negativa hacia abajo (hasta 60°).
  double get inclinacionGrados {
    if (_vy < 0) {
      return math.min(-_vy / impulso, 1) * inclinacionMaximaArriba;
    }

    return -math.min(_vy / velocidadParaInclinacionMaxima, 1) *
        inclinacionMaximaAbajo;
  }

  /// Un toque: el primero empieza la partida; todos dan un impulso hacia arriba.
  void tocar() {
    if (terminado) return;

    _esperando = false;
    _vy = -impulso;
  }

  /// Pone una barrera ya, con su borde izquierdo en [x] (los tests; la partida las crea sola).
  @visibleForTesting
  BarreraCabezazos colocarBarrera(double x, double centroHueco, double hueco) {
    final barrera = BarreraCabezazos(x, centroHueco, hueco);

    _barreras.add(barrera);

    return barrera;
  }

  /// Coloca a Mutxigol a esa altura (los tests).
  @visibleForTesting
  void colocarY(double nuevaY, {double velocidad = 0}) {
    _y = nuevaY;
    _vy = velocidad;
  }

  @override
  void avanzar(Duration dt) {
    final s = LogicaJuego.segundosDe(dt);

    if (_esperando) {
      // Flota suave arriba y abajo: no cae ni avanza nada.
      _y = alto * 0.4 + amplitudFlotar * math.sin(segundos * frecuenciaFlotar);

      return;
    }

    _vy += gravedad * s;
    _y += _vy * s;
    _recorrido += velocidadBarreras * s;

    _crearBarreras(s);

    for (final barrera in List.of(_barreras)) {
      barrera.x -= velocidadBarreras * s;

      if (barrera.x + anchoBarrera < -10) {
        _barreras.remove(barrera);
        continue;
      }

      if (!barrera.superada && barrera.x + anchoBarrera < xMutxigol - radio) {
        barrera.superada = true;
        _puntos++;
        alEvento?.call(EventoJuego.punto);
      }
    }

    if (_choca()) {
      _muerto = true;
      alEvento?.call(EventoJuego.fallo);
    }
  }

  void _crearBarreras(double s) {
    _hastaLaSiguiente -= velocidadBarreras * s;

    if (_hastaLaSiguiente > 0) return;

    _hastaLaSiguiente += separacionBarreras;

    final hueco = huecoActual;
    final minimo = margenHueco + hueco / 2;
    final maximo = suelo - margenHueco - hueco / 2;

    var centro = minimo + _random.nextDouble() * (maximo - minimo);

    // Que no cambie demasiado respecto a la anterior: siempre se puede llegar.
    final anterior = _ultimoCentro;

    if (anterior != null) {
      centro = centro
          .clamp(anterior - cambioMaximoDeAltura, anterior + cambioMaximoDeAltura)
          .clamp(minimo, maximo)
          .toDouble();
    }

    _ultimoCentro = centro;
    _creadas++;
    _barreras.add(BarreraCabezazos(LogicaJuego.ancho + 20, centro, hueco));
  }

  bool _choca() {
    // El techo y el suelo.
    if (_y - radio <= 0 || _y + radio >= suelo) return true;

    for (final barrera in _barreras) {
      final dentroEnX =
          xMutxigol + radio > barrera.x &&
          xMutxigol - radio < barrera.x + anchoBarrera;

      if (dentroEnX &&
          (_y - radio < barrera.techoDelHueco ||
              _y + radio > barrera.sueloDelHueco)) {
        return true;
      }
    }

    return false;
  }
}
