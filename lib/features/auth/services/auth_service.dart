import '../../../core/network/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

import '../models/auth_user.dart';

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

    try {
      final data = await ApiClient.post(
        '/app/auth/login',
        body: request.toJson(),
      );

      return LoginResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw Exception('La cuenta no está activa.');
      }

      if (e.statusCode == 401) {
        throw Exception('Email o contraseña incorrectos.');
      }

      rethrow;
    }
  }

  /// Borra la cuenta del usuario autenticado (confirmando su contraseña).
  ///
  /// Lanza [ApiException] con `statusCode` 400 si la contraseña no es
  /// correcta y 429 si hay demasiados intentos fallidos. Tras un borrado
  /// correcto el llamador debe cerrar la sesión local.
  static Future<void> eliminarCuenta({required String password}) async {
    await ApiClient.delete(
      '/app/auth/cuenta',
      body: {'password': password},
      autenticado: true,
    );
  }

  static Future<AuthUser> obtenerUsuarioActual() async {
    final data = await ApiClient.get('/app/auth/me', autenticado: true);

    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  /// Activa la cuenta con el código de 6 dígitos recibido por email
  /// y fija la contraseña elegida. El backend, tras activarla, inicia
  /// sesión directamente: la respuesta es un login válido (mismo
  /// formato que [login]).
  static Future<LoginResponse> activarCuenta({
    required String email,
    required String codigo,
    required String password,
  }) async {
    try {
      final data = await ApiClient.post(
        '/app/auth/activar',
        body: {
          'email': email.trim().toLowerCase(),
          'codigo': codigo.trim(),
          'password': password,
        },
      );

      return LoginResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw Exception(e.message);
      }

      rethrow;
    }
  }
}
