import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'logica_juego.dart';

/// Lo que hay en el campo de Regatea.
enum TipoPista {
  /// Obstáculo: −1 vida (con 1 s de invulnerabilidad).
  defensa,

  /// Obstáculo: −1 vida (con 1 s de invulnerabilidad).
  cono,

  /// Obstáculo: frena 1,5 s, no quita vida.
  charco,

  /// +1.
  balon,

  /// +5.
  balonDorado;

  bool get esObstaculo => this == defensa || this == cono || this == charco;
}

/// Un objeto en el campo: en qué carril y a cuánta [distancia] delante de Mutxigol (0 es donde está él).
class ObjetoPista {
  ObjetoPista(this.tipo, this.carril, this.distancia);

  final TipoPista tipo;
  final int carril;
  double distancia;

  /// Ya se ha cruzado con él (para no contarlo dos veces).
  bool resuelto = false;
}

/// Regatea: carrera infinita. Mutxigol corre de espaldas por un campo de 3 carriles; se desliza a izquierda o derecha
/// para cambiar de carril, esquivando defensas, conos y charcos y recogiendo balones. Cada obstáculo superado suma 1, un
/// balón 1 y un balón dorado 5. 3 vidas. La velocidad sube poco a poco. Nunca se bloquean los 3 carriles de una fila.
class RegateaLogica extends LogicaJuego {
  /// [generarSolo] false deja de generar filas por su cuenta (los tests colocan los objetos con [colocar]).
  RegateaLogica({
    required super.alto,
    math.Random? random,
    this.generarSolo = true,
  }) : _random = random ?? math.Random();

  final bool generarSolo;

  final math.Random _random;

  // ---- Reglas ----

  static const int carriles = 3;
  static const int vidasIniciales = 3;

  /// Lo que dura el cambio de carril.
  static const double segundosCambioCarril = 0.15;

  /// Invulnerabilidad tras un golpe y lo que frena un charco.
  static const double segundosInvulnerable = 1;
  static const double segundosFrenado = 1.5;
  static const double factorFrenado = 0.5;

  /// La velocidad (unidades de distancia por segundo): 300 al empezar y +6 por segundo hasta 700.
  static const double velocidadInicial = 300;
  static const double velocidadMaxima = 700;
  static const double aceleracion = 6;

  /// Lo lejos que aparecen los objetos (el horizonte).
  static const double horizonte = 1400;

  /// La separación entre filas: nunca menos de 520 ni de 0,85 de la velocidad (ritmo de puntos que acepta el backend).
  static const double separacionMinima = 520;

  /// Los obstáculos que cruzan a Mutxigol a menos de esto del centro de su carril le dan.
  static const double toleranciaDeCarril = 0.5;

  /// Las imágenes por segundo de correr a la velocidad inicial (sube con la velocidad).
  static const double imagenesPorSegundo = 8;

  /// El orden de las imágenes de correr: 1, 2, 3, 2.
  static const List<int> secuenciaDeCarrera = [0, 1, 2, 1];

  // ---- Estado ----

  int _carril = 1;
  double _posicionCarril = 1;
  int _puntos = 0;
  int _vidas = vidasIniciales;
  double _invulnerable = 0;
  double _frenado = 0;
  double _distanciaDesdeFila = 0;
  double _faseCarrera = 0;
  double _recorrido = 0;
  final List<ObjetoPista> _objetos = [];

  @override
  int get puntos => _puntos;

  @override
  int? get vidas => _vidas;

  @override
  bool get terminado => _vidas <= 0;

  /// El carril al que va Mutxigol (0 izquierda, 1 centro, 2 derecha).
  int get carril => _carril;

  /// El carril con la transición: de 0 a 2 con decimales mientras se mueve.
  double get posicionCarril => _posicionCarril;

  bool get invulnerable => _invulnerable > 0;
  double get invulnerableRestante => _invulnerable;
  bool get frenado => _frenado > 0;

  /// Lo que ha corrido (para mover las franjas del césped).
  double get recorrido => _recorrido;

  List<ObjetoPista> get objetos => List.unmodifiable(_objetos);

  double get velocidadBase =>
      math.min(velocidadInicial + aceleracion * segundos, velocidadMaxima);

  /// La velocidad de ahora (a la mitad mientras frena un charco).
  double get velocidad => velocidadBase * (frenado ? factorFrenado : 1);

  /// Qué imagen de correr toca (0, 1 o 2 → corriendo_1, _2, _3).
  int get cuadroDeCarrera =>
      secuenciaDeCarrera[_faseCarrera.floor() % secuenciaDeCarrera.length];

  /// Cambia de carril: [direccion] −1 a la izquierda, 1 a la derecha. No sale del campo.
  void cambiarCarril(int direccion) {
    if (terminado || direccion == 0) return;

    _carril = (_carril + direccion.sign).clamp(0, carriles - 1);
  }

  /// Pone un objeto a [distancia] de Mutxigol (los tests; la partida genera filas sola).
  @visibleForTesting
  ObjetoPista colocar(TipoPista tipo, int carril, double distancia) {
    final objeto = ObjetoPista(tipo, carril, distancia);

    _objetos.add(objeto);

    return objeto;
  }

  /// Genera una fila a lo lejos (de 1 a 2 carriles con obstáculo, nunca los 3).
  @visibleForTesting
  void soltarFila() {
    final dosObstaculos = segundos > 10 && _random.nextDouble() < 0.35;
    final cuantos = dosObstaculos ? 2 : 1;
    final libres = [0, 1, 2];
    final bloqueados = <int>[];

    for (var i = 0; i < cuantos; i++) {
      bloqueados.add(libres.removeAt(_random.nextInt(libres.length)));
    }

    for (final carril in bloqueados) {
      final r = _random.nextDouble();
      final tipo = r < 0.25
          ? TipoPista.charco
          : r < 0.65
          ? TipoPista.defensa
          : TipoPista.cono;

      _objetos.add(ObjetoPista(tipo, carril, horizonte));
    }

    // En los carriles libres, a veces un balón (y de vez en cuando uno dorado).
    for (final carril in libres) {
      final r = _random.nextDouble();

      if (r < 0.06) {
        _objetos.add(ObjetoPista(TipoPista.balonDorado, carril, horizonte));
      } else if (r < 0.50) {
        _objetos.add(ObjetoPista(TipoPista.balon, carril, horizonte));
      }
    }
  }

  @override
  void avanzar(Duration dt) {
    final s = LogicaJuego.segundosDe(dt);

    if (_invulnerable > 0) _invulnerable = math.max(0, _invulnerable - s);
    if (_frenado > 0) _frenado = math.max(0, _frenado - s);

    // La transición suave entre carriles.
    final paso = s / segundosCambioCarril;
    final dif = _carril - _posicionCarril;

    _posicionCarril = dif.abs() <= paso ? _carril.toDouble() : _posicionCarril + paso * dif.sign;

    final v = velocidad;
    final avance = v * s;

    _recorrido += avance;

    _faseCarrera += s * imagenesPorSegundo * (velocidadBase / velocidadInicial);

    if (generarSolo) {
      _distanciaDesdeFila += avance;

      if (_distanciaDesdeFila >= math.max(separacionMinima, 0.85 * velocidadBase)) {
        _distanciaDesdeFila = 0;
        soltarFila();
      }
    }

    for (final objeto in List.of(_objetos)) {
      final antes = objeto.distancia;

      objeto.distancia -= avance;

      if (!objeto.resuelto && antes > 0 && objeto.distancia <= 0) {
        objeto.resuelto = true;
        _cruzar(objeto);
      }

      // Ya pasó de largo.
      if (objeto.distancia < -200) _objetos.remove(objeto);

      if (terminado) return;
    }
  }

  void _cruzar(ObjetoPista objeto) {
    final enSuCarril =
        (objeto.carril - _posicionCarril).abs() <= toleranciaDeCarril;

    if (!objeto.tipo.esObstaculo) {
      if (enSuCarril) {
        _puntos += objeto.tipo == TipoPista.balonDorado ? 5 : 1;
        alEvento?.call(EventoJuego.punto);
      }

      return;
    }

    if (!enSuCarril) {
      // Obstáculo superado.
      _puntos++;
      alEvento?.call(EventoJuego.punto);

      return;
    }

    if (objeto.tipo == TipoPista.charco) {
      _frenado = segundosFrenado;
      alEvento?.call(EventoJuego.fallo);

      return;
    }

    // Defensa o cono: una vida, salvo durante la invulnerabilidad.
    if (_invulnerable > 0) return;

    _vidas--;
    _invulnerable = segundosInvulnerable;
    alEvento?.call(EventoJuego.fallo);
  }
}
