class AppConfig {
  AppConfig._();

  //static const String apiBaseUrl = 'https://api.mutxamelcf.es/api'; //ENTORNO PRO
  static const String apiBaseUrl =
      'http://192.168.1.160:8080/api'; //ENTORNO DEV

  static String get mediaBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return uri.origin;
  }
}
