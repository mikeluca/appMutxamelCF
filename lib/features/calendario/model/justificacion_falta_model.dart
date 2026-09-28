import '../../../core/utils/backend_date.dart';

/// Aviso informativo de falta a una sesión de entrenamiento, enviado por
/// el propio jugador o un familiar suyo. No requiere aprobación por parte
/// del entrenador, solo le informa.
class JustificacionFaltaModel {
  final int id;
  final int sesionId;
  final int jugadorId;
  final String jugador;
  final int usuarioAppId;
  final String? motivo;
  final DateTime? fechaCreacion;

  const JustificacionFaltaModel({
    required this.id,
    required this.sesionId,
    required this.jugadorId,
    required this.jugador,
    required this.usuarioAppId,
    this.motivo,
    this.fechaCreacion,
  });

  factory JustificacionFaltaModel.fromJson(Map<String, dynamic> json) {
    return JustificacionFaltaModel(
      id: json['id'] as int,
      sesionId: json['sesionId'] as int,
      jugadorId: json['jugadorId'] as int,
      jugador: json['jugador'] as String? ?? '',
      usuarioAppId: json['usuarioAppId'] as int,
      motivo: json['motivo'] as String?,
      fechaCreacion: parseFechaBackend(json['fechaCreacion']),
    );
  }
}
