class PlayerModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String categoria;
  final String equipo;
  final String deporte;
  final int? dorsal;

  /// El texto guardado tal cual (backend antiguo o un valor que no es de la lista).
  final String? posicion;

  /// PORTERO, DEFENSA, CENTROCAMPISTA, EXTREMO, DELANTERO o null si el texto guardado no coincide con ninguno.
  final String? posicionCodigo;
  final String? fotoBase64;

  /// El usuario puede editar el dorsal y la posición (gestiona el equipo). Un backend antiguo no lo manda: false.
  final bool editable;

  const PlayerModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.categoria,
    required this.equipo,
    required this.deporte,
    this.dorsal,
    this.posicion,
    this.posicionCodigo,
    this.fotoBase64,
    this.editable = false,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      categoria: json['categoria'] ?? '',
      equipo: json['equipo'] ?? '',
      deporte: json['deporte'] ?? '',
      dorsal: json['dorsal'],
      posicion: json['posicion'],
      posicionCodigo: json['posicionCodigo'],
      fotoBase64: json['fotoBase64'],
      editable: json['editable'] == true,
    );
  }

  /// El mismo jugador con otro dorsal y otra posición (lo que devuelve el backend al editarlos).
  PlayerModel conDorsalYPosicion({
    required int? dorsal,
    required String? posicion,
    required String? posicionCodigo,
  }) {
    return PlayerModel(
      id: id,
      nombre: nombre,
      apellidos: apellidos,
      categoria: categoria,
      equipo: equipo,
      deporte: deporte,
      dorsal: dorsal,
      posicion: posicion,
      posicionCodigo: posicionCodigo,
      fotoBase64: fotoBase64,
      editable: editable,
    );
  }

  String get nombreCompleto {
    return '$nombre $apellidos'.trim();
  }
}
