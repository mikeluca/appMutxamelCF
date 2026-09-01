import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/news_model.dart';

class NewsService {
  Future<List<NewsModel>> obtenerNoticias() async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/public/noticias',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener las noticias: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded is List
        ? decoded
        : (decoded['content'] ?? decoded['data'] ?? decoded['noticias'] ?? []);

    return data
        .map(
          (json) => NewsModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}