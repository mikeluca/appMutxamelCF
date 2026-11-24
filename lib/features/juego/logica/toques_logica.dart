import 'dart:math' as math;
import 'dart:ui';

import 'logica_juego.dart';

/// Toques: el balón cae con gravedad; al tocarlo sube y sale hacia un lado según dónde lo toques (si lo tocas a la
/// izquierda de su centro, va a la derecha), y rebota en las paredes laterales. 1 punto por toque; si toca el suelo,
/// se acaba. La gravedad aumenta poco a poco.
class ToquesLogica extends LogicaJuego {
  ToquesLogica({required super.alto});

  // ---- Reglas (unidades de juego) ----

  static const double radioBalon = 32;

  /// El toque vale si cae a esta distancia del centro del balón (un poco más que el balón, para dedos gordos).
  static const double radioToque = radioBalon * 1.8;

  static const double gravedadInicial = 900;
  static const double gravedadMaxima = 1700;

  /// Cuánto sube la gravedad por segundo jugado.
  static const double gravedadPorSegundo = 15;

  /// Hasta dónde sube el balón con cada toque (se calcula la velocidad para que sea siempre la misma altura).
  static const double alturaToque = 250;

  /// La velocidad lateral máxima que da un toque.
  static const double empujeLateral = 300;

  /// Entre dos toques que cuentan pasa al menos esto (5,5 por segundo como mucho, dentro del ritmo que acepta el
  /// backend).
  static const double separacionMinimaToques = 0.18;

  /// Cuánta velocidad conserva el balón al rebotar en una pared.
  static const double rebote = 0.9;

  // ---- Estado ----

  Offset _posicion = const Offset(LogicaJuego.ancho / 2, 150);
  Offset _velocidad = Offset.zero;
  int _puntos = 0;
  bool _terminado = false;
  double _ultimoToque = -1;

  @override
  int get puntos => _puntos;

  @override
  int? get vidas => null;

  @override
  bool get terminado => _terminado;

  /// El centro del balón.
  Offset get balon => _posicion;

  Offset get velocidad => _velocidad;

  /// La altura del suelo (donde pisa Mutxigol): si el balón llega aquí, se acaba.
  double get suelo => alto - 90;

  double get gravedad => math.min(
    gravedadInicial + gravedadPorSegundo * segundos,
    gravedadMaxima,
  );

  /// Un toque en [punto]. Devuelve true si ha dado al balón y cuenta.
  bool tocar(Offset punto) {
    if (_terminado) return false;

    if ((punto - _posicion).distance > radioToque) return false;

    if (_ultimoToque >= 0 && segundos - _ultimoToque < separacionMinimaToques) {
      return false;
    }

    _ultimoToque = segundos;

    final lateral = ((_posicion.dx - punto.dx) / radioToque).clamp(-1.0, 1.0);

    _velocidad = Offset(
      lateral * empujeLateral,
      -math.sqrt(2 * gravedad * alturaToque),
    );

    _puntos++;
    alEvento?.call(EventoJuego.punto);

    return true;
  }

  @override
  void avanzar(Duration dt) {
    final s = LogicaJuego.segundosDe(dt);

    _velocidad = Offset(_velocidad.dx, _velocidad.dy + gravedad * s);

    var x = _posicion.dx + _velocidad.dx * s;
    var y = _posicion.dy + _velocidad.dy * s;
    var vx = _velocidad.dx;
    var vy = _velocidad.dy;

    if (x < radioBalon) {
      x = radioBalon;
      vx = vx.abs() * rebote;
    } else if (x > LogicaJuego.ancho - radioBalon) {
      x = LogicaJuego.ancho - radioBalon;
      vx = -vx.abs() * rebote;
    }

    if (y < radioBalon) {
      y = radioBalon;
      vy = vy.abs() * 0.5;
    }

    _posicion = Offset(x, y);
    _velocidad = Offset(vx, vy);

    if (y + radioBalon >= suelo) {
      _terminado = true;
      alEvento?.call(EventoJuego.fallo);
    }
  }
}
