import '../../../core/network/api_client.dart';
import '../models/comunicacion_model.dart';
import '../models/notificacion_model.dart';
import '../models/destinatario_comunicacion_model.dart';
import '../models/mensaje_conversacion_model.dart';

class ComunicacionService {
  ComunicacionService._();

  static Future<List<ComunicacionModel>> obtenerComunicaciones() async {
    final data = await ApiClient.get(
      '/app/comunicaciones',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map((json) => ComunicacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ComunicacionModel>> obtenerConversacionesPrivadas() async {
    final data = await ApiClient.get(
      '/app/comunicaciones/conversaciones',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map((json) => ComunicacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ComunicacionModel>> obtenerComunicacionesEnviadas() async {
    final data = await ApiClient.get(
      '/app/comunicaciones/enviadas',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map((json) => ComunicacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<ComunicacionModel> obtenerComunicacionPorId(int id) async {
    try {
      final data = await ApiClient.get(
        '/app/comunicaciones/$id',
        autenticado: true,
      );

      return ComunicacionModel.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('La comunicación no existe.');
      }

      rethrow;
    }
  }

  static Future<void> crearComunicacion({
    String? titulo,
    required String contenido,
    required List<int> equipoIds,
    required List<String> categorias,
    required List<int> destinatariosIds,
  }) async {
    try {
      await ApiClient.post(
        '/app/comunicaciones',
        autenticado: true,
        body: {
          'titulo': titulo?.trim(),
          'contenido': contenido.trim(),
          'equipoIds': equipoIds,
          'categorias': categorias,
          'destinatariosIds': destinatariosIds,
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw Exception('No tienes permiso para crear esta comunicación.');
      }

      if (e.statusCode == 400) {
        throw Exception(e.message);
      }

      rethrow;
    }
  }

  static Future<List<DestinatarioComunicacionModel>>
  obtenerDestinatariosDirectos() async {
    final data = await ApiClient.get(
      '/app/comunicaciones/destinatarios',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map(
          (json) => DestinatarioComunicacionModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<int> contarComunicacionesNoLeidas() async {
    final data = await ApiClient.get(
      '/app/notificaciones/comunicaciones/no-leidas/count',
      autenticado: true,
    );

    return data is int ? data : int.parse(data.toString());
  }

  static Future<List<NotificacionModel>> obtenerNotificaciones() async {
    final data = await ApiClient.get(
      '/app/notificaciones',
      autenticado: true,
    ) as List<dynamic>;

    return data
        .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> marcarNotificacionComoLeida(int notificacionId) async {
    await ApiClient.put(
      '/app/notificaciones/$notificacionId/leida',
      autenticado: true,
    );
  }

  static Future<List<MensajeConversacionModel>> obtenerConversacion(
    int otroUsuarioId,
  ) async {
    final data =
        await ApiClient.get(
              '/app/comunicaciones/conversacion/$otroUsuarioId',
              autenticado: true,
            )
            as List<dynamic>;

    return data
        .map(
          (json) =>
              MensajeConversacionModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> marcarConversacionLeida(int otroUsuarioId) async {
    await ApiClient.put(
      '/app/comunicaciones/conversacion/$otroUsuarioId/leida',
      autenticado: true,
    );
  }
}
