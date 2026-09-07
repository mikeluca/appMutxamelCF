class NotificacionModel {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final int? referenciaId;
  final DateTime? fecha;
  final bool leida;

  const NotificacionModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.referenciaId,
    required this.fecha,
    required this.leida,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: (json['id'] as num).toInt(),
      tipo: json['tipo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      referenciaId: json['referenciaId'] != null
          ? (json['referenciaId'] as num).toInt()
          : null,
      fecha: _parseFecha(json['fecha']),
      leida: json['leida'] as bool? ?? false,
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    if (value is List && value.length >= 6) {
      final year = (value[0] as num).toInt();
      final month = (value[1] as num).toInt();
      final day = (value[2] as num).toInt();
      final hour = (value[3] as num).toInt();
      final minute = (value[4] as num).toInt();
      final second = (value[5] as num).toInt();

      final nanosegundos = value.length > 6 ? (value[6] as num).toInt() : 0;

      final microseconds = nanosegundos ~/ 1000;

      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        microseconds ~/ 1000,
        microseconds % 1000,
      );
    }

    return null;
  }
}
