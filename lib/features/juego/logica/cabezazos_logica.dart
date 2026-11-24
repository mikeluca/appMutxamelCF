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
/// estrechando. +1 por barrera superada. 1 vida: tocar una barrera, el suelo o el techo acaba la partida.
///
/// No lleva cuenta atrás: empieza en espera (Mutxigol flota) y el primer toque arranca la partida y el tiempo.
class CabezazosLogica extends LogicaJuego {
  CabezazosLogica({required super.alto, math.Random? random})
    : _random = random ?? math.Random(),
      _y = alto * alturaDeEspera;

  final math.Random _random;

  // ---- Mutxigol (unidades de juego) ----

  /// La posición horizontal del centro de su cuerpo (un tercio del ancho).
  static const double xMutxigol = LogicaJuego.ancho / 3;

  /// El tamaño con el que se dibuja la imagen cuadrada de la pose de salto: el personaje visible mide ~86 de alto.
  static const double tamanoImagen = 126;

  /// Lo que mide el personaje visible (cuernos y pies incluidos) dentro de la imagen, de 0 a 1.
  static const double alturaVisibleEnImagen = 0.68;

  /// Dónde está el centro del cuerpo (cabeza y tronco, sin cuernos ni puntas de los brazos) respecto al centro de la
  /// imagen, en fracción de su tamaño.
  static const double cuerpoDx = 0.053;
  static const double cuerpoDy = -0.109;

  /// El círculo de choque: ajustado al cuerpo visible (cabeza y tronco).
  static const double radio = 24;
  static const double diametro = radio * 2;

  // ---- Física ----

  static const double gravedad = 1100;

  /// El impulso de cada toque (velocidad vertical, hacia arriba).
  static const double impulso = 380;

  /// La velocidad máxima de caída.
  static const double velocidadMaximaDeCaida = 550;

  // ---- Barreras ----

  /// La velocidad con la que entran las barreras (constante) y la distancia entre ellas.
  static const double velocidadBarreras = 150;
  static const double separacionBarreras = 210;
  static const double anchoBarrera = 62;

  /// La primera barrera llega a Mutxigol a los 2 s del primer toque.
  static const double segundosHastaLaPrimera = 2;

  /// El hueco: empieza en ~3,5 diámetros, se estrecha 4 por barrera y no baja de 140 (2,9 diámetros).
  static const double huecoInicial = 3.5 * diametro;
  static const double huecoMinimo = 140;
  static const double estrechamiento = 4;

  /// El hueco mínimo siempre es jugable: al menos 2,6 veces el diámetro de choque.
  static const double huecoMinimoJugable = 2.6 * diametro;

  /// Lo que puede cambiar la altura del hueco de una barrera a la siguiente (que siempre sea alcanzable).
  static const double cambioMaximoDeAltura = 150;

  /// El suelo (el césped de abajo mide esto) y el margen mínimo del hueco con el techo y el suelo.
  static const double alturaCesped = 70;
  static const double margenHueco = 60;

  /// La inclinación de la imagen: hasta 20° hacia arriba y 60° hacia abajo.
  static const double inclinacionMaximaArriba = 20;
  static const double inclinacionMaximaAbajo = 60;

  /// El movimiento de flotar mientras se espera el primer toque.
  static const double alturaDeEspera = 0.4;
  static const double amplitudFlotar = 14;
  static const double frecuenciaFlotar = 2.4;

  // ---- Estado ----

  double _y;
  double _vy = 0;
  bool _esperando = true;
  bool _muerto = false;
  int _puntos = 0;
  double _recorrido = 0;
  double? _ultimoCentro;
  int _creadas = 0;
  Duration _cronometro = Duration.zero;
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

  /// El tiempo de partida: empieza con el primer toque (la espera no cuenta).
  @override
  Duration get tiempoJugado => _cronometro;

  /// La altura del centro del cuerpo de Mutxigol (el centro del círculo de choque).
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

    return -math.min(_vy / velocidadMaximaDeCaida, 1) * inclinacionMaximaAbajo;
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
      _y =
          alto * alturaDeEspera +
          amplitudFlotar * math.sin(segundos * frecuenciaFlotar);

      return;
    }

    _cronometro += dt;

    _vy = math.min(_vy + gravedad * s, velocidadMaximaDeCaida);
    _y += _vy * s;
    _recorrido += velocidadBarreras * s;

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

    _crearBarreras();

    if (_choca()) {
      _muerto = true;
      alEvento?.call(EventoJuego.fallo);
    }
  }

  /// Mantiene las barreras que entran: la primera llega a los 2 s del primer toque y las demás a [separacionBarreras].
  void _crearBarreras() {
    while (_barreras.isEmpty && _creadas == 0 ||
        (_barreras.isNotEmpty &&
            _barreras.last.x + separacionBarreras <= LogicaJuego.ancho + 40)) {
      final x = _barreras.isEmpty
          ? xMutxigol + radio + velocidadBarreras * segundosHastaLaPrimera
          : _barreras.last.x + separacionBarreras;

      _crear(x);
    }
  }

  void _crear(double x) {
    final hueco = huecoActual;
    final minimo = margenHueco + hueco / 2;
    final maximo = suelo - margenHueco - hueco / 2;

    var centro = minimo + _random.nextDouble() * (maximo - minimo);

    // Que no cambie demasiado respecto a la anterior: siempre se puede llegar. La primera, cerca de donde está él.
    final anterior = _ultimoCentro ?? _y;
    final cambio = _ultimoCentro == null ? 70.0 : cambioMaximoDeAltura;

    centro = centro
        .clamp(anterior - cambio, anterior + cambio)
        .clamp(minimo, maximo)
        .toDouble();

    _ultimoCentro = centro;
    _creadas++;
    _barreras.add(BarreraCabezazos(x, centro, hueco));
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
