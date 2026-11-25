/// Lo que la cuenta tiene por hacer (GET /app/pendientes). Solo en memoria.
class GrupoPendiente {
  static const String listasSinPasar = 'LISTAS_SIN_PASAR';
  static const String convocatoriasSinPublicar = 'CONVOCATORIAS_SIN_PUBLICAR';
  static const String resultadosPendientes = 'RESULTADOS_PENDIENTES';
  static const String solicitudesFamilia = 'SOLICITUDES_FAMILIA';
  static const String jugadoresALiberar = 'JUGADORES_A_LIBERAR';
  static const String invitacionesPorAprobar = 'INVITACIONES_POR_APROBAR';
  static const String invitacionesSinLiberar = 'INVITACIONES_SIN_LIBERAR';
  static const String moderacion = 'MODERACION';
  static const String usuariosCaducadas = 'USUARIOS_CADUCADAS';
  static const String imagenesPrevia = 'IMAGENES_PREVIA';
  static const String imagenesResultados = 'IMAGENES_RESULTADOS';

  final String codigo;

  /// Ya en el idioma de la cuenta.
  final String titulo;

  /// El total (puede ser mayor que los [elementos], que son como mucho 5).
  final int cantidad;
  final List<ElementoPendiente> elementos;

  const GrupoPendiente({
    required this.codigo,
    required this.titulo,
    required this.cantidad,
    required this.elementos,
  });

  factory GrupoPendiente.fromJson(Map<String, dynamic> json) {
    return GrupoPendiente(
      codigo: json['codigo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      elementos: (json['elementos'] as List<dynamic>? ?? const [])
          .map((e) => ElementoPendiente.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ElementoPendiente {
  final int? id;
  final String texto;
  final DateTime? fecha;

  /// Un código que la app sabe abrir: PASAR_LISTA:12, CONVOCATORIA_NUEVA:30, RESULTADO:30, SOLICITUDES_FAMILIA,
  /// INVITACIONES, MODERACION, USUARIOS_CADUCADAS, IMAGENES_PREVIA:2026-11-27, IMAGENES_RESULTADOS:2026-11-27.
  final String destino;

  /// Solo en los resultados pendientes.
  final int? diasRetraso;

  /// Para abrir el formulario sin pedir nada más (listas, convocatorias y resultados).
  final int? equipoId;
  final String? equipo;
  final String? rival;
  final String? hora;

  const ElementoPendiente({
    this.id,
    required this.texto,
    this.fecha,
    required this.destino,
    this.diasRetraso,
    this.equipoId,
    this.equipo,
    this.rival,
    this.hora,
  });

  factory ElementoPendiente.fromJson(Map<String, dynamic> json) {
    return ElementoPendiente(
      id: (json['id'] as num?)?.toInt(),
      texto: json['texto'] as String? ?? '',
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      destino: json['destino'] as String? ?? '',
      diasRetraso: (json['diasRetraso'] as num?)?.toInt(),
      equipoId: (json['equipoId'] as num?)?.toInt(),
      equipo: json['equipo'] as String?,
      rival: json['rival'] as String?,
      hora: json['hora'] as String?,
    );
  }
}
