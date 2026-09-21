import '../../../core/network/api_client.dart';
import '../model/entrenamiento_model.dart';

class EntrenamientoService {
  Future<List<EntrenamientoModel>> obtenerPorEquipo(int equipoId) async {
    final data = await ApiClient.get(
      '/app/entrenamientos?equipoId=$equipoId',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map(
          (item) => EntrenamientoModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<EntrenamientoModel> crear({
    required int equipoId,
    required String fecha,
    required Map<int, String> asistencias,
  }) async {
    final data = await ApiClient.post(
      '/app/entrenamientos',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'fecha': fecha,
        'asistencias': asistencias.entries
            .map((entry) => {'jugadorId': entry.key, 'estado': entry.value})
            .toList(),
      },
    );

    return EntrenamientoModel.fromJson(data as Map<String, dynamic>);
  }

  Future<EntrenamientoModel> actualizar({
    required int entrenamientoId,
    required int equipoId,
    required String fecha,
    required Map<int, String> asistencias,
  }) async {
    final data = await ApiClient.put(
      '/app/entrenamientos/$entrenamientoId',
      autenticado: true,
      body: {
        'equipoId': equipoId,
        'fecha': fecha,
        'asistencias': asistencias.entries
            .map((entry) => {'jugadorId': entry.key, 'estado': entry.value})
            .toList(),
      },
    );

    return EntrenamientoModel.fromJson(data as Map<String, dynamic>);
  }
}
