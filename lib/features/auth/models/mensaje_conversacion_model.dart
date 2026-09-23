class MensajeConversacionModel {
  final int id;
  final String contenido;
  final DateTime? fecha;
  final int autorId;
  final bool esMia;
  final bool leida;

  const MensajeConversacionModel({
    required this.id,
    required this.contenido,
    required this.fecha,
    required this.autorId,
    required this.esMia,
    required this.leida,
  });

  factory MensajeConversacionModel.fromJson(Map<String, dynamic> json) {
    return MensajeConversacionModel(
      id: (json['id'] as num).toInt(),
      contenido: json['contenido'] as String? ?? '',
      fecha: _parseFecha(json['fecha']),
      autorId: (json['autorId'] as num).toInt(),
      esMia: json['esMia'] as bool? ?? false,
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
