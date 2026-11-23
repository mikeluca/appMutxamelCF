class StandingsRowModel {
  final int posicion;
  final String equipo;
  final bool esNuestro;
  final int puntos;
  final int pj;
  final int pg;
  final int pe;
  final int pp;
  final int gf;
  final int gc;

  /// Escudo del club (ruta relativa del backend); null si no tiene, en nuestra fila y con un backend antiguo.
  final String? escudoUrl;

  /// true si la fila es de nuestro club (también los filiales, cuyo escudoUrl es null): se pinta nuestro escudo.
  /// Un backend antiguo no lo manda: false.
  final bool esPropio;

  const StandingsRowModel({
    required this.posicion,
    required this.equipo,
    required this.esNuestro,
    required this.puntos,
    required this.pj,
    required this.pg,
    required this.pe,
    required this.pp,
    required this.gf,
    required this.gc,
    this.escudoUrl,
    this.esPropio = false,
  });

  factory StandingsRowModel.fromJson(Map<String, dynamic> json) {
    return StandingsRowModel(
      posicion: (json['posicion'] as num?)?.toInt() ?? 0,
      equipo: json['equipo'] ?? '',
      esNuestro: json['esNuestro'] == true,
      puntos: (json['puntos'] as num?)?.toInt() ?? 0,
      pj: (json['pj'] as num?)?.toInt() ?? 0,
      pg: (json['pg'] as num?)?.toInt() ?? 0,
      pe: (json['pe'] as num?)?.toInt() ?? 0,
      pp: (json['pp'] as num?)?.toInt() ?? 0,
      gf: (json['gf'] as num?)?.toInt() ?? 0,
      gc: (json['gc'] as num?)?.toInt() ?? 0,
      escudoUrl: json['escudoUrl'] as String?,
      esPropio: json['esPropio'] == true,
    );
  }
}

class StandingsModel {
  final String competicion;
  final int? jornada;
  final DateTime? fechaImportacion;
  final List<StandingsRowModel> filas;

  /// false si el backend marca la jornada como no fiable (`jornadaFiable: false`): no se enseña. Sin la marca, true.
  final bool jornadaFiable;

  /// Todas las competiciones del equipo (la Liga y la Copa de Veteranos), la principal la primera. Vacía si el equipo
  /// tiene una sola o el backend es antiguo: entonces se ve como siempre, sin pestañas.
  final List<StandingsModel> competiciones;

  const StandingsModel({
    required this.competicion,
    required this.jornada,
    required this.fechaImportacion,
    required this.filas,
    this.jornadaFiable = true,
    this.competiciones = const [],
  });

  /// Las competiciones que se ofrecen en pestañas: solo con más de una.
  List<StandingsModel> get pestanas =>
      competiciones.length > 1 ? competiciones : const [];

  factory StandingsModel.fromJson(Map<String, dynamic> json) {
    final filas = (json['clasificacion'] as List<dynamic>? ?? [])
        .map((f) => StandingsRowModel.fromJson(f as Map<String, dynamic>))
        .toList();

    final varias = (json['competiciones'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(StandingsModel.fromJson)
        .toList();

    return StandingsModel(
      competicion: json['competicion'] ?? '',
      jornada: (json['jornada'] as num?)?.toInt(),
      fechaImportacion: DateTime.tryParse(json['fechaImportacion'] ?? ''),
      filas: filas,
      jornadaFiable: json['jornadaFiable'] != false,
      competiciones: varias,
    );
  }
}
