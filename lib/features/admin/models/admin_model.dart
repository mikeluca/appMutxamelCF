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

// ---------------------------------------------------------------------------
// Usuarios de la app (ADMIN_APP)
// ---------------------------------------------------------------------------

/// El estado de una cuenta, con la misma regla que las insignias del panel web (el backend lo calcula).
enum EstadoCuenta {
  activa('ACTIVA'),
  pendiente('PENDIENTE'),
  caducada('CADUCADA'),
  desactivada('DESACTIVADA');

  final String codigo;

  const EstadoCuenta(this.codigo);

  static EstadoCuenta desdeTexto(String? texto) =>
      EstadoCuenta.values.firstWhere(
        (e) => e.codigo == texto,
        orElse: () => EstadoCuenta.desactivada,
      );
}

/// Un rol de una cuenta, con su nombre ("Redes sociales").
class RolCuentaModel {
  final String codigo;
  final String nombre;

  const RolCuentaModel({required this.codigo, required this.nombre});

  /// El rol de administrador: solo se asigna y se quita desde el panel web.
  bool get esAdmin => codigo == 'ADMIN_APP';

  /// Los roles de persona (jugador, familiar, entrenador) salen de un vínculo con su ficha; el resto (coordinador,
  /// retransmisión, redes sociales...) son roles sin persona.
  bool get esDePersona =>
      codigo == 'JUGADOR' || codigo == 'FAMILIAR' || codigo == 'ENTRENADOR';
}

/// Un vínculo de la cuenta con una persona del club (su ficha).
class VinculoCuentaModel {
  /// JUGADOR, FAMILIAR o ENTRENADOR.
  final String tipo;
  final int? personaId;
  final String nombre;
  final String detalle;

  const VinculoCuentaModel({
    required this.tipo,
    this.personaId,
    this.nombre = '',
    this.detalle = '',
  });
}

/// Una cuenta en el listado de GET /app/admin/usuarios.
class UsuarioAdminModel {
  final int id;
  final String email;

  /// El nombre que muestra el panel (el de la ficha o el propio de la cuenta); null si no tiene.
  final String? nombre;
  final EstadoCuenta estado;
  final List<RolCuentaModel> roles;
  final List<VinculoCuentaModel> vinculos;
  final DateTime? ultimoAcceso;

  const UsuarioAdminModel({
    required this.id,
    required this.email,
    this.nombre,
    this.estado = EstadoCuenta.activa,
    this.roles = const [],
    this.vinculos = const [],
    this.ultimoAcceso,
  });

  bool get activa => estado == EstadoCuenta.activa;

  /// Con ficha vinculada el nombre sale de ella y no se edita aquí (como en el panel).
  bool get tieneFicha => vinculos.isNotEmpty;

  bool get esAdmin => roles.any((r) => r.esAdmin);

  /// El nombre para pintar: el de la cuenta o, si no tiene, el email.
  String get nombreVisible =>
      (nombre ?? '').trim().isEmpty ? email : nombre!.trim();

  /// Los roles sin persona (los que se añaden y quitan sin ficha).
  List<RolCuentaModel> get rolesSinPersona =>
      roles.where((r) => !r.esDePersona && !r.esAdmin).toList();

  /// Una copia con otros datos cambiados.
  UsuarioAdminModel conNombre(String? nuevo) => UsuarioAdminModel(
    id: id,
    email: email,
    nombre: nuevo,
    estado: estado,
    roles: roles,
    vinculos: vinculos,
    ultimoAcceso: ultimoAcceso,
  );

  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminModel(
      id: (json['id'] as num).toInt(),
      email: json['email']?.toString() ?? '',
      nombre: json['nombre']?.toString(),
      estado: EstadoCuenta.desdeTexto(json['estado']?.toString()),
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (r) => RolCuentaModel(
              codigo: r['codigo']?.toString() ?? '',
              nombre: r['nombre']?.toString() ?? r['codigo']?.toString() ?? '',
            ),
          )
          .toList(),
      vinculos: (json['vinculos'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (v) => VinculoCuentaModel(
              tipo: v['tipo']?.toString() ?? '',
              personaId: (v['personaId'] as num?)?.toInt(),
              nombre: v['nombre']?.toString() ?? '',
              detalle: v['detalle']?.toString() ?? '',
            ),
          )
          .toList(),
      ultimoAcceso: _fechaHora(json['ultimoAcceso']),
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

  /// GET /app/admin/usuarios/opciones: los roles asignables (nunca ADMIN_APP) y las personas sin cuenta por tipo.
  factory VinculosDisponiblesModel.fromOpcionesJson(Map<String, dynamic> json) {
    final personas = (json['personas'] as Map<String, dynamic>?) ?? const {};

    List<PersonaDisponibleModel> lista(String clave, TipoVinculo tipo) {
      return (personas[clave] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((m) {
            final equipo = m['equipo']?.toString() ?? '';
            final email = m['email']?.toString() ?? '';

            return PersonaDisponibleModel(
              tipo: tipo,
              id: (m['id'] as num).toInt(),
              nombre: m['nombreCompleto']?.toString() ?? '',
              detalle: equipo.isNotEmpty ? equipo : email,
            );
          })
          .toList();
    }

    return VinculosDisponiblesModel(
      jugadores: lista('jugadores', TipoVinculo.jugador),
      familiares: lista('familiares', TipoVinculo.familiar),
      cuerpoTecnico: lista('cuerpoTecnico', TipoVinculo.cuerpoTecnico),
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => RolDisponibleModel(
              codigo: e['codigo'].toString(),
              nombre: e['nombre']?.toString() ?? '',
            ),
          )
          .where((r) => r.codigo != 'ADMIN_APP')
          .toList(),
    );
  }

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
