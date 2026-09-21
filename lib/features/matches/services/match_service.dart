import '../../../core/network/api_client.dart';
import '../models/match_model.dart';

class MatchService {
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async {
    try {
      final data = await ApiClient.get('/public/resultados/primer-equipo');

      return MatchModel.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  Future<List<MatchModel>> obtenerResultados() async {
    final data = await ApiClient.get('/public/resultados') as List<dynamic>;

    return data
        .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
