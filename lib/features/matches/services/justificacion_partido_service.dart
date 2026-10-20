import '../../../core/network/api_client.dart';
import '../models/justificacion_partido_model.dart';

/// Ausencia justificada a partidos. Justifican y retiran el propio jugador o
/// un familiar; la consulta es del cuerpo técnico. El plazo y los permisos los
/// comprueba el backend.
class JustificacionPartidoService {
  /// Crea o actualiza la justificación (el motivo es obligatorio).
  Future<JustificacionPartidoModel> justificar({
    required int partidoId,
    required int jugadorId,
    required String motivo,
  }) async {
    final data = await ApiClient.post(
      '/app/partidos/$partidoId/justificaciones',
      autenticado: true,
      body: {'jugadorId': jugadorId, 'motivo': motivo},
    );

    return JustificacionPartidoModel.fromJson(data as Map<String, dynamic>);
  }

  /// Retira la justificación del jugador.
  Future<void> retirar({required int partidoId, required int jugadorId}) async {
    await ApiClient.delete(
      '/app/partidos/$partidoId/justificaciones/$jugadorId',
      autenticado: true,
    );
  }

  /// Vista del entrenador: quién ha justificado su ausencia a este partido.
  /// El backend devuelve 403 si quien llama no gestiona el equipo.
  Future<List<JustificacionPartidoModel>> obtener(int partidoId) async {
    final data =
        await ApiClient.get(
              '/app/partidos/$partidoId/justificaciones',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map(
          (item) =>
              JustificacionPartidoModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
