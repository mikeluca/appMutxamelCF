/// Una convocatoria de un jugador vinculado al usuario (él mismo o un hijo),
/// con su respuesta y el plazo para darla (GET /api/app/mis-convocatorias).
class MiConvocatoriaModel {
  static const String respuestaVa = 'VA';
  static const String respuestaNoPuede = 'NO_PUEDE';

  final int convocatoriaId;
  final int jugadorId;
  final String jugador;
  final int? equipoId;
  final String equipo;
  final String rival;
  final DateTime? fechaPartido;
  final String? horaPartido;
  final String? campo;
  final bool local;
  final bool cancelado;
  final String? horaConvocatoria;
  final String? lugarConvocatoria;

  /// 'VA', 'NO_PUEDE' o null (sin responder).
  final String? respuesta;
  final String? motivo;
  final DateTime? fechaRespuesta;

  final bool puedeResponder;
  final DateTime? limiteRespuesta;

  const MiConvocatoriaModel({
    required this.convocatoriaId,
    required this.jugadorId,
    required this.jugador,
    this.equipoId,
    this.equipo = '',
    this.rival = '',
    this.fechaPartido,
    this.horaPartido,
    this.campo,
    this.local = true,
    this.cancelado = false,
    this.horaConvocatoria,
    this.lugarConvocatoria,
    this.respuesta,
    this.motivo,
    this.fechaRespuesta,
    this.puedeResponder = false,
    this.limiteRespuesta,
  });

  factory MiConvocatoriaModel.fromJson(Map<String, dynamic> json) {
    return MiConvocatoriaModel(
      convocatoriaId: (json['convocatoriaId'] as num).toInt(),
      jugadorId: (json['jugadorId'] as num).toInt(),
      jugador: json['jugador'] as String? ?? '',
      equipoId: (json['equipoId'] as num?)?.toInt(),
      equipo: json['equipo'] as String? ?? '',
      rival: json['rival'] as String? ?? '',
      fechaPartido: DateTime.tryParse(json['fechaPartido']?.toString() ?? ''),
      horaPartido: json['horaPartido'] as String?,
      campo: json['campo'] as String?,
      local: json['local'] as bool? ?? true,
      cancelado: json['cancelado'] as bool? ?? false,
      horaConvocatoria: json['horaConvocatoria'] as String?,
      lugarConvocatoria: json['lugarConvocatoria'] as String?,
      respuesta: json['respuesta'] as String?,
      motivo: json['motivo'] as String?,
      fechaRespuesta: DateTime.tryParse(
        json['fechaRespuesta']?.toString() ?? '',
      ),
      puedeResponder: json['puedeResponder'] as bool? ?? false,
      limiteRespuesta: DateTime.tryParse(
        json['limiteRespuesta']?.toString() ?? '',
      ),
    );
  }
}
