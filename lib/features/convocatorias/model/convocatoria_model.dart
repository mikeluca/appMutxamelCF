class ConvocatoriaModel {
  final int id;
  final int equipoId;
  final String equipo;
  final int partidoId;

  /// Rival/campo/fecha/hora del partido: el backend ya no los guarda en
  /// la convocatoria, los lee en vivo del partido vinculado (partidoId)
  /// y los expone aquí igual que antes para no romper la UI existente.
  final String rival;
  final String campo;
  final String fechaPartido;
  final String horaPartido;

  final String horaConvocatoria;
  final String lugarConvocatoria;
  final int usuarioEntrenadorId;
  final List<ConvocatoriaJugadorModel> jugadores;

  /// Cuántos convocados van, no pueden o aún no han respondido.
  int get van => jugadores.where((j) => j.respuesta == 'VA').length;

  int get noPueden =>
      jugadores.where((j) => j.respuesta == 'NO_PUEDE').length;

  int get sinResponder => jugadores.length - van - noPueden;

  ConvocatoriaModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    required this.partidoId,
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
      partidoId: json['partidoId'],
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

  /// 'VA', 'NO_PUEDE' o null (sin responder).
  final String? respuesta;
  final String? motivo;
  final DateTime? fechaRespuesta;

  ConvocatoriaJugadorModel({
    required this.jugadorId,
    required this.jugador,
    this.respuesta,
    this.motivo,
    this.fechaRespuesta,
  });

  factory ConvocatoriaJugadorModel.fromJson(Map<String, dynamic> json) {
    return ConvocatoriaJugadorModel(
      jugadorId: json['jugadorId'],
      jugador: json['jugador'] ?? '',
      respuesta: json['respuesta'] as String?,
      motivo: json['motivo'] as String?,
      fechaRespuesta: DateTime.tryParse(json['fechaRespuesta']?.toString() ?? ''),
    );
  }
}
