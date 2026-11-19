/// Patrocinador del club mostrado en la pantalla principal. La lista viene del backend
/// (GET /api/public/patrocinadores): la misma que pinta el pie de la web. No se guarda en el móvil.
class Patrocinador {
  final String nombre;

  /// Ruta del logo relativa a la raíz de la web ("/images/frutasJuanete.jpg"); se le antepone
  /// AppConfig.mediaBaseUrl.
  final String imagenUrl;

  /// Enlace externo a la web/red social del patrocinador. Null si no lleva enlace (p. ej. Aresala).
  final String? url;

  /// true si el logo se muestra recortado en círculo.
  final bool circular;

  const Patrocinador({
    required this.nombre,
    required this.imagenUrl,
    this.url,
    this.circular = false,
  });

  factory Patrocinador.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] as String?)?.trim();

    return Patrocinador(
      nombre: (json['nombre'] as String?) ?? '',
      imagenUrl: (json['imagenUrl'] as String?) ?? '',
      url: (url == null || url.isEmpty) ? null : url,
      circular: json['circular'] == true,
    );
  }
}
