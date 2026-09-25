import '../../../core/config/app_preferences.dart';
import '../../../core/notifications/services/push_notification_service.dart';
import '../models/auth_user.dart';
import '../models/login_response.dart';
import 'auth_service.dart';
import 'auth_session.dart';

class AuthManager {
  AuthManager._();

  static AuthUser? _usuarioActual;

  static AuthUser? get usuarioActual => _usuarioActual;

  static bool get estaAutenticado => _usuarioActual != null;

  /// Deja la sesión lista tras un login o una activación de cuenta:
  /// guarda el token, registra el dispositivo para notificaciones
  /// push y carga el perfil del usuario autenticado.
  static Future<AuthUser> completarAcceso(LoginResponse loginResponse) async {
    await AuthSession.guardarSesion(loginResponse);

    await PushNotificationService.registrarDispositivoActual();

    // Quien inicia sesión recibe los avisos por el canal personal de
    // su cuenta: se desuscribe de los topics anónimos para que no le
    // lleguen duplicados, y se deja el estado local coherente por si
    // vuelve a ver los interruptores anónimos tras cerrar sesión.
    await PushNotificationService.desuscribirDeTopicsAnonimos();
    await AppPreferences.guardarNotifNoticias(false);
    await AppPreferences.guardarNotifResultados(false);

    final usuario = await AuthService.obtenerUsuarioActual();

    await establecerUsuario(usuario);

    return usuario;
  }

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
