import '../../../core/utils/backend_date.dart';

/// Sesión concreta de entrenamiento (generada a partir de un horario
/// recurrente, o dada de alta suelta) dentro del calendario de un equipo.
class SesionEntrenamientoModel {
  final int id;
  final int equipoId;
  final String equipo;
  final int? horarioId;
  final DateTime fecha;

  /// Formato "HH:mm".
  final String? hora;
  final String? lugar;

  /// "PROGRAMADA" | "CANCELADA".
  final String estado;

  /// Solo viene relleno cuando el calendario se consultó indicando un
  /// jugador concreto (vista jugador/familiar): si ESE jugador ya ha
  /// justificado su falta a esta sesión, y con qué motivo.
  final bool justificado;
  final String? motivoJustificacion;

  /// Solo relleno cuando estado == "CANCELADA": motivo obligatorio que
  /// indicó el entrenador/coordinador al cancelarla.
  final String? motivoCancelacion;

  /// Estado de asistencia del jugador ("PRESENTE"/"FALTA"/
  /// "FALTA_JUSTIFICADA"/"MAL_COMPORTAMIENTO"/"RETRASO") al entrenamiento
  /// vinculado a esta sesión. Solo viene relleno, igual que justificado,
  /// cuando el calendario se consultó indicando un jugador concreto Y la
  /// sesión ya ha pasado (la asistencia se registra durante/después de
  /// la sesión, no antes).
  final String? asistencia;

  const SesionEntrenamientoModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    this.horarioId,
    required this.fecha,
    this.hora,
    this.lugar,
    required this.estado,
    this.justificado = false,
    this.motivoJustificacion,
    this.motivoCancelacion,
    this.asistencia,
  });

  factory SesionEntrenamientoModel.fromJson(Map<String, dynamic> json) {
    return SesionEntrenamientoModel(
      id: json['id'] as int,
      equipoId: json['equipoId'] as int,
      equipo: json['equipo'] as String? ?? '',
      horarioId: json['horarioId'] as int?,
      fecha: parseFechaBackend(json['fecha'])!,
      hora: json['hora'] as String?,
      lugar: json['lugar'] as String?,
      estado: json['estado'] as String? ?? 'PROGRAMADA',
      justificado: json['justificado'] as bool? ?? false,
      motivoJustificacion: json['motivoJustificacion'] as String?,
      motivoCancelacion: json['motivoCancelacion'] as String?,
      asistencia: json['asistencia'] as String?,
    );
  }

  bool get cancelada => estado == 'CANCELADA';
}
