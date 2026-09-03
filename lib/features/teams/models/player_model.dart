class PlayerModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String categoria;
  final String equipo;
  final String deporte;
  final int? dorsal;
  final String? posicion;
  final String? fotoBase64;

  const PlayerModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.categoria,
    required this.equipo,
    required this.deporte,
    this.dorsal,
    this.posicion,
    this.fotoBase64,
  });

  factory PlayerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PlayerModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      categoria: json['categoria'] ?? '',
      equipo: json['equipo'] ?? '',
      deporte: json['deporte'] ?? '',
      dorsal: json['dorsal'],
      posicion: json['posicion'],
      fotoBase64: json['fotoBase64'],
    );
  }

  String get nombreCompleto {
    return '$nombre $apellidos'.trim();
  }
}