/// Horario semanal fijo de entrenamiento de un equipo (p.ej. "todos los
/// martes a las 18:00 en el campo municipal"). Cada alta/edición dispara,
/// en el backend, la generación inmediata de las sesiones concretas
/// correspondientes.
class HorarioEntrenamientoModel {
  final int id;
  final int equipoId;
  final String equipo;

  /// 1 = lunes ... 7 = domingo.
  final int diaSemana;

  /// Formato "HH:mm".
  final String hora;
  final String? lugar;
  final bool activo;

  const HorarioEntrenamientoModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    required this.diaSemana,
    required this.hora,
    this.lugar,
    required this.activo,
  });

  factory HorarioEntrenamientoModel.fromJson(Map<String, dynamic> json) {
    return HorarioEntrenamientoModel(
      id: json['id'] as int,
      equipoId: json['equipoId'] as int,
      equipo: json['equipo'] as String? ?? '',
      diaSemana: json['diaSemana'] as int,
      hora: json['hora'] as String? ?? '',
      lugar: json['lugar'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
