class EntrenamientoModel {
  final int id;
  final int equipoId;
  final String equipo;
  final String fecha;
  final int usuarioEntrenadorId;
  final List<EntrenamientoAsistenciaModel> asistencias;

  EntrenamientoModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    required this.fecha,
    required this.usuarioEntrenadorId,
    required this.asistencias,
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
