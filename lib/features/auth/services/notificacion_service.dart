import '../../../core/network/api_client.dart';
import '../models/notificacion_model.dart';

class NotificacionService {
  static Future<List<NotificacionModel>> obtenerNotificaciones() async {
    final data = await ApiClient.get(
      '/app/notificaciones',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<NotificacionModel>> obtenerNoLeidas() async {
    final data = await ApiClient.get(
      '/app/notificaciones/no-leidas',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<int> contarNoLeidas() async {
    final data = await ApiClient.get(
      '/app/notificaciones/no-leidas/count',
      autenticado: true,
    ) as Map<String, dynamic>;

    return (data['cantidad'] as num?)?.toInt() ?? 0;
  }

  static Future<void> marcarComoLeida(int id) async {
    await ApiClient.put('/app/notificaciones/$id/leida', autenticado: true);
  }

  static Future<void> marcarTodasComoLeidas() async {
    await ApiClient.put('/app/notificaciones/leidas', autenticado: true);
  }
}
