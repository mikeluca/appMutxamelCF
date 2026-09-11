import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'auth_session.dart';
import '../models/comunicacion_model.dart';
import '../models/notificacion_model.dart';
import '../models/destinatario_comunicacion_model.dart';

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

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

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

  static Future<List<ComunicacionModel>> obtenerComunicacionesEnviadas() async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/comunicaciones/enviadas',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener las comunicaciones enviadas: '
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

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    if (response.statusCode == 404) {
      throw Exception('La comunicación no existe.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener la comunicación: '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    return ComunicacionModel.fromJson(data);
  }

  static Future<void> crearComunicacion({
    required String titulo,
    required String contenido,
    required List<int> equipoIds,
    required List<String> categorias,
    required List<int> destinatariosIds,
  }) async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/app/comunicaciones');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
      body: jsonEncode({
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'equipoIds': equipoIds,
        'categorias': categorias,
        'destinatariosIds': destinatariosIds,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No tienes permiso para crear esta comunicación.',
        ),
      );
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'Los datos de la comunicación no son válidos.',
        ),
      );
    }

    if (response.statusCode != 201) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'Error al crear la comunicación '
          '(${response.statusCode}).',
        ),
      );
    }
  }

  static String _extraerMensajeError(String body, String mensajePorDefecto) {
    if (body.trim().isEmpty) {
      return mensajePorDefecto;
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        final posibles = [
          decoded['message'],
          decoded['mensaje'],
          decoded['error'],
        ];

        for (final valor in posibles) {
          if (valor is String && valor.trim().isNotEmpty) {
            return valor;
          }
        }
      }
    } catch (_) {
      // El backend puede devolver directamente texto plano.
    }

    return body.trim();
  }

  static Future<List<DestinatarioComunicacionModel>>
  obtenerDestinatariosDirectos() async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/comunicaciones/destinatarios',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener los destinatarios: '
        '${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map(
          (json) => DestinatarioComunicacionModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<int> contarComunicacionesNoLeidas() async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/notificaciones/comunicaciones/no-leidas/count',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al contar las comunicaciones no leídas: '
        '${response.statusCode}',
      );
    }

    return int.parse(response.body);
  }

  static Future<List<NotificacionModel>> obtenerNotificaciones() async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/app/notificaciones');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
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

  static Future<void> marcarNotificacionComoLeida(int notificacionId) async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      throw Exception('No hay una sesión iniciada.');
    }

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/app/notificaciones/$notificacionId/leida',
    );

    final response = await http.put(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenSesion',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al marcar la notificación como leída: '
        '${response.statusCode}',
      );
    }
  }
}
