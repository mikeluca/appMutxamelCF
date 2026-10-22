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
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] ?? 0,
      categoria: json['categoria'] ?? '',
      grupo: json['grupo'] ?? '',
      orden: json['orden'] ?? '',
      nombre: json['nombre'] ?? '',
      deporte: json['deporte'] ?? '',
      modalidad: json['modalidad'] as String?,
    );
  }

  /// Solo los equipos de fútbol 11 registran estadísticas individuales.
  bool get admiteEstadisticas => modalidad == 'F11';
}
