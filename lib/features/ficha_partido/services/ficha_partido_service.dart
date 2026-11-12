import '../../../core/network/api_client.dart';
import '../models/ficha_partido_model.dart';

/// Ficha pública del partido del Primer Equipo (sin sesión).
class FichaPartidoService {
  /// [idioma] (es, ca, en) va en Accept-Language: el backend redacta con él la competición. Un 404 (partido de
  /// otro equipo o inexistente) llega como [ApiException] con statusCode 404.
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) async {
    final data = await ApiClient.get(
      '/public/partidos/$partidoId/ficha',
      headers: idioma == null ? null : {'Accept-Language': idioma},
    );

    return FichaPartido.fromJson(data as Map<String, dynamic>);
  }
}
