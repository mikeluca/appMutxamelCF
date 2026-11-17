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

  // Partidos que el usuario sigue ("Seguir este partido"): "id|yyyy-MM-dd" (el día del partido).
  static const String _clavePartidosSeguidos = 'partidos_seguidos';

  // Última app de mapas elegida en iOS para "Cómo llegar" ('google' o 'apple').
  static const String _claveMapaPreferido = 'mapa_como_llegar';

  static Future<String?> obtenerMapaPreferido() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_claveMapaPreferido);
  }

  static Future<void> guardarMapaPreferido(String mapa) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_claveMapaPreferido, mapa);
  }

  // Informes de errores (Firebase Crashlytics): "Enviar informes de errores" en Ajustes. Activado por defecto.
  static const String _claveInformesErrores = 'informes_errores';

  // Bienvenida del primer arranque (idioma y avisos): true cuando ya se ha hecho o se ha saltado, o cuando la app se
  // actualiza desde una versión anterior (que no la tenía).
  static const String _claveBienvenidaHecha = 'bienvenida_hecha';

  // Pantalla previa al permiso de notificaciones: cuántas veces se ha ofrecido y cuándo fue la última.
  static const String _claveOfertaAvisosVeces = 'oferta_avisos_veces';
  static const String _claveOfertaAvisosUltima = 'oferta_avisos_ultima';

  static Future<bool> obtenerInformesErrores() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_claveInformesErrores) ?? true;
  }

  static Future<void> guardarInformesErrores(bool activo) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_claveInformesErrores, activo);
  }

  static Future<bool> obtenerBienvenidaHecha() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_claveBienvenidaHecha) ?? false;
  }

  static Future<void> guardarBienvenidaHecha() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_claveBienvenidaHecha, true);
  }

  static Future<int> obtenerOfertaAvisosVeces() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_claveOfertaAvisosVeces) ?? 0;
  }

  static Future<DateTime?> obtenerOfertaAvisosUltima() async {
    final prefs = await SharedPreferences.getInstance();

    return DateTime.tryParse(prefs.getString(_claveOfertaAvisosUltima) ?? '');
  }

  /// Anota que se ha ofrecido la pantalla previa al permiso de notificaciones (una vez más, ahora).
  static Future<void> registrarOfertaAvisos(DateTime ahora) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _claveOfertaAvisosVeces,
      (prefs.getInt(_claveOfertaAvisosVeces) ?? 0) + 1,
    );
    await prefs.setString(_claveOfertaAvisosUltima, ahora.toIso8601String());
  }

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

  /// Los partidos seguidos: id -> día en que se juegan.
  static Future<Map<int, DateTime>> obtenerPartidosSeguidos() async {
    final prefs = await SharedPreferences.getInstance();
    final seguidos = <int, DateTime>{};

    for (final texto
        in prefs.getStringList(_clavePartidosSeguidos) ?? const <String>[]) {
      final partes = texto.split('|');
      final id = int.tryParse(partes.first);
      final fecha = partes.length > 1 ? DateTime.tryParse(partes[1]) : null;

      if (id != null && fecha != null) {
        seguidos[id] = DateTime(fecha.year, fecha.month, fecha.day);
      }
    }

    return seguidos;
  }

  static Future<void> guardarPartidosSeguidos(
    Map<int, DateTime> seguidos,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    String dia(DateTime f) =>
        '${f.year.toString().padLeft(4, "0")}-${f.month.toString().padLeft(2, "0")}-${f.day.toString().padLeft(2, "0")}';

    await prefs.setStringList(_clavePartidosSeguidos, [
      for (final e in seguidos.entries) '${e.key}|${dia(e.value)}',
    ]);
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
