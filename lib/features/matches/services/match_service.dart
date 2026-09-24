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

  Future<List<MatchModel>> obtenerUltimosPorEquipoId(
    int equipoId, {
    int limite = 5,
  }) async {
    final data =
        await ApiClient.get('/public/partidos?equipoId=$equipoId&limite=$limite')
            as List<dynamic>;

    return data
        .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<MatchModel>> obtenerUltimosPorEquipoNombre(
    String equipoNombre, {
    int limite = 5,
  }) async {
    final equipoCodificado = Uri.encodeQueryComponent(equipoNombre);

    final data = await ApiClient.get(
      '/public/partidos?equipo=$equipoCodificado&limite=$limite',
    ) as List<dynamic>;

    return data
        .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MatchModel> crearPartido({
    required int equipoId,
    required String rival,
    String? dia,
    String? hora,
    String? campo,
    String? resultado,
  }) async {
    final data = await ApiClient.post(
      '/app/partidos',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'rival': rival,
        'dia': dia,
        'hora': hora,
        'campo': campo,
        'resultado': resultado,
      },
    );

    return MatchModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MatchModel> actualizarPartido({
    required int partidoId,
    required int equipoId,
    required String rival,
    String? dia,
    String? hora,
    String? campo,
    String? resultado,
  }) async {
    final data = await ApiClient.put(
      '/app/partidos/$partidoId',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'rival': rival,
        'dia': dia,
        'hora': hora,
        'campo': campo,
        'resultado': resultado,
      },
    );

    return MatchModel.fromJson(data as Map<String, dynamic>);
  }
}
