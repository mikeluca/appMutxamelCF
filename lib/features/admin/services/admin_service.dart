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

  Future<List<UsuarioPendienteModel>> obtenerUsuariosPendientes() async {
    final data =
        await ApiClient.get('/app/admin/usuarios-pendientes', autenticado: true)
            as List<dynamic>;

    return data
        .map((e) => UsuarioPendienteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Reenvía la activación y devuelve el email al que se envió.
  Future<String> reenviarActivacion(int usuarioId) async {
    final data =
        await ApiClient.post(
              '/app/admin/usuarios/$usuarioId/reenviar-activacion',
              autenticado: true,
            )
            as Map<String, dynamic>;

    return data['email']?.toString() ?? '';
  }

  // ---- reactivar al autor de un reporte --------------------------------------------------------

  /// Reactiva la cuenta del autor de un reporte AUTOR_DESACTIVADO. El reporte sigue en ese
  /// estado, con una anotación de la reactivación.
  Future<void> reactivarAutor(int reporteId, {String? nota}) =>
      _accion('/app/moderacion/reportes/$reporteId/reactivar-autor', nota: nota);

  // ---- invitar usuarios ------------------------------------------------------------------------

  Future<VinculosDisponiblesModel> obtenerVinculosDisponibles() async {
    final data = await ApiClient.get(
      '/app/admin/vinculos-disponibles',
      autenticado: true,
    );

    return VinculosDisponiblesModel.fromJson(data as Map<String, dynamic>);
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
      '/app/admin/invitaciones',
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
