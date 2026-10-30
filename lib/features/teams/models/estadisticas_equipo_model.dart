import '../../../core/utils/modalidad.dart';

/// Estados de la tarjeta de un jugador (los calcula el backend).
const String estadoTarjetaOk = 'OK';
const String estadoTarjetaAUna = 'A_UNA';
const String estadoTarjetaSancionPosible = 'SANCION_POSIBLE';

/// Amarillas y rojas de un jugador en la temporada activa.
class TarjetasJugadorModel {
  final int jugadorId;
  final String nombre;
  final int? dorsal;
  final int amarillas;
  final int rojas;
  final String estado;

  /// Es de otro equipo y juega aquí como invitado: sus tarjetas cuentan aparte en cada
  /// competición.
  final bool invitado;

  const TarjetasJugadorModel({
    required this.jugadorId,
    required this.nombre,
    required this.dorsal,
    required this.amarillas,
    required this.rojas,
    required this.estado,
    this.invitado = false,
  });

  factory TarjetasJugadorModel.fromJson(Map<String, dynamic> json) {
    return TarjetasJugadorModel(
      jugadorId: (json['jugadorId'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      dorsal: (json['dorsal'] as num?)?.toInt(),
      amarillas: (json['amarillas'] as num?)?.toInt() ?? 0,
      rojas: (json['rojas'] as num?)?.toInt() ?? 0,
      estado: json['estado']?.toString() ?? estadoTarjetaOk,
      invitado: json['invitado'] as bool? ?? false,
    );
  }
}

/// Un jugador de la lista de goleadores o de asistentes.
class JugadorDestacadoModel {
  final int jugadorId;
  final String nombre;
  final int? dorsal;
  final int goles;
  final int asistencias;
  final int partidos;

  /// Es de otro equipo y ha jugado con este como invitado.
  final bool invitado;

  const JugadorDestacadoModel({
    required this.jugadorId,
    required this.nombre,
    required this.dorsal,
    required this.goles,
    required this.asistencias,
    required this.partidos,
    this.invitado = false,
  });

  factory JugadorDestacadoModel.fromJson(Map<String, dynamic> json) {
    return JugadorDestacadoModel(
      jugadorId: (json['jugadorId'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      dorsal: (json['dorsal'] as num?)?.toInt(),
      goles: (json['goles'] as num?)?.toInt() ?? 0,
      asistencias: (json['asistencias'] as num?)?.toInt() ?? 0,
      partidos: (json['partidos'] as num?)?.toInt() ?? 0,
      invitado: json['invitado'] as bool? ?? false,
    );
  }
}

/// Asistencia de un jugador a los entrenamientos pasados.
class AsistenciaJugadorModel {
  final int jugadorId;
  final String nombre;
  final int asistidos;
  final int total;

  /// null si el jugador aún no tiene entrenamientos.
  final int? porcentaje;

  const AsistenciaJugadorModel({
    required this.jugadorId,
    required this.nombre,
    required this.asistidos,
    required this.total,
    required this.porcentaje,
  });

  factory AsistenciaJugadorModel.fromJson(Map<String, dynamic> json) {
    return AsistenciaJugadorModel(
      jugadorId: (json['jugadorId'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      asistidos: (json['asistidos'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      porcentaje: (json['porcentaje'] as num?)?.toInt(),
    );
  }
}

class EntrenamientosEquipoModel {
  final int sesiones;

  /// Entrenamientos pasados cuya lista no está revisada: no cuentan en la asistencia.
  final int sesionesSinRevisar;

  /// null sin entrenamientos con lista revisada.
  final int? asistenciaMedia;
  final List<AsistenciaJugadorModel> porJugador;

  const EntrenamientosEquipoModel({
    required this.sesiones,
    this.sesionesSinRevisar = 0,
    required this.asistenciaMedia,
    required this.porJugador,
  });

  factory EntrenamientosEquipoModel.fromJson(Map<String, dynamic> json) {
    return EntrenamientosEquipoModel(
      sesiones: (json['sesiones'] as num?)?.toInt() ?? 0,
      sesionesSinRevisar: (json['sesionesSinRevisar'] as num?)?.toInt() ?? 0,
      asistenciaMedia: (json['asistenciaMedia'] as num?)?.toInt(),
      porJugador: (json['porJugador'] as List<dynamic>? ?? [])
          .map(
            (e) => AsistenciaJugadorModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class PartidosEquipoModel {
  final int jugados;
  final int ganados;
  final int empatados;
  final int perdidos;
  final int golesFavor;
  final int golesContra;

  const PartidosEquipoModel({
    required this.jugados,
    required this.ganados,
    required this.empatados,
    required this.perdidos,
    required this.golesFavor,
    required this.golesContra,
  });

  factory PartidosEquipoModel.fromJson(Map<String, dynamic> json) {
    int n(String clave) => (json[clave] as num?)?.toInt() ?? 0;

    return PartidosEquipoModel(
      jugados: n('jugados'),
      ganados: n('ganados'),
      empatados: n('empatados'),
      perdidos: n('perdidos'),
      golesFavor: n('golesFavor'),
      golesContra: n('golesContra'),
    );
  }
}

/// Estadísticas del equipo en la temporada activa.
class EstadisticasEquipoModel {
  final List<JugadorDestacadoModel> goleadores;
  final List<JugadorDestacadoModel> asistentes;
  final EntrenamientosEquipoModel entrenamientos;
  final PartidosEquipoModel partidos;

  /// false si el equipo (fútbol 8/5) no registra goleadores ni asistentes.
  /// Sin el campo (backend antiguo) se asume que sí.
  final bool admiteEstadisticas;

  const EstadisticasEquipoModel({
    required this.goleadores,
    required this.asistentes,
    required this.entrenamientos,
    required this.partidos,
    this.admiteEstadisticas = true,
  });

  factory EstadisticasEquipoModel.fromJson(Map<String, dynamic> json) {
    List<JugadorDestacadoModel> lista(String clave) =>
        (json[clave] as List<dynamic>? ?? [])
            .map(
              (e) => JugadorDestacadoModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();

    return EstadisticasEquipoModel(
      goleadores: lista('goleadores'),
      asistentes: lista('asistentes'),
      entrenamientos: EntrenamientosEquipoModel.fromJson(
        json['entrenamientos'] as Map<String, dynamic>? ?? const {},
      ),
      admiteEstadisticas: leerAdmiteEstadisticas(json),
      partidos: PartidosEquipoModel.fromJson(
        json['partidos'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// Tarjetas de un equipo (GET /api/app/equipos/{id}/tarjetas). Si el equipo no
/// admite estadísticas de jugador la lista va vacía y [admiteEstadisticas] es
/// false. Acepta también la respuesta antigua, que era la lista a secas.
class TarjetasEquipoModel {
  final bool admiteEstadisticas;
  final List<TarjetasJugadorModel> jugadores;

  const TarjetasEquipoModel({
    this.admiteEstadisticas = true,
    this.jugadores = const [],
  });

  factory TarjetasEquipoModel.fromJson(dynamic json) {
    List<TarjetasJugadorModel> lista(List<dynamic> datos) => datos
        .map((e) => TarjetasJugadorModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (json is List<dynamic>) {
      return TarjetasEquipoModel(jugadores: lista(json));
    }

    final mapa = json as Map<String, dynamic>;

    return TarjetasEquipoModel(
      admiteEstadisticas: leerAdmiteEstadisticas(mapa),
      jugadores: lista(mapa['jugadores'] as List<dynamic>? ?? const []),
    );
  }
}
