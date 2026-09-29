class AppConfig {
  AppConfig._();

  static const String apiBaseUrl =
      'https://api.mutxamelcf.es/api'; //ENTORNO PRO
  //static const String apiBaseUrl = 'http://192.168.1.160:8080/api'; //ENTORNO DEV
  //static const String apiBaseUrl = 'http://88.18.223.106:8080/api'; //ENTORNO DEV-IP-EXTERNA

  static String get mediaBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return uri.origin;
  }
}
