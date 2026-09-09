import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../models/player_model.dart';
import '../models/staff_model.dart';
import '../models/team_model.dart';
import '../../auth/services/auth_session.dart';
import '../models/familiar_jugador_model.dart';

class TeamService {
  Future<List<TeamModel>> obtenerEquipos() async {
    final url = Uri.parse('${ApiClient.baseUrl}/public/equipos');

    final response = await http.get(url, headers: ApiClient.jsonHeaders);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener los equipos: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => TeamModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TeamModel?> obtenerEquipo(int id) async {
    final url = Uri.parse('${ApiClient.baseUrl}/public/equipos/$id');

    final response = await http.get(url, headers: ApiClient.jsonHeaders);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener el equipo: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    return TeamModel.fromJson(data);
  }

  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/public/equipos/'
      '$equipoId/jugadores',
    );

    final response = await http.get(url, headers: ApiClient.jsonHeaders);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener los jugadores: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => PlayerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<StaffModel>> obtenerCuerpoTecnico(int equipoId) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/public/equipos/'
      '$equipoId/cuerpo-tecnico',
    );

    final response = await http.get(url, headers: ApiClient.jsonHeaders);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener el cuerpo técnico: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => StaffModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlayerModel>> obtenerJugadoresGestion(int equipoId) async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión autenticada');
    }

    final url = Uri.parse(
      '${ApiClient.baseUrl}/app/equipos/jugadores?equipoId=$equipoId',
    );

    final response = await http.get(
      url,
      headers: {...ApiClient.jsonHeaders, 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      throw Exception('Sesión no válida o expirada');
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para gestionar este equipo');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener los jugadores del equipo: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => PlayerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<FamiliarJugadorModel>> obtenerFamiliaresJugador({
    required int equipoId,
    required int jugadorId,
  }) async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión autenticada');
    }

    final url = Uri.parse(
      '${ApiClient.baseUrl}/app/equipos/'
      'jugadores/$jugadorId/familiares'
      '?equipoId=$equipoId',
    );

    final response = await http.get(
      url,
      headers: {...ApiClient.jsonHeaders, 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      throw Exception('Sesión no válida o expirada');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permiso para consultar los familiares de este jugador',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener los familiares: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map(
          (json) => FamiliarJugadorModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }
}
