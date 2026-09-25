import '../../../core/network/api_client.dart';
import '../models/news_model.dart';

class NewsService {
  /// Trae una página de noticias, ordenada de más reciente a más
  /// antigua dentro de esa página.
  ///
  /// Sin [antesId]: las últimas [limite] noticias (las más
  /// recientes). Con [antesId] (el id de la noticia más antigua ya
  /// cargada): las [limite] noticias siguientes, anteriores a esa.
  Future<List<NewsModel>> obtenerNoticias({int? antesId, int limite = 5}) async {
    final params = <String>['limite=$limite'];

    if (antesId != null) {
      params.add('antesId=$antesId');
    }

    final decoded = await ApiClient.get(
      '/public/noticias?${params.join('&')}',
    );

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
