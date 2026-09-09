class FamiliarJugadorModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String? telefono;
  final String? email;
  final int whatsappActivo;
  final String? parentesco;
  final int esPrincipal;

  FamiliarJugadorModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.telefono,
    this.email,
    required this.whatsappActivo,
    this.parentesco,
    required this.esPrincipal,
  });

  factory FamiliarJugadorModel.fromJson(Map<String, dynamic> json) {
    return FamiliarJugadorModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      whatsappActivo: json['whatsappActivo'] as int? ?? 0,
      parentesco: json['parentesco'] as String?,
      esPrincipal: json['esPrincipal'] as int? ?? 0,
    );
  }

  String get nombreCompleto {
    return '$nombre $apellidos'.trim();
  }

  bool get tieneWhatsapp {
    return whatsappActivo == 1;
  }

  bool get esFamiliarPrincipal {
    return esPrincipal == 1;
  }
}
