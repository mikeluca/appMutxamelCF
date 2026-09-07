import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'auth_session.dart';
import '../models/preferencias_notificacion_model.dart';

class PreferenciasNotificacionService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesión no iniciada');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<PreferenciasNotificacionModel> obtenerPreferencias() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/app/preferencias-notificacion'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener las preferencias: '
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return PreferenciasNotificacionModel.fromJson(data);
  }

  static Future<PreferenciasNotificacionModel> actualizarPreferencias(
    PreferenciasNotificacionModel preferencias,
  ) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/app/preferencias-notificacion'),
      headers: await _headers(),
      body: jsonEncode(preferencias.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar las preferencias: '
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return PreferenciasNotificacionModel.fromJson(data);
  }
}
