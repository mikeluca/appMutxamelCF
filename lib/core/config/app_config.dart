class AppConfig {
  AppConfig._();

  static const String apiBaseUrl =
      'https://api.mutxamelcf.es/api'; //ENTORNO PRO

  static String get mediaBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return uri.origin;
  }
}
