import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../features/auth/services/auth_session.dart';
import '../models/comunicacion_model.dart';

class ComunicacionService {
  ComunicacionService._();

  static Future<List<ComunicacionModel>> obtenerComunicaciones() async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/app/comunicaciones');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener las comunicaciones: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => ComunicacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<ComunicacionModel> obtenerComunicacionPorId(int id) async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/app/comunicaciones/$id');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
    );

    if (response.statusCode == 404) {
      throw Exception('La comunicación no existe.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener la comunicación: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    return ComunicacionModel.fromJson(data);
  }
}
