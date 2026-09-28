class MatchModel {
  final int? id;
  final int? equipoId;
  final String categoria;
  final String equipo;
  final String rival;
  final String? resultado;
  final DateTime? dia;
  final String? diaFormateado;
  final String? hora;
  final String? campo;
  final String? tipo;
  final bool cancelado;

  const MatchModel({
    this.id,
    this.equipoId,
    required this.categoria,
    required this.equipo,
    required this.rival,
    this.resultado,
    this.dia,
    this.diaFormateado,
    this.hora,
    this.campo,
    this.tipo,
    this.cancelado = false,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as int?,
      equipoId: json['equipoId'] as int?,
      categoria: json['categoria'] ?? '',
      equipo: json['equipo'] ?? '',
      rival: json['rival'] ?? '',
      resultado: json['resultado'],
      dia: _parseFecha(json['dia']),
      diaFormateado: json['diaFormateado'],
      hora: json['hora'],
      campo: json['campo'],
      tipo: json['tipo'],
      // Ausente en respuestas antiguas/otros endpoints: por compatibilidad
      // se asume no cancelado si no viene informado.
      cancelado: json['cancelado'] as bool? ?? false,
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
