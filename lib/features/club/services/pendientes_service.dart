import '../../../core/network/api_client.dart';
import '../models/pendientes.dart';

/// "Pendientes" del Área Club. Nada se guarda en el móvil.
class PendientesService {
  const PendientesService();

  Future<List<GrupoPendiente>> obtener() async {
    final data =
        await ApiClient.get('/app/pendientes', autenticado: true)
            as Map<String, dynamic>;

    return (data['grupos'] as List<dynamic>? ?? const [])
        .map((g) => GrupoPendiente.fromJson(g as Map<String, dynamic>))
        .where((g) => g.cantidad > 0)
        .toList();
  }
}
