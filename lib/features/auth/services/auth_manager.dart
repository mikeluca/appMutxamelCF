import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_preferences.dart';
import '../../../core/errores/informes_errores.dart';
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

  /// Sube cada vez que cambia el usuario (inicio de sesión, recarga de roles, cierre): las pantallas que dependen de
  /// sus roles (el Área Club) se reconstruyen escuchándolo.
  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);

  /// Solo para tests: deja la app sin usuario, sin tocar el almacenamiento.
  @visibleForTesting
  static void olvidarUsuario() => _usuarioActual = null;

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

    // Ya con la sesión: si la cuenta recibe los resultados, se baja de los partidos seguidos (evita avisos
    // duplicados). Sin esperar, y sin que un fallo afecte al acceso (sincronizarPartidosSeguidos nunca lanza).
    unawaited(PushNotificationService.sincronizarPartidosSeguidos());
    unawaited(InformesErrores.actualizarClaves());

    return usuario;
  }

  /// Solo para tests: cómo se pide el usuario al backend al restaurar la sesión.
  @visibleForTesting
  static Future<AuthUser> Function() cargarUsuario =
      AuthService.obtenerUsuarioActual;

  static Future<bool>? _restauracion;

  /// Hay un token guardado (sesión de una ejecución anterior). Un fallo del almacenamiento cuenta como que no.
  static Future<bool> haySesionGuardada() async {
    try {
      return await AuthSession.estaAutenticado();
    } catch (_) {
      return false;
    }
  }

  /// Para quien necesita saber si hay sesión sin haber pasado por "Área Club": con usuario, true; sin usuario pero con
  /// token guardado, restaura la sesión; sin token, false.
  static Future<bool> asegurarSesion() async {
    if (estaAutenticado) return true;

    if (!await haySesionGuardada()) return false;

    return restaurarSesion();
  }

  /// Restaura el usuario a partir del token guardado. Llamadas a la vez comparten la misma petición. Avisa por
  /// [cambios] si con ello hay usuario (o deja de haberlo).
  static Future<bool> restaurarSesion() =>
      _restauracion ??= _restaurar().whenComplete(() => _restauracion = null);

  static Future<bool> _restaurar() async {
    final habiaUsuario = _usuarioActual != null;
    bool restaurada;

    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      _usuarioActual = null;
      restaurada = false;
    } else {
      try {
        _usuarioActual = await cargarUsuario();
        restaurada = true;
      } catch (_) {
        // FL-03: no se borra la sesión guardada aquí. Si el fallo fue un
        // 401, ApiClient ya la ha limpiado (ver _enviar); si fue un fallo
        // de red o timeout, el token sigue siendo válido y no hay que
        // expulsar al usuario por abrir la app sin cobertura.
        _usuarioActual = null;
        restaurada = false;
      }
    }

    if (habiaUsuario != (_usuarioActual != null)) cambios.value++;

    return restaurada;
  }

  static Future<void> establecerUsuario(AuthUser usuario) async {
    _usuarioActual = usuario;
    cambios.value++;
  }

  /// Vuelve a pedir el usuario al backend (con sus roles actuales): la usa el aviso de que el club ha aprobado una
  /// solicitud de familia, igual que al iniciar sesión. Devuelve true si cambiaron los roles. Un fallo de red se
  /// ignora (el usuario actual se queda como está).
  static Future<bool> recargarUsuario() async {
    final antes = _usuarioActual;

    if (antes == null) return false;

    try {
      final usuario = await AuthService.obtenerUsuarioActual();
      final cambiaron =
          usuario.roles.length != antes.roles.length ||
          !usuario.roles.every(antes.roles.contains);

      await establecerUsuario(usuario);

      return cambiaron;
    } catch (_) {
      return false;
    }
  }

  /// [desregistrarDispositivo] debe ser false cuando el cierre de sesión
  /// lo dispara un 401 de ApiClient (token ya inválido): desregistrar
  /// llama a DELETE /api/app/dispositivos con ese mismo token, que
  /// volvería a devolver 401 y a llamar a cerrarSesion() en bucle
  /// infinito (N-01). El valor por defecto (true) es para un logout real
  /// iniciado por el usuario, donde el token todavía es válido.
  static Future<void> cerrarSesion({
    bool desregistrarDispositivo = true,
  }) async {
    // SEC-07: desregistrar el dispositivo requiere el token de sesión
    // actual, así que debe hacerse antes de borrarlo.
    if (desregistrarDispositivo) {
      await PushNotificationService.desregistrarDispositivoActual();
    }

    _usuarioActual = null;
    await AuthSession.cerrarSesion();
    cambios.value++;

    // Sin sesión cuenta el ajuste anónimo de resultados: se sincronizan de nuevo los partidos seguidos. Sin esperar y
    // sin que un fallo rompa el cierre de sesión.
    unawaited(PushNotificationService.sincronizarPartidosSeguidos());
    unawaited(InformesErrores.actualizarClaves());
  }
}
