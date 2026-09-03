import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/match_model.dart';

class MatchService {
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/public/resultados/primer-equipo',
    );

    final response = await http.get(url);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener el partido del Primer Equipo: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    return MatchModel.fromJson(data);
  }

  Future<List<MatchModel>> obtenerResultados() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/public/resultados');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener los resultados: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
