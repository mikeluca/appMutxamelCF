import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String _claveTema = 'tema_aplicacion';
  static const String _claveIdioma = 'idioma_aplicacion';

  // Preferencias de notificaciones "anónimas" (sin sesión iniciada,
  // sin cuenta): se guardan solo en el dispositivo, no en el
  // backend. Se usan junto a la suscripción a topics de FCM
  // (ver PushNotificationService).
  static const String _claveNotifNoticias = 'notif_anonima_noticias';
  static const String _claveNotifResultados = 'notif_anonima_resultados';

  static const String _claveUltimoAvisoVersion = 'ultimo_aviso_version';

  // Último idioma que el backend ya conoce para la cuenta de este dispositivo
  // (se guarda tras cada llamada que lo envía con éxito) y el idioma para el que
  // se han ajustado por última vez los topics anónimos de FCM.
  static const String _claveUltimoIdiomaEnviado = 'ultimo_idioma_enviado';
  static const String _claveIdiomaTopics = 'idioma_topics_anonimos';

  static Future<String> obtenerTema() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveTema) ?? 'system';
  }

  static Future<void> guardarTema(String tema) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveTema, tema);
  }

  /// Código de idioma ('es', 'ca' o 'en' — 'ca' es el código ISO 639 que
  /// también se usa para el valenciano, no hay uno separado oficial).
  static Future<String> obtenerIdioma() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveIdioma) ?? 'es';
  }

  /// Indica si ya se ha guardado alguna vez una preferencia de idioma
  /// (bien porque el usuario la cambió en Ajustes, bien porque ya se
  /// detectó una vez el idioma del dispositivo en un arranque anterior).
  /// Permite distinguir el "primer arranque" (sin nada guardado, momento
  /// en que se debe detectar el idioma del sistema) de arranques
  /// posteriores, en los que la preferencia guardada debe respetarse
  /// siempre y no se debe volver a detectar.
  static Future<bool> existeIdiomaGuardado() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(_claveIdioma);
  }

  static Future<void> guardarIdioma(String idioma) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveIdioma, idioma);
  }

  /// El idioma que se envió al backend con éxito la última vez, o null si
  /// nunca se ha enviado.
  static Future<String?> obtenerUltimoIdiomaEnviado() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveUltimoIdiomaEnviado);
  }

  static Future<void> guardarUltimoIdiomaEnviado(String idioma) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveUltimoIdiomaEnviado, idioma);
  }

  /// El idioma para el que están ajustados los topics anónimos, o null si
  /// nunca se han ajustado por idioma (instalaciones anteriores a 1.0.7).
  static Future<String?> obtenerIdiomaTopics() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveIdiomaTopics);
  }

  static Future<void> guardarIdiomaTopics(String idioma) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveIdiomaTopics, idioma);
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

  /// Día (yyyy-MM-dd) en que se avisó por última vez de que hay una versión
  /// recomendada de la app: el aviso no bloqueante sale una vez al día.
  static Future<String?> obtenerUltimoAvisoVersion() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveUltimoAvisoVersion);
  }

  static Future<void> guardarUltimoAvisoVersion(String dia) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveUltimoAvisoVersion, dia);
  }
}
