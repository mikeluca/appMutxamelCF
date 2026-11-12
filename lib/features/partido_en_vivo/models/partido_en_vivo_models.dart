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

  /// F11, F8 o F5 si el backend la envía (hoy no): marca cuántos titulares caben.
  final String? modalidad;

  const PartidoEnVivoDisponible({
    required this.id,
    required this.rival,
    this.hora,
    this.campo,
    this.local = true,
    this.modalidad,
  });

  /// Titulares de una alineación según la modalidad (F11 11, F8 8, F5 5); 11 si no se conoce.
  int get maximoTitulares => switch (modalidad) {
    'F8' => 8,
    'F5' => 5,
    _ => 11,
  };

  factory PartidoEnVivoDisponible.fromJson(Map<String, dynamic> json) {
    return PartidoEnVivoDisponible(
      id: (json['id'] as num).toInt(),
      rival: json['rival'] as String? ?? '',
      hora: json['hora'] as String?,
      campo: json['campo'] as String?,
      local: json['local'] as bool? ?? true,
      modalidad: json['modalidad'] as String?,
    );
  }
}

/// Un jugador entre los que elegir al autor de un gol o la alineación.
class ConvocadoEnVivo {
  static const String origenConvocatoria = 'CONVOCATORIA';
  static const String origenPlantilla = 'PLANTILLA';

  final int jugadorId;
  final int? dorsal;

  /// Nombre y apellidos (el campo antiguo `nombre`).
  final String nombre;

  /// Cómo saldrá en los avisos y la portada; null si el backend no lo envía. Si el jugador no tiene
  /// uno propio, el backend manda el nombre completo.
  final String? nombreRetransmision;

  /// CONVOCATORIA (convocados efectivos) o PLANTILLA (el partido no tiene convocatoria); null en un
  /// backend antiguo.
  final String? origen;

  const ConvocadoEnVivo({
    required this.jugadorId,
    this.dorsal,
    required this.nombre,
    this.nombreRetransmision,
    this.origen,
  });

  factory ConvocadoEnVivo.fromJson(Map<String, dynamic> json) {
    final nombre = (json['nombreCompleto'] ?? json['nombre']) as String? ?? '';
    final retransmision = (json['nombreRetransmision'] as String?)?.trim();

    return ConvocadoEnVivo(
      jugadorId: (json['jugadorId'] as num).toInt(),
      dorsal: (json['dorsal'] as num?)?.toInt(),
      nombre: nombre,
      nombreRetransmision: retransmision == null || retransmision.isEmpty
          ? null
          : retransmision,
      origen: json['origen'] as String?,
    );
  }

  /// El nombre con el que saldrá en el aviso: el de retransmisión o, si no, nombre y apellidos.
  String get nombreEnDirecto => nombreRetransmision ?? nombre;

  /// true si el nombre de retransmisión es distinto del completo (merece enseñarse aparte).
  bool get tieneNombreRetransmision =>
      nombreRetransmision != null && nombreRetransmision != nombre;
}

class EventoEnVivo {
  final int id;

  /// INICIO, GOL_FAVOR, GOL_CONTRA, DESCANSO, SEGUNDA_PARTE, FINAL, CAMBIO, TARJETA_AMARILLA o TARJETA_ROJA.
  static const String cambio = 'CAMBIO';
  static const String tarjetaAmarilla = 'TARJETA_AMARILLA';
  static const String tarjetaRoja = 'TARJETA_ROJA';

  final String tipo;
  final int? jugadorId;

  /// Nombre del jugador, texto libre o 'p.p.'. En un cambio, el que sale; en una tarjeta, el amonestado.
  final String? autor;
  final DateTime? fecha;

  /// Minuto del partido en que se marcó el gol (0-150); null en el resto de eventos
  /// y en goles de un backend antiguo.
  final int? minuto;

  /// Solo en un CAMBIO: el que entra.
  final int? jugadorEntraId;
  final String? jugadorEntra;

  /// true en la segunda amarilla de un jugador (expulsiÃ³n).
  final bool dobleAmarilla;

  const EventoEnVivo({
    required this.id,
    required this.tipo,
    this.jugadorId,
    this.autor,
    this.fecha,
    this.minuto,
    this.jugadorEntraId,
    this.jugadorEntra,
    this.dobleAmarilla = false,
  });

  bool get esGol => tipo == 'GOL_FAVOR' || tipo == 'GOL_CONTRA';

  bool get esTarjeta => tipo == tarjetaAmarilla || tipo == tarjetaRoja;

  /// Los eventos a los que se puede corregir el minuto: goles, cambios y tarjetas.
  bool get minutoCorregible => esGol || tipo == cambio || esTarjeta;

  factory EventoEnVivo.fromJson(Map<String, dynamic> json) {
    return EventoEnVivo(
      id: (json['id'] as num).toInt(),
      tipo: json['tipo'] as String? ?? '',
      jugadorId: (json['jugadorId'] as num?)?.toInt(),
      autor: json['autor'] as String?,
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      minuto: (json['minuto'] as num?)?.toInt(),
      jugadorEntraId: (json['jugadorEntraId'] as num?)?.toInt(),
      jugadorEntra: json['jugadorEntra'] as String?,
      dobleAmarilla: json['dobleAmarilla'] as bool? ?? false,
    );
  }
}

/// La alineaciÃ³n guardada del partido y quiÃ©n estÃ¡ ahora en el campo (ids de jugador).
class AlineacionEnVivo {
  final String? formacion;
  final List<int> titulares;
  final List<int> suplentes;
  final List<int> enElCampo;
  final List<int> suplentesDisponibles;
  final List<int> expulsados;

  const AlineacionEnVivo({
    this.formacion,
    this.titulares = const [],
    this.suplentes = const [],
    this.enElCampo = const [],
    this.suplentesDisponibles = const [],
    this.expulsados = const [],
  });

  factory AlineacionEnVivo.fromJson(Map<String, dynamic> json) {
    List<int> ids(String clave) => (json[clave] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toInt())
        .toList();

    return AlineacionEnVivo(
      formacion: json['formacion'] as String?,
      titulares: ids('titulares'),
      suplentes: ids('suplentes'),
      enElCampo: ids('enElCampo'),
      suplentesDisponibles: ids('suplentesDisponibles'),
      expulsados: ids('expulsados'),
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

  /// El último evento si todavía se puede deshacer, y cuántos segundos quedan
  /// según el reloj del servidor (el del móvil puede ir adelantado o atrasado).
  final int? deshacibleId;
  final int? deshacibleSegundos;

  /// El minuto del partido ahora mismo según el servidor; null antes del inicio, en el
  /// descanso y tras el final.
  final int? minutoActual;

  /// La alineaciÃ³n guardada y quiÃ©n estÃ¡ en el campo; null si no se ha enviado ninguna (o backend antiguo).
  final AlineacionEnVivo? alineacion;

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
    this.deshacibleSegundos,
    this.minutoActual,
    this.alineacion,
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
      deshacibleSegundos: (deshacible?['segundosRestantesDeshacer'] as num?)
          ?.toInt(),
      minutoActual: (json['minutoActual'] as num?)?.toInt(),
      alineacion: json['alineacion'] is Map<String, dynamic>
          ? AlineacionEnVivo.fromJson(json['alineacion'] as Map<String, dynamic>)
          : null,
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
