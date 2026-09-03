import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String _claveTema = 'tema_aplicacion';
  static const String _claveNotificaciones = 'notificaciones_activadas';

  static Future<String> obtenerTema() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveTema) ?? 'system';
  }

  static Future<void> guardarTema(String tema) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveTema, tema);
  }

  static Future<bool> obtenerNotificaciones() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_claveNotificaciones) ?? true;
  }

  static Future<void> guardarNotificaciones(bool activadas) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_claveNotificaciones, activadas);
  }
}
