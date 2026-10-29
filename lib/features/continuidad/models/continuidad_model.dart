/// Respuestas posibles a "¿seguirá el jugador la temporada siguiente?" (el
/// valor del PUT y del GET). [respuestaPendiente] solo llega en el GET: la
/// familia todavía no ha contestado.
const String respuestaPendiente = 'PENDIENTE';
const String respuestaSigue = 'SIGUE';
const String respuestaNoSigue = 'NO_SIGUE';
const String respuestaDuda = 'DUDA';

/// Un jugador del usuario con su respuesta de continuidad para la temporada
/// siguiente (GET /api/app/continuidad).
class ContinuidadJugadorModel {
  final int jugadorId;
  final String nombre;
  final String? categoria;
  final int temporadaId;
  final String temporada;

  /// PENDIENTE, SIGUE, NO_SIGUE o DUDA.
  final String respuesta;

  /// Cuándo se dio la respuesta; null si todavía no se ha contestado.
  final DateTime? fechaRespuesta;

  const ContinuidadJugadorModel({
    required this.jugadorId,
    required this.nombre,
    this.categoria,
    required this.temporadaId,
    required this.temporada,
    required this.respuesta,
    this.fechaRespuesta,
  });

  bool get contestada => respuesta != respuestaPendiente;

  factory ContinuidadJugadorModel.fromJson(Map<String, dynamic> json) {
    return ContinuidadJugadorModel(
      jugadorId: (json['jugadorId'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria']?.toString(),
      temporadaId: (json['temporadaId'] as num?)?.toInt() ?? 0,
      temporada: json['temporada']?.toString() ?? '',
      respuesta: json['respuesta']?.toString() ?? respuestaPendiente,
      fechaRespuesta: _fecha(json['fechaRespuesta']),
    );
  }

  /// El backend manda la fecha como texto ISO local ("2027-05-03T09:30:00");
  /// por si algún día llega como lista [a, m, d, h, mi, s] también se lee.
  static DateTime? _fecha(Object? valor) {
    if (valor is String && valor.isNotEmpty) {
      return DateTime.tryParse(valor);
    }

    if (valor is List && valor.length >= 3) {
      int n(int i) => i < valor.length ? (valor[i] as num).toInt() : 0;

      return DateTime(n(0), n(1), n(2), n(3), n(4), n(5));
    }

    return null;
  }
}
