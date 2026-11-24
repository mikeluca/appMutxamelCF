import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'formas_choque.dart';
import 'logica_juego.dart';

/// Una barrera: una columna de defensas arriba y otra abajo, con un hueco entre ellas. [x] es su borde izquierdo.
class BarreraCabezazos {
  BarreraCabezazos(this.x, this.centroHueco, this.hueco, {this.sueloCampo = 570});

  double x;

  /// La altura del centro del hueco y lo que mide.
  final double centroHueco;
  final double hueco;

  /// Dónde acaba la columna de abajo (el borde del césped).
  final double sueloCampo;

  /// Ya se ha superado (puntúa una sola vez).
  bool superada = false;

  double get techoDelHueco => centroHueco - hueco / 2;
  double get sueloDelHueco => centroHueco + hueco / 2;

  /// Los recuadros (con x = 0) de las defensas de las dos columnas: un número entero de defensas que llena de arriba a
  /// abajo sin huecos ni defensas cortadas.
  late final List<Rect> _locales = [
    ...columna(0, techoDelHueco),
    ...columna(sueloDelHueco, sueloCampo),
  ];

  /// Los recuadros de las defensas, donde están ahora.
  List<Rect> get recuadros => [for (final r in _locales) r.shift(Offset(x, 0))];

  /// Las formas de choque de las defensas, donde están ahora.
  List<FormaDefensa> get formas => [for (final r in recuadros) FormaDefensa.de(r)];

  /// Una columna de defensas entre [desde] y [hasta]: el alto se reparte entre un número entero de defensas.
  static List<Rect> columna(double desde, double hasta) {
    final total = hasta - desde;

    if (total <= 0) return const [];

    final cuantas = math.max(1, (total / CabezazosLogica.altoDefensa).round());
    final alto = total / cuantas;

    return [
      for (var i = 0; i < cuantas; i++)
        Rect.fromLTWH(0, desde + i * alto, CabezazosLogica.anchoBarrera, alto),
    ];
  }
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

  /// La posición horizontal del pivote de Mutxigol (el centro del tronco): un tercio del ancho.
  static const double xMutxigol = LogicaJuego.ancho / 3;

  /// El tamaño con el que se dibuja la imagen cuadrada (768 px) de la pose de salto: el personaje visible mide ~73.
  static const double tamanoImagen = 108;

  /// Lo que mide el personaje visible (cuernos y pies incluidos) dentro de la imagen, de 0 a 1: 520 de 768 px (medido
  /// sobre el canal alfa de mutxigol_salto.webp: x 225–547, y 84–604).
  static const double alturaVisibleEnImagen = 0.68;

  /// Las formas de choque de Mutxigol en la pose de salto: 3 círculos medidos sobre el canal alfa de
  /// mutxigol_salto.webp (768 × 768 px). Cada uno es (dx, dy, r) en fracción del tamaño de la imagen, con (0, 0) en su
  /// centro y el eje Y hacia abajo:
  ///
  /// * cabeza con hocico: centro (432, 245) px, radio 110 → cubre la cabeza y casi la punta del hocico, sin los cuernos
  ///   (y 84–140) ni el mechón;
  /// * tronco: centro (378, 410) px, radio 80 → la camiseta;
  /// * piernas recogidas: centro (300, 548) px, radio 52.
  ///
  /// Quedan fuera los cuernos, el mechón y la mano del brazo estirado (x 225–310, y 190–300). El test
  /// `forma_choque_alfa_test.dart` comprueba contra la imagen que los círculos caen casi enteros sobre píxeles opacos
  /// y que no cubren cuernos ni mano.
  static const List<(double, double, double)> circulosCuerpo = [
    (0.0625, -0.1810, 0.1432), // cabeza con hocico
    (-0.0078, 0.0339, 0.1042), // tronco
    (-0.1094, 0.2135, 0.0677), // piernas recogidas
  ];

  /// El pivote: el centro del tronco. La imagen gira alrededor de él y es el punto cuya altura es [y].
  static const double pivoteDx = -0.0078;
  static const double pivoteDy = 0.0339;

  /// Lo que se desvía a cada lado del pivote la forma de choque (sin girar), en unidades de juego.
  static const double extensionIzquierda = 0.1693 * tamanoImagen;
  static const double extensionDerecha = 0.2135 * tamanoImagen;

  /// El alto de la forma de choque (de lo más alto de la cabeza a lo más bajo de las piernas), en unidades.
  static const double altoDeLaForma = 0.605 * tamanoImagen;

  /// El "diámetro" de referencia para el hueco: el 56 % del alto visible del personaje (como el círculo único de
  /// antes respecto a la imagen grande).
  static const double diametro = 0.56 * tamanoImagen * alturaVisibleEnImagen;

  /// Un roce de unas unidades no cuenta: la forma de Mutxigol se encoge esto a favor del jugador.
  static const double tolerancia = 2.5;

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

  /// El alto aproximado de cada defensa de la columna (se ajusta para llenarla entera).
  static const double altoDefensa = 68;

  /// El hueco: empieza en ~3,5 diámetros, se estrecha 4 por barrera y no baja de 120 (2,9 diámetros: el mínimo de antes,
  /// 140, ajustado al tamaño nuevo de Mutxigol).
  static const double huecoInicial = 3.5 * diametro;
  static const double huecoMinimo = 120;
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
    final barrera = BarreraCabezazos(x, centroHueco, hueco, sueloCampo: suelo);

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

      if (!barrera.superada &&
          barrera.x + anchoBarrera < xMutxigol - extensionIzquierda) {
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
          ? xMutxigol + extensionDerecha + velocidadBarreras * segundosHastaLaPrimera
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
    _barreras.add(BarreraCabezazos(x, centro, hueco, sueloCampo: suelo));
  }

  /// El ángulo con el que se gira la imagen (y las formas de choque), en radianes: positivo en el sentido de las agujas
  /// del reloj (hacia abajo); la inclinación hacia arriba lo hace negativo.
  double get angulo => -inclinacionGrados * math.pi / 180;

  /// Los círculos de choque de Mutxigol donde están ahora: a escala, colocados alrededor del pivote en ([xMutxigol],
  /// [y]) y girados con la inclinación (igual que la imagen).
  List<CirculoChoque> get circulosEnMundo {
    final a = angulo;

    return [
      for (final (dx, dy, r) in circulosCuerpo)
        CirculoChoque(
          xMutxigol + (dx - pivoteDx) * tamanoImagen,
          _y + (dy - pivoteDy) * tamanoImagen,
          r * tamanoImagen,
        ).girado(a, xMutxigol, _y),
    ];
  }

  bool _choca() {
    final circulos = circulosEnMundo;

    // El techo y el suelo, con las formas.
    final arriba = circulos.map((c) => c.cy - c.r).reduce(math.min);
    final abajo = circulos.map((c) => c.cy + c.r).reduce(math.max);

    if (arriba < -tolerancia || abajo > suelo + tolerancia) return true;

    for (final barrera in _barreras) {
      // Descarte rápido: lejos en horizontal no hay nada que comprobar.
      if (barrera.x > xMutxigol + extensionDerecha + 10 ||
          barrera.x + anchoBarrera < xMutxigol - extensionIzquierda - 10) {
        continue;
      }

      for (final forma in barrera.formas) {
        for (final c in circulos) {
          // Solo cuenta si se solapan más que la tolerancia.
          if (forma.distanciaA(c) < -tolerancia) return true;
        }
      }
    }

    return false;
  }
}
