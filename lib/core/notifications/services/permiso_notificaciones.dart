import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../config/app_preferences.dart';
import '../widgets/pantalla_avisos.dart';

/// Cómo está el permiso de notificaciones del sistema.
enum EstadoPermisoAvisos {
  /// Todavía no se ha decidido (notDetermined en iOS; en Android 13+ no concedido y sin haberlo pedido).
  sinDecidir,

  /// Concedido (también el provisional de iOS, y Android antes de la 13).
  concedido,

  /// Rechazado: el sistema ya no vuelve a preguntar; solo se puede activar desde los ajustes del sistema.
  denegado,
}

/// Desde dónde se pide el permiso.
enum MotivoPermiso {
  /// Al arrancar una app actualizada cuyo permiso sigue sin decidir (una vez).
  arranque,

  /// Al iniciar sesión.
  inicioSesion,

  /// Al pulsar "Seguir este partido".
  seguirPartido,

  /// En los ajustes de avisos (solo avisa si está denegado: no ofrece la pantalla previa).
  ajustes,
}

/// El permiso de notificaciones, siempre a través de una pantalla propia antes de la petición del sistema.
///
/// - Sin decidir: se muestra [PantallaAvisos] ("No te pierdas nada del Mutxamel C.F."). Solo con "Activar notificaciones" se
///   lanza la petición del sistema; con "Ahora no" no se pide nada (así en iPhone se puede volver a pedir).
/// - La pantalla se ofrece como mucho [maxOfertas] veces en total (la primera y una más, al iniciar sesión o al seguir un
///   partido) y nunca más de una vez cada [entreOfertas].
/// - Denegado del todo: en "Seguir este partido" y en los ajustes de avisos, un aviso con "Abrir ajustes".
class PermisoNotificaciones {
  PermisoNotificaciones._();

  static const int maxOfertas = 2;
  static const Duration entreOfertas = Duration(days: 7);

  /// Lee el permiso del sistema (los tests lo sustituyen).
  static Future<EstadoPermisoAvisos> Function() leerEstado = _leerEstado;

  /// La peticion del sistema (los tests la sustituyen).
  @visibleForTesting
  static Future<bool> Function() pedirAlSistema = _pedirAlSistema;

  /// Abre los ajustes de notificaciones del sistema (los tests lo sustituyen).
  static Future<void> Function() abrirAjustes = () =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  /// Se llama tras conceder el permiso (registrar el dispositivo para los avisos personales; lo pone PushNotificationService).
  static Future<void> Function() alConceder = () async {};

  static Future<EstadoPermisoAvisos> _leerEstado() async {
    try {
      final ajustes = await FirebaseMessaging.instance
          .getNotificationSettings();

      switch (ajustes.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return EstadoPermisoAvisos.concedido;
        case AuthorizationStatus.denied:
          // iOS: rechazado del todo. Android 13+: rechazado una vez, el sistema aun puede volver a preguntar.
          return Platform.isIOS
              ? EstadoPermisoAvisos.denegado
              : EstadoPermisoAvisos.sinDecidir;
        case AuthorizationStatus.deniedPermanently:
          return EstadoPermisoAvisos.denegado;
        case AuthorizationStatus.notDetermined:
          return EstadoPermisoAvisos.sinDecidir;
      }
    } catch (e) {
      debugPrint('NO SE PUDO LEER EL PERMISO DE NOTIFICACIONES: $e');

      // Ante la duda no se molesta: ni pantalla ni petición.
      return EstadoPermisoAvisos.denegado;
    }
  }

  static Future<bool> _pedirAlSistema() async {
    try {
      final ajustes = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return ajustes.authorizationStatus == AuthorizationStatus.authorized ||
          ajustes.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('NO SE PUDO PEDIR EL PERMISO DE NOTIFICACIONES: $e');
      return false;
    }
  }

  /// true si el permiso está concedido ahora (sin pedir nada).
  static Future<bool> estaConcedido() async =>
      await leerEstado() == EstadoPermisoAvisos.concedido;

  /// Si toca ofrecer la pantalla previa: aún no se han agotado las ofertas, han pasado 7 días desde la última y, al
  /// arrancar, es la primera.
  static Future<bool> puedeOfrecer(MotivoPermiso motivo) async {
    final veces = await AppPreferences.obtenerOfertaAvisosVeces();

    if (motivo == MotivoPermiso.ajustes) return false;

    if (motivo == MotivoPermiso.arranque && veces > 0) return false;

    if (veces >= maxOfertas) return false;

    final ultima = await AppPreferences.obtenerOfertaAvisosUltima();

    return ultima == null || ahora().difference(ultima) >= entreOfertas;
  }

  /// Anota que se ha ofrecido la pantalla (la bienvenida la usa también, con sus propios interruptores).
  static Future<void> registrarOferta() =>
      AppPreferences.registrarOfertaAvisos(ahora());

  /// Asegura el permiso: true si está concedido al terminar.
  ///
  /// Concedido: true sin más. Sin decidir: la pantalla previa (si toca) y, solo si el usuario la acepta, la petición
  /// del sistema. Denegado: en [MotivoPermiso.seguirPartido] y [MotivoPermiso.ajustes], el aviso con "Abrir ajustes".
  static Future<bool> asegurar(
    BuildContext context,
    MotivoPermiso motivo,
  ) async {
    final estado = await leerEstado();

    if (estado == EstadoPermisoAvisos.concedido) return true;

    if (!context.mounted) return false;

    if (estado == EstadoPermisoAvisos.denegado) {
      if (motivo == MotivoPermiso.seguirPartido ||
          motivo == MotivoPermiso.ajustes) {
        await mostrarAvisoDenegado(context);
      }

      return false;
    }

    if (!await puedeOfrecer(motivo)) return false;

    if (!context.mounted) return false;

    await registrarOferta();

    if (!context.mounted) return false;

    final acepta = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PantallaAvisos(),
      ),
    );

    if (acepta != true) return false;

    return pedirYRegistrar();
  }

  /// La petición del sistema y, si se concede, lo que haga falta después.
  static Future<bool> pedirYRegistrar() async {
    final concedido = await pedirAlSistema();

    if (concedido) await alConceder();

    return concedido;
  }

  /// "Notificaciones desactivadas" con el botón "Abrir ajustes" (los ajustes de notificaciones del sistema).
  static Future<void> mostrarAvisoDenegado(BuildContext context) async {
    final t = AppLocalizations.of(context);

    final abrir = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(t.notifDeniedTitle),
        content: Text(t.notifDeniedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            key: const ValueKey('abrir-ajustes'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: Text(t.openSettingsAction),
          ),
        ],
      ),
    );

    if (abrir == true) await abrirAjustes();
  }
}
