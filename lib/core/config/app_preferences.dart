import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String _claveTema = 'tema_aplicacion';

  static Future<String> obtenerTema() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveTema) ?? 'system';
  }

  static Future<void> guardarTema(String tema) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveTema, tema);
  }
}
