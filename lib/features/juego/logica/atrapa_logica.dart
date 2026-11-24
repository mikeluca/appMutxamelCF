import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'logica_juego.dart';

/// Lo que puede caer en Atrapa balones.
enum TipoCaida {
  /// +1. Si llega al suelo, −1 vida.
  balon,

  /// Cae en curva (deriva lateral suave a un lado o al otro). +1. Si llega al suelo, −1 vida.
  balonEfecto,

  /// Aplastado y gris: hay que dejarlo caer. Atraparlo quita 1 vida; que llegue al suelo no quita nada.
  balonPinchado,

  /// Poco frecuente: +5.
  balonDorado,

  /// El escudo del club (raro, solo si falta alguna vida): +1 vida, máximo 3.
  escudo,

  /// −1 vida.
  tarjetaRoja,

  /// Dos atrapadas quitan 1 vida (el contador se reinicia al perder cualquier vida).
  tarjetaAmarilla,

  /// Cae más rápida y en diagonal, rebotando en las paredes. Atraparla quita 1 vida.
  bota,

  /// Atraparlo deja a Mutxigol quieto 2 segundos. No quita vida.
  silbato;

  /// Los objetos que hay que dejar caer.
  bool get esMalo => switch (this) {
    balonPinchado || tarjetaRoja || tarjetaAmarilla || bota => true,
    _ => false,
  };
}

/// Un objeto cayendo. [x] y [y] son su posición actual; los de deriva ([vx] distinto de 0) se mueven de lado.
class ObjetoCayendo {
  ObjetoCayendo(
    this.tipo,
    this.x,
    this.y,
    this.velocidad, {
    this.vx = 0,
    this.sentido = 1,
  }) : x0 = x;

  final TipoCaida tipo;
  double x;
  final double x0;
  double y;

  /// La velocidad de caída (unidades por segundo).
  final double velocidad;

  /// La velocidad lateral (la bota rebota con ella).
  double vx;

  /// Hacia qué lado curva el balón con efecto (1 o −1).
  final int sentido;

  /// Segundos que lleva cayendo.
  double edad = 0;
}

/// Atrapa balones: Mutxigol se mueve abajo, a izquierda y derecha (arrastrando el dedo), y atrapa lo que cae. Lo bueno
/// suma (balones, balón dorado, escudo del club) y lo malo hay que esquivar (balón pinchado, tarjetas, bota, silbato).
/// 3 vidas. La velocidad llega al máximo hacia el segundo 60 y, desde el 15 y el 30, caen tandas de 2 y de 3 objetos a
/// la vez (con al menos 0,6 s entre tandas).
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

  /// Los segundos en los que se llega a la velocidad máxima.
  static const double segundosHastaVelocidadMaxima = 60;

  /// Segundos entre una tanda y la siguiente: de 1,1 a 0,6 (nunca menos).
  static const double intervaloInicial = 1.1;
  static const double intervaloMinimo = 0.6;
  static const double reduccionIntervalo = 0.01;

  /// Desde estos segundos pueden caer 2 y 3 objetos a la vez.
  static const double segundosParaDos = 15;
  static const double segundosParaTres = 30;

  /// Los objetos malos empiezan hacia el segundo 6 y su frecuencia sube con el tiempo.
  static const double segundosSinMalos = 6;
  static const double probabilidadMaloInicial = 0.15;
  static const double subidaProbabilidadMalo = 0.006;
  static const double probabilidadMaloMaxima = 0.45;

  /// Probabilidades de lo bueno (por objeto): efecto, dorado (poco frecuente) y escudo (raro, solo si falta vida).
  static const double probabilidadEfecto = 0.2;
  static const double probabilidadDorado = 0.05;
  static const double probabilidadEscudo = 0.04;

  /// Lo que dura Mutxigol quieto tras atrapar el silbato.
  static const double segundosCongelado = 2;

  /// Cuántas tarjetas amarillas hacen perder una vida.
  static const int amarillasPorVida = 2;

  /// La bota cae más rápido y en diagonal.
  static const double factorVelocidadBota = 1.35;
  static const double velocidadLateralBota = 130;

  /// El balón con efecto: cuánto se desvía de lado y a qué ritmo.
  static const double amplitudEfecto = 60;
  static const double frecuenciaEfecto = 1.8;

  /// Separación mínima entre dos objetos de la misma tanda.
  static const double separacionEnTanda = 80;

  // ---- Estado ----

  double _x = LogicaJuego.ancho / 2;
  int _puntos = 0;
  int _vidas = vidasIniciales;
  int _amarillas = 0;
  double _congelado = 0;
  double _hastaLaSiguiente = 0.8;
  final List<ObjetoCayendo> _objetos = [];

  @override
  int get puntos => _puntos;

  @override
  int? get vidas => _vidas;

  @override
  bool get terminado => _vidas <= 0;

  /// Tarjetas amarillas atrapadas desde la última vida perdida (0 o 1).
  int get amarillas => _amarillas;

  /// Los segundos que le quedan a Mutxigol quieto (0 si se mueve).
  double get congeladoRestante => _congelado;

  bool get congelado => _congelado > 0;

  /// La posición horizontal (el centro) de Mutxigol.
  double get x => _x;

  /// La altura a la que se atrapa.
  double get yCaptura => alto - 110;

  /// La altura del suelo: un balón que llega aquí se pierde.
  double get suelo => alto - 70;

  List<ObjetoCayendo> get objetos => List.unmodifiable(_objetos);

  /// La velocidad de caída: sube de forma lineal y llega al máximo hacia el segundo 60.
  double get velocidadCaida => math.min(
    velocidadInicial +
        (velocidadMaxima - velocidadInicial) *
            (segundos / segundosHastaVelocidadMaxima),
    velocidadMaxima,
  );

  double get intervalo => math.max(
    intervaloInicial - reduccionIntervalo * segundos,
    intervaloMinimo,
  );

  /// Cuántos objetos puede soltar una tanda a los [segundos] de partida: 1, 2 (desde el 15) o 3 (desde el 30).
  static int tamanoMaximoDeTanda(double segundos) => segundos >= segundosParaTres
      ? 3
      : segundos >= segundosParaDos
      ? 2
      : 1;

  /// La probabilidad de que un objeto sea de los malos: 0 hasta el segundo 6 y luego sube hasta el 45 %.
  static double probabilidadDeMalo(double segundos) => segundos < segundosSinMalos
      ? 0
      : math.min(
          probabilidadMaloInicial +
              subidaProbabilidadMalo * (segundos - segundosSinMalos),
          probabilidadMaloMaxima,
        );

  /// Mueve a Mutxigol hasta [nuevaX] (dentro de los márgenes). Quieto, no se mueve.
  void moverA(double nuevaX) {
    if (terminado || congelado) return;

    _x = nuevaX.clamp(margen, LogicaJuego.ancho - margen).toDouble();
  }

  /// Suelta un objeto ya (la partida lo hace sola; los tests, para no depender del azar).
  @visibleForTesting
  ObjetoCayendo soltar(TipoCaida tipo, double x) {
    final objeto = switch (tipo) {
      TipoCaida.bota => ObjetoCayendo(
        tipo,
        x,
        -20,
        velocidadCaida * factorVelocidadBota,
        vx: x < LogicaJuego.ancho / 2
            ? velocidadLateralBota
            : -velocidadLateralBota,
      ),
      TipoCaida.balonEfecto => ObjetoCayendo(
        tipo,
        x,
        -20,
        velocidadCaida,
        sentido: _random.nextBool() ? 1 : -1,
      ),
      _ => ObjetoCayendo(tipo, x, -20, velocidadCaida),
    };

    _objetos.add(objeto);

    return objeto;
  }

  /// Suelta una tanda ya: 1 a 3 objetos según el tiempo de partida.
  @visibleForTesting
  void soltarTanda() {
    final maximo = tamanoMaximoDeTanda(segundos);
    final cuantos = maximo == 1 ? 1 : 1 + _random.nextInt(maximo);
    final xs = <double>[];

    for (var i = 0; i < cuantos; i++) {
      xs.add(_elegirX(xs));
      soltar(_elegirTipo(), xs.last);
    }
  }

  double _elegirX(List<double> ocupadas) {
    var x = margen;

    // Unos intentos para no soltar dos objetos casi en el mismo sitio.
    for (var i = 0; i < 6; i++) {
      x = margen + _random.nextDouble() * (LogicaJuego.ancho - 2 * margen);

      if (ocupadas.every((o) => (o - x).abs() >= separacionEnTanda)) break;
    }

    return x;
  }

  TipoCaida _elegirTipo() {
    if (_random.nextDouble() < probabilidadDeMalo(segundos)) {
      final r = _random.nextDouble();

      if (r < 0.30) return TipoCaida.balonPinchado;
      if (r < 0.50) return TipoCaida.tarjetaRoja;
      if (r < 0.75) return TipoCaida.tarjetaAmarilla;
      if (r < 0.90) return TipoCaida.bota;

      return TipoCaida.silbato;
    }

    final r = _random.nextDouble();

    if (_vidas < vidasIniciales && r < probabilidadEscudo) {
      return TipoCaida.escudo;
    }

    if (r < probabilidadEscudo + probabilidadDorado) return TipoCaida.balonDorado;
    if (r < probabilidadEscudo + probabilidadDorado + probabilidadEfecto) {
      return TipoCaida.balonEfecto;
    }

    return TipoCaida.balon;
  }

  @override
  void avanzar(Duration dt) {
    final s = LogicaJuego.segundosDe(dt);

    if (_congelado > 0) _congelado = math.max(0, _congelado - s);

    _hastaLaSiguiente -= s;

    if (soltarSolo && _hastaLaSiguiente <= 0) {
      _hastaLaSiguiente += intervalo;
      soltarTanda();
    }

    for (final objeto in List.of(_objetos)) {
      _mover(objeto, s);

      final enLaZonaDeCaptura =
          objeto.y >= yCaptura - 30 &&
          objeto.y <= yCaptura + 25 &&
          (objeto.x - _x).abs() <= mitadCaptura;

      if (enLaZonaDeCaptura) {
        _objetos.remove(objeto);
        _atrapar(objeto.tipo);
      } else if (objeto.y >= suelo) {
        _objetos.remove(objeto);

        // Solo los balones normales (y con efecto) quitan vida al llegar al suelo; lo demás se pierde sin castigo.
        if (objeto.tipo == TipoCaida.balon ||
            objeto.tipo == TipoCaida.balonEfecto) {
          _perderVida();
        }
      }

      if (terminado) return;
    }
  }

  void _mover(ObjetoCayendo objeto, double s) {
    objeto.edad += s;
    objeto.y += objeto.velocidad * s;

    switch (objeto.tipo) {
      case TipoCaida.balonEfecto:
        objeto.x =
            (objeto.x0 +
                    objeto.sentido *
                        amplitudEfecto *
                        math.sin(objeto.edad * frecuenciaEfecto))
                .clamp(margen / 2, LogicaJuego.ancho - margen / 2)
                .toDouble();
      case TipoCaida.bota:
        objeto.x += objeto.vx * s;

        // Rebota en las paredes.
        if (objeto.x < margen / 2) {
          objeto.x = margen / 2;
          objeto.vx = objeto.vx.abs();
        } else if (objeto.x > LogicaJuego.ancho - margen / 2) {
          objeto.x = LogicaJuego.ancho - margen / 2;
          objeto.vx = -objeto.vx.abs();
        }
      default:
        break;
    }
  }

  void _atrapar(TipoCaida tipo) {
    switch (tipo) {
      case TipoCaida.balon:
      case TipoCaida.balonEfecto:
        _sumar(1);
      case TipoCaida.balonDorado:
        _sumar(5);
      case TipoCaida.escudo:
        _vidas = math.min(vidasIniciales, _vidas + 1);
        alEvento?.call(EventoJuego.punto);
      case TipoCaida.balonPinchado:
      case TipoCaida.tarjetaRoja:
      case TipoCaida.bota:
        _perderVida();
      case TipoCaida.tarjetaAmarilla:
        _amarillas++;

        if (_amarillas >= amarillasPorVida) {
          _perderVida();
        } else {
          alEvento?.call(EventoJuego.fallo);
        }
      case TipoCaida.silbato:
        _congelado = segundosCongelado;
        alEvento?.call(EventoJuego.fallo);
    }
  }

  void _sumar(int cuantos) {
    _puntos += cuantos;
    alEvento?.call(EventoJuego.punto);
  }

  void _perderVida() {
    _vidas--;
    _amarillas = 0;
    alEvento?.call(EventoJuego.fallo);
  }
}
