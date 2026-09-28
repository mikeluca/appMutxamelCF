import '../../../core/network/api_client.dart';
import '../model/calendario_model.dart';
import '../model/horario_entrenamiento_model.dart';
import '../model/justificacion_falta_model.dart';
import '../model/sesion_entrenamiento_model.dart';

class CalendarioService {
  String _formatearFecha(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // CALENDARIO COMBINADO (sesiones + partidos)
  // ============================================================

  Future<CalendarioModel> obtenerCalendario({
    required int equipoId,
    required DateTime desde,
    required DateTime hasta,
    int? jugadorId,
  }) async {
    final data = await ApiClient.get(
      '/app/calendario?equipoId=$equipoId'
      '&desde=${_formatearFecha(desde)}'
      '&hasta=${_formatearFecha(hasta)}'
      '${jugadorId != null ? '&jugadorId=$jugadorId' : ''}',
      autenticado: true,
    );

    return CalendarioModel.fromJson(data as Map<String, dynamic>);
  }

  // ============================================================
  // HORARIOS SEMANALES DE ENTRENAMIENTO
  // ============================================================

  Future<List<HorarioEntrenamientoModel>> obtenerHorarios(
    int equipoId,
  ) async {
    final data =
        await ApiClient.get(
              '/app/horarios-entrenamiento?equipoId=$equipoId',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map(
          (item) => HorarioEntrenamientoModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<HorarioEntrenamientoModel> crearHorario({
    required int equipoId,
    required int diaSemana,
    required String hora,
    String? lugar,
  }) async {
    final data = await ApiClient.post(
      '/app/horarios-entrenamiento',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'diaSemana': diaSemana,
        'hora': hora,
        'lugar': lugar,
      },
    );

    return HorarioEntrenamientoModel.fromJson(data as Map<String, dynamic>);
  }

  Future<HorarioEntrenamientoModel> actualizarHorario({
    required int horarioId,
    required int diaSemana,
    required String hora,
    String? lugar,
    required bool activo,
  }) async {
    final data = await ApiClient.put(
      '/app/horarios-entrenamiento/$horarioId',
      autenticado: true,
      body: {
        'diaSemana': diaSemana,
        'hora': hora,
        'lugar': lugar,
        'activo': activo,
      },
    );

    return HorarioEntrenamientoModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> eliminarHorario(int horarioId) async {
    await ApiClient.delete(
      '/app/horarios-entrenamiento/$horarioId',
      autenticado: true,
    );
  }

  // ============================================================
  // SESIONES DE ENTRENAMIENTO
  // ============================================================

  Future<List<SesionEntrenamientoModel>> obtenerSesiones({
    required int equipoId,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final data =
        await ApiClient.get(
              '/app/sesiones-entrenamiento?equipoId=$equipoId'
              '&desde=${_formatearFecha(desde)}'
              '&hasta=${_formatearFecha(hasta)}',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map(
          (item) => SesionEntrenamientoModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<SesionEntrenamientoModel> crearSesion({
    required int equipoId,
    required DateTime fecha,
    String? hora,
    String? lugar,
  }) async {
    final data = await ApiClient.post(
      '/app/sesiones-entrenamiento',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'fecha': _formatearFecha(fecha),
        'hora': hora,
        'lugar': lugar,
      },
    );

    return SesionEntrenamientoModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SesionEntrenamientoModel> actualizarSesion({
    required int sesionId,
    String? hora,
    String? lugar,
  }) async {
    final data = await ApiClient.put(
      '/app/sesiones-entrenamiento/$sesionId',
      autenticado: true,
      body: {'hora': hora, 'lugar': lugar},
    );

    return SesionEntrenamientoModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> cancelarSesion(int sesionId, String motivo) async {
    await ApiClient.post(
      '/app/sesiones-entrenamiento/$sesionId/cancelar',
      autenticado: true,
      body: {'motivo': motivo},
    );
  }

  // ============================================================
  // JUSTIFICACIONES DE FALTA
  // ============================================================

  Future<JustificacionFaltaModel> justificarFalta({
    required int sesionId,
    required int jugadorId,
    String? motivo,
  }) async {
    final data = await ApiClient.post(
      '/app/sesiones-entrenamiento/$sesionId/justificaciones',
      autenticado: true,
      body: {'jugadorId': jugadorId, 'motivo': motivo},
    );

    return JustificacionFaltaModel.fromJson(data as Map<String, dynamic>);
  }

  /// Vista del entrenador: quién ha justificado su falta a una sesión.
  /// El backend devuelve 403 si quien llama no puede gestionar el equipo.
  Future<List<JustificacionFaltaModel>> obtenerJustificaciones(
    int sesionId,
  ) async {
    final data =
        await ApiClient.get(
              '/app/sesiones-entrenamiento/$sesionId/justificaciones',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map(
          (item) => JustificacionFaltaModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // PARTIDOS (cancelación, compartida con la gestión de calendario)
  // ============================================================

  Future<void> cancelarPartido(int partidoId) async {
    await ApiClient.post('/app/partidos/$partidoId/cancelar', autenticado: true);
  }
}
