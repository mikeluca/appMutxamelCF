import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/auth/services/auth_manager.dart';
import '../../features/auth/services/auth_session.dart';
import '../config/app_config.dart';

/// Excepción lanzada ante cualquier fallo de una llamada a la API
/// (red, timeout, respuesta de error del backend...).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

enum _HttpMethod { get, post, put, delete }

/// Cliente HTTP centralizado: añade cabeceras (incluido el token de sesión),
/// aplica un timeout, decodifica el JSON de la respuesta y traduce
/// los fallos de red/HTTP a [ApiException] de forma consistente.
class ApiClient {
  ApiClient._();

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
  };

  static String get baseUrl => AppConfig.apiBaseUrl;

  static const Duration _timeout = Duration(seconds: 15);

  static Future<dynamic> get(String path, {bool autenticado = false}) {
    return _enviar(_HttpMethod.get, path, autenticado: autenticado);
  }

  static Future<dynamic> post(
    String path, {
    Object? body,
    bool autenticado = false,
  }) {
    return _enviar(_HttpMethod.post, path, body: body, autenticado: autenticado);
  }

  static Future<dynamic> put(
    String path, {
    Object? body,
    bool autenticado = false,
  }) {
    return _enviar(_HttpMethod.put, path, body: body, autenticado: autenticado);
  }

  static Future<dynamic> delete(String path, {bool autenticado = false}) {
    return _enviar(_HttpMethod.delete, path, autenticado: autenticado);
  }

  static Future<dynamic> _enviar(
    _HttpMethod metodo,
    String path, {
    Object? body,
    bool autenticado = false,
  }) async {
    final headers = <String, String>{...jsonHeaders};

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (autenticado) {
      final token = await AuthSession.obtenerToken();

      if (token == null || token.isEmpty) {
        throw const ApiException('No hay una sesión activa.');
      }

      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    final bodyJson = body == null ? null : jsonEncode(body);

    http.Response response;

    try {
      switch (metodo) {
        case _HttpMethod.get:
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case _HttpMethod.post:
          response = await http
              .post(uri, headers: headers, body: bodyJson)
              .timeout(_timeout);
          break;
        case _HttpMethod.put:
          response = await http
              .put(uri, headers: headers, body: bodyJson)
              .timeout(_timeout);
          break;
        case _HttpMethod.delete:
          response =
              await http.delete(uri, headers: headers).timeout(_timeout);
          break;
      }
    } on TimeoutException {
      throw const ApiException('El servidor no responde. Inténtalo de nuevo.');
    } on SocketException {
      throw const ApiException('No hay conexión a internet.');
    } on http.ClientException catch (e) {
      throw ApiException('Error de red: ${e.message}');
    }

    if (response.statusCode == 401) {
      if (autenticado) {
        // El token ya no es válido: purgamos la sesión almacenada
        // para que la app no siga usándolo en próximas peticiones.
        await AuthManager.cerrarSesion();
      }

      throw ApiException(
        _extraerMensaje(response.body) ?? 'La sesión ha caducado o no es válida.',
        statusCode: 401,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const ApiException('Respuesta inesperada del servidor.');
      }
    }

    throw ApiException(
      _extraerMensaje(response.body) ??
          'Error en la petición (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  static String? _extraerMensaje(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        for (final clave in ['message', 'mensaje', 'error']) {
          final valor = decoded[clave];

          if (valor is String && valor.trim().isNotEmpty) {
            return valor;
          }
        }

        // Errores de validación del backend: {"campo": "mensaje", ...}.
        final valoresTexto = decoded.values.whereType<String>().where(
              (valor) => valor.trim().isNotEmpty,
            );

        if (valoresTexto.isNotEmpty) {
          return valoresTexto.join('\n');
        }
      }
    } catch (_) {
      // El backend puede devolver directamente texto plano.
    }

    return body.trim().isEmpty ? null : body.trim();
  }
}
