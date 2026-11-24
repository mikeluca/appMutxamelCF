/// Qué ha pasado en la partida (para la vibración ligera de la vista).
enum EventoJuego { punto, fallo }

/// La base de la lógica de un minijuego: sin widgets ni reloj propio. El tiempo avanza solo cuando alguien llama a
/// [tick] con el tiempo transcurrido (la vista lo hace en cada fotograma del Ticker; los tests, con el tiempo que
/// quieran), así que la lógica se puede probar con un reloj falso. El campo mide siempre [ancho] unidades de ancho
/// (la vista lo escala al tamaño real de la pantalla) y [alto] de alto.
abstract class LogicaJuego {
  /// El ancho del campo en unidades de juego.
  static const double ancho = 360;

  LogicaJuego({required this.alto});

  /// El alto del campo en unidades de juego (según la proporción de la pantalla).
  final double alto;

  /// La vista se entera aquí de los puntos y los fallos (vibración).
  void Function(EventoJuego evento)? alEvento;

  Duration _tiempoJugado = Duration.zero;

  /// El tiempo jugado de verdad (sin la cuenta atrás ni las pausas): es la duración que se envía al backend.
  Duration get tiempoJugado => _tiempoJugado;

  int get puntos;

  /// Las vidas que quedan; null si el juego no tiene vidas (Toques).
  int? get vidas;

  bool get terminado;

  /// Avanza el juego [dt] (no hace nada si ya ha terminado).
  void tick(Duration dt) {
    if (terminado || dt <= Duration.zero) return;

    _tiempoJugado += dt;
    avanzar(dt);
  }

  /// Los segundos que lleva la partida.
  double get segundos => _tiempoJugado.inMicroseconds / 1e6;

  void avanzar(Duration dt);

  /// Los segundos de [dt].
  static double segundosDe(Duration dt) => dt.inMicroseconds / 1e6;
}
