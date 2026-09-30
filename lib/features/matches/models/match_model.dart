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
  final int? golesFavor;
  final int? golesContra;

  /// Solo viene relleno cuando el calendario se consultó indicando un
  /// jugador concreto: true/false si el partido ya tiene convocatoria
  /// creada y el jugador está o no en ella, null si el partido todavía
  /// no tiene convocatoria (no aplica, no es lo mismo que "no
  /// convocado").
  final bool? convocado;

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
    this.golesFavor,
    this.golesContra,
    this.convocado,
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
      golesFavor: json['golesFavor'] as int?,
      golesContra: json['golesContra'] as int?,
      convocado: json['convocado'] as bool?,
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

  /// Indica si la fecha y hora del partido ya han pasado, con el mismo
  /// criterio que aplica el backend para aceptar la introducción de
  /// estadísticas (PUT /api/app/partidos/{id}/estadisticas lo rechaza si
  /// el partido todavía no se ha jugado). Si no se conoce la fecha, se
  /// asume que NO ha pasado (no se puede afirmar lo contrario).
  bool get esPartidoPasado {
    final fecha = dia;

    if (fecha == null) {
      return false;
    }

    final horaPartido = hora;
    DateTime limite;

    if (horaPartido != null && horaPartido.trim().isNotEmpty) {
      final partes = horaPartido.split(':');
      final horas = int.tryParse(partes.isNotEmpty ? partes[0] : '') ?? 0;
      final minutos = int.tryParse(partes.length > 1 ? partes[1] : '') ?? 0;

      limite = DateTime(fecha.year, fecha.month, fecha.day, horas, minutos);
    } else {
      // Sin hora conocida: se considera pasado a partir del día
      // siguiente, para no bloquear la introducción de resultado el
      // mismo día del partido por no conocer la hora exacta.
      limite = DateTime(fecha.year, fecha.month, fecha.day + 1);
    }

    return limite.isBefore(DateTime.now());
  }
}
