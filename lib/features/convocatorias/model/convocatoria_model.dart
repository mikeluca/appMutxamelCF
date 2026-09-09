class ConvocatoriaModel {
  final int id;
  final int equipoId;
  final String equipo;
  final String rival;
  final String campo;
  final String fechaPartido;
  final String horaPartido;
  final String horaConvocatoria;
  final String lugarConvocatoria;
  final int usuarioEntrenadorId;
  final List<ConvocatoriaJugadorModel> jugadores;

  ConvocatoriaModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    required this.rival,
    required this.campo,
    required this.fechaPartido,
    required this.horaPartido,
    required this.horaConvocatoria,
    required this.lugarConvocatoria,
    required this.usuarioEntrenadorId,
    required this.jugadores,
  });

  factory ConvocatoriaModel.fromJson(Map<String, dynamic> json) {
    return ConvocatoriaModel(
      id: json['id'],
      equipoId: json['equipoId'],
      equipo: json['equipo'] ?? '',
      rival: json['rival'] ?? '',
      campo: json['campo'] ?? '',
      fechaPartido: json['fechaPartido'].toString(),
      horaPartido: json['horaPartido'] ?? '',
      horaConvocatoria: json['horaConvocatoria'] ?? '',
      lugarConvocatoria: json['lugarConvocatoria'] ?? '',
      usuarioEntrenadorId: json['usuarioEntrenadorId'],
      jugadores: (json['jugadores'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ConvocatoriaJugadorModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class ConvocatoriaJugadorModel {
  final int jugadorId;
  final String jugador;

  ConvocatoriaJugadorModel({required this.jugadorId, required this.jugador});

  factory ConvocatoriaJugadorModel.fromJson(Map<String, dynamic> json) {
    return ConvocatoriaJugadorModel(
      jugadorId: json['jugadorId'],
      jugador: json['jugador'] ?? '',
    );
  }
}
