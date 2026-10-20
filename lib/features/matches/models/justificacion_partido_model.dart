/// Ausencia justificada de un jugador a un partido
/// (GET /api/app/partidos/{id}/justificaciones, vista del entrenador).
class JustificacionPartidoModel {
  final int partidoId;
  final int jugadorId;
  final String jugador;
  final String motivo;
  final DateTime? fechaCreacion;

  const JustificacionPartidoModel({
    required this.partidoId,
    required this.jugadorId,
    required this.jugador,
    required this.motivo,
    this.fechaCreacion,
  });

  factory JustificacionPartidoModel.fromJson(Map<String, dynamic> json) {
    return JustificacionPartidoModel(
      partidoId: (json['partidoId'] as num).toInt(),
      jugadorId: (json['jugadorId'] as num).toInt(),
      jugador: json['jugador'] as String? ?? '',
      motivo: json['motivo'] as String? ?? '',
      fechaCreacion: DateTime.tryParse(json['fechaCreacion']?.toString() ?? ''),
    );
  }
}
