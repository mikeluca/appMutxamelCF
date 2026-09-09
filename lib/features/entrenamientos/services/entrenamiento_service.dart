import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_session.dart';
import '../model/entrenamiento_model.dart';

class EntrenamientoService {
  Future<List<EntrenamientoModel>> obtenerPorEquipo(int equipoId) async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/entrenamientos?equipoId=$equipoId',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener los entrenamientos: '
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map(
          (item) => EntrenamientoModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<EntrenamientoModel> crear({
    required int equipoId,
    required String fecha,
    required Map<int, String> asistencias,
  }) async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/app/entrenamientos');

    final body = {
      'equipoId': equipoId,
      'fecha': fecha,
      'asistencias': asistencias.entries
          .map((entry) => {'jugadorId': entry.key, 'estado': entry.value})
          .toList(),
    };

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al crear el entrenamiento: '
        '${response.statusCode} ${response.body}',
      );
    }

    return EntrenamientoModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<EntrenamientoModel> actualizar({
    required int entrenamientoId,
    required int equipoId,
    required String fecha,
    required Map<int, String> asistencias,
  }) async {
    final token = await AuthSession.obtenerToken();

    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/app/entrenamientos/$entrenamientoId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'equipoId': equipoId,
        'fecha': fecha,
        'asistencias': asistencias.entries.map((entry) {
          return {'jugadorId': entry.key, 'estado': entry.value};
        }).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar entrenamiento: '
        '${response.statusCode} ${response.body}',
      );
    }

    return EntrenamientoModel.fromJson(jsonDecode(response.body));
  }
}
