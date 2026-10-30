import '../../../core/network/api_client.dart';
import '../model/convocatoria_model.dart';

class ConvocatoriaService {
  Future<List<ConvocatoriaModel>> obtenerPorEquipo(int equipoId) async {
    final data =
        await ApiClient.get(
              '/app/convocatorias?equipoId=$equipoId',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map((item) => ConvocatoriaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ConvocatoriaModel> obtenerPorId(int convocatoriaId) async {
    final data = await ApiClient.get(
      '/app/convocatorias/$convocatoriaId',
      autenticado: true,
    );

    return ConvocatoriaModel.fromJson(data as Map<String, dynamic>);
  }

  /// Crea una convocatoria a partir de un partido YA existente: el
  /// rival/campo/fecha/hora ya no se envían (se leen en el backend, en
  /// vivo, del partido indicado por [partidoId]).
  ///
  /// [invitadosIds] son los jugadores de otros equipos (máximo 3); quedan
  /// pendientes de coordinación. Es una lista: sin invitados, la lista vacía.
  Future<ConvocatoriaModel> crear({
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
    List<int>? invitadosIds,
  }) async {
    final data = await ApiClient.post(
      '/app/convocatorias',
      autenticado: true,
      body: {
        'partidoId': partidoId,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
        'jugadoresIds': jugadoresIds,
        'invitadosIds': ?invitadosIds,
      },
    );

    return ConvocatoriaModel.fromJson(data as Map<String, dynamic>);
  }

  /// Actualiza una convocatoria: puede re-apuntarse a otro partido (mismo
  /// equipo), cambiar hora y lugar y, con [jugadoresIds], añadir y quitar
  /// jugadores (los demás se conservan). Sin [jugadoresIds] los convocados no
  /// se tocan.
  ///
  /// [invitadosIds]: con null el servidor NO toca los invitados; con una lista, la
  /// convocatoria queda con exactamente esos (los que faltan se quitan, [] quita a
  /// todos). Una pantalla que gestiona los invitados la envía siempre.
  Future<ConvocatoriaModel> actualizar({
    required int convocatoriaId,
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    List<int>? jugadoresIds,
    List<int>? invitadosIds,
  }) async {
    final data = await ApiClient.put(
      '/app/convocatorias/$convocatoriaId',
      autenticado: true,
      body: {
        'partidoId': partidoId,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
        'jugadoresIds': ?jugadoresIds,
        'invitadosIds': ?invitadosIds,
      },
    );

    return ConvocatoriaModel.fromJson(data as Map<String, dynamic>);
  }

  /// Elimina la convocatoria y avisa a los convocados. Solo se puede si el
  /// partido no tiene resultado y su fecha es hoy o posterior (si no, el backend
  /// responde 400 con el motivo). Las justificaciones de ausencia no se borran.
  Future<void> eliminar(int convocatoriaId) async {
    await ApiClient.delete(
      '/app/convocatorias/$convocatoriaId',
      autenticado: true,
    );
  }
}
