import 'dart:math' as math;

import '../models/juego_modelos.dart';
import 'logica_juego.dart';

/// Cómo está una carta del tablero.
enum EstadoCarta { oculta, descubierta, emparejada }

/// Una carta: el escudo que lleva (el [indice] del club, igual en su pareja) y cómo está.
class CartaParejas {
  CartaParejas(this.posicion, this.escudo);

  /// El sitio en el tablero (0 a 15).
  final int posicion;
  final EscudoJuego escudo;
  EstadoCarta estado = EstadoCarta.oculta;
}

/// Parejas de escudos (memoria): tablero de 4×4 con 8 parejas. Se descubren las cartas de dos en dos: si son del mismo
/// club se quedan descubiertas; si no, se vuelven a girar a los 0,8 s. El cronómetro empieza con la primera carta y se
/// para con la última pareja. Se cuentan los intentos (cada par de cartas descubierto), solo como información.
///
/// La marca es el tiempo ([tiempoJugado]): los puntos son siempre [parejas] (8) al terminar.
class ParejasLogica extends LogicaJuego {
  /// [escudos] son los clubes del tablero (hacen falta al menos [parejas]; se usan los [parejas] primeros).
  ParejasLogica({
    required super.alto,
    required List<EscudoJuego> escudos,
    math.Random? random,
  }) {
    assert(escudos.length >= parejas, 'Hacen falta $parejas escudos');

    final elegidos = escudos.take(parejas).toList();
    final todas = [...elegidos, ...elegidos]..shuffle(random ?? math.Random());

    for (var i = 0; i < todas.length; i++) {
      _cartas.add(CartaParejas(i, todas[i]));
    }
  }

  static const int parejas = 8;
  static const int columnas = 4;
  static const int filas = 4;

  /// Lo que tarda en volver a girarse un par que no coincide.
  static const Duration tiempoDeError = Duration(milliseconds: 800);

  final List<CartaParejas> _cartas = [];

  Duration _cronometro = Duration.zero;
  bool _empezada = false;
  int _intentos = 0;
  int _encontradas = 0;
  final List<CartaParejas> _descubiertas = [];
  Duration _hastaVolverAGirar = Duration.zero;

  List<CartaParejas> get cartas => List.unmodifiable(_cartas);

  /// Los intentos hechos (pares de cartas descubiertos).
  int get intentos => _intentos;

  /// Las parejas encontradas.
  int get encontradas => _encontradas;

  /// true cuando se ha descubierto la primera carta: ahí empieza el cronómetro.
  bool get empezada => _empezada;

  /// Hay un par que no coincide esperando a girarse: no se puede tocar otra carta hasta entonces.
  bool get esperandoGiro => _hastaVolverAGirar > Duration.zero;

  /// El tiempo que marca el cronómetro (empieza con la primera carta; se para con la última pareja).
  @override
  Duration get tiempoJugado => _cronometro;

  /// Los puntos de la partida: 8 al completar el tablero (lo que acepta el backend); mientras, las parejas halladas.
  @override
  int get puntos => _encontradas;

  @override
  int? get vidas => null;

  @override
  bool get terminado => _encontradas >= parejas;

  /// Toca la carta [posicion]. Devuelve true si se ha descubierto (no si ya estaba descubierta, ya emparejada, el
  /// tablero espera a girar un par o la partida ha acabado).
  bool tocar(int posicion) {
    if (terminado || esperandoGiro) return false;
    if (posicion < 0 || posicion >= _cartas.length) return false;

    final carta = _cartas[posicion];

    if (carta.estado != EstadoCarta.oculta) return false;

    _empezada = true;
    carta.estado = EstadoCarta.descubierta;
    _descubiertas.add(carta);

    if (_descubiertas.length == 2) {
      _intentos++;

      final a = _descubiertas[0];
      final b = _descubiertas[1];

      if (a.escudo.id == b.escudo.id) {
        a.estado = EstadoCarta.emparejada;
        b.estado = EstadoCarta.emparejada;
        _encontradas++;
        _descubiertas.clear();
        alEvento?.call(EventoJuego.punto);
      } else {
        _hastaVolverAGirar = tiempoDeError;
        alEvento?.call(EventoJuego.fallo);
      }
    }

    return true;
  }

  @override
  void avanzar(Duration dt) {
    // El cronómetro no corre hasta la primera carta.
    if (!_empezada) return;

    _cronometro += dt;

    if (_hastaVolverAGirar > Duration.zero) {
      _hastaVolverAGirar -= dt;

      if (_hastaVolverAGirar <= Duration.zero) {
        _hastaVolverAGirar = Duration.zero;

        for (final carta in _descubiertas) {
          carta.estado = EstadoCarta.oculta;
        }

        _descubiertas.clear();
      }
    }
  }
}
