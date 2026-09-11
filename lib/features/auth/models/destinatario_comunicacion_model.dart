class DestinatarioComunicacionModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String rol;

  const DestinatarioComunicacionModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.rol,
  });

  factory DestinatarioComunicacionModel.fromJson(Map<String, dynamic> json) {
    return DestinatarioComunicacionModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }

  String get nombreCompleto {
    final completo = '$nombre $apellidos'.trim();
    return completo.isEmpty ? 'Sin nombre' : completo;
  }
}
