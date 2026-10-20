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
