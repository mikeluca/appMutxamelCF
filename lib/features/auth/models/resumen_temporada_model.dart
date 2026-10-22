import '../../../core/utils/modalidad.dart';

/// Resumen de la temporada activa de un jugador
/// (GET /api/app/jugadores/{id}/resumen-temporada).
class ResumenTemporadaModel {
  /// Nombre de la temporada activa; null si no hay ninguna.
  final String? temporada;

  final int convocado;
  final int goles;
  final int asistencias;
  final int amarillas;
  final int rojas;

  /// Partidos de la temporada con una ausencia justificada del jugador.
  final int ausenciasJustificadas;

  final int entrenamientosTotal;
  final int entrenamientosAsistidos;
  final int faltas;
  final int justificadas;

  /// Porcentaje de asistencia (0-100); null si todavía no hay entrenamientos.
  final int? porcentaje;

  /// false si el equipo del jugador (fútbol 8/5) no registra goles, asistencias
  /// ni tarjetas. Sin el campo (backend antiguo) se asume que sí.
  final bool admiteEstadisticas;

  const ResumenTemporadaModel({
    this.temporada,
    this.convocado = 0,
    this.goles = 0,
    this.asistencias = 0,
    this.amarillas = 0,
    this.rojas = 0,
    this.ausenciasJustificadas = 0,
    this.entrenamientosTotal = 0,
    this.entrenamientosAsistidos = 0,
    this.faltas = 0,
    this.justificadas = 0,
    this.porcentaje,
    this.admiteEstadisticas = true,
  });

  factory ResumenTemporadaModel.fromJson(Map<String, dynamic> json) {
    final temporada = json['temporada'] as Map<String, dynamic>?;
    final partidos = json['partidos'] as Map<String, dynamic>? ?? const {};
    final entrenamientos =
        json['entrenamientos'] as Map<String, dynamic>? ?? const {};

    int entero(Map<String, dynamic> mapa, String clave) =>
        (mapa[clave] as num?)?.toInt() ?? 0;

    return ResumenTemporadaModel(
      temporada: temporada?['nombre'] as String?,
      convocado: entero(partidos, 'convocado'),
      goles: entero(partidos, 'goles'),
      asistencias: entero(partidos, 'asistencias'),
      amarillas: entero(partidos, 'amarillas'),
      rojas: entero(partidos, 'rojas'),
      ausenciasJustificadas: entero(partidos, 'ausenciasJustificadas'),
      entrenamientosTotal: entero(entrenamientos, 'total'),
      entrenamientosAsistidos: entero(entrenamientos, 'asistidos'),
      faltas: entero(entrenamientos, 'faltas'),
      justificadas: entero(entrenamientos, 'justificadas'),
      porcentaje: (entrenamientos['porcentaje'] as num?)?.toInt(),
      admiteEstadisticas: leerAdmiteEstadisticas(json),
    );
  }

  /// Hay algo que enseñar: temporada activa y al menos un dato.
  bool get hayDatos =>
      temporada != null &&
      (convocado > 0 ||
          goles > 0 ||
          asistencias > 0 ||
          amarillas > 0 ||
          rojas > 0 ||
          ausenciasJustificadas > 0 ||
          entrenamientosTotal > 0);
}
