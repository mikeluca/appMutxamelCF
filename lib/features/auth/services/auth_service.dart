import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

import '../models/auth_user.dart';
import 'auth_session.dart';

class AuthService {
  AuthService._();

  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/app/auth/login'),
      headers: {
        ...ApiClient.jsonHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      return LoginResponse.fromJson(data);
    }

    if (response.statusCode == 403) {
      throw Exception('La cuenta no está activa.');
    }

    if (response.statusCode == 401) {
      throw Exception('Email o contraseña incorrectos.');
    }

    throw Exception('Error al iniciar sesión (${response.statusCode}).');
  }

  static Future<AuthUser> obtenerUsuarioActual() async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión activa.');
    }

    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/app/auth/me'),
      headers: {
        ...ApiClient.jsonHeaders,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      return AuthUser.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw Exception('La sesión ha caducado o no es válida.');
    }

    throw Exception('Error al comprobar la sesión (${response.statusCode}).');
  }
}
