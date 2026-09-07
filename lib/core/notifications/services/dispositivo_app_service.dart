import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../features/auth/services/auth_session.dart';
import '../models/dispositivo_app_request.dart';

class DispositivoAppService {
  DispositivoAppService._();

  static Future<void> registrar({
    required String tokenFcm,
    required String plataforma,
  }) async {
    final tokenSesion = await AuthSession.obtenerToken();

    // No hay sesión iniciada.
    if (tokenSesion == null || tokenSesion.isEmpty) {
      return;
    }

    final request = DispositivoAppRequest(
      tokenFcm: tokenFcm,
      plataforma: plataforma,
    );

    final url = Uri.parse('${ApiClient.baseUrl}/app/dispositivos');

    final response = await http.post(
      url,
      headers: {
        ...ApiClient.jsonHeaders,
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al registrar el dispositivo: '
        '${response.statusCode}',
      );
    }
  }
}
