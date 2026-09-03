import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_response.dart';

class AuthSession {
  AuthSession._();

  static const String _tokenKey = 'auth_token';
  static const String _usuarioIdKey = 'auth_usuario_id';
  static const String _emailKey = 'auth_email';
  static const String _rolesKey = 'auth_roles';

  static Future<void> guardarSesion(LoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, loginResponse.token);

    await prefs.setInt(_usuarioIdKey, loginResponse.usuarioId);

    await prefs.setString(_emailKey, loginResponse.email);

    await prefs.setString(_rolesKey, jsonEncode(loginResponse.roles));
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  static Future<int?> obtenerUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_usuarioIdKey);
  }

  static Future<String?> obtenerEmail() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_emailKey);
  }

  static Future<List<String>> obtenerRoles() async {
    final prefs = await SharedPreferences.getInstance();

    final rolesJson = prefs.getString(_rolesKey);

    if (rolesJson == null) {
      return [];
    }

    final List<dynamic> roles = jsonDecode(rolesJson);

    return roles.cast<String>();
  }

  static Future<bool> estaAutenticado() async {
    final token = await obtenerToken();

    return token != null && token.isNotEmpty;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_usuarioIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_rolesKey);
  }
}
