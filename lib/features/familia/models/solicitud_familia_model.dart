/// Parentesco de quien pide el acceso (el código que espera el backend).
enum ParentescoFamilia {
  madre('MADRE'),
  padre('PADRE'),
  tutor('TUTOR'),
  otro('OTRO');

  final String codigo;

  const ParentescoFamilia(this.codigo);

  static ParentescoFamilia? deCodigo(String? codigo) {
    for (final p in values) {
      if (p.codigo == codigo) return p;
    }

    return null;
  }
}

/// Estados de una solicitud y de cada hijo (el backend los manda como texto).
const String estadoSolicitudPendienteEmail = 'PENDIENTE_EMAIL';
const String estadoSolicitudPendiente = 'PENDIENTE';
const String estadoSolicitudAprobada = 'APROBADA';
const String estadoSolicitudRechazada = 'RECHAZADA';
const String estadoHijoPendiente = 'PENDIENTE';
const String estadoHijoAprobado = 'APROBADO';
const String estadoHijoRechazado = 'RECHAZADO';

/// Un hijo tal como lo escribe la familia al pedir el acceso: nada de fecha de nacimiento ni otros datos.
class HijoNuevo {
  final String nombre;
  final String apellidos;
  final String equipo;

  const HijoNuevo({
    required this.nombre,
    required this.apellidos,
    this.equipo = '',
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre.trim(),
    'apellidos': apellidos.trim(),
    if (equipo.trim().isNotEmpty) 'equipo': equipo.trim(),
  };
}

/// La petición de acceso (con o sin sesión). Con sesión no hacen falta los datos del familiar.
class SolicitudFamiliaNueva {
  final String? nombre;
  final String? apellidos;
  final String? email;
  final String? telefono;
  final ParentescoFamilia parentesco;
  final List<HijoNuevo> hijos;

  const SolicitudFamiliaNueva({
    this.nombre,
    this.apellidos,
    this.email,
    this.telefono,
    required this.parentesco,
    required this.hijos,
  });

  Map<String, dynamic> toJson({String? idioma}) => {
    'nombre': ?nombre?.trim(),
    'apellidos': ?apellidos?.trim(),
    'email': ?email?.trim().toLowerCase(),
    if (telefono != null && telefono!.trim().isNotEmpty)
      'telefono': telefono!.trim(),
    'parentesco': parentesco.codigo,
    'hijos': [for (final h in hijos) h.toJson()],
    // Las dos casillas son obligatorias: solo se llega aquí con ambas marcadas.
    'aceptaPrivacidad': true,
    'declaraRepresentante': true,
    'idioma': ?idioma,
  };
}

/// Qué respondió el registro sin sesión.
enum EstadoRegistroFamilia {
  /// Cuenta nueva: el código de 6 dígitos va por email.
  codigoEnviado,

  /// El email ya tiene una cuenta: que inicie sesión y pida el acceso desde dentro.
  cuentaExistente,

  /// El email tiene una invitación del club sin canjear: que use "Activar cuenta".
  invitacionPendiente,

  /// La cuenta se creó pero el email no salió (503): hay que reenviar el código.
  envioFallido,
}

class HijoMio {
  final int id;
  final String nombre;
  final String apellidos;
  final String equipo;
  final String estado;

  const HijoMio({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.equipo,
    required this.estado,
  });

  factory HijoMio.fromJson(Map<String, dynamic> json) => HijoMio(
    id: (json['id'] as num?)?.toInt() ?? 0,
    nombre: json['nombre']?.toString() ?? '',
    apellidos: json['apellidos']?.toString() ?? '',
    equipo: json['equipo']?.toString() ?? '',
    estado: json['estado']?.toString() ?? estadoHijoPendiente,
  );

  String get nombreCompleto => '$nombre $apellidos'.trim();
}

/// Una solicitud en la vista de la propia familia: nunca lleva jugadores ni coincidencias.
class SolicitudFamiliaMia {
  final int id;
  final String estado;
  final String parentesco;
  final DateTime? fechaSolicitud;
  final DateTime? fechaRevision;
  final String? motivoRechazo;
  final List<HijoMio> hijos;

  const SolicitudFamiliaMia({
    required this.id,
    required this.estado,
    required this.parentesco,
    required this.fechaSolicitud,
    required this.fechaRevision,
    required this.motivoRechazo,
    required this.hijos,
  });

  factory SolicitudFamiliaMia.fromJson(
    Map<String, dynamic> json,
  ) => SolicitudFamiliaMia(
    id: (json['id'] as num?)?.toInt() ?? 0,
    estado: json['estado']?.toString() ?? estadoSolicitudPendiente,
    parentesco: json['parentesco']?.toString() ?? '',
    fechaSolicitud: DateTime.tryParse(json['fechaSolicitud']?.toString() ?? ''),
    fechaRevision: DateTime.tryParse(json['fechaRevision']?.toString() ?? ''),
    motivoRechazo: json['motivoRechazo']?.toString(),
    hijos: [
      for (final h in (json['hijos'] as List<dynamic>? ?? const []))
        HijoMio.fromJson(h as Map<String, dynamic>),
    ],
  );

  /// Sigue esperando al club (con el email sin confirmar o ya confirmado).
  bool get abierta =>
      estado == estadoSolicitudPendiente ||
      estado == estadoSolicitudPendienteEmail;

  bool get algunHijoAprobado =>
      hijos.any((h) => h.estado == estadoHijoAprobado);
}

/// Un jugador que coincide con lo que escribió la familia, o que el revisor encuentra buscando.
class CoincidenciaJugador {
  final int jugadorId;
  final String nombre;
  final int? equipoId;
  final String equipo;
  final bool coincideEquipo;

  /// El backend no lo manda hoy; si lo manda se enseña.
  final int? dorsal;

  const CoincidenciaJugador({
    required this.jugadorId,
    required this.nombre,
    required this.equipoId,
    required this.equipo,
    required this.coincideEquipo,
    this.dorsal,
  });

  factory CoincidenciaJugador.fromJson(Map<String, dynamic> json) =>
      CoincidenciaJugador(
        jugadorId: (json['jugadorId'] as num?)?.toInt() ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        equipoId: (json['equipoId'] as num?)?.toInt(),
        equipo: json['equipo']?.toString() ?? '',
        coincideEquipo: json['coincideEquipo'] == true,
        dorsal: (json['dorsal'] as num?)?.toInt(),
      );
}

class HijoRevision {
  final int id;
  final String nombre;
  final String apellidos;
  final String equipo;
  final String estado;
  final CoincidenciaJugador? jugador;
  final List<CoincidenciaJugador> coincidencias;

  const HijoRevision({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.equipo,
    required this.estado,
    required this.jugador,
    required this.coincidencias,
  });

  factory HijoRevision.fromJson(Map<String, dynamic> json) => HijoRevision(
    id: (json['id'] as num?)?.toInt() ?? 0,
    nombre: json['nombre']?.toString() ?? '',
    apellidos: json['apellidos']?.toString() ?? '',
    equipo: json['equipo']?.toString() ?? '',
    estado: json['estado']?.toString() ?? estadoHijoPendiente,
    jugador: json['jugador'] is Map<String, dynamic>
        ? CoincidenciaJugador.fromJson(json['jugador'] as Map<String, dynamic>)
        : null,
    coincidencias: [
      for (final c in (json['coincidencias'] as List<dynamic>? ?? const []))
        CoincidenciaJugador.fromJson(c as Map<String, dynamic>),
    ],
  );

  String get nombreCompleto => '$nombre $apellidos'.trim();

  bool get pendiente => estado == estadoHijoPendiente;
}

/// Una solicitud como la ve quien revisa.
class SolicitudRevision {
  final int id;
  final String nombre;
  final String apellidos;
  final String email;
  final String? telefono;
  final String parentesco;
  final String estado;
  final DateTime? fechaSolicitud;
  final List<HijoRevision> hijos;

  const SolicitudRevision({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.telefono,
    required this.parentesco,
    required this.estado,
    required this.fechaSolicitud,
    required this.hijos,
  });

  factory SolicitudRevision.fromJson(Map<String, dynamic> json) =>
      SolicitudRevision(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        apellidos: json['apellidos']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        telefono: json['telefono']?.toString(),
        parentesco: json['parentesco']?.toString() ?? '',
        estado: json['estado']?.toString() ?? estadoSolicitudPendiente,
        fechaSolicitud: DateTime.tryParse(
          json['fechaSolicitud']?.toString() ?? '',
        ),
        hijos: [
          for (final h in (json['hijos'] as List<dynamic>? ?? const []))
            HijoRevision.fromJson(h as Map<String, dynamic>),
        ],
      );

  String get nombreCompleto => '$nombre $apellidos'.trim();
}
