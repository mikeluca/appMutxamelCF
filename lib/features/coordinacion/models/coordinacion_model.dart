DateTime? _fecha(Object? valor) {
  final fecha = DateTime.tryParse(valor?.toString() ?? '');

  return fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
}

int _entero(Object? valor) => (valor as num?)?.toInt() ?? 0;

/// Un partido del panel del fin de semana (sin convocatoria o con el resultado
/// pendiente).
class PartidoPanelModel {
  final int equipoId;
  final String equipo;
  final int partidoId;
  final String rival;
  final DateTime? dia;
  final String? hora;
  final bool local;

  /// Solo en los resultados pendientes.
  final int diasDeRetraso;

  const PartidoPanelModel({
    required this.equipoId,
    required this.equipo,
    required this.partidoId,
    required this.rival,
    required this.dia,
    required this.hora,
    required this.local,
    this.diasDeRetraso = 0,
  });

  factory PartidoPanelModel.fromJson(Map<String, dynamic> json) {
    return PartidoPanelModel(
      equipoId: _entero(json['equipoId']),
      equipo: json['equipo']?.toString() ?? '',
      partidoId: _entero(json['partidoId']),
      rival: json['rival']?.toString() ?? '',
      dia: _fecha(json['dia']),
      hora: json['hora']?.toString(),
      local: json['local'] as bool? ?? true,
      diasDeRetraso: _entero(json['diasDeRetraso']),
    );
  }
}

class EquipoPanelModel {
  final int equipoId;
  final String equipo;
  final int? jornada;

  const EquipoPanelModel({
    required this.equipoId,
    required this.equipo,
    this.jornada,
  });

  factory EquipoPanelModel.fromJson(Map<String, dynamic> json) {
    return EquipoPanelModel(
      equipoId: _entero(json['equipoId']),
      equipo: json['equipo']?.toString() ?? '',
      jornada: (json['jornada'] as num?)?.toInt(),
    );
  }
}

/// Respuesta de GET /app/coordinacion/fin-de-semana.
class FinDeSemanaModel {
  /// Viernes y domingo del fin de semana consultado.
  final DateTime desde;
  final DateTime hasta;
  final List<PartidoPanelModel> sinConvocatoria;
  final List<PartidoPanelModel> resultadosPendientes;
  final List<EquipoPanelModel> descansan;
  final List<EquipoPanelModel> sinPartido;
  final DateTime? ultimaImportacionFfcv;

  const FinDeSemanaModel({
    required this.desde,
    required this.hasta,
    required this.sinConvocatoria,
    required this.resultadosPendientes,
    required this.descansan,
    required this.sinPartido,
    required this.ultimaImportacionFfcv,
  });

  /// Nada que hacer: sin partidos sin convocatoria, sin resultados pendientes
  /// y sin equipos sin partido (los descansos son solo informativos).
  bool get todoAlDia =>
      sinConvocatoria.isEmpty &&
      resultadosPendientes.isEmpty &&
      sinPartido.isEmpty;

  factory FinDeSemanaModel.fromJson(Map<String, dynamic> json) {
    List<T> lista<T>(String clave, T Function(Map<String, dynamic>) crear) =>
        (json[clave] as List<dynamic>? ?? [])
            .map((e) => crear(e as Map<String, dynamic>))
            .toList();

    final resumen = json['resumen'] as Map<String, dynamic>? ?? const {};
    final importacion = DateTime.tryParse(
      resumen['ultimaImportacionFfcv']?.toString() ?? '',
    );

    return FinDeSemanaModel(
      desde: _fecha(json['desde']) ?? DateTime.now(),
      hasta: _fecha(json['hasta']) ?? DateTime.now(),
      sinConvocatoria: lista('sinConvocatoria', PartidoPanelModel.fromJson),
      resultadosPendientes: lista(
        'resultadosPendientes',
        PartidoPanelModel.fromJson,
      ),
      descansan: lista('descansan', EquipoPanelModel.fromJson),
      sinPartido: lista('sinPartido', EquipoPanelModel.fromJson),
      ultimaImportacionFfcv: importacion,
    );
  }
}

const String motivoSeguimientoFaltas = 'FALTAS';
const String motivoSeguimientoComportamiento = 'COMPORTAMIENTO';
const String motivoSeguimientoAmbos = 'AMBOS';

const String periodoSeguimiento30d = '30d';
const String periodoSeguimientoTemporada = 'temporada';

/// Un jugador del seguimiento de faltas y mal comportamiento.
class SeguimientoJugadorModel {
  final int jugadorId;
  final String nombre;
  final String equipo;
  final int faltas;
  final int faltasJustificadas;
  final int malComportamiento;
  final int retrasos;
  final DateTime? ultimaIncidencia;
  final String? motivo;

  const SeguimientoJugadorModel({
    required this.jugadorId,
    required this.nombre,
    required this.equipo,
    required this.faltas,
    required this.faltasJustificadas,
    required this.malComportamiento,
    required this.retrasos,
    required this.ultimaIncidencia,
    required this.motivo,
  });

  factory SeguimientoJugadorModel.fromJson(Map<String, dynamic> json) {
    return SeguimientoJugadorModel(
      jugadorId: _entero(json['jugadorId']),
      nombre: json['nombre']?.toString() ?? '',
      equipo: json['equipo']?.toString() ?? '',
      faltas: _entero(json['faltas']),
      faltasJustificadas: _entero(json['faltasJustificadas']),
      malComportamiento: _entero(json['malComportamiento']),
      retrasos: _entero(json['retrasos']),
      ultimaIncidencia: _fecha(json['ultimaIncidencia']),
      motivo: json['motivo']?.toString(),
    );
  }
}

class IncidenciaEntrenamientoModel {
  final DateTime? fecha;
  final String estado;

  const IncidenciaEntrenamientoModel({
    required this.fecha,
    required this.estado,
  });

  factory IncidenciaEntrenamientoModel.fromJson(Map<String, dynamic> json) {
    return IncidenciaEntrenamientoModel(
      fecha: _fecha(json['fecha']),
      estado: json['estado']?.toString() ?? '',
    );
  }
}

/// Detalle de un jugador: sus contadores y sus incidencias del periodo.
class SeguimientoDetalleModel {
  final SeguimientoJugadorModel jugador;
  final List<IncidenciaEntrenamientoModel> incidencias;

  const SeguimientoDetalleModel({
    required this.jugador,
    required this.incidencias,
  });

  factory SeguimientoDetalleModel.fromJson(Map<String, dynamic> json) {
    return SeguimientoDetalleModel(
      jugador: SeguimientoJugadorModel.fromJson(
        json['jugador'] as Map<String, dynamic>? ?? const {},
      ),
      incidencias: (json['incidencias'] as List<dynamic>? ?? [])
          .map(
            (e) => IncidenciaEntrenamientoModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
