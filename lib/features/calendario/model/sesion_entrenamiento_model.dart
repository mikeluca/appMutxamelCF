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

  const SesionEntrenamientoModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    this.horarioId,
    required this.fecha,
    this.hora,
    this.lugar,
    required this.estado,
  });

  factory SesionEntrenamientoModel.fromJson(Map<String, dynamic> json) {
    return SesionEntrenamientoModel(
      id: json['id'] as int,
      equipoId: json['equipoId'] as int,
      equipo: json['equipo'] as String? ?? '',
      horarioId: json['horarioId'] as int?,
      fecha: DateTime.parse(json['fecha'] as String),
      hora: json['hora'] as String?,
      lugar: json['lugar'] as String?,
      estado: json['estado'] as String? ?? 'PROGRAMADA',
    );
  }

  bool get cancelada => estado == 'CANCELADA';
}
