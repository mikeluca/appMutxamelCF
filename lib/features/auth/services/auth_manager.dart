import '../models/auth_user.dart';
import 'auth_service.dart';
import 'auth_session.dart';

class AuthManager {
  AuthManager._();

  static AuthUser? _usuarioActual;

  static AuthUser? get usuarioActual => _usuarioActual;

  static bool get estaAutenticado => _usuarioActual != null;

  static Future<bool> restaurarSesion() async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      _usuarioActual = null;
      return false;
    }

    try {
      final usuario = await AuthService.obtenerUsuarioActual();

      _usuarioActual = usuario;

      return true;
    } catch (_) {
      await cerrarSesion();
      return false;
    }
  }

  static Future<void> establecerUsuario(AuthUser usuario) async {
    _usuarioActual = usuario;
  }

  static Future<void> cerrarSesion() async {
    _usuarioActual = null;
    await AuthSession.cerrarSesion();
  }
}
