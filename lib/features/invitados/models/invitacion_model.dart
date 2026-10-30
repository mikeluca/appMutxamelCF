import '../../../core/network/api_client.dart';
import '../../../core/utils/backend_date.dart';

/// Máximo de jugadores de otros equipos por convocatoria (sin contar los
/// rechazados ni los que la familia ha desestimado). Lo comprueba el servidor;
/// la app solo lo usa para el contador.
const int maximoInvitados = 3;

/// Estado de un jugador invitado (docs/api-app-convocatoria-invitados.md, §1).
enum EstadoInvitacion {
  pendienteCoordinacion,
  pendienteEntrenador,
  autorizado,
  rechazado;

  static EstadoInvitacion? desde(String? texto) {
    return switch (texto) {
      'PENDIENTE_COORDINACION' => pendienteCoordinacion,
      'PENDIENTE_ENTRENADOR' => pendienteEntrenador,
      'AUTORIZADO' => autorizado,
      'RECHAZADO' => rechazado,
      _ => null,
    };
  }
}

/// Un equipo del que el equipo de un partido puede invitar jugadores.
class EquipoInvitableModel {
  final int equipoId;
  final String nombre;
  final String categoria;
  final String grupo;

  const EquipoInvitableModel({
    required this.equipoId,
    required this.nombre,
    this.categoria = '',
    this.grupo = '',
  });

  factory EquipoInvitableModel.fromJson(Map<String, dynamic> json) {
    return EquipoInvitableModel(
      equipoId: (json['equipoId'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      grupo: json['grupo']?.toString() ?? '',
    );
  }
}

/// Un jugador que se puede invitar a un partido.
class JugadorInvitableModel {
  final int jugadorId;
  final String nombre;
  final int? dorsal;

  /// Ya está invitado (sin rechazar) a la convocatoria de este partido.
  final bool yaInvitado;

  /// Ya está autorizado como invitado con otro equipo ese día: no se puede invitar.
  final bool bloqueado;
  final String? motivoBloqueo;

  const JugadorInvitableModel({
    required this.jugadorId,
    required this.nombre,
    this.dorsal,
    this.yaInvitado = false,
    this.bloqueado = false,
    this.motivoBloqueo,
  });

  factory JugadorInvitableModel.fromJson(Map<String, dynamic> json) {
    return JugadorInvitableModel(
      jugadorId: (json['jugadorId'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      dorsal: (json['dorsal'] as num?)?.toInt(),
      yaInvitado: json['yaInvitado'] as bool? ?? false,
      bloqueado: json['bloqueado'] as bool? ?? false,
      motivoBloqueo: json['motivoBloqueo'] as String?,
    );
  }
}

/// Un jugador de otro equipo en la selección de una convocatoria: el que se
/// acaba de elegir ([estado] null, todavía sin enviar) o el que ya estaba en la
/// convocatoria que se edita.
class InvitadoElegido {
  final int jugadorId;
  final String nombre;
  final int? equipoOrigenId;
  final String equipoOrigen;

  /// null si se acaba de elegir y todavía no se ha guardado.
  final EstadoInvitacion? estado;

  /// La familia lo ha desestimado: sigue en la lista pero ya no cuenta para el máximo.
  final bool ausenciaJustificada;
  final String? motivoAusencia;
  final String? motivoRechazo;

  const InvitadoElegido({
    required this.jugadorId,
    required this.nombre,
    this.equipoOrigenId,
    required this.equipoOrigen,
    this.estado,
    this.ausenciaJustificada = false,
    this.motivoAusencia,
    this.motivoRechazo,
  });

  bool get rechazado => estado == EstadoInvitacion.rechazado;

  /// Cuenta para el máximo de invitados.
  bool get cuenta => !rechazado && !ausenciaJustificada;
}

/// Un partido de su equipo de origen que coincide con el de la invitación.
class PartidoSolapadoModel {
  final int partidoId;
  final String hora;
  final String rival;

  const PartidoSolapadoModel({
    required this.partidoId,
    this.hora = '',
    this.rival = '',
  });

  factory PartidoSolapadoModel.fromJson(Map<String, dynamic> json) {
    return PartidoSolapadoModel(
      partidoId: (json['partidoId'] as num?)?.toInt() ?? 0,
      hora: json['hora']?.toString() ?? '',
      rival: json['rival']?.toString() ?? '',
    );
  }
}

/// Otra invitación del mismo jugador ese día, en otro partido.
class OtraInvitacionModel {
  final int convocatoriaJugadorId;
  final String equipoDestino;
  final String rival;
  final String horaPartido;
  final EstadoInvitacion? estado;

  const OtraInvitacionModel({
    required this.convocatoriaJugadorId,
    required this.equipoDestino,
    this.rival = '',
    this.horaPartido = '',
    this.estado,
  });

  factory OtraInvitacionModel.fromJson(Map<String, dynamic> json) {
    return OtraInvitacionModel(
      convocatoriaJugadorId:
          (json['convocatoriaJugadorId'] as num?)?.toInt() ?? 0,
      equipoDestino: json['equipoDestino']?.toString() ?? '',
      rival: json['rival']?.toString() ?? '',
      horaPartido: json['horaPartido']?.toString() ?? '',
      estado: EstadoInvitacion.desde(json['estado']?.toString()),
    );
  }
}

/// Una invitación en la lista de coordinación (GET /app/invitaciones/pendientes).
class InvitacionPendienteModel {
  final int id;
  final EstadoInvitacion estado;
  final int convocatoriaId;
  final int partidoId;
  final int jugadorId;
  final String jugador;
  final int equipoOrigenId;
  final String equipoOrigen;
  final int equipoDestinoId;
  final String equipoDestino;
  final DateTime? fechaPartido;
  final String horaPartido;
  final String rival;
  final String convoca;
  final DateTime? fechaPeticionEntrenador;

  /// Más de 12 horas esperando a que su entrenador lo libere.
  final bool plazoVencido;

  /// Su entrenador lo tiene convocado ese día.
  final bool jugadorConvocadoEnOrigen;
  final List<PartidoSolapadoModel> solapamiento;
  final OtraInvitacionModel? otraInvitacion;

  const InvitacionPendienteModel({
    required this.id,
    required this.estado,
    this.convocatoriaId = 0,
    this.partidoId = 0,
    this.jugadorId = 0,
    required this.jugador,
    this.equipoOrigenId = 0,
    required this.equipoOrigen,
    this.equipoDestinoId = 0,
    required this.equipoDestino,
    this.fechaPartido,
    this.horaPartido = '',
    this.rival = '',
    this.convoca = '',
    this.fechaPeticionEntrenador,
    this.plazoVencido = false,
    this.jugadorConvocadoEnOrigen = false,
    this.solapamiento = const [],
    this.otraInvitacion,
  });

  factory InvitacionPendienteModel.fromJson(Map<String, dynamic> json) {
    final otra = json['otraInvitacion'];

    return InvitacionPendienteModel(
      id: (json['id'] as num).toInt(),
      estado:
          EstadoInvitacion.desde(json['estado']?.toString()) ??
          EstadoInvitacion.pendienteCoordinacion,
      convocatoriaId: (json['convocatoriaId'] as num?)?.toInt() ?? 0,
      partidoId: (json['partidoId'] as num?)?.toInt() ?? 0,
      jugadorId: (json['jugadorId'] as num?)?.toInt() ?? 0,
      jugador: json['jugador']?.toString() ?? '',
      equipoOrigenId: (json['equipoOrigenId'] as num?)?.toInt() ?? 0,
      equipoOrigen: json['equipoOrigen']?.toString() ?? '',
      equipoDestinoId: (json['equipoDestinoId'] as num?)?.toInt() ?? 0,
      equipoDestino: json['equipoDestino']?.toString() ?? '',
      fechaPartido: parseFechaBackend(json['fechaPartido']),
      horaPartido: json['horaPartido']?.toString() ?? '',
      rival: json['rival']?.toString() ?? '',
      convoca: json['convoca']?.toString() ?? '',
      fechaPeticionEntrenador: parseFechaBackend(
        json['fechaPeticionEntrenador'],
      ),
      plazoVencido: json['plazoVencido'] as bool? ?? false,
      jugadorConvocadoEnOrigen:
          json['jugadorConvocadoEnOrigen'] as bool? ?? false,
      solapamiento: (json['solapamiento'] as List<dynamic>? ?? [])
          .map((e) => PartidoSolapadoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      otraInvitacion: otra is Map<String, dynamic>
          ? OtraInvitacionModel.fromJson(otra)
          : null,
    );
  }
}

/// El resultado de aprobar, rechazar o liberar una invitación.
class InvitacionResultadoModel {
  final int id;
  final EstadoInvitacion? estado;
  final String jugador;
  final String? motivoRechazo;

  const InvitacionResultadoModel({
    required this.id,
    this.estado,
    this.jugador = '',
    this.motivoRechazo,
  });

  factory InvitacionResultadoModel.fromJson(Map<String, dynamic> json) {
    return InvitacionResultadoModel(
      id: (json['id'] as num).toInt(),
      estado: EstadoInvitacion.desde(json['estado']?.toString()),
      jugador: json['jugador']?.toString() ?? '',
      motivoRechazo: json['motivoRechazo'] as String?,
    );
  }
}

/// Códigos del 409 de las invitaciones.
const String codigoJugadorInvitadoEseDia = 'JUGADOR_INVITADO_ESE_DIA';
const String codigoJugadorYaInvitadoEseDia = 'JUGADOR_YA_INVITADO_ESE_DIA';

/// El 409 de un jugador ya autorizado como invitado con otro equipo ese día.
/// La app decide por [codigo], nunca por el texto del mensaje.
class ConflictoInvitacion {
  /// [codigoJugadorInvitadoEseDia]: se convoca (en la lista del propio equipo) a un
  /// jugador que ese día ya va invitado con otro equipo.
  /// [codigoJugadorYaInvitadoEseDia]: se invita, aprueba o libera a uno que ya está
  /// autorizado con otro equipo ese día.
  final String codigo;
  final int? jugadorId;

  /// El equipo con el que el jugador ya está autorizado ese día.
  final String equipoDestino;
  final DateTime? fecha;

  const ConflictoInvitacion({
    required this.codigo,
    this.jugadorId,
    required this.equipoDestino,
    this.fecha,
  });

  /// El conflicto que describe [error], o null si no es un 409 con uno de los
  /// códigos de las invitaciones.
  static ConflictoInvitacion? desde(Object? error) {
    if (error is! ApiException || error.statusCode != 409) return null;

    final datos = error.datos;

    if (datos is! Map) return null;

    final codigo = datos['codigo']?.toString();

    if (codigo != codigoJugadorInvitadoEseDia &&
        codigo != codigoJugadorYaInvitadoEseDia) {
      return null;
    }

    return ConflictoInvitacion(
      codigo: codigo!,
      jugadorId: (datos['jugadorId'] as num?)?.toInt(),
      equipoDestino: datos['equipoDestino']?.toString() ?? '',
      fecha: parseFechaBackend(datos['fecha']),
    );
  }
}

/// Lo que lleva el aviso INVITACION_LIBERAR a la convocatoria del equipo de origen:
/// la invitación (para liberarla) y el jugador al que afecta.
class LiberarInvitacion {
  final int invitacionId;
  final int? jugadorId;

  const LiberarInvitacion({required this.invitacionId, this.jugadorId});
}
