import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/login_response.dart';

class AuthSession {
  AuthSession._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';
  static const String _usuarioIdKey = 'auth_usuario_id';
  static const String _emailKey = 'auth_email';
  static const String _rolesKey = 'auth_roles';

  static Future<void> guardarSesion(LoginResponse loginResponse) async {
    await _storage.write(key: _tokenKey, value: loginResponse.token);

    await _storage.write(
      key: _usuarioIdKey,
      value: loginResponse.usuarioId.toString(),
    );

    await _storage.write(key: _emailKey, value: loginResponse.email);

    await _storage.write(
      key: _rolesKey,
      value: jsonEncode(loginResponse.roles),
    );
  }

  static Future<String?> obtenerToken() {
    return _storage.read(key: _tokenKey);
  }

  static Future<int?> obtenerUsuarioId() async {
    final valor = await _storage.read(key: _usuarioIdKey);

    if (valor == null) {
      return null;
    }

    return int.tryParse(valor);
  }

  static Future<String?> obtenerEmail() {
    return _storage.read(key: _emailKey);
  }

  static Future<List<String>> obtenerRoles() async {
    final rolesJson = await _storage.read(key: _rolesKey);

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
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usuarioIdKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _rolesKey);
  }
}
