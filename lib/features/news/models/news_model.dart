import '../../../core/config/app_config.dart';

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

  String? get fullImagenUrl {
    if (imagenUrl == null || imagenUrl!.trim().isEmpty) return null;
    final url = imagenUrl!.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = AppConfig.mediaBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final rawImagen = json['imagenUrl'] ??
        json['imagen_url'] ??
        json['imageUrl'] ??
        json['image_url'] ??
        json['imagen'] ??
        json['image'] ??
        json['url'];

    return NewsModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titulo: json['titulo'] ?? json['title'] ?? '',
      contenido: json['contenido'] ?? json['content'] ?? json['descripcion'] ?? '',
      fecha: json['fecha'] != null || json['date'] != null || json['created_at'] != null
          ? DateTime.tryParse(
              (json['fecha'] ?? json['date'] ?? json['created_at']).toString(),
            )
          : null,
      imagenUrl: rawImagen?.toString(),
    );
  }
}