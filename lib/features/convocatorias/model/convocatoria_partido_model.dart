import '../../../core/utils/backend_date.dart';

/// Un convocado tal como lo ve la familia: sin datos de contacto.
class ConvocadoPartidoModel {
  final String nombre;
  final String apellidos;
  final int? dorsal;

  const ConvocadoPartidoModel({
    required this.nombre,
    required this.apellidos,
    this.dorsal,
  });

  factory ConvocadoPartidoModel.fromJson(Map<String, dynamic> json) {
    return ConvocadoPartidoModel(
      nombre: json['nombre'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      dorsal: json['dorsal'] as int?,
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();

  /// true si es el jugador [nombre] [apellidos] (sin distinguir mayúsculas).
  bool esJugador(String nombre, String apellidos) {
    String limpio(String texto) => texto.trim().toLowerCase();

    return limpio(this.nombre) == limpio(nombre) &&
        limpio(this.apellidos) == limpio(apellidos);
  }
}

/// GET /app/partidos/{id}/convocatoria?jugadorId=: la convocatoria de un partido
/// vista por un jugador o un familiar suyo.
class ConvocatoriaPartidoModel {
  final int convocatoriaId;
  final String rival;
  final DateTime? fecha;
  final String? hora;
  final String? campo;

  /// true si el Mutxamel juega como local.
  final bool local;
  final String? horaCitacion;
  final String? lugarCitacion;

  /// Si el jugador por el que se preguntó está en la convocatoria.
  final bool convocado;

  /// Los convocados, ordenados por dorsal.
  final List<ConvocadoPartidoModel> convocados;

  const ConvocatoriaPartidoModel({
    required this.convocatoriaId,
    required this.rival,
    this.fecha,
    this.hora,
    this.campo,
    this.local = true,
    this.horaCitacion,
    this.lugarCitacion,
    required this.convocado,
    this.convocados = const [],
  });

  factory ConvocatoriaPartidoModel.fromJson(Map<String, dynamic> json) {
    return ConvocatoriaPartidoModel(
      convocatoriaId: json['convocatoriaId'] as int? ?? 0,
      rival: json['rival'] as String? ?? '',
      fecha: parseFechaBackend(json['fecha']),
      hora: json['hora'] as String?,
      campo: json['campo'] as String?,
      local: json['local'] as bool? ?? true,
      horaCitacion: json['horaCitacion'] as String?,
      lugarCitacion: json['lugarCitacion'] as String?,
      convocado: json['convocado'] as bool? ?? false,
      convocados: (json['convocados'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ConvocadoPartidoModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
