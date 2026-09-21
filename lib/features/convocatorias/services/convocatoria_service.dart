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

  Future<ConvocatoriaModel> crear({
    required int equipoId,
    required String rival,
    required String campo,
    required String fechaPartido,
    required String horaPartido,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
  }) async {
    final data = await ApiClient.post(
      '/app/convocatorias',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'rival': rival,
        'campo': campo,
        'fechaPartido': fechaPartido,
        'horaPartido': horaPartido,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
        'jugadoresIds': jugadoresIds,
      },
    );

    return ConvocatoriaModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ConvocatoriaModel> actualizar({
    required int convocatoriaId,
    required int equipoId,
    required String rival,
    required String campo,
    required String fechaPartido,
    required String horaPartido,
    required String horaConvocatoria,
    required String lugarConvocatoria,
  }) async {
    final data = await ApiClient.put(
      '/app/convocatorias/$convocatoriaId',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'rival': rival,
        'campo': campo,
        'fechaPartido': fechaPartido,
        'horaPartido': horaPartido,
        'horaConvocatoria': horaConvocatoria,
        'lugarConvocatoria': lugarConvocatoria,
      },
    );

    return ConvocatoriaModel.fromJson(data as Map<String, dynamic>);
  }
}
