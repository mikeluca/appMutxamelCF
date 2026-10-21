import '../../../core/network/api_client.dart';
import '../models/player_model.dart';
import '../models/standings_model.dart';
import '../models/team_model.dart';
import '../models/familiar_jugador_model.dart';

class TeamService {
  Future<List<TeamModel>> obtenerEquipos() async {
    final data = await ApiClient.get('/public/equipos') as List<dynamic>;

    return data
        .map((json) => TeamModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async {
    final data = await ApiClient.get(
      '/public/equipos/$equipoId/jugadores',
    ) as List<dynamic>;

    return data
        .map((json) => PlayerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Clasificación del grupo del equipo, o null si todavía no hay datos (404).
  Future<StandingsModel?> obtenerClasificacion(int equipoId) async {
    try {
      final data = await ApiClient.get('/public/equipos/$equipoId/clasificacion');

      return StandingsModel.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  Future<List<PlayerModel>> obtenerJugadoresGestion(int equipoId) async {
    try {
      final data = await ApiClient.get(
        '/app/equipos/jugadores?equipoId=$equipoId',
        autenticado: true,
      ) as List<dynamic>;

      return data
          .map((json) => PlayerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw Exception('No tienes permiso para gestionar este equipo');
      }

      rethrow;
    }
  }

  Future<List<FamiliarJugadorModel>> obtenerFamiliaresJugador({
    required int equipoId,
    required int jugadorId,
  }) async {
    try {
      final data = await ApiClient.get(
        '/app/equipos/jugadores/$jugadorId/familiares?equipoId=$equipoId',
        autenticado: true,
      ) as List<dynamic>;

      return data
          .map(
            (json) =>
                FamiliarJugadorModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw Exception(
          'No tienes permiso para consultar los familiares de este jugador',
        );
      }

      rethrow;
    }
  }
}
