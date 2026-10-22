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

  /// Recuerda al entrenador del partido que publique la convocatoria
  /// ([tipoRecordatorioConvocatoria]) o meta el resultado
  /// ([tipoRecordatorioResultado]). Errores del servidor: 400 si no procede, 403
  /// sin rol, 409 si el equipo no tiene entrenadores con cuenta y 429 si ya se
  /// recordó hace menos de 2 horas (con la hora del último en `datos["ultimo"]`).
  Future<RecordatorioEnviadoModel> recordar({
    required int partidoId,
    required String tipo,
  }) async {
    final data = await ApiClient.post(
      '/app/coordinacion/recordatorios',
      autenticado: true,
      body: {'partidoId': partidoId, 'tipo': tipo},
    );

    return RecordatorioEnviadoModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SeguimientoModel> obtenerSeguimiento({
    String periodo = periodoSeguimiento30d,
  }) async {
    final data = await ApiClient.get(
      '/app/coordinacion/seguimiento-jugadores?periodo=$periodo',
      autenticado: true,
    );

    return SeguimientoModel.fromJson(data as Map<String, dynamic>);
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
