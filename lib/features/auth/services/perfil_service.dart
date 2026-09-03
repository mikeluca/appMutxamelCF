import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/perfil_app.dart';
import 'auth_session.dart';

class PerfilService {
  PerfilService._();

  static Future<PerfilApp> obtenerPerfil() async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión activa.');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/app/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      return PerfilApp.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    if (response.statusCode == 404) {
      throw Exception('No se ha encontrado el perfil del usuario.');
    }

    throw Exception('Error al obtener el perfil (${response.statusCode}).');
  }
}
