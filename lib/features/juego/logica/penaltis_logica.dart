import 'dart:math' as math;
import 'dart:ui';

import 'logica_juego.dart';

/// En qué momento del penalti estamos.
enum FasePenalti { apuntando, disparo, resultado }

/// Cómo ha acabado un tiro.
enum ResultadoTiro { gol, parada, flojo, fuera }

/// Penaltis: Mutxigol es el portero y tú tiras deslizando el dedo desde el balón hacia la portería. La dirección y la
/// fuerza del deslizamiento eligen una de las 6 zonas de la portería (3 columnas × 2 alturas); un tiro flojo o fuera de
/// la portería es fallo. El portero elige zona al azar y cada vez acierta más (de un 20 % a un 60 %). 1 punto por gol y
/// 3 vidas (un fallo o una parada quita una).
class PenaltisLogica extends LogicaJuego {
  PenaltisLogica({required super.alto, math.Random? random})
    : _random = random ?? math.Random();

  final math.Random _random;

  // ---- Reglas (unidades de juego) ----

  static const int vidasIniciales = 3;

  /// La portería: 3 columnas × 2 alturas.
  static const Rect porteria = Rect.fromLTRB(50, 130, 310, 270);
  static const int columnas = 3;
  static const int alturas = 2;

  /// El gesto solo empieza si el dedo toca el balón (a esta distancia como mucho).
  static const double radioInicioGesto = 70;

  /// Por debajo de esta longitud el tiro es flojo; por encima de la máxima no se nota más fuerza.
  static const double longitudMinima = 60;
  static const double longitudMaxima = 220;

  /// Cuánto se alarga el deslizamiento hasta el punto al que va el balón.
  static const double alcance = 4;

  /// La probabilidad de que el portero acierte la zona: empieza en el 20 % y sube un 2,5 % por tiro hasta el 60 %.
  static const double paradaInicial = 0.2;
  static const double paradaMaxima = 0.6;
  static const double paradaPorTiro = 0.025;

  /// Lo que dura el balón en el aire y lo que se queda el resultado en pantalla. Juntos son 1,35 s por tiro, que
  /// respeta el ritmo máximo de goles que acepta el backend.
  static const Duration duracionDisparo = Duration(milliseconds: 450);
  static const Duration duracionResultado = Duration(milliseconds: 900);

  // ---- Estado ----

  FasePenalti _fase = FasePenalti.apuntando;
  int _puntos = 0;
  int _vidas = vidasIniciales;
  int _tiros = 0;
  bool _terminado = false;

  Duration _enFase = Duration.zero;

  Offset _destino = Offset.zero;
  ResultadoTiro? _resultado;
  int? _zonaTiro;
  int _zonaPortero = 0;

  @override
  int get puntos => _puntos;

  @override
  int? get vidas => _vidas;

  @override
  bool get terminado => _terminado;

  FasePenalti get fase => _fase;

  /// El resultado del último tiro (null antes del primero).
  ResultadoTiro? get resultado => _resultado;

  /// La zona (0-5; fila × 3 + columna, la fila 0 es la de arriba) a la que ha ido el último tiro, si fue a la portería.
  int? get zonaTiro => _zonaTiro;

  /// La zona a la que se ha tirado el portero en el último tiro.
  int get zonaPortero => _zonaPortero;

  /// Los tiros que se han hecho.
  int get tiros => _tiros;

  /// Donde espera el balón.
  Offset get balonReposo => Offset(LogicaJuego.ancho / 2, alto - 150);

  /// Hacia dónde va el último tiro.
  Offset get destino => _destino;

  /// La probabilidad con la que el portero acertará la zona del próximo tiro.
  double get probabilidadParada =>
      math.min(paradaMaxima, paradaInicial + paradaPorTiro * _tiros);

  /// 0 al soltar el balón y 1 al llegar a su destino.
  double get progresoVuelo => _fase == FasePenalti.apuntando
      ? 0
      : _fase == FasePenalti.disparo
      ? (_enFase.inMicroseconds / duracionDisparo.inMicroseconds).clamp(0, 1)
      : 1;

  /// Dónde está el balón ahora.
  Offset get balon {
    final p = 1 - (1 - progresoVuelo) * (1 - progresoVuelo);

    return Offset.lerp(balonReposo, _destino, p)!;
  }

  /// El centro de una zona de la portería.
  static Offset centroDeZona(int zona) {
    final columna = zona % columnas;
    final fila = zona ~/ columnas;

    return Offset(
      porteria.left + porteria.width / columnas * (columna + 0.5),
      porteria.top + porteria.height / alturas * (fila + 0.5),
    );
  }

  /// La zona de un punto de la portería (null si está fuera).
  static int? zonaDe(Offset punto) {
    if (!porteria.contains(punto)) return null;

    final columna = ((punto.dx - porteria.left) / (porteria.width / columnas))
        .floor()
        .clamp(0, columnas - 1);
    final fila = ((punto.dy - porteria.top) / (porteria.height / alturas))
        .floor()
        .clamp(0, alturas - 1);

    return fila * columnas + columna;
  }

  /// Un deslizamiento del dedo de [inicio] a [fin]. Devuelve true si es un tiro (empieza en el balón y se puede tirar
  /// ahora); false si se ignora.
  bool disparar(Offset inicio, Offset fin) {
    if (_terminado || _fase != FasePenalti.apuntando) return false;

    if ((inicio - balonReposo).distance > radioInicioGesto) return false;

    var gesto = fin - inicio;
    final longitud = gesto.distance;

    if (longitud > longitudMaxima) {
      gesto = gesto * (longitudMaxima / longitud);
    }

    _destino = balonReposo + gesto * alcance;
    _tiros++;

    final haciaArriba = gesto.dy < 0;

    if (longitud < longitudMinima || !haciaArriba || _destino.dy > porteria.bottom) {
      _resultado = ResultadoTiro.flojo;
      _zonaTiro = null;
      _zonaPortero = _random.nextInt(columnas * alturas);
    } else {
      final zona = zonaDe(_destino);

      if (zona == null) {
        _resultado = ResultadoTiro.fuera;
        _zonaTiro = null;
        _zonaPortero = _random.nextInt(columnas * alturas);
      } else {
        _zonaTiro = zona;
        // La probabilidad es la del tiro que se acaba de hacer (la de antes de contarlo).
        final acierta =
            _random.nextDouble() <
            math.min(paradaMaxima, paradaInicial + paradaPorTiro * (_tiros - 1));

        if (acierta) {
          _zonaPortero = zona;
          _resultado = ResultadoTiro.parada;
        } else {
          final otra = _random.nextInt(columnas * alturas - 1);
          _zonaPortero = otra >= zona ? otra + 1 : otra;
          _resultado = ResultadoTiro.gol;
        }
      }
    }

    _fase = FasePenalti.disparo;
    _enFase = Duration.zero;

    return true;
  }

  @override
  void avanzar(Duration dt) {
    _enFase += dt;

    if (_fase == FasePenalti.disparo && _enFase >= duracionDisparo) {
      _enFase -= duracionDisparo;
      _fase = FasePenalti.resultado;
      _cerrarTiro();
    }

    if (_fase == FasePenalti.resultado && _enFase >= duracionResultado) {
      _enFase = Duration.zero;
      _fase = FasePenalti.apuntando;

      if (_vidas <= 0) _terminado = true;
    }
  }

  void _cerrarTiro() {
    if (_resultado == ResultadoTiro.gol) {
      _puntos++;
      alEvento?.call(EventoJuego.punto);
    } else {
      _vidas--;
      alEvento?.call(EventoJuego.fallo);
    }
  }
}
