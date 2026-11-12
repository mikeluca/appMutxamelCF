/// Estado del partido en la cabecera de la ficha pública.
enum EstadoFicha {
  proximo,
  enJuego,
  descanso,
  finalizado,
  cancelado;

  static EstadoFicha desdeTexto(String? texto) {
    return switch (texto) {
      'EN_JUEGO' => EstadoFicha.enJuego,
      'DESCANSO' => EstadoFicha.descanso,
      'FINALIZADO' => EstadoFicha.finalizado,
      'CANCELADO' => EstadoFicha.cancelado,
      _ => EstadoFicha.proximo,
    };
  }

  /// Mientras el partido se está jugando la ficha se recarga sola.
  bool get seEstaJugando =>
      this == EstadoFicha.enJuego || this == EstadoFicha.descanso;
}

/// Ficha pública de un partido del Primer Equipo
/// (GET /public/partidos/{id}/ficha). Ver docs/api-app-retransmision.md del backend.
class FichaPartido {
  final CabeceraFicha cabecera;

  /// Lo último primero.
  final List<EventoFicha> eventos;
  final AlineacionFicha alineacion;

  /// Los últimos partidos con resultado, del más reciente al más antiguo.
  final List<FormaFicha> forma;

  const FichaPartido({
    required this.cabecera,
    this.eventos = const [],
    this.alineacion = const AlineacionFicha(),
    this.forma = const [],
  });

  factory FichaPartido.fromJson(Map<String, dynamic> json) {
    return FichaPartido(
      cabecera: CabeceraFicha.fromJson(
        json['cabecera'] as Map<String, dynamic>? ?? const {},
      ),
      eventos: _lista(json['eventos'], EventoFicha.fromJson),
      alineacion: AlineacionFicha.fromJson(
        json['alineacion'] as Map<String, dynamic>? ?? const {},
      ),
      forma: _lista(json['forma'], FormaFicha.fromJson),
    );
  }
}

List<T> _lista<T>(dynamic valor, T Function(Map<String, dynamic>) desde) {
  return (valor as List<dynamic>? ?? const [])
      .map((e) => desde(e as Map<String, dynamic>))
      .toList();
}

class CabeceraFicha {
  final int partidoId;
  final String equipoLocal;
  final String equipoVisitante;

  /// "2026-11-08".
  final DateTime? dia;
  final String? hora;
  final int? golesFavor;
  final int? golesContra;
  final EstadoFicha estado;

  /// Ya redactada por el backend en el idioma pedido.
  final String competicion;

  /// El club se llama siempre "Mutxamel CF" en la ficha.
  static const String nombreClub = 'Mutxamel CF';

  const CabeceraFicha({
    required this.partidoId,
    this.equipoLocal = '',
    this.equipoVisitante = '',
    this.dia,
    this.hora,
    this.golesFavor,
    this.golesContra,
    this.estado = EstadoFicha.proximo,
    this.competicion = '',
  });

  factory CabeceraFicha.fromJson(Map<String, dynamic> json) {
    return CabeceraFicha(
      partidoId: (json['partidoId'] as num?)?.toInt() ?? 0,
      equipoLocal: json['equipoLocal'] as String? ?? '',
      equipoVisitante: json['equipoVisitante'] as String? ?? '',
      dia: DateTime.tryParse(json['dia']?.toString() ?? ''),
      hora: json['hora'] as String?,
      golesFavor: (json['golesFavor'] as num?)?.toInt(),
      golesContra: (json['golesContra'] as num?)?.toInt(),
      estado: EstadoFicha.desdeTexto(json['estado'] as String?),
      competicion: json['competicion'] as String? ?? '',
    );
  }

  /// true si el Mutxamel juega de local.
  bool get mutxamelEsLocal => equipoLocal.trim() == nombreClub;

  String get rival => mutxamelEsLocal ? equipoVisitante : equipoLocal;

  /// Goles del equipo local y del visitante, tal como se pintan; null si no hay marcador.
  int? get golesLocal => mutxamelEsLocal ? golesFavor : golesContra;
  int? get golesVisitante => mutxamelEsLocal ? golesContra : golesFavor;
}

/// Un hecho del partido o un separador (DESCANSO, FINAL).
class EventoFicha {
  static const String golFavor = 'GOL_FAVOR';
  static const String golContra = 'GOL_CONTRA';
  static const String cambio = 'CAMBIO';
  static const String tarjetaAmarilla = 'TARJETA_AMARILLA';
  static const String tarjetaRoja = 'TARJETA_ROJA';
  static const String descanso = 'DESCANSO';
  static const String finalPartido = 'FINAL';

  final String tipo;
  final int? minuto;

  /// Goleador, amonestado o el que sale en un cambio (nombre en directo).
  final String? jugador;
  final String? jugadorEntra;

  /// Marcador tras el gol, o al descanso / al final en los separadores.
  final int? golesFavor;
  final int? golesContra;

  /// El backend lo redacta en el idioma pedido; la app pinta sus propios textos en los separadores.
  final String? texto;
  final bool dobleAmarilla;

  const EventoFicha({
    required this.tipo,
    this.minuto,
    this.jugador,
    this.jugadorEntra,
    this.golesFavor,
    this.golesContra,
    this.texto,
    this.dobleAmarilla = false,
  });

  factory EventoFicha.fromJson(Map<String, dynamic> json) {
    return EventoFicha(
      tipo: json['tipo'] as String? ?? '',
      minuto: (json['minuto'] as num?)?.toInt(),
      jugador: json['jugador'] as String?,
      jugadorEntra: json['jugadorEntra'] as String?,
      golesFavor: (json['golesFavor'] as num?)?.toInt(),
      golesContra: (json['golesContra'] as num?)?.toInt(),
      texto: json['texto'] as String?,
      dobleAmarilla: json['dobleAmarilla'] as bool? ?? false,
    );
  }

  bool get esSeparador => tipo == descanso || tipo == finalPartido;

  /// Los hechos del Mutxamel: todos menos el gol del rival (solo se registran los nuestros).
  bool get esNuestro => tipo != golContra;
}

class TarjetaFicha {
  final String color;
  final int? minuto;
  final bool dobleAmarilla;

  const TarjetaFicha({
    required this.color,
    this.minuto,
    this.dobleAmarilla = false,
  });

  factory TarjetaFicha.fromJson(Map<String, dynamic> json) {
    return TarjetaFicha(
      color: json['color'] as String? ?? 'AMARILLA',
      minuto: (json['minuto'] as num?)?.toInt(),
      dobleAmarilla: json['dobleAmarilla'] as bool? ?? false,
    );
  }

  bool get esRoja => color == 'ROJA';
}

class TitularFicha {
  final int? dorsal;
  final String nombre;

  /// 1 = portero, después las líneas de atrás adelante; null si la alineación no tiene formación.
  final int? fila;
  final int? columna;
  final bool sustituido;
  final int? minutoSustitucion;
  final List<TarjetaFicha> tarjetas;

  /// Miniatura JPEG en base64, solo de mayores de edad; null para un menor (se pinta el avatar).
  final String? fotoBase64;

  const TitularFicha({
    this.dorsal,
    required this.nombre,
    this.fila,
    this.columna,
    this.sustituido = false,
    this.minutoSustitucion,
    this.tarjetas = const [],
    this.fotoBase64,
  });

  factory TitularFicha.fromJson(Map<String, dynamic> json) {
    return TitularFicha(
      dorsal: (json['dorsal'] as num?)?.toInt(),
      nombre: json['nombre'] as String? ?? '',
      fila: (json['fila'] as num?)?.toInt(),
      columna: (json['columna'] as num?)?.toInt(),
      sustituido: json['sustituido'] as bool? ?? false,
      minutoSustitucion: (json['minutoSustitucion'] as num?)?.toInt(),
      tarjetas: _lista(json['tarjetas'], TarjetaFicha.fromJson),
      fotoBase64: json['fotoBase64'] as String?,
    );
  }
}

class SuplenteFicha {
  final int? dorsal;
  final String nombre;
  final bool entro;
  final int? minutoEntrada;
  final List<TarjetaFicha> tarjetas;
  final String? fotoBase64;

  const SuplenteFicha({
    this.dorsal,
    required this.nombre,
    this.entro = false,
    this.minutoEntrada,
    this.tarjetas = const [],
    this.fotoBase64,
  });

  factory SuplenteFicha.fromJson(Map<String, dynamic> json) {
    return SuplenteFicha(
      dorsal: (json['dorsal'] as num?)?.toInt(),
      nombre: json['nombre'] as String? ?? '',
      entro: json['entro'] as bool? ?? false,
      minutoEntrada: (json['minutoEntrada'] as num?)?.toInt(),
      tarjetas: _lista(json['tarjetas'], TarjetaFicha.fromJson),
      fotoBase64: json['fotoBase64'] as String?,
    );
  }
}

class AlineacionFicha {
  final String? formacion;
  final List<TitularFicha> titulares;
  final List<SuplenteFicha> suplentes;

  const AlineacionFicha({
    this.formacion,
    this.titulares = const [],
    this.suplentes = const [],
  });

  factory AlineacionFicha.fromJson(Map<String, dynamic> json) {
    return AlineacionFicha(
      formacion: json['formacion'] as String?,
      titulares: _lista(json['titulares'], TitularFicha.fromJson),
      suplentes: _lista(json['suplentes'], SuplenteFicha.fromJson),
    );
  }

  bool get vacia => titulares.isEmpty && suplentes.isEmpty;

  /// Los titulares se pueden dibujar en el campo solo si todos traen fila y columna.
  bool get tienePosiciones =>
      titulares.isNotEmpty &&
      titulares.every((t) => t.fila != null && t.columna != null);
}

/// Un partido de la forma del equipo.
class FormaFicha {
  final int partidoId;
  final DateTime? dia;

  /// true si el Mutxamel jugó en casa.
  final bool local;
  final String rival;
  final int golesFavor;
  final int golesContra;

  /// G, E o P.
  final String resultado;

  const FormaFicha({
    required this.partidoId,
    this.dia,
    this.local = true,
    this.rival = '',
    this.golesFavor = 0,
    this.golesContra = 0,
    this.resultado = 'E',
  });

  factory FormaFicha.fromJson(Map<String, dynamic> json) {
    return FormaFicha(
      partidoId: (json['partidoId'] as num).toInt(),
      dia: DateTime.tryParse(json['dia']?.toString() ?? ''),
      local: json['local'] as bool? ?? true,
      rival: json['rival'] as String? ?? '',
      golesFavor: (json['golesFavor'] as num?)?.toInt() ?? 0,
      golesContra: (json['golesContra'] as num?)?.toInt() ?? 0,
      resultado: json['resultado'] as String? ?? 'E',
    );
  }

  /// Goles del local y del visitante de ese partido, en el orden en que se pintan.
  int get golesLocal => local ? golesFavor : golesContra;
  int get golesVisitante => local ? golesContra : golesFavor;
}
