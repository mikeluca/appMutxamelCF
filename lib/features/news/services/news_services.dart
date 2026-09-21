import '../../../core/network/api_client.dart';
import '../models/news_model.dart';

class NewsService {
  Future<List<NewsModel>> obtenerNoticias() async {
    final decoded = await ApiClient.get('/public/noticias');

    final List<dynamic> data = decoded is List
        ? decoded
        : ((decoded as Map<String, dynamic>)['content'] ??
                  decoded['data'] ??
                  decoded['noticias'] ??
                  [])
              as List<dynamic>;

    return data
        .map(
          (json) => NewsModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
