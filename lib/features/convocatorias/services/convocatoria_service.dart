import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_session.dart';
import '../model/convocatoria_model.dart';

class ConvocatoriaService {
  Future<List<ConvocatoriaModel>> obtenerPorEquipo(int equipoId) async {
    final token = await AuthSession.obtenerToken();

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/app/convocatorias?equipoId=$equipoId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener las convocatorias: '
        '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((item) => ConvocatoriaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ConvocatoriaModel> obtenerPorId(int convocatoriaId) async {
    final token = await AuthSession.obtenerToken();

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/app/convocatorias/$convocatoriaId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener la convocatoria: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ConvocatoriaModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ConvocatoriaModel> crear({
    required int equipoId,
    required String rival,
    required String campo,
    required String fechaPartido,
    required String horaPartido,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
  }) async {
    final token = await AuthSession.obtenerToken();

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/app/convocatorias'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'equipoId': equipoId,
        'rival': rival,
        'campo': campo,
        'fechaPartido': fechaPartido,
        'horaPartido': horaPartido,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
        'jugadoresIds': jugadoresIds,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al crear la convocatoria: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ConvocatoriaModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ConvocatoriaModel> actualizar({
    required int convocatoriaId,
    required int equipoId,
    required String rival,
    required String campo,
    required String fechaPartido,
    required String horaPartido,
    required String horaConvocatoria,
    required String lugarConvocatoria,
  }) async {
    final token = await AuthSession.obtenerToken();

    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/app/convocatorias/$convocatoriaId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'equipoId': equipoId,
        'rival': rival,
        'campo': campo,
        'fechaPartido': fechaPartido,
        'horaPartido': horaPartido,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar la convocatoria: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ConvocatoriaModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
