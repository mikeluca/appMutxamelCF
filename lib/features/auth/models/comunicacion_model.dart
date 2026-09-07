class ComunicacionModel {
  final int id;
  final String titulo;
  final String contenido;
  final int usuarioAutorId;
  final DateTime? fechaCreacion;
  final DateTime? fechaPublicacion;
  final int activa;

  const ComunicacionModel({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.usuarioAutorId,
    required this.fechaCreacion,
    required this.fechaPublicacion,
    required this.activa,
  });

  factory ComunicacionModel.fromJson(Map<String, dynamic> json) {
    return ComunicacionModel(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String? ?? '',
      contenido: json['contenido'] as String? ?? '',
      usuarioAutorId: (json['usuarioAutorId'] as num).toInt(),
      fechaCreacion: _parseFecha(json['fechaCreacion']),
      fechaPublicacion: _parseFecha(json['fechaPublicacion']),
      activa: (json['activa'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) {
      return null;
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

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
