import '../../../core/utils/modalidad.dart';

class TeamModel {
  final int id;
  final String categoria;
  final String grupo;
  final String orden;
  final String nombre;
  final String deporte;

  /// F11, F8 o F5; null si el equipo no tiene modalidad.
  final String? modalidad;

  const TeamModel({
    required this.id,
    required this.categoria,
    required this.grupo,
    required this.orden,
    required this.nombre,
    required this.deporte,
    this.modalidad,
    bool? admiteEstadisticas,
  }) : admiteEstadisticas = admiteEstadisticas ?? modalidad == 'F11';

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] ?? 0,
      categoria: json['categoria'] ?? '',
      grupo: json['grupo'] ?? '',
      orden: json['orden'] ?? '',
      nombre: json['nombre'] ?? '',
      deporte: json['deporte'] ?? '',
      modalidad: json['modalidad'] as String?,

      admiteEstadisticas: leerAdmiteEstadisticas(json),
    );
  }

  /// Solo los equipos de fútbol 11 registran estadísticas individuales; sin la
  /// clave "modalidad" en el JSON (backend antiguo) se asume que sí.
  final bool admiteEstadisticas;
}
