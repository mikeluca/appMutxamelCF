DateTime? _fechaHora(Object? valor) =>
    DateTime.tryParse(valor?.toString() ?? '');

const String estadoReportePendiente = 'PENDIENTE';
const String estadoReporteDescartado = 'DESCARTADO';
const String estadoReporteMensajeBorrado = 'MENSAJE_BORRADO';
const String estadoReporteAutorDesactivado = 'AUTOR_DESACTIVADO';

/// Un mensaje reportado, con la copia que se guardó al reportarlo.
class ReporteModel {
  final int id;
  final DateTime? fechaReporte;
  final String? motivo;
  final String reportador;
  final int? autorId;
  final String autor;
  final bool autorActivo;

  /// Un ADMIN_APP no se puede desactivar desde la moderación.
  final bool autorEsAdmin;
  final String? titulo;
  final String contenido;
  final DateTime? fechaMensaje;
  final String estado;
  final String? resueltoPor;
  final DateTime? fechaResolucion;
  final String? nota;

  /// Otros reportes (pendientes y resueltos) contra el mismo autor.
  final int otrosReportesDelAutor;

  const ReporteModel({
    required this.id,
    required this.fechaReporte,
    required this.motivo,
    required this.reportador,
    required this.autorId,
    required this.autor,
    required this.autorActivo,
    required this.autorEsAdmin,
    required this.titulo,
    required this.contenido,
    required this.fechaMensaje,
    required this.estado,
    required this.resueltoPor,
    required this.fechaResolucion,
    required this.nota,
    required this.otrosReportesDelAutor,
  });

  bool get pendiente => estado == estadoReportePendiente;

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    final reportador = json['reportador'] as Map<String, dynamic>? ?? const {};
    final autor = json['autor'] as Map<String, dynamic>? ?? const {};
    final resueltoPor = json['resueltoPor'] as Map<String, dynamic>?;

    return ReporteModel(
      id: (json['id'] as num).toInt(),
      fechaReporte: _fechaHora(json['fechaReporte']),
      motivo: json['motivo']?.toString(),
      reportador: reportador['nombre']?.toString() ?? '',
      autorId: (autor['id'] as num?)?.toInt(),
      autor: autor['nombre']?.toString() ?? '',
      autorActivo: autor['activo'] as bool? ?? false,
      autorEsAdmin: autor['esAdmin'] as bool? ?? false,
      titulo: json['tituloCopia']?.toString(),
      contenido: json['contenidoCopia']?.toString() ?? '',
      fechaMensaje: _fechaHora(json['fechaMensaje']),
      estado: json['estado']?.toString() ?? estadoReportePendiente,
      resueltoPor: resueltoPor?['nombre']?.toString(),
      fechaResolucion: _fechaHora(json['fechaResolucion']),
      nota: json['notaResolucion']?.toString(),
      otrosReportesDelAutor:
          (json['otrosReportesDelAutor'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Una cuenta invitada que todavía no se ha activado.
class UsuarioPendienteModel {
  final int id;
  final String email;
  final String? nombre;
  final String? apellidos;
  final List<String> roles;
  final List<String> vinculos;
  final DateTime? fechaAlta;
  final bool tokenCaducado;
  final int intentosActivacion;

  const UsuarioPendienteModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellidos,
    required this.roles,
    required this.vinculos,
    required this.fechaAlta,
    required this.tokenCaducado,
    required this.intentosActivacion,
  });

  /// El nombre de la persona vinculada; si no hay, el de la cuenta; si no, el email.
  String get nombreMostrable {
    if (vinculos.isNotEmpty) return vinculos.first;

    final propio = '${nombre ?? ''} ${apellidos ?? ''}'.trim();

    return propio.isEmpty ? email : propio;
  }

  factory UsuarioPendienteModel.fromJson(Map<String, dynamic> json) {
    List<String> textos(String clave) =>
        (json[clave] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return UsuarioPendienteModel(
      id: (json['id'] as num).toInt(),
      email: json['email']?.toString() ?? '',
      nombre: json['nombre']?.toString(),
      apellidos: json['apellidos']?.toString(),
      roles: textos('roles'),
      vinculos: textos('vinculos'),
      fechaAlta: _fechaHora(json['fechaAlta']),
      tokenCaducado: json['tokenCaducado'] as bool? ?? false,
      intentosActivacion: (json['intentosActivacion'] as num?)?.toInt() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Invitar usuarios desde la app (ADMIN_APP)
// ---------------------------------------------------------------------------

/// Tipo de persona del club a la que se vincula una cuenta: el "tipo" del vínculo
/// que espera el backend.
enum TipoVinculo {
  jugador('JUGADOR'),
  familiar('FAMILIAR'),
  cuerpoTecnico('ENTRENADOR');

  final String codigo;

  const TipoVinculo(this.codigo);
}

/// Una persona del club sin cuenta que se puede elegir al invitar.
class PersonaDisponibleModel {
  final TipoVinculo tipo;
  final int id;
  final String nombre;

  /// El equipo (jugador, cuerpo técnico) o los jugadores de los que es familiar.
  final String detalle;

  const PersonaDisponibleModel({
    required this.tipo,
    required this.id,
    required this.nombre,
    this.detalle = '',
  });

  @override
  bool operator ==(Object other) =>
      other is PersonaDisponibleModel && other.tipo == tipo && other.id == id;

  @override
  int get hashCode => Object.hash(tipo, id);
}

/// Un rol que no sale de un vínculo (COORDINADOR, RETRANSMISION...).
class RolDisponibleModel {
  final String codigo;
  final String nombre;

  const RolDisponibleModel({required this.codigo, required this.nombre});
}

/// GET /app/admin/vinculos-disponibles.
class VinculosDisponiblesModel {
  final List<PersonaDisponibleModel> jugadores;
  final List<PersonaDisponibleModel> familiares;
  final List<PersonaDisponibleModel> cuerpoTecnico;
  final List<RolDisponibleModel> roles;

  const VinculosDisponiblesModel({
    this.jugadores = const [],
    this.familiares = const [],
    this.cuerpoTecnico = const [],
    this.roles = const [],
  });

  List<PersonaDisponibleModel> de(TipoVinculo tipo) => switch (tipo) {
    TipoVinculo.jugador => jugadores,
    TipoVinculo.familiar => familiares,
    TipoVinculo.cuerpoTecnico => cuerpoTecnico,
  };

  factory VinculosDisponiblesModel.fromJson(Map<String, dynamic> json) {
    List<PersonaDisponibleModel> personas(
      String clave,
      TipoVinculo tipo,
      String detalle,
    ) {
      return (json[clave] as List<dynamic>? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        final valor = m[detalle];

        return PersonaDisponibleModel(
          tipo: tipo,
          id: (m['id'] as num).toInt(),
          nombre: m['nombre']?.toString() ?? '',
          detalle: valor is List
              ? valor.map((j) => j.toString()).join(', ')
              : valor?.toString() ?? '',
        );
      }).toList();
    }

    return VinculosDisponiblesModel(
      jugadores: personas('jugadores', TipoVinculo.jugador, 'equipo'),
      familiares: personas('familiares', TipoVinculo.familiar, 'jugadores'),
      cuerpoTecnico: personas(
        'cuerpoTecnico',
        TipoVinculo.cuerpoTecnico,
        'equipo',
      ),
      roles: (json['rolesAdicionales'] as List<dynamic>? ?? [])
          .map(
            (e) => RolDisponibleModel(
              codigo: (e as Map<String, dynamic>)['codigo'].toString(),
              nombre: e['nombre']?.toString() ?? '',
            ),
          )
          .toList(),
    );
  }
}

/// La respuesta de una invitación creada.
class InvitacionEnviadaModel {
  final String email;

  /// false si la cuenta se creó pero el email no salió (se reenvía desde Cuentas pendientes).
  final bool emailEnviado;

  const InvitacionEnviadaModel({required this.email, this.emailEnviado = true});

  factory InvitacionEnviadaModel.fromJson(Map<String, dynamic> json) {
    return InvitacionEnviadaModel(
      email: json['email']?.toString() ?? '',
      emailEnviado: json['emailEnviado'] as bool? ?? true,
    );
  }
}

// ---------------------------------------------------------------------------
// Estado de la app (ADMIN_APP)
// ---------------------------------------------------------------------------

/// Los filtros de las listas de cuentas del estado (el "filtro" del backend).
enum FiltroEstado {
  sinDispositivo('SIN_DISPOSITIVO'),
  sinNotificaciones('SIN_NOTIFICACIONES'),
  versionAntigua('VERSION_ANTIGUA'),
  inactivos('INACTIVOS');

  final String codigo;

  const FiltroEstado(this.codigo);
}

/// Dispositivos activos de una plataforma y versión.
class VersionDispositivosModel {
  final String plataforma;
  final String version;
  final int dispositivos;

  /// Inferior a la versión mínima de su plataforma.
  final bool porDebajoMinima;

  const VersionDispositivosModel({
    required this.plataforma,
    required this.version,
    required this.dispositivos,
    this.porDebajoMinima = false,
  });

  factory VersionDispositivosModel.fromJson(Map<String, dynamic> json) {
    return VersionDispositivosModel(
      plataforma: json['plataforma']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      dispositivos: (json['dispositivos'] as num?)?.toInt() ?? 0,
      porDebajoMinima: json['porDebajoMinima'] as bool? ?? false,
    );
  }
}

/// GET /app/admin/estado.
class EstadoAppModel {
  final int activas;
  final int pendientes;
  final int desactivadas;
  final int activasSinDispositivo;
  final int activasSinNotificaciones;
  final int usuariosInactivos;
  final int diasInactividad;
  final int dispositivosVersionAntigua;
  final List<VersionDispositivosModel> versiones;
  final String minimaAndroid;
  final String minimaIos;

  const EstadoAppModel({
    this.activas = 0,
    this.pendientes = 0,
    this.desactivadas = 0,
    this.activasSinDispositivo = 0,
    this.activasSinNotificaciones = 0,
    this.usuariosInactivos = 0,
    this.diasInactividad = 30,
    this.dispositivosVersionAntigua = 0,
    this.versiones = const [],
    this.minimaAndroid = '',
    this.minimaIos = '',
  });

  /// El total que se enseña en la tarjeta de cada filtro (el de versión antigua cuenta
  /// dispositivos, no cuentas: el tamaño real de la lista lo da el servidor).
  int total(FiltroEstado filtro) => switch (filtro) {
    FiltroEstado.sinDispositivo => activasSinDispositivo,
    FiltroEstado.sinNotificaciones => activasSinNotificaciones,
    FiltroEstado.versionAntigua => dispositivosVersionAntigua,
    FiltroEstado.inactivos => usuariosInactivos,
  };

  factory EstadoAppModel.fromJson(Map<String, dynamic> json) {
    final cuentas = json['cuentas'] as Map<String, dynamic>? ?? const {};
    final minima = json['versionMinima'] as Map<String, dynamic>? ?? const {};

    int entero(Object? v) => (v as num?)?.toInt() ?? 0;

    return EstadoAppModel(
      activas: entero(cuentas['activas']),
      pendientes: entero(cuentas['pendientes']),
      desactivadas: entero(cuentas['desactivadas']),
      activasSinDispositivo: entero(json['activasSinDispositivo']),
      activasSinNotificaciones: entero(json['activasSinNotificaciones']),
      usuariosInactivos: entero(json['usuariosInactivos']),
      diasInactividad: json['diasInactividad'] == null
          ? 30
          : entero(json['diasInactividad']),
      dispositivosVersionAntigua: entero(json['dispositivosVersionAntigua']),
      versiones: (json['versiones'] as List<dynamic>? ?? [])
          .map(
            (e) => VersionDispositivosModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      minimaAndroid: minima['android']?.toString() ?? '',
      minimaIos: minima['ios']?.toString() ?? '',
    );
  }
}

/// Una cuenta de las listas del estado.
class UsuarioEstadoModel {
  final int id;
  final String nombre;
  final String email;
  final List<String> roles;
  final DateTime? ultimoAcceso;
  final List<String> versiones;

  const UsuarioEstadoModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.roles = const [],
    this.ultimoAcceso,
    this.versiones = const [],
  });

  factory UsuarioEstadoModel.fromJson(Map<String, dynamic> json) {
    List<String> textos(String clave) =>
        (json[clave] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return UsuarioEstadoModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: textos('roles'),
      ultimoAcceso: _fechaHora(json['ultimoAcceso']),
      versiones: textos('versiones'),
    );
  }
}
