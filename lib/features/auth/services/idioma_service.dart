import 'package:flutter/foundation.dart';

import '../../../core/config/app_preferences.dart';
import '../../../core/network/api_client.dart';
import 'auth_session.dart';

/// Mantiene el idioma de la cuenta en el backend, que escribe los avisos
/// (bandeja, push y emails) en él. El idioma viaja también en el login, la
/// activación, el restablecimiento y el registro del dispositivo; aquí están
/// los otros dos momentos: el cambio en Ajustes y el arranque.
class IdiomaService {
  IdiomaService._();

  static const List<String> idiomasAdmitidos = ['es', 'ca', 'en'];

  /// PUT /app/preferencias/idioma. Sin sesión iniciada no hace nada (el
  /// idioma viajará con el siguiente login). Lanza si la llamada falla.
  static Future<void> enviar(String idioma) async {
    final token = await AuthSession.obtenerToken();

    if (token == null || token.isEmpty) {
      return;
    }

    await ApiClient.put(
      '/app/preferencias/idioma',
      autenticado: true,
      body: {'idioma': idioma},
    );

    await AppPreferences.guardarUltimoIdiomaEnviado(idioma);
  }

  /// Al cambiar el idioma en Ajustes, en ese momento. Nunca bloquea ni lanza:
  /// si falla, se reintenta en el siguiente arranque (ver
  /// [sincronizarAlArrancar]).
  static Future<void> alCambiarIdioma(String idioma) async {
    try {
      await enviar(idioma);
    } catch (e) {
      debugPrint('NO SE PUDO ENVIAR EL IDIOMA AL BACKEND: $e');
    }
  }

  /// Al arrancar con sesión iniciada: si el idioma que la app muestra ahora
  /// no es el último que se envió (p. ej. porque cambió el idioma del móvil, o
  /// porque un envío anterior falló), se envía. Si no ha cambiado, no hay
  /// llamada. Nunca bloquea ni lanza.
  static Future<void> sincronizarAlArrancar() async {
    try {
      final token = await AuthSession.obtenerToken();

      if (token == null || token.isEmpty) {
        return;
      }

      final actual = await AppPreferences.obtenerIdioma();
      final ultimo = await AppPreferences.obtenerUltimoIdiomaEnviado();

      if (actual == ultimo) {
        return;
      }

      await enviar(actual);
    } catch (e) {
      debugPrint('NO SE PUDO SINCRONIZAR EL IDIOMA CON EL BACKEND: $e');
    }
  }
}
