import '../../../core/network/api_client.dart';
import '../models/continuidad_model.dart';

/// Confirmación de continuidad de las familias (GET y PUT
/// /api/app/continuidad).
class ContinuidadService {
  /// Los jugadores del usuario a los que ya se ha preguntado. Vacía si no hay
  /// nada que confirmar.
  Future<List<ContinuidadJugadorModel>> listar() async {
    final data = await ApiClient.get('/app/continuidad', autenticado: true);

    return (data as List<dynamic>? ?? [])
        .map((e) => ContinuidadJugadorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Guarda [respuesta] (SIGUE, NO_SIGUE o DUDA) y devuelve el estado nuevo.
  /// Errores: 400 si no procede, 403 sin vínculo con el jugador y 409 si no
  /// hay temporada siguiente.
  Future<ContinuidadJugadorModel> responder(
    int jugadorId,
    String respuesta,
  ) async {
    final data = await ApiClient.put(
      '/app/continuidad/$jugadorId',
      autenticado: true,
      body: {'respuesta': respuesta},
    );

    return ContinuidadJugadorModel.fromJson(data as Map<String, dynamic>);
  }
}
