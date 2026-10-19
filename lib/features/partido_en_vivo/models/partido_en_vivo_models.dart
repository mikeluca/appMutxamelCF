/// Fases del partido en directo, tal como las calcula el backend.
enum FasePartido {
  sinEmpezar,
  primeraParte,
  descanso,
  segundaParte,
  finalPartido;

  static FasePartido desdeTexto(String? texto) {
    return switch (texto) {
      'PRIMERA_PARTE' => FasePartido.primeraParte,
      'DESCANSO' => FasePartido.descanso,
      'SEGUNDA_PARTE' => FasePartido.segundaParte,
      'FINAL' => FasePartido.finalPartido,
      _ => FasePartido.sinEmpezar,
    };
  }
}

/// Un partido de hoy del Primer Equipo que se puede retransmitir.
class PartidoEnVivoDisponible {
  final int id;
  final String rival;
  final String? hora;
  final String? campo;

  /// true si el Mutxamel juega de local.
  final bool local;

  const PartidoEnVivoDisponible({
    required this.id,
    required this.rival,
    this.hora,
    this.campo,
    this.local = true,
  });

  factory PartidoEnVivoDisponible.fromJson(Map<String, dynamic> json) {
    return PartidoEnVivoDisponible(
      id: (json['id'] as num).toInt(),
      rival: json['rival'] as String? ?? '',
      hora: json['hora'] as String?,
      campo: json['campo'] as String?,
      local: json['local'] as bool? ?? true,
    );
  }
}

/// Un jugador entre los que elegir al autor de un gol.
class ConvocadoEnVivo {
  final int jugadorId;
  final int? dorsal;
  final String nombre;

  const ConvocadoEnVivo({
    required this.jugadorId,
    this.dorsal,
    required this.nombre,
  });

  factory ConvocadoEnVivo.fromJson(Map<String, dynamic> json) {
    return ConvocadoEnVivo(
      jugadorId: (json['jugadorId'] as num).toInt(),
      dorsal: (json['dorsal'] as num?)?.toInt(),
      nombre: json['nombre'] as String? ?? '',
    );
  }
}

class EventoEnVivo {
  final int id;

  /// INICIO, GOL_FAVOR, GOL_CONTRA, DESCANSO, SEGUNDA_PARTE o FINAL.
  final String tipo;
  final int? jugadorId;

  /// Nombre del jugador, texto libre o 'p.p.'.
  final String? autor;
  final DateTime? fecha;

  const EventoEnVivo({
    required this.id,
    required this.tipo,
    this.jugadorId,
    this.autor,
    this.fecha,
  });

  factory EventoEnVivo.fromJson(Map<String, dynamic> json) {
    return EventoEnVivo(
      id: (json['id'] as num).toInt(),
      tipo: json['tipo'] as String? ?? '',
      jugadorId: (json['jugadorId'] as num?)?.toInt(),
      autor: json['autor'] as String?,
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
    );
  }
}

/// Estado del partido en directo (GET /api/app/partido-en-vivo/{partidoId}).
class EstadoPartidoEnVivo {
  /// Autor de un gol en propia puerta del rival, tal como llega del backend.
  static const String propiaPuerta = 'p.p.';

  final int partidoId;
  final String rival;
  final bool local;
  final FasePartido fase;
  final int golesFavor;
  final int golesContra;
  final List<String> goleadores;
  final List<EventoEnVivo> eventos;

  /// El último evento si todavía se puede deshacer, y hasta cuándo.
  final int? deshacibleId;
  final DateTime? deshacibleExpira;

  const EstadoPartidoEnVivo({
    required this.partidoId,
    this.rival = '',
    this.local = true,
    this.fase = FasePartido.sinEmpezar,
    this.golesFavor = 0,
    this.golesContra = 0,
    this.goleadores = const [],
    this.eventos = const [],
    this.deshacibleId,
    this.deshacibleExpira,
  });

  factory EstadoPartidoEnVivo.fromJson(Map<String, dynamic> json) {
    final deshacible = json['ultimoEventoDeshacible'] as Map<String, dynamic>?;

    return EstadoPartidoEnVivo(
      partidoId: (json['partidoId'] as num).toInt(),
      rival: json['rival'] as String? ?? '',
      local: json['local'] as bool? ?? true,
      fase: FasePartido.desdeTexto(json['fase'] as String?),
      golesFavor: (json['golesFavor'] as num?)?.toInt() ?? 0,
      golesContra: (json['golesContra'] as num?)?.toInt() ?? 0,
      goleadores: List<String>.from(json['goleadores'] ?? const []),
      eventos: (json['eventos'] as List<dynamic>? ?? const [])
          .map((e) => EventoEnVivo.fromJson(e as Map<String, dynamic>))
          .toList(),
      deshacibleId: (deshacible?['id'] as num?)?.toInt(),
      deshacibleExpira: DateTime.tryParse(
        deshacible?['expira']?.toString() ?? '',
      ),
    );
  }

  /// El evento que se puede deshacer, si lo hay.
  EventoEnVivo? get eventoDeshacible {
    if (deshacibleId == null) {
      return null;
    }

    for (final evento in eventos) {
      if (evento.id == deshacibleId) {
        return evento;
      }
    }

    return null;
  }
}
