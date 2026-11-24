import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import 'models/juego_modelos.dart';
import 'services/juego_service.dart';

/// En qué punto está el envío de la puntuación al acabar la partida.
enum EstadoEnvio {
  /// Nada que enviar (0 puntos).
  noAplica,

  /// Sin sesión: no se guarda; se le dice que inicie sesión en el Área Club.
  sinSesion,

  /// Con sesión pero sin alias: se le pide el alias (y se envía al elegirlo).
  sinAlias,

  enviando,

  /// Enviada: el [EnvioPuntuacion.resultado] trae los récords y la posición.
  enviado,

  /// Falló (red o servidor): se puede reintentar. No hay cola en el móvil.
  error,
}

/// Envía la puntuación de una partida acabada (POST /api/app/juego/puntuacion) y lleva el estado que enseña el fin de
/// partida. Sin cola ni almacenamiento: si falla, el botón de reintentar la manda otra vez.
class EnvioPuntuacion extends ChangeNotifier {
  EnvioPuntuacion({
    required this.servicio,
    required this.juego,
    required this.puntos,
    required Duration duracion,
    required this.conSesion,
    required String? alias,
  }) : _alias = alias,
       duracionMs = math.max(duracion.inMilliseconds, duracionMinimaMs);

  /// El backend no acepta partidas de menos de 3 segundos.
  static const int duracionMinimaMs = 3000;

  final JuegoService servicio;
  final Juego juego;
  final int puntos;
  final int duracionMs;
  final bool conSesion;

  String? _alias;
  EstadoEnvio _estado = EstadoEnvio.noAplica;
  ResultadoPuntuacion? _resultado;
  String? _mensajeError;
  bool _descartado = false;

  EstadoEnvio get estado => _estado;

  /// La respuesta del backend cuando el estado es [EstadoEnvio.enviado].
  ResultadoPuntuacion? get resultado => _resultado;

  /// El motivo del error cuando el servidor lo ha explicado (null: fallo de conexión).
  String? get mensajeError => _mensajeError;

  /// Decide qué hacer con la puntuación y, si toca, la envía.
  Future<void> iniciar() async {
    if (puntos <= 0) {
      return _cambiar(EstadoEnvio.noAplica);
    }

    if (!conSesion) {
      return _cambiar(EstadoEnvio.sinSesion);
    }

    if (_alias == null || _alias!.trim().isEmpty) {
      return _cambiar(EstadoEnvio.sinAlias);
    }

    await _enviar();
  }

  /// El botón de reintentar tras un error.
  Future<void> reintentar() => _enviar();

  /// Ya hay alias (lo ha elegido en el diálogo): se envía la puntuación.
  Future<void> aliasElegido(String alias) {
    _alias = alias;

    return _enviar();
  }

  Future<void> _enviar() async {
    _cambiar(EstadoEnvio.enviando);

    try {
      final resultado = await servicio.guardarPuntuacion(
        juego: juego,
        puntos: puntos,
        duracionMs: duracionMs,
      );

      _resultado = resultado;
      _mensajeError = null;
      _cambiar(EstadoEnvio.enviado);
    } on ApiException catch (e) {
      final datos = e.datos;

      if (e.statusCode == 409 &&
          datos is Map &&
          datos['codigo'] == JuegoService.codigoAliasRequerido) {
        _alias = null;
        _cambiar(EstadoEnvio.sinAlias);

        return;
      }

      // Un 4xx del juego trae el motivo (límite de envíos...); el resto es un fallo de conexión.
      final codigo = e.statusCode;

      _mensajeError =
          codigo != null && codigo >= 400 && codigo < 500 && codigo != 403
          ? e.message
          : null;
      _cambiar(EstadoEnvio.error);
    } catch (_) {
      _mensajeError = null;
      _cambiar(EstadoEnvio.error);
    }
  }

  void _cambiar(EstadoEnvio estado) {
    _estado = estado;

    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
