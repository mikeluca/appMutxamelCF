import '../../../core/network/api_client.dart';
import '../models/partido_en_vivo_models.dart';

class PartidoEnVivoService {
  static const String _base = '/app/partido-en-vivo';

  /// Alineación elegida entre los jugadores del partido: los ids de titulares y suplentes, cada lista
  /// en el orden en que se eligieron (con [formacion], el de los titulares da la posición en el campo). Los
  /// suplentes y la formación son opcionales. El aviso solo sale con [avisar]; reenviarla reemplaza a la anterior.
  Future<void> enviarAlineacion(
    int partidoId, {
    required List<int> titulares,
    List<int> suplentes = const [],
    String? formacion,
    bool avisar = false,
  }) {
    return ApiClient.post(
      '$_base/$partidoId/alineacion',
      autenticado: true,
      body: {
        'titulares': titulares,
        'suplentes': suplentes,
        'formacion': formacion,
        'avisar': avisar,
      },
    );
  }

  /// Cambio: sale [jugadorSaleId], entra [jugadorEntraId]. Sin [minuto] lo calcula el servidor. Sin aviso.
  Future<EstadoPartidoEnVivo> enviarCambio(
    int partidoId, {
    required int jugadorSaleId,
    required int jugadorEntraId,
    int? minuto,
  }) => _evento(
    partidoId,
    'cambio',
    body: {
      'jugadorSaleId': jugadorSaleId,
      'jugadorEntraId': jugadorEntraId,
      'minuto': minuto,
    },
  );

  /// Tarjeta ([color] AMARILLA o ROJA). La segunda amarilla de un jugador es una expulsión. Sin aviso.
  Future<EstadoPartidoEnVivo> enviarTarjeta(
    int partidoId, {
    required int jugadorId,
    required String color,
    int? minuto,
  }) => _evento(
    partidoId,
    'tarjeta',
    body: {'jugadorId': jugadorId, 'color': color, 'minuto': minuto},
  );

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

  /// Jugadores entre los que elegir autor o alineación: los convocados efectivos (`origen` CONVOCATORIA)
  /// o, sin convocatoria, la plantilla activa (`origen` PLANTILLA).
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
    int? minuto,
  }) => _evento(
    partidoId,
    'gol-favor',
    body: {
      'jugadorId': jugadorId,
      'autorTexto': autorTexto,
      'minuto': minuto,
    },
  );

  /// Sin [minuto] lo calcula el servidor.
  Future<EstadoPartidoEnVivo> enviarGolContra(int partidoId, {int? minuto}) =>
      _evento(partidoId, 'gol-contra', body: {'minuto': minuto});

  Future<EstadoPartidoEnVivo> enviarDescanso(int partidoId) =>
      _evento(partidoId, 'descanso');

  Future<EstadoPartidoEnVivo> enviarSegundaParte(int partidoId) =>
      _evento(partidoId, 'segunda-parte');

  Future<EstadoPartidoEnVivo> enviarFinalPartido(int partidoId) =>
      _evento(partidoId, 'final');

  /// Corrige el minuto (0-150) de un gol, cambio o tarjeta no anulado del partido de hoy; el servidor no
  /// reenvía ningún aviso.
  Future<EstadoPartidoEnVivo> corregirMinuto(
    int partidoId,
    int eventoId,
    int minuto,
  ) async {
    final data = await ApiClient.patch(
      '$_base/$partidoId/eventos/$eventoId/minuto',
      autenticado: true,
      body: {'minuto': minuto},
    );

    return EstadoPartidoEnVivo.fromJson(data as Map<String, dynamic>);
  }

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
