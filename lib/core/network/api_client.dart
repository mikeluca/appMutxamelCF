import '../config/app_config.dart';

class ApiClient {
  ApiClient._();

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
  };

  static String get baseUrl => AppConfig.apiBaseUrl;
}