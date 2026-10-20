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
}
