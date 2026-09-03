class NewsModel {
  final int id;
  final String titulo;
  final String contenido;
  final DateTime? fecha;
  final String? imagenUrl;

  const NewsModel({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.fecha,
    this.imagenUrl,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      fecha: _parseFecha(json['fecha']),
      imagenUrl: json['imagenUrl'],
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) {
      return null;
    }

    // Spring Boot está enviando la fecha como timestamp
    // en milisegundos desde 1970.
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // Por si en el futuro el backend devuelve una fecha
    // en formato texto.
    return DateTime.tryParse(value.toString());
  }
}