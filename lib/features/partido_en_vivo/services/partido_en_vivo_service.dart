import '../../../core/network/api_client.dart';
import '../models/partido_en_vivo_models.dart';

class PartidoEnVivoService {
  static const String _base = '/app/partido-en-vivo';

  Future<void> enviarAlineacion({
    required String onceInicial,
    required String suplentes,
  }) {
    return ApiClient.post(
      '$_base/alineacion',
      autenticado: true,
      body: {'onceInicial': onceInicial, 'suplentes': suplentes},
    );
  }

  /// Partidos del Primer Equipo de hoy, no cancelados. Vacía si no hay.
  Future<List<PartidoEnVivoDisponible>> obtenerPartidosDisponibles() async {
    final data =
        await ApiClient.get('$_base/partidos-disponibles', autenticado: true)
            as List<dynamic>;

    return data
        .map(
          (json) =>
              PartidoEnVivoDisponible.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<EstadoPartidoEnVivo> obtenerEstado(int partidoId) async {
    final data = await ApiClient.get('$_base/$partidoId', autenticado: true);

    return EstadoPartidoEnVivo.fromJson(data as Map<String, dynamic>);
  }

  /// Jugadores de la convocatoria del partido (o la plantilla del Primer Equipo).
  Future<List<ConvocadoEnVivo>> obtenerConvocados(int partidoId) async {
    final data =
        await ApiClient.get('$_base/$partidoId/convocados', autenticado: true)
            as List<dynamic>;

    return data
        .map((json) => ConvocadoEnVivo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<EstadoPartidoEnVivo> enviarInicioPartido(int partidoId) =>
      _evento(partidoId, 'inicio');

  /// Gol de un convocado ([jugadorId]) o de "Otro" / "p.p." ([autorTexto]).
  Future<EstadoPartidoEnVivo> enviarGolFavor(
    int partidoId, {
    int? jugadorId,
    String? autorTexto,
  }) => _evento(
    partidoId,
    'gol-favor',
    body: {'jugadorId': jugadorId, 'autorTexto': autorTexto},
  );

  Future<EstadoPartidoEnVivo> enviarGolContra(int partidoId) =>
      _evento(partidoId, 'gol-contra');

  Future<EstadoPartidoEnVivo> enviarDescanso(int partidoId) =>
      _evento(partidoId, 'descanso');

  Future<EstadoPartidoEnVivo> enviarSegundaParte(int partidoId) =>
      _evento(partidoId, 'segunda-parte');

  Future<EstadoPartidoEnVivo> enviarFinalPartido(int partidoId) =>
      _evento(partidoId, 'final');

  /// Anula el último evento (solo durante los 2 minutos siguientes).
  Future<EstadoPartidoEnVivo> deshacer(int partidoId, int eventoId) async {
    final data = await ApiClient.post(
      '$_base/$partidoId/eventos/$eventoId/deshacer',
      autenticado: true,
    );

    return EstadoPartidoEnVivo.fromJson(data as Map<String, dynamic>);
  }

  Future<EstadoPartidoEnVivo> _evento(
    int partidoId,
    String ruta, {
    Object? body,
  }) async {
    final data = await ApiClient.post(
      '$_base/$partidoId/$ruta',
      autenticado: true,
      body: body,
    );

    return EstadoPartidoEnVivo.fromJson(data as Map<String, dynamic>);
  }
}
