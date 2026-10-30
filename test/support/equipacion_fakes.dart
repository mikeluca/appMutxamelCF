import 'package:app_mutxamel_cf/features/convocatorias/model/equipacion_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/equipacion_service.dart';

/// Sustituye al servicio real de equipajes en los tests del formulario de convocatoria que no
/// hablan de equipaje: sin esto la pantalla intentaría llamar a la red.
class FakeEquipacionesVacias extends EquipacionService {
  @override
  Future<List<EquipacionModel>> obtenerActivas() async => [];
}
