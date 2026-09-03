class PerfilApp {
  final int usuarioId;
  final String email;
  final List<String> roles;

  final String? nombre;
  final String? apellidos;
  final String? telefono;

  final DateTime? fechaAlta;
  final DateTime? fechaActivacion;
  final DateTime? fechaUltimoAcceso;

  final List<PerfilJugador> jugadores;
  final List<PerfilEquipo> equipos;

  PerfilApp({
    required this.usuarioId,
    required this.email,
    required this.roles,
    this.nombre,
    this.apellidos,
    this.telefono,
    this.fechaAlta,
    this.fechaActivacion,
    this.fechaUltimoAcceso,
    required this.jugadores,
    required this.equipos,
  });

  factory PerfilApp.fromJson(Map<String, dynamic> json) {
    return PerfilApp(
      usuarioId: json['usuarioId'] as int,
      email: json['email'] as String,
      roles: List<String>.from(json['roles'] ?? []),

      nombre: json['nombre'] as String?,
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,

      fechaAlta: _fechaDesdeTimestamp(json['fechaAlta']),
      fechaActivacion: _fechaDesdeTimestamp(json['fechaActivacion']),
      fechaUltimoAcceso: _fechaDesdeTimestamp(json['fechaUltimoAcceso']),

      jugadores: (json['jugadores'] as List<dynamic>? ?? [])
          .map((item) => PerfilJugador.fromJson(item as Map<String, dynamic>))
          .toList(),

      equipos: (json['equipos'] as List<dynamic>? ?? [])
          .map((item) => PerfilEquipo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime? _fechaDesdeTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(value as int);
  }

  bool tieneRol(String rol) {
    return roles.contains(rol);
  }

  String get nombreCompleto {
    final partes = [
      nombre,
      apellidos,
    ].where((parte) => parte != null && parte.trim().isNotEmpty);

    return partes.join(' ');
  }
}

class PerfilJugador {
  final int id;
  final String nombre;
  final String apellidos;
  final String? categoria;
  final String? equipo;
  final String? deporte;
  final int? dorsal;
  final String? posicion;

  PerfilJugador({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.categoria,
    this.equipo,
    this.deporte,
    this.dorsal,
    this.posicion,
  });

  factory PerfilJugador.fromJson(Map<String, dynamic> json) {
    return PerfilJugador(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      categoria: json['categoria'] as String?,
      equipo: json['equipo'] as String?,
      deporte: json['deporte'] as String?,
      dorsal: json['dorsal'] as int?,
      posicion: json['posicion'] as String?,
    );
  }

  String get nombreCompleto {
    return '$nombre $apellidos'.trim();
  }
}

class PerfilEquipo {
  final int id;
  final String nombre;
  final String? categoria;
  final String? grupo;
  final String? deporte;

  PerfilEquipo({
    required this.id,
    required this.nombre,
    this.categoria,
    this.grupo,
    this.deporte,
  });

  factory PerfilEquipo.fromJson(Map<String, dynamic> json) {
    return PerfilEquipo(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      categoria: json['categoria'] as String?,
      grupo: json['grupo'] as String?,
      deporte: json['deporte'] as String?,
    );
  }
}
