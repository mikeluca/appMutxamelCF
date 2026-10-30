import '../../../core/network/api_client.dart';
import '../../matches/models/justificacion_partido_model.dart';
import '../models/invitacion_model.dart';

/// Jugadores de otros equipos invitados a una convocatoria
/// (docs/api-app-convocatoria-invitados.md del backend). Los permisos, los
/// estados y los plazos los comprueba el servidor: 403 sin permiso, 400 con el
/// motivo y 409 con un `codigo` (ver [ConflictoInvitacion]).
class InvitadosService {
  /// Los equipos de los que el equipo de ese partido puede invitar jugadores.
  Future<List<EquipoInvitableModel>> obtenerEquipos(int partidoId) async {
    final data =
        await ApiClient.get(
              '/app/partidos/$partidoId/invitables/equipos',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map((e) => EquipoInvitableModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Los jugadores invitables de [equipoId] para ese partido.
  Future<List<JugadorInvitableModel>> obtenerJugadores(
    int partidoId,
    int equipoId,
  ) async {
    final data =
        await ApiClient.get(
              '/app/partidos/$partidoId/invitables/equipos/$equipoId/jugadores',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map((e) => JugadorInvitableModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Pendientes de coordinación y de su entrenador (COORDINADOR y ADMIN_APP).
  Future<List<InvitacionPendienteModel>> obtenerPendientes() async {
    final data =
        await ApiClient.get('/app/invitaciones/pendientes', autenticado: true)
            as List<dynamic>;

    return data
        .map(
          (e) => InvitacionPendienteModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<InvitacionResultadoModel> aprobar(int invitacionId) async {
    final data = await ApiClient.post(
      '/app/invitaciones/$invitacionId/aprobar',
      autenticado: true,
    );

    return InvitacionResultadoModel.fromJson(data as Map<String, dynamic>);
  }

  /// Rechaza la invitación; el [motivo] es opcional (hasta 500 caracteres).
  Future<InvitacionResultadoModel> rechazar(
    int invitacionId, {
    String? motivo,
  }) async {
    final texto = motivo?.trim() ?? '';

    final data = await ApiClient.post(
      '/app/invitaciones/$invitacionId/rechazar',
      autenticado: true,
      body: texto.isEmpty ? null : {'motivo': texto},
    );

    return InvitacionResultadoModel.fromJson(data as Map<String, dynamic>);
  }

  /// Libera al jugador (pendiente de su entrenador): lo quita de la convocatoria de
  /// su equipo ese día y queda autorizado. Lo hace el cuerpo técnico del equipo de
  /// origen o coordinación.
  Future<InvitacionResultadoModel> liberar(int invitacionId) async {
    final data = await ApiClient.post(
      '/app/invitaciones/$invitacionId/liberar',
      autenticado: true,
    );

    return InvitacionResultadoModel.fromJson(data as Map<String, dynamic>);
  }

  /// La familia o el jugador desestiman al invitado autorizado: es una
  /// justificación de ausencia a ese partido (el motivo es obligatorio, de 3 a
  /// 500 caracteres, y el plazo es el de siempre).
  Future<JustificacionPartidoModel> desestimar({
    required int partidoId,
    required int jugadorId,
    required String motivo,
  }) async {
    final data = await ApiClient.post(
      '/app/partidos/$partidoId/invitados/$jugadorId/desestimar',
      autenticado: true,
      body: {'motivo': motivo},
    );

    return JustificacionPartidoModel.fromJson(data as Map<String, dynamic>);
  }
}
