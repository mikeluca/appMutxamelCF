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
    );
  }
}

class StandingsModel {
  final String competicion;
  final int? jornada;
  final DateTime? fechaImportacion;
  final List<StandingsRowModel> filas;

  const StandingsModel({
    required this.competicion,
    required this.jornada,
    required this.fechaImportacion,
    required this.filas,
  });

  factory StandingsModel.fromJson(Map<String, dynamic> json) {
    final filas = (json['clasificacion'] as List<dynamic>? ?? [])
        .map((f) => StandingsRowModel.fromJson(f as Map<String, dynamic>))
        .toList();

    return StandingsModel(
      competicion: json['competicion'] ?? '',
      jornada: (json['jornada'] as num?)?.toInt(),
      fechaImportacion: DateTime.tryParse(json['fechaImportacion'] ?? ''),
      filas: filas,
    );
  }
}
