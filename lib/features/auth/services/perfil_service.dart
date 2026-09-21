import '../../../core/network/api_client.dart';
import '../models/perfil_app.dart';

class PerfilService {
  PerfilService._();

  static Future<PerfilApp> obtenerPerfil() async {
    try {
      final data = await ApiClient.get('/app/perfil', autenticado: true);

      return PerfilApp.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('No se ha encontrado el perfil del usuario.');
      }

      rethrow;
    }
  }
}
