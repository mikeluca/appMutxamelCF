import '../../../core/network/api_client.dart';
import '../models/proximo_partido.dart';

/// "Tu próximo partido" de Inicio (solo con sesión). Nada se guarda en el móvil.
class ProximosPartidosService {
  const ProximosPartidosService();

  Future<List<ProximoPartido>> obtener() async {
    final data =
        await ApiClient.get('/app/inicio/proximos-partidos', autenticado: true)
            as Map<String, dynamic>;

    return (data['entradas'] as List<dynamic>? ?? const [])
        .map((e) => ProximoPartido.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
