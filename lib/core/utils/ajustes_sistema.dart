import 'package:flutter/services.dart';

/// Abre los ajustes del sistema (sustituye al plugin app_settings, que aplica el Kotlin Gradle Plugin).
/// Android: los ajustes de notificaciones de la app o los de la app. iOS: los ajustes de la app. Nunca lanza.
class AjustesSistema {
  AjustesSistema._();

  static const MethodChannel _canal = MethodChannel('com.mutxamelcf.app/ajustes');

  /// Ajustes de notificaciones de la app (en iOS, los ajustes de la app).
  static Future<void> abrirNotificaciones() => _abrir('abrirAjustesNotificaciones');

  /// Ajustes de la app.
  static Future<void> abrirApp() => _abrir('abrirAjustesApp');

  static Future<void> _abrir(String metodo) async {
    try {
      await _canal.invokeMethod<void>(metodo);
    } catch (_) {
      // Sin ajustes que abrir: no pasa nada.
    }
  }
}
