import '../../../core/network/api_client.dart';
import '../models/resumen_temporada_model.dart';

class ResumenTemporadaService {
  /// Resumen de la temporada activa del jugador. El backend responde 403 si el
  /// usuario no tiene vínculo con él.
  Future<ResumenTemporadaModel> obtenerResumen(int jugadorId) async {
    final data = await ApiClient.get(
      '/app/jugadores/$jugadorId/resumen-temporada',
      autenticado: true,
    );

    return ResumenTemporadaModel.fromJson(data as Map<String, dynamic>);
  }
}
