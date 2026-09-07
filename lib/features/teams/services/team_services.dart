import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../models/player_model.dart';
import '../models/staff_model.dart';
import '../models/team_model.dart';

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
}
