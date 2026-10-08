import '../../../core/network/api_client.dart';
import '../model/entrenamiento_model.dart';

class EntrenamientoService {
  /// Entrenamientos del equipo. [desde] y [hasta] (ambos incluidos y
  /// opcionales) acotan el rango de fechas; sin ellos devuelve todos.
  Future<List<EntrenamientoModel>> obtenerPorEquipo(
    int equipoId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final params = <String>['equipoId=$equipoId'];

    if (desde != null) params.add('desde=${_fechaApi(desde)}');
    if (hasta != null) params.add('hasta=${_fechaApi(hasta)}');

    final data =
        await ApiClient.get(
              '/app/entrenamientos?${params.join('&')}',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map(
          (item) => EntrenamientoModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static String _fechaApi(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '${fecha.year.toString().padLeft(4, '0')}-$mes-$dia';
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
