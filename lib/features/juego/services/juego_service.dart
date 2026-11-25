import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/juego_modelos.dart';

/// Las llamadas del juego de Mutxigol (docs/api-app-juego.md del backend). El ranking es público; el resto pide sesión.
/// Los errores son [ApiException] (con el mensaje del servidor y, en los conflictos, `datos['codigo']`).
class JuegoService {
  const JuegoService();

  /// El código de un 409 sin alias.
  static const String codigoAliasRequerido = 'ALIAS_REQUERIDO';

  /// El código de un 409 de alias repetido.
  static const String codigoAliasEnUso = 'ALIAS_EN_USO';

  /// En debug, anota en la consola el método, la ruta, el código y el cuerpo de la respuesta de una llamada del juego que
  /// falla, para ver la causa. Después el error sigue su camino.
  @visibleForTesting
  static Future<T> registrando<T>(
    String metodo,
    String ruta,
    Future<T> Function() llamada,
  ) async {
    try {
      return await llamada();
    } catch (e) {
      if (kDebugMode) {
        if (e is ApiException) {
          debugPrint(
            '[juego] $metodo $ruta -> ${e.statusCode ?? "sin respuesta"} '
            '${e.datos ?? e.message}',
          );
        } else {
          debugPrint('[juego] $metodo $ruta -> sin respuesta ($e)');
        }
      }

      rethrow;
    }
  }

  /// GET /public/juego/ranking: los 50 mejores (sin sesión).
  Future<List<FilaRanking>> ranking(Juego juego, PeriodoRanking periodo) async {
    final ruta =
        '/public/juego/ranking?juego=${juego.codigo}&periodo=${periodo.codigo}';
    final datos = await registrando('GET', ruta, () => ApiClient.get(ruta));

    return (datos as List)
        .map(
          (f) => FilaRanking.fromJson(
            Map<String, dynamic>.from(f as Map),
            tiempoPorDefecto: juego.esDeTiempo,
          ),
        )
        .toList();
  }

  /// GET /public/juego/escudos?cantidad=: clubes con escudo, al azar, para las cartas de Parejas (sin sesión).
  Future<List<EscudoJuego>> escudos({int cantidad = 8}) async {
    final ruta = '/public/juego/escudos?cantidad=$cantidad';
    final datos = await registrando('GET', ruta, () => ApiClient.get(ruta));

    return (datos as List)
        .map((e) => EscudoJuego.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /app/juego/perfil.
  Future<PerfilJuego> perfil() async {
    final datos = await registrando(
      'GET',
      '/app/juego/perfil',
      () => ApiClient.get('/app/juego/perfil', autenticado: true),
    );

    return PerfilJuego.fromJson(Map<String, dynamic>.from(datos as Map));
  }

  /// PUT /app/juego/perfil: alias y/o equipación (al menos uno). 400 con el motivo si el alias no vale; 409 si está en
  /// uso.
  Future<PerfilJuego> actualizarPerfil({
    String? alias,
    Equipacion? equipacion,
  }) async {
    final datos = await registrando(
      'PUT',
      '/app/juego/perfil',
      () => ApiClient.put(
        '/app/juego/perfil',
        body: {'alias': ?alias, 'equipacion': ?equipacion?.codigo},
        autenticado: true,
      ),
    );

    return PerfilJuego.fromJson(Map<String, dynamic>.from(datos as Map));
  }

  /// POST /app/juego/puntuacion.
  Future<ResultadoPuntuacion> guardarPuntuacion({
    required Juego juego,
    required int puntos,
    required int duracionMs,
  }) async {
    final datos = await registrando(
      'POST',
      '/app/juego/puntuacion',
      () => ApiClient.post(
        '/app/juego/puntuacion',
        body: {
          'juego': juego.codigo,
          'puntos': puntos,
          'duracionMs': duracionMs,
        },
        autenticado: true,
      ),
    );

    return ResultadoPuntuacion.fromJson(
      Map<String, dynamic>.from(datos as Map),
    );
  }

  // ---- Moderación (solo ADMIN_APP) ----

  /// GET /app/admin/juego/perfiles?alias=
  Future<List<PerfilJuegoAdmin>> listarPerfiles({String? alias}) async {
    final filtro = alias == null || alias.trim().isEmpty
        ? ''
        : '?alias=${Uri.encodeQueryComponent(alias.trim())}';

    final datos = await ApiClient.get(
      '/app/admin/juego/perfiles$filtro',
      autenticado: true,
    );

    return (datos as List)
        .map(
          (p) => PerfilJuegoAdmin.fromJson(Map<String, dynamic>.from(p as Map)),
        )
        .toList();
  }

  /// GET /app/admin/juego/perfiles/{id}/puntuaciones: las últimas partidas.
  Future<List<PuntuacionAdmin>> puntuacionesDe(int usuarioId) async {
    final datos = await ApiClient.get(
      '/app/admin/juego/perfiles/$usuarioId/puntuaciones',
      autenticado: true,
    );

    return (datos as List)
        .map(
          (p) => PuntuacionAdmin.fromJson(Map<String, dynamic>.from(p as Map)),
        )
        .toList();
  }

  /// PUT /app/admin/juego/perfiles/{id}/alias
  Future<void> cambiarAlias(int usuarioId, String alias) async {
    await ApiClient.put(
      '/app/admin/juego/perfiles/$usuarioId/alias',
      body: {'alias': alias},
      autenticado: true,
    );
  }

  /// PUT /app/admin/juego/perfiles/{id}/oculto
  Future<void> ocultar(int usuarioId, {required bool oculto}) async {
    await ApiClient.put(
      '/app/admin/juego/perfiles/$usuarioId/oculto',
      body: {'oculto': oculto},
      autenticado: true,
    );
  }

  /// DELETE /app/admin/juego/puntuaciones/{id}
  Future<void> borrarPuntuacion(int puntuacionId) async {
    await ApiClient.delete(
      '/app/admin/juego/puntuaciones/$puntuacionId',
      autenticado: true,
    );
  }

  /// DELETE /app/admin/juego/perfiles/{id}/puntuaciones: todas las del perfil.
  Future<void> borrarTodas(int usuarioId) async {
    await ApiClient.delete(
      '/app/admin/juego/perfiles/$usuarioId/puntuaciones',
      autenticado: true,
    );
  }
}
