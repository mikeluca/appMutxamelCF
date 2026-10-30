import '../../../core/network/api_client.dart';
import '../model/equipacion_model.dart';

/// Los equipajes del club para elegir en la convocatoria. El backend responde 403 si el
/// usuario no gestiona ningún equipo.
class EquipacionService {
  /// Los equipajes activos, ya ordenados por el servidor (orden y nombre).
  Future<List<EquipacionModel>> obtenerActivas() async {
    final data =
        await ApiClient.get('/app/equipaciones', autenticado: true)
            as List<dynamic>;

    return data
        .map((item) => EquipacionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
