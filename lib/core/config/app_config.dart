class AppConfig {
  AppConfig._();

  /// Cuotas aún no está disponible: la tarjeta de Club se oculta porque Apple
  /// rechaza funciones "próximamente" (guidelines 2.1/2.2). CuotasPage, su ruta
  /// y los textos siguen en el código; se reactiva poniendo esto a true.
  static const bool cuotasDisponibles = false;

  static const String apiBaseUrl =
      'https://api.mutxamelcf.es/api'; //ENTORNO PRO

  static String get mediaBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return uri.origin;
  }
}
