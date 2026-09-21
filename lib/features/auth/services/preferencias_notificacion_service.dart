import '../../../core/network/api_client.dart';
import '../models/preferencias_notificacion_model.dart';

class PreferenciasNotificacionService {
  static Future<PreferenciasNotificacionModel> obtenerPreferencias() async {
    final data = await ApiClient.get(
      '/app/preferencias-notificacion',
      autenticado: true,
    );

    return PreferenciasNotificacionModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  static Future<PreferenciasNotificacionModel> actualizarPreferencias(
    PreferenciasNotificacionModel preferencias,
  ) async {
    final data = await ApiClient.put(
      '/app/preferencias-notificacion',
      autenticado: true,
      body: preferencias.toJson(),
    );

    return PreferenciasNotificacionModel.fromJson(
      data as Map<String, dynamic>,
    );
  }
}
