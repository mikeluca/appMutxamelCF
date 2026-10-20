import '../../../core/network/api_client.dart';
import '../models/estadisticas_equipo_model.dart';

/// Tarjetas y estadísticas de un equipo (solo su cuerpo técnico).
class EstadisticasEquipoService {
  Future<List<TarjetasJugadorModel>> obtenerTarjetas(int equipoId) async {
    final data =
        await ApiClient.get(
              '/app/equipos/$equipoId/tarjetas',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map((e) => TarjetasJugadorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EstadisticasEquipoModel> obtenerEstadisticas(int equipoId) async {
    final data = await ApiClient.get(
      '/app/equipos/$equipoId/estadisticas',
      autenticado: true,
    );

    return EstadisticasEquipoModel.fromJson(data as Map<String, dynamic>);
  }
}
