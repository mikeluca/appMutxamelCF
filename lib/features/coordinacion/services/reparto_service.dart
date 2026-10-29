import '../../../core/network/api_client.dart';
import '../models/reparto_model.dart';

/// Reparto de septiembre y altas de prueba (solo COORDINADOR y ADMIN_APP).
/// Errores del servidor: 400 con el motivo, 403 sin rol y 409 si no hay
/// temporada activa o siguiente.
class RepartoService {
  /// Categorías formativas con equipos en la temporada activa, en orden de edad.
  Future<List<String>> obtenerCategorias() async {
    final data = await ApiClient.get(
      '/app/reparto/categorias',
      autenticado: true,
    );

    return (data as List<dynamic>? ?? []).map((e) => e.toString()).toList();
  }

  Future<RepartoCategoriaModel> obtenerReparto(String categoria) async {
    final data = await ApiClient.get(
      '/app/reparto?categoria=${Uri.encodeQueryComponent(categoria)}',
      autenticado: true,
    );

    return RepartoCategoriaModel.fromJson(data as Map<String, dynamic>);
  }

  /// Asigna [jugadores] al equipo definitivo [equipoId]. Con jugadores de prueba
  /// y [confirmarPruebas] a false el servidor no asigna nada y responde 409
  /// PRUEBAS_SIN_CONFIRMAR: se lanza [PruebasSinConfirmarException] para que la
  /// pantalla pregunte y repita con true.
  Future<ResultadoRepartoModel> asignar({
    required int equipoId,
    required List<AsignacionJugador> jugadores,
    bool confirmarPruebas = false,
  }) async {
    try {
      final data = await ApiClient.post(
        '/app/reparto/asignar',
        autenticado: true,
        body: {
          'equipoId': equipoId,
          'jugadores': jugadores.map((j) => j.toJson()).toList(),
          'confirmarPruebas': confirmarPruebas,
        },
      );

      return ResultadoRepartoModel.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      final datos = e.datos;

      if (e.statusCode == 409 &&
          datos is Map &&
          datos['codigo'] == 'PRUEBAS_SIN_CONFIRMAR') {
        throw PruebasSinConfirmarException(
          (datos['pruebas'] as List<dynamic>? ?? [])
              .map((p) => p.toString())
              .toList(),
        );
      }

      rethrow;
    }
  }

  /// Devuelve a la pretemporada de su categoría a jugadores asignados por error.
  Future<ResultadoDevolucionModel> devolver(List<int> jugadorIds) async {
    final data = await ApiClient.post(
      '/app/reparto/devolver',
      autenticado: true,
      body: {'jugadorIds': jugadorIds},
    );

    return ResultadoDevolucionModel.fromJson(data as Map<String, dynamic>);
  }

  /// Crea el siguiente equipo de la categoría (inactivo hasta su primer jugador).
  Future<EquipoRepartoModel> crearEquipo(String categoria) async {
    final data = await ApiClient.post(
      '/app/reparto/equipos?categoria=${Uri.encodeQueryComponent(categoria)}',
      autenticado: true,
    );

    return EquipoRepartoModel.fromJson(data as Map<String, dynamic>);
  }

  /// Alta de un jugador de prueba en la temporada siguiente.
  Future<PruebaCreadaModel> altaPrueba({
    required String nombre,
    required String apellidos,
    required int anioNacimiento,
  }) async {
    final data = await ApiClient.post(
      '/app/pruebas',
      autenticado: true,
      body: {
        'nombre': nombre,
        'apellidos': apellidos,
        'anioNacimiento': anioNacimiento,
      },
    );

    return PruebaCreadaModel.fromJson(data as Map<String, dynamic>);
  }
}
