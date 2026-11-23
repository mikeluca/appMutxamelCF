import '../../../core/network/api_client.dart';
import '../models/admin_model.dart';

/// Moderación de mensajes reportados y cuentas pendientes (solo ADMIN_APP).
class AdminService {
  Future<List<ReporteModel>> obtenerReportes({bool resueltos = false}) async {
    final estado = resueltos ? 'RESUELTOS' : 'PENDIENTE';

    final data =
        await ApiClient.get(
              '/app/moderacion/reportes?estado=$estado',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map((e) => ReporteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> contarReportesPendientes() async {
    final data =
        await ApiClient.get(
              '/app/moderacion/reportes/pendientes/contador',
              autenticado: true,
            )
            as Map<String, dynamic>;

    return (data['pendientes'] as num?)?.toInt() ?? 0;
  }

  Future<void> descartar(int reporteId, {String? nota}) =>
      _accion('/app/moderacion/reportes/$reporteId/descartar', nota: nota);

  Future<void> borrarMensaje(int reporteId, {String? nota}) =>
      _accion('/app/moderacion/reportes/$reporteId/borrar-mensaje', nota: nota);

  Future<void> desactivarAutor(
    int reporteId, {
    String? nota,
    required bool borrarMensaje,
  }) => _accion(
    '/app/moderacion/reportes/$reporteId/desactivar-autor',
    nota: nota,
    borrarMensaje: borrarMensaje,
  );

  Future<void> _accion(String ruta, {String? nota, bool? borrarMensaje}) async {
    await ApiClient.post(
      ruta,
      autenticado: true,
      body: {
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
        'borrarMensaje': ?borrarMensaje,
      },
    );
  }

  // ---- usuarios de la app (GET/POST /app/admin/usuarios/**, solo ADMIN_APP) ----------------------

  /// Todas las cuentas de la app (sin las que borró su titular). Los filtros se aplican en el móvil.
  Future<List<UsuarioAdminModel>> obtenerUsuarios() async {
    final data =
        await ApiClient.get('/app/admin/usuarios', autenticado: true)
            as List<dynamic>;

    return data
        .whereType<Map<String, dynamic>>()
        .map(UsuarioAdminModel.fromJson)
        .toList();
  }

  /// Cambia el nombre de una cuenta sin ficha vinculada.
  Future<void> actualizarNombreUsuario(
    int id, {
    required String nombre,
    String? apellidos,
  }) => _accionUsuario(
    id,
    'nombre',
    body: {'nombre': nombre.trim(), 'apellidos': ?_limpio(apellidos)},
  );

  /// Vincula la cuenta a una persona del club (jugador, familiar o cuerpo técnico).
  Future<void> anadirVinculoUsuario(int id, PersonaDisponibleModel persona) =>
      _accionUsuario(
        id,
        'vinculos',
        body: {
          'vinculos': [
            {'tipo': persona.tipo.codigo, 'personaId': persona.id},
          ],
        },
      );

  /// Añade un rol sin persona (COORDINADOR, RETRANSMISION, RRSS...).
  Future<void> anadirRolUsuario(int id, String codigoRol) => _accionUsuario(
    id,
    'vinculos',
    body: {
      'vinculos': [
        {'tipo': codigoRol},
      ],
    },
  );

  /// Quita un vínculo con una persona (tipo + personaId) o un rol sin persona (solo el tipo).
  Future<void> quitarVinculoUsuario(
    int id, {
    required String tipo,
    int? personaId,
  }) => _accionUsuario(
    id,
    'vinculos/quitar',
    body: {'tipo': tipo, 'personaId': ?personaId},
  );

  /// Reenvía la invitación; devuelve el email al que se mandó. Un 429 es "inténtalo en N min".
  Future<String> reenviarUsuario(int id) async {
    final data = await _accionUsuario(id, 'reenviar');

    return data?['email']?.toString() ?? '';
  }

  Future<void> activarUsuario(int id) => _accionUsuario(id, 'activar');

  Future<void> desactivarUsuario(int id) => _accionUsuario(id, 'desactivar');

  /// Solo invitaciones sin activar.
  Future<void> eliminarUsuario(int id) => _accionUsuario(id, 'eliminar');

  Future<Map<String, dynamic>?> _accionUsuario(
    int id,
    String accion, {
    Map<String, dynamic>? body,
  }) async {
    final data = await ApiClient.post(
      '/app/admin/usuarios/$id/$accion',
      autenticado: true,
      body: body,
    );

    return data is Map<String, dynamic> ? data : null;
  }

  // ---- reactivar al autor de un reporte --------------------------------------------------------

  /// Reactiva la cuenta del autor de un reporte AUTOR_DESACTIVADO. El reporte sigue en ese
  /// estado, con una anotación de la reactivación.
  Future<void> reactivarAutor(int reporteId, {String? nota}) => _accion(
    '/app/moderacion/reportes/$reporteId/reactivar-autor',
    nota: nota,
  );

  // ---- invitar usuarios ------------------------------------------------------------------------

  Future<VinculosDisponiblesModel> obtenerVinculosDisponibles() async {
    final data = await ApiClient.get(
      '/app/admin/usuarios/opciones',
      autenticado: true,
    );

    return VinculosDisponiblesModel.fromOpcionesJson(
      data as Map<String, dynamic>,
    );
  }

  /// Invita a una persona. Errores del servidor: 400 (datos no válidos, o el rol ADMIN_APP),
  /// 403 (no es administrador) y 409 (el email ya está registrado).
  Future<InvitacionEnviadaModel> invitar({
    required String email,
    String? nombre,
    String? apellidos,
    required List<PersonaDisponibleModel> vinculos,
    List<String> roles = const [],
  }) async {
    final data = await ApiClient.post(
      '/app/admin/usuarios/invitar',
      autenticado: true,
      body: {
        'email': email.trim(),
        'nombre': ?_limpio(nombre),
        'apellidos': ?_limpio(apellidos),
        'vinculos': [
          for (final v in vinculos) {'tipo': v.tipo.codigo, 'personaId': v.id},
        ],
        'roles': roles,
      },
    );

    return InvitacionEnviadaModel.fromJson(data as Map<String, dynamic>);
  }

  static String? _limpio(String? texto) {
    final limpio = texto?.trim() ?? '';

    return limpio.isEmpty ? null : limpio;
  }

  // ---- estado de la app ------------------------------------------------------------------------

  Future<EstadoAppModel> obtenerEstado() async {
    final data = await ApiClient.get('/app/admin/estado', autenticado: true);

    return EstadoAppModel.fromJson(data as Map<String, dynamic>);
  }

  /// Las cuentas de un filtro del estado (como mucho 200).
  Future<List<UsuarioEstadoModel>> obtenerUsuariosEstado(
    FiltroEstado filtro,
  ) async {
    final data =
        await ApiClient.get(
              '/app/admin/estado/usuarios?filtro=${filtro.codigo}',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map((e) => UsuarioEstadoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
