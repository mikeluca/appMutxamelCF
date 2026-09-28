import '../../../core/network/api_client.dart';
import '../model/convocatoria_model.dart';

class ConvocatoriaService {
  Future<List<ConvocatoriaModel>> obtenerPorEquipo(int equipoId) async {
    final data = await ApiClient.get(
      '/app/convocatorias?equipoId=$equipoId',
      autenticado: true,
    ) as List<dynamic>;

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
  Future<ConvocatoriaModel> crear({
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
  }) async {
    final data = await ApiClient.post(
      '/app/convocatorias',
      autenticado: true,
      body: {
        'partidoId': partidoId,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
        'jugadoresIds': jugadoresIds,
      },
    );

    return ConvocatoriaModel.fromJson(data as Map<String, dynamic>);
  }

  /// Actualiza una convocatoria. Se permite re-apuntarla a otro partido
  /// (mismo equipo), igual que se permite cambiar hora/lugar.
  Future<ConvocatoriaModel> actualizar({
    required int convocatoriaId,
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
  }) async {
    final data = await ApiClient.put(
      '/app/convocatorias/$convocatoriaId',
      autenticado: true,
      body: {
        'partidoId': partidoId,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
      },
    );

    return ConvocatoriaModel.fromJson(data as Map<String, dynamic>);
  }
}
