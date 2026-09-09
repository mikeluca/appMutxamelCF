class AppConfig {
  AppConfig._();

  // static const String apiBaseUrl = 'http://88.18.223.106:8080/api';
  static const String apiBaseUrl = 'http://192.168.1.36:8080/api';

  static String get mediaBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return uri.origin;
  }
}
