class EntrenamientoModel {
  final int id;
  final int equipoId;
  final String equipo;
  final String fecha;
  final int usuarioEntrenadorId;
  final List<EntrenamientoAsistenciaModel> asistencias;

  /// true si el staff ya ha guardado la asistencia. Si el backend no lo envía
  /// se da por revisada, para no marcar listas que no sabemos si lo están.
  final bool listaRevisada;
  final String? fechaRevision;

  EntrenamientoModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    required this.fecha,
    required this.usuarioEntrenadorId,
    required this.asistencias,
    this.listaRevisada = true,
    this.fechaRevision,
  });

  factory EntrenamientoModel.fromJson(Map<String, dynamic> json) {
    return EntrenamientoModel(
      id: (json['id'] as num).toInt(),
      equipoId: (json['equipoId'] as num).toInt(),
      equipo: json['equipo']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      usuarioEntrenadorId: (json['usuarioEntrenadorId'] as num?)?.toInt() ?? 0,
      asistencias: (json['asistencias'] as List<dynamic>? ?? [])
          .map(
            (item) => EntrenamientoAsistenciaModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      listaRevisada: json['listaRevisada'] as bool? ?? true,
      fechaRevision: json['fechaRevision']?.toString(),
    );
  }
}

class EntrenamientoAsistenciaModel {
  final int jugadorId;
  final String jugador;
  final String estado;

  EntrenamientoAsistenciaModel({
    required this.jugadorId,
    required this.jugador,
    required this.estado,
  });

  factory EntrenamientoAsistenciaModel.fromJson(Map<String, dynamic> json) {
    return EntrenamientoAsistenciaModel(
      jugadorId: (json['jugadorId'] as num).toInt(),
      jugador: json['jugador']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
    );
  }
}
