class StaffModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String categoria;
  final String equipo;
  final String deporte;
  final String? puesto;
  final String? fotoBase64;

  const StaffModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.categoria,
    required this.equipo,
    required this.deporte,
    this.puesto,
    this.fotoBase64,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      categoria: json['categoria'] ?? '',
      equipo: json['equipo'] ?? '',
      deporte: json['deporte'] ?? '',
      puesto: json['puesto'],
      fotoBase64: json['fotoBase64'],
    );
  }

  String get nombreCompleto {
    return '$nombre $apellidos'.trim();
  }
}
