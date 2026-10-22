import '../../../core/network/api_client.dart';
import '../model/convocatoria_partido_model.dart';

/// La convocatoria de un partido para JUGADOR/FAMILIAR. El backend responde 403
/// si el usuario no está vinculado al jugador o el jugador es de otro equipo, y
/// 404 si el partido todavía no tiene convocatoria.
class ConvocatoriaPartidoService {
  Future<ConvocatoriaPartidoModel> obtener({
    required int partidoId,
    required int jugadorId,
  }) async {
    final data = await ApiClient.get(
      '/app/partidos/$partidoId/convocatoria?jugadorId=$jugadorId',
      autenticado: true,
    );

    return ConvocatoriaPartidoModel.fromJson(data as Map<String, dynamic>);
  }
}
