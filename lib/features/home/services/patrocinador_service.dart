import '../../../core/network/api_client.dart';
import '../models/patrocinador.dart';

class PatrocinadorService {
  /// Los patrocinadores del club, en el orden en que se muestran. Público: sin sesión.
  Future<List<Patrocinador>> obtenerPatrocinadores() async {
    final decoded = await ApiClient.get('/public/patrocinadores');

    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Patrocinador.fromJson)
        .where((p) => p.nombre.isNotEmpty && p.imagenUrl.isNotEmpty)
        .toList();
  }
}
