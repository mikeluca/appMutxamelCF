import '../config/app_config.dart';

class ApiClient {
  ApiClient._();

  static String get baseUrl => AppConfig.apiBaseUrl;
}