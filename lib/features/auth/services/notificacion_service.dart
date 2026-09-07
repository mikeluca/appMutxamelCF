import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/notificacion_model.dart';
import 'auth_session.dart';

class NotificacionService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesión no iniciada');
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<List<NotificacionModel>> obtenerNotificaciones() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/app/notificaciones');

    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 401) {
      throw Exception('Sesión no válida');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener las notificaciones: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<NotificacionModel>> obtenerNoLeidas() async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/notificaciones/no-leidas',
    );

    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 401) {
      throw Exception('Sesión no válida');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener las notificaciones no leídas: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<int> contarNoLeidas() async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/notificaciones/no-leidas/count',
    );

    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 401) {
      throw Exception('Sesión no válida');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al contar las notificaciones: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    return (data['cantidad'] as num?)?.toInt() ?? 0;
  }

  static Future<void> marcarComoLeida(int id) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/notificaciones/$id/leida',
    );

    final response = await http.put(url, headers: await _headers());

    if (response.statusCode == 401) {
      throw Exception('Sesión no válida');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al marcar la notificación como leída: '
        '${response.statusCode}',
      );
    }
  }

  static Future<void> marcarTodasComoLeidas() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/app/notificaciones/leidas');

    final response = await http.put(url, headers: await _headers());

    if (response.statusCode == 401) {
      throw Exception('Sesión no válida');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al marcar las notificaciones como leídas: '
        '${response.statusCode}',
      );
    }
  }
}
