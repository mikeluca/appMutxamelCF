class TeamModel {
  final int id;
  final String categoria;
  final String grupo;
  final String orden;
  final String nombre;
  final String deporte;

  const TeamModel({
    required this.id,
    required this.categoria,
    required this.grupo,
    required this.orden,
    required this.nombre,
    required this.deporte,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] ?? 0,
      categoria: json['categoria'] ?? '',
      grupo: json['grupo'] ?? '',
      orden: json['orden'] ?? '',
      nombre: json['nombre'] ?? '',
      deporte: json['deporte'] ?? '',
    );
  }
}
