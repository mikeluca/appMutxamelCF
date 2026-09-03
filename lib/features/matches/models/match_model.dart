class MatchModel {
  final String categoria;
  final String equipo;
  final String rival;
  final String? resultado;
  final DateTime? dia;
  final String? diaFormateado;
  final String? hora;
  final String? campo;

  const MatchModel({
    required this.categoria,
    required this.equipo,
    required this.rival,
    this.resultado,
    this.dia,
    this.diaFormateado,
    this.hora,
    this.campo,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      categoria: json['categoria'] ?? '',
      equipo: json['equipo'] ?? '',
      rival: json['rival'] ?? '',
      resultado: json['resultado'],
      dia: _parseFecha(json['dia']),
      diaFormateado: json['diaFormateado'],
      hora: json['hora'],
      campo: json['campo'],
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }

  bool get esProximoPartido {
    return resultado == null && rival.trim().toUpperCase() != 'DESCANSA';
  }

  bool get estaJugado {
    return resultado != null && resultado!.trim().isNotEmpty;
  }

  bool get estaDescansando {
    final rivalNormalizado = rival.trim().toUpperCase();

    return rivalNormalizado.isEmpty || rivalNormalizado == 'DESCANSA';
  }
}
