/// Estadística de un jugador en un partido. Se reutiliza el mismo modelo
/// tanto para lo que devuelve el backend (GET .../estadisticas, donde
/// viene informado `jugador` con el nombre) como para las filas editables
/// del formulario y el cuerpo de la petición PUT .../estadisticas (donde
/// el nombre simplemente se ignora al serializar, ya que el backend solo
/// necesita el id).
class EstadisticaJugadorModel {
  final int jugadorId;
  final String jugador;
  final int goles;
  final int asistencias;
  final int tarjetasAmarillas;
  final bool tarjetaRoja;

  const EstadisticaJugadorModel({
    required this.jugadorId,
    this.jugador = '',
    required this.goles,
    required this.asistencias,
    required this.tarjetasAmarillas,
    required this.tarjetaRoja,
  });

  factory EstadisticaJugadorModel.fromJson(Map<String, dynamic> json) {
    return EstadisticaJugadorModel(
      jugadorId: json['jugadorId'],
      jugador: json['jugador'] ?? '',
      goles: json['goles'] as int? ?? 0,
      asistencias: json['asistencias'] as int? ?? 0,
      tarjetasAmarillas: json['tarjetasAmarillas'] as int? ?? 0,
      tarjetaRoja: json['tarjetaRoja'] as bool? ?? false,
    );
  }

  /// Cuerpo esperado por el backend para esta fila dentro de
  /// PartidoEstadisticasGuardarRequest.jugadores (sin el nombre, que el
  /// backend no necesita en la petición).
  Map<String, dynamic> toJson() {
    return {
      'jugadorId': jugadorId,
      'goles': goles,
      'asistencias': asistencias,
      'tarjetasAmarillas': tarjetasAmarillas,
      'tarjetaRoja': tarjetaRoja,
    };
  }
}

/// Estadísticas (resultado y por jugador) guardadas para un partido.
/// Cuando todavía no se ha introducido ningún resultado, el backend
/// devuelve golesFavor/golesContra/resultado a null y jugadores vacío.
class PartidoEstadisticasModel {
  final int? partidoId;
  final int? golesFavor;
  final int? golesContra;
  final String? resultado;
  final List<EstadisticaJugadorModel> jugadores;

  const PartidoEstadisticasModel({
    this.partidoId,
    this.golesFavor,
    this.golesContra,
    this.resultado,
    this.jugadores = const [],
  });

  factory PartidoEstadisticasModel.fromJson(Map<String, dynamic> json) {
    return PartidoEstadisticasModel(
      partidoId: json['partidoId'],
      golesFavor: json['golesFavor'] as int?,
      golesContra: json['golesContra'] as int?,
      resultado: json['resultado'],
      jugadores: (json['jugadores'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                EstadisticaJugadorModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

/// Un jugador de la plantilla candidato a aparecer como fila del
/// formulario de estadísticas, con independencia de si procede de la
/// convocatoria del partido (cuando existe) o de la plantilla completa
/// del equipo (cuando no hay convocatoria para ese partido).
class RosterJugadorModel {
  final int jugadorId;
  final String jugador;

  const RosterJugadorModel({required this.jugadorId, required this.jugador});
}

/// Combina la plantilla a mostrar en el formulario con las estadísticas
/// ya guardadas para ese partido (si las hubiera), casando por
/// jugadorId (nunca por posición en la lista, ya que la plantilla puede
/// haber cambiado desde la última vez que se guardó el resultado).
///
/// Cualquier jugador de la plantilla sin estadística guardada se rellena
/// a 0/false. Cualquier estadística guardada de un jugador que ya no
/// está en la plantilla actual (p. ej. la convocatoria se editó después
/// de guardar el resultado) se descarta: el formulario solo debe
/// mostrar y enviar los jugadores de la plantilla vigente.
List<EstadisticaJugadorModel> fusionarRosterConEstadisticas({
  required List<RosterJugadorModel> roster,
  required List<EstadisticaJugadorModel> guardadas,
}) {
  final guardadasPorId = {
    for (final estadistica in guardadas) estadistica.jugadorId: estadistica,
  };

  return roster.map((jugador) {
    final guardada = guardadasPorId[jugador.jugadorId];

    return EstadisticaJugadorModel(
      jugadorId: jugador.jugadorId,
      jugador: jugador.jugador,
      goles: guardada?.goles ?? 0,
      asistencias: guardada?.asistencias ?? 0,
      tarjetasAmarillas: guardada?.tarjetasAmarillas ?? 0,
      tarjetaRoja: guardada?.tarjetaRoja ?? false,
    );
  }).toList();
}
