import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String _claveTema = 'tema_aplicacion';

  // Preferencias de notificaciones "anónimas" (sin sesión iniciada,
  // sin cuenta): se guardan solo en el dispositivo, no en el
  // backend. Se usan junto a la suscripción a topics de FCM
  // (ver PushNotificationService).
  static const String _claveNotifNoticias = 'notif_anonima_noticias';
  static const String _claveNotifResultados = 'notif_anonima_resultados';

  static Future<String> obtenerTema() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveTema) ?? 'system';
  }

  static Future<void> guardarTema(String tema) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveTema, tema);
  }

  static Future<bool> obtenerNotifNoticias() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_claveNotifNoticias) ?? false;
  }

  static Future<void> guardarNotifNoticias(bool activo) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_claveNotifNoticias, activo);
  }

  static Future<bool> obtenerNotifResultados() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_claveNotifResultados) ?? false;
  }

  static Future<void> guardarNotifResultados(bool activo) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_claveNotifResultados, activo);
  }
}
