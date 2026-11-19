/// Por qué el cartel del próximo partido no se puede generar (el "motivo" de la API).
const String motivoSinPartido = 'SIN_PARTIDO';
const String motivoYaEmpezado = 'YA_EMPEZADO';

/// El valor de la pestaña del cartel del Primer Equipo (junto a [tipoImagenPrevia] y [tipoImagenResultados]).
const String tipoImagenPartidoPrimerEquipo = 'PARTIDO_PRIMER_EQUIPO';
const String tipoImagenPartidoFilial = 'PARTIDO_FILIAL';

/// El próximo partido del Primer Equipo que devuelve el backend
/// (`GET /api/app/imagenes-redes/partido-primer-equipo`). Si no está disponible solo trae [motivo].
class PartidoPrimerEquipoModel {
  final bool disponible;

  /// [motivoSinPartido] o [motivoYaEmpezado] (null si está disponible).
  final String? motivo;
  final int? partidoId;

  /// true si el Mutxamel juega en casa.
  final bool local;
  final String rival;

  /// Ruta relativa del escudo del rival; null si no tiene.
  final String? escudoRivalUrl;
  final DateTime? dia;
  final String? hora;
  final String? campo;
  final String? competicion;
  final int? jornada;
  final String tipo;
  final String textoEs;
  final String textoCa;

  const PartidoPrimerEquipoModel({
    required this.disponible,
    this.motivo,
    this.partidoId,
    this.local = true,
    this.rival = '',
    this.escudoRivalUrl,
    this.dia,
    this.hora,
    this.campo,
    this.competicion,
    this.jornada,
    this.tipo = 'LIGA',
    this.textoEs = '',
    this.textoCa = '',
  });

  factory PartidoPrimerEquipoModel.fromJson(Map<String, dynamic> json) {
    final fecha = DateTime.tryParse(json['dia']?.toString() ?? '');
    final texto = json['textoPublicacion'];

    String? limpio(Object? valor) {
      final t = valor?.toString().trim();

      return t == null || t.isEmpty ? null : t;
    }

    return PartidoPrimerEquipoModel(
      disponible: json['disponible'] == true,
      motivo: limpio(json['motivo']),
      partidoId: (json['partidoId'] as num?)?.toInt(),
      local: json['local'] != false,
      rival: json['rival']?.toString() ?? '',
      escudoRivalUrl: limpio(json['escudoRivalUrl']),
      dia: fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day),
      hora: limpio(json['hora']),
      campo: limpio(json['campo']),
      competicion: limpio(json['competicion']),
      jornada: (json['jornada'] as num?)?.toInt(),
      tipo: limpio(json['tipo']) ?? 'LIGA',
      textoEs: texto is Map ? texto['es']?.toString() ?? '' : '',
      textoCa: texto is Map ? texto['ca']?.toString() ?? '' : '',
    );
  }

  /// El texto para publicar en ese idioma.
  String textoDe(IdiomaCartel idioma) =>
      idioma == IdiomaCartel.ca ? textoCa : textoEs;
}

/// Los tamaños del cartel (el "formato" de la API).
enum FormatoCartel {
  publicacion('PUBLICACION', 1350),
  historia('HISTORIA', 1920);

  final String api;

  /// El alto en píxeles (el ancho es siempre 1080), para su proporción.
  final double alto;

  const FormatoCartel(this.api, this.alto);

  double get proporcion => 1080 / alto;
}

/// El idioma en que se escribe el cartel (el "idioma" de la API).
enum IdiomaCartel {
  es('es'),
  ca('ca');

  final String api;

  const IdiomaCartel(this.api);
}

/// Lo que se pide al generar el cartel. Siempre empieza con los tres opcionales marcados (no se guarda).
class OpcionesCartel {
  final FormatoCartel formato;
  final IdiomaCartel idioma;
  final bool racha;
  final bool qr;
  final bool hashtags;

  const OpcionesCartel({
    this.formato = FormatoCartel.publicacion,
    this.idioma = IdiomaCartel.es,
    this.racha = true,
    this.qr = true,
    this.hashtags = true,
  });

  OpcionesCartel copiaCon({
    FormatoCartel? formato,
    IdiomaCartel? idioma,
    bool? racha,
    bool? qr,
    bool? hashtags,
  }) {
    return OpcionesCartel(
      formato: formato ?? this.formato,
      idioma: idioma ?? this.idioma,
      racha: racha ?? this.racha,
      qr: qr ?? this.qr,
      hashtags: hashtags ?? this.hashtags,
    );
  }

  /// La consulta del PNG: `?formato=...&idioma=...&racha=...&qr=...&hashtags=...`.
  String get consulta =>
      '?formato=${formato.api}&idioma=${idioma.api}&racha=$racha&qr=$qr&hashtags=$hashtags';

  @override
  bool operator ==(Object other) =>
      other is OpcionesCartel &&
      other.formato == formato &&
      other.idioma == idioma &&
      other.racha == racha &&
      other.qr == qr &&
      other.hashtags == hashtags;

  @override
  int get hashCode => Object.hash(formato, idioma, racha, qr, hashtags);
}

/// El texto sin la línea de hashtags (`#somMTX #mareaAzul #MutxamelCF`): quita las palabras que empiezan por `#`.
String textoSinHashtags(String texto) {
  return texto
      .split(RegExp(r'\s+'))
      .where((palabra) => !palabra.startsWith('#'))
      .join(' ')
      .trim();
}

/// De qué equipo es el cartel del próximo partido: cambia la ruta del backend (`partido-primer-equipo` o
/// `partido-filial`), los textos y el nombre del fichero que se comparte. El resto es igual.
enum CartelEquipo {
  primerEquipo('partido-primer-equipo', 'cartel_primer_equipo'),
  filial('partido-filial', 'cartel_filial');

  /// El tramo de la ruta tras `/app/imagenes-redes/`.
  final String ruta;

  /// El principio del nombre del PNG que se comparte.
  final String prefijoFichero;

  const CartelEquipo(this.ruta, this.prefijoFichero);
}
