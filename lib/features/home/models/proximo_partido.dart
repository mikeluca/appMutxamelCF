import '../../convocatorias/model/equipacion_model.dart';
import '../../matches/models/match_model.dart';

/// Una entrada de "Tu próximo partido" (GET /app/inicio/proximos-partidos): una persona y equipo de la cuenta con su
/// próximo partido. Solo en memoria.
class ProximoPartido {
  /// JUGADOR, FAMILIAR o ENTRENADOR.
  final String tipo;
  final int? jugadorId;
  final String? nombreJugador;
  final int? equipoId;
  final String nombreEquipo;

  /// El próximo partido; null si el equipo [descansa].
  final MatchModel? partido;
  final ConvocatoriaProximoPartido? convocatoria;

  /// El equipo no juega esta jornada (según la FFCV) ni hay otro partido en los próximos 14 días.
  final bool descansa;

  const ProximoPartido({
    required this.tipo,
    this.jugadorId,
    this.nombreJugador,
    this.equipoId,
    required this.nombreEquipo,
    this.partido,
    this.convocatoria,
    this.descansa = false,
  });

  bool get esEntrenador => tipo == 'ENTRENADOR';

  factory ProximoPartido.fromJson(Map<String, dynamic> json) {
    final partido = json['partido'];
    final convocatoria = json['convocatoria'];

    return ProximoPartido(
      tipo: json['tipo'] as String? ?? 'JUGADOR',
      jugadorId: (json['jugadorId'] as num?)?.toInt(),
      nombreJugador: json['nombreJugador'] as String?,
      equipoId: (json['equipoId'] as num?)?.toInt(),
      nombreEquipo: json['nombreEquipo'] as String? ?? '',
      partido: partido is Map<String, dynamic>
          ? MatchModel.fromJson(partido)
          : null,
      convocatoria: convocatoria is Map<String, dynamic>
          ? ConvocatoriaProximoPartido.fromJson(convocatoria)
          : null,
      descansa: json['descansa'] as bool? ?? false,
    );
  }
}

/// Cómo está el partido para esa persona.
class ConvocatoriaProximoPartido {
  static const String sinConvocatoria = 'SIN_CONVOCATORIA';
  static const String convocado = 'CONVOCADO';
  static const String noConvocado = 'NO_CONVOCADO';
  static const String ausenciaJustificada = 'AUSENCIA_JUSTIFICADA';
  static const String invitado = 'INVITADO';
  static const String publicada = 'PUBLICADA';

  final String estado;
  final String? horaCitacion;
  final String? lugarCitacion;
  final EquipacionModel? equipaje;
  final EquipacionModel? equipajeMochila;

  /// Solo INVITADO: el equipo que invita.
  final String? equipoInvita;

  /// Solo PUBLICADA (entrenador): cuántos van convocados y la convocatoria para abrirla.
  final int? numeroConvocados;
  final int? convocatoriaId;

  const ConvocatoriaProximoPartido({
    required this.estado,
    this.horaCitacion,
    this.lugarCitacion,
    this.equipaje,
    this.equipajeMochila,
    this.equipoInvita,
    this.numeroConvocados,
    this.convocatoriaId,
  });

  /// Hay una convocatoria publicada que abrir (la de la familia o la del entrenador).
  bool get existe =>
      estado == convocado || estado == invitado || estado == publicada;

  factory ConvocatoriaProximoPartido.fromJson(Map<String, dynamic> json) {
    String? texto(Object? valor) {
      final limpio = valor?.toString().trim();

      return limpio == null || limpio.isEmpty ? null : limpio;
    }

    return ConvocatoriaProximoPartido(
      estado: json['estado'] as String? ?? sinConvocatoria,
      horaCitacion: texto(json['horaCitacion']),
      lugarCitacion: texto(json['lugarCitacion']),
      equipaje: EquipacionModel.fromJsonOrNull(json['equipaje']),
      equipajeMochila: EquipacionModel.fromJsonOrNull(json['equipajeMochila']),
      equipoInvita: texto(json['equipoInvita']),
      numeroConvocados: (json['numeroConvocados'] as num?)?.toInt(),
      convocatoriaId: (json['convocatoriaId'] as num?)?.toInt(),
    );
  }
}
