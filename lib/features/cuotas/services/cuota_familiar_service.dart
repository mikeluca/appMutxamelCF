import '../../../core/network/api_client.dart';
import '../models/cuota_familiar_model.dart';

class CuotaFamiliarService {
  CuotaFamiliarService._();

  static Future<List<CuotaFamiliarModel>> obtenerMisCuotas() async {
    final data = await ApiClient.get('/app/cuotas', autenticado: true)
        as List<dynamic>;

    return data
        .map(
          (item) => CuotaFamiliarModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
