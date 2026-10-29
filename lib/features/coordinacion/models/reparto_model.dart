int _entero(Object? valor) => (valor as num?)?.toInt() ?? 0;

List<String> _textos(Object? valor) =>
    (valor as List<dynamic>? ?? []).map((e) => e.toString()).toList();

/// Estado de un jugador del reparto: CONFIRMADO o PRUEBA (pasa a CONFIRMADO al
/// asignarle un equipo definitivo).
const String estadoJugadorPrueba = 'PRUEBA';

/// Un jugador en el reparto de septiembre.
class JugadorRepartoModel {
  final int jugadorId;
  final String nombre;
  final int? anioNacimiento;
  final int? dorsal;
  final String estado;
  final bool equipoDefinitivo;

  const JugadorRepartoModel({
    required this.jugadorId,
    required this.nombre,
    this.anioNacimiento,
    this.dorsal,
    required this.estado,
    required this.equipoDefinitivo,
  });

  bool get esPrueba => estado == estadoJugadorPrueba;

  factory JugadorRepartoModel.fromJson(Map<String, dynamic> json) {
    return JugadorRepartoModel(
      jugadorId: _entero(json['jugadorId']),
      nombre: json['nombre']?.toString() ?? '',
      anioNacimiento: (json['anioNacimiento'] as num?)?.toInt(),
      dorsal: (json['dorsal'] as num?)?.toInt(),
      estado: json['estado']?.toString() ?? 'CONFIRMADO',
      equipoDefinitivo: json['equipoDefinitivo'] == true,
    );
  }
}

/// Un equipo de la categoría: el de pretemporada o uno definitivo.
class EquipoRepartoModel {
  final int equipoId;
  final String nombre;
  final String? grupo;
  final String? modalidad;
  final bool activo;
  final List<JugadorRepartoModel> jugadores;

  const EquipoRepartoModel({
    required this.equipoId,
    required this.nombre,
    this.grupo,
    this.modalidad,
    required this.activo,
    this.jugadores = const [],
  });

  factory EquipoRepartoModel.fromJson(Map<String, dynamic> json) {
    return EquipoRepartoModel(
      equipoId: _entero(json['equipoId']),
      nombre: json['nombre']?.toString() ?? '',
      grupo: json['grupo']?.toString(),
      modalidad: json['modalidad']?.toString(),
      activo: json['activo'] == true,
      jugadores: (json['jugadores'] as List<dynamic>? ?? [])
          .map((e) => JugadorRepartoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// El reparto de una categoría (GET /api/app/reparto?categoria=).
class RepartoCategoriaModel {
  final String categoria;

  /// null si la categoría no tiene equipo de pretemporada.
  final EquipoRepartoModel? pretemporada;
  final List<JugadorRepartoModel> porAsignar;
  final List<EquipoRepartoModel> equipos;

  const RepartoCategoriaModel({
    required this.categoria,
    this.pretemporada,
    this.porAsignar = const [],
    this.equipos = const [],
  });

  factory RepartoCategoriaModel.fromJson(Map<String, dynamic> json) {
    final pretemporada = json['pretemporada'];

    return RepartoCategoriaModel(
      categoria: json['categoria']?.toString() ?? '',
      pretemporada: pretemporada is Map<String, dynamic>
          ? EquipoRepartoModel.fromJson(pretemporada)
          : null,
      porAsignar: (json['porAsignar'] as List<dynamic>? ?? [])
          .map((e) => JugadorRepartoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      equipos: (json['equipos'] as List<dynamic>? ?? [])
          .map((e) => EquipoRepartoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Un jugador de la petición de asignar, con el dorsal que tendrá (null = sin
/// dorsal).
class AsignacionJugador {
  final int jugadorId;
  final int? dorsal;

  const AsignacionJugador(this.jugadorId, this.dorsal);

  Map<String, dynamic> toJson() => {'jugadorId': jugadorId, 'dorsal': dorsal};
}

/// La respuesta de asignar (200).
class ResultadoRepartoModel {
  final int asignados;
  final List<String> avisos;
  final bool equipoActivado;
  final bool pretemporadaVaciada;
  final List<String> pruebasConfirmadas;

  const ResultadoRepartoModel({
    required this.asignados,
    this.avisos = const [],
    this.equipoActivado = false,
    this.pretemporadaVaciada = false,
    this.pruebasConfirmadas = const [],
  });

  factory ResultadoRepartoModel.fromJson(Map<String, dynamic> json) {
    return ResultadoRepartoModel(
      asignados: _entero(json['asignados']),
      avisos: _textos(json['avisos']),
      equipoActivado: json['equipoActivado'] == true,
      pretemporadaVaciada: json['pretemporadaVaciada'] == true,
      pruebasConfirmadas: _textos(json['pruebasConfirmadas']),
    );
  }
}

/// La respuesta de devolver a la pretemporada (200).
class ResultadoDevolucionModel {
  final int devueltos;
  final bool pretemporadaReactivada;

  const ResultadoDevolucionModel({
    required this.devueltos,
    this.pretemporadaReactivada = false,
  });

  factory ResultadoDevolucionModel.fromJson(Map<String, dynamic> json) {
    return ResultadoDevolucionModel(
      devueltos: _entero(json['devueltos']),
      pretemporadaReactivada: json['pretemporadaReactivada'] == true,
    );
  }
}

/// El jugador de prueba recién dado de alta (201).
class PruebaCreadaModel {
  final int jugadorId;
  final String? categoria;

  const PruebaCreadaModel({required this.jugadorId, this.categoria});

  factory PruebaCreadaModel.fromJson(Map<String, dynamic> json) {
    return PruebaCreadaModel(
      jugadorId: _entero(json['jugadorId']),
      categoria: json['categoria']?.toString(),
    );
  }
}

/// El 409 PRUEBAS_SIN_CONFIRMAR de asignar: no se ha asignado nada porque hay
/// jugadores de prueba y falta confirmar que pasan a CONFIRMADO.
class PruebasSinConfirmarException implements Exception {
  final List<String> pruebas;

  const PruebasSinConfirmarException(this.pruebas);

  @override
  String toString() => 'PRUEBAS_SIN_CONFIRMAR: ${pruebas.join(', ')}';
}
