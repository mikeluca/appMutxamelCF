/// Tipos de imagen para redes sociales (el "tipo" de la API).
const String tipoImagenPrevia = 'PREVIA';
const String tipoImagenResultados = 'RESULTADOS';

/// Una imagen generada (un PNG de 1080x1350): una página de una modalidad.
class ImagenRedesModel {
  final int id;
  final String tipo;
  final String modalidad;
  final int pagina;
  final int totalPaginas;

  /// Sube cada vez que se regenera: sirve para no reutilizar un PNG antiguo.
  final int version;
  final DateTime? fechaGeneracion;

  const ImagenRedesModel({
    required this.id,
    required this.tipo,
    required this.modalidad,
    required this.pagina,
    required this.totalPaginas,
    required this.version,
    this.fechaGeneracion,
  });

  factory ImagenRedesModel.fromJson(Map<String, dynamic> json) {
    return ImagenRedesModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipo: json['tipo']?.toString() ?? '',
      modalidad: json['modalidad']?.toString() ?? '',
      pagina: (json['pagina'] as num?)?.toInt() ?? 1,
      totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 1,
      version: (json['version'] as num?)?.toInt() ?? 1,
      fechaGeneracion: DateTime.tryParse(
        json['fechaGeneracion']?.toString() ?? '',
      ),
    );
  }
}

/// Las imágenes de un fin de semana y los textos sugeridos para publicarlas.
class ImagenesRedesModel {
  final DateTime? desde;
  final DateTime? hasta;
  final List<ImagenRedesModel> imagenes;
  final String textoPrevia;
  final String textoResultados;

  const ImagenesRedesModel({
    required this.desde,
    required this.hasta,
    required this.imagenes,
    required this.textoPrevia,
    required this.textoResultados,
  });

  factory ImagenesRedesModel.fromJson(Map<String, dynamic> json) {
    DateTime? fecha(Object? valor) {
      final f = DateTime.tryParse(valor?.toString() ?? '');

      return f == null ? null : DateTime(f.year, f.month, f.day);
    }

    return ImagenesRedesModel(
      desde: fecha(json['desde']),
      hasta: fecha(json['hasta']),
      imagenes: [
        for (final i in (json['imagenes'] as List<dynamic>? ?? const []))
          ImagenRedesModel.fromJson(i as Map<String, dynamic>),
      ],
      textoPrevia: json['textoPrevia']?.toString() ?? '',
      textoResultados: json['textoResultados']?.toString() ?? '',
    );
  }

  /// Las imágenes de [tipo], en el orden del servidor (modalidad y página).
  List<ImagenRedesModel> deTipo(String tipo) => [
    for (final i in imagenes)
      if (i.tipo == tipo) i,
  ];

  String textoDe(String tipo) =>
      tipo == tipoImagenResultados ? textoResultados : textoPrevia;
}
