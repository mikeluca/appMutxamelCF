import '../../../core/network/api_client.dart';
import '../models/coordinacion_model.dart';

/// Paneles de coordinación (solo COORDINADOR y ADMIN_APP).
class CoordinacionService {
  /// El fin de semana de [fecha] (el servidor elige el viernes-domingo de
  /// referencia); sin fecha, el de hoy.
  Future<FinDeSemanaModel> obtenerFinDeSemana({DateTime? fecha}) async {
    final consulta = fecha == null ? '' : '?fecha=${_fechaApi(fecha)}';

    final data = await ApiClient.get(
      '/app/coordinacion/fin-de-semana$consulta',
      autenticado: true,
    );

    return FinDeSemanaModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SeguimientoJugadorModel>> obtenerSeguimiento({
    String periodo = periodoSeguimiento30d,
  }) async {
    final data = await ApiClient.get(
      '/app/coordinacion/seguimiento-jugadores?periodo=$periodo',
      autenticado: true,
    );

    return ((data as Map<String, dynamic>)['jugadores'] as List<dynamic>? ?? [])
        .map((e) => SeguimientoJugadorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SeguimientoDetalleModel> obtenerDetalle(
    int jugadorId, {
    String periodo = periodoSeguimiento30d,
  }) async {
    final data = await ApiClient.get(
      '/app/coordinacion/seguimiento-jugadores/$jugadorId?periodo=$periodo',
      autenticado: true,
    );

    return SeguimientoDetalleModel.fromJson(data as Map<String, dynamic>);
  }

  static String _fechaApi(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '${fecha.year.toString().padLeft(4, '0')}-$mes-$dia';
  }
}
