import '../../../core/network/api_client.dart';
import '../models/ffcv_model.dart';

/// Subir los datos de la FFCV desde la app (solo ADMIN_APP): los mismos servicios que el panel web, en
/// /api/app/admin/ffcv/**. Los errores del servidor ({"error": "..."}) llegan como [ApiException] con su texto.
class FfcvService {
  /// Sube el LstPartidos.csv y devuelve la vista previa (no escribe nada).
  Future<PrevisualizacionPartidosModel> previsualizarPartidos({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final data = await ApiClient.postArchivo(
      '/app/admin/ffcv/partidos/previsualizar',
      campo: 'archivo',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      autenticado: true,
    );

    return PrevisualizacionPartidosModel.fromJson(data as Map<String, dynamic>);
  }

  /// Confirma la vista previa de partidos. [asignaciones]: el equipo elegido para cada competición+letra de las
  /// filas SIN_EQUIPO (competición, letra y equipoId).
  Future<ResultadoPartidosModel> confirmarPartidos(
    PrevisualizacionPartidosModel previa, {
    List<({String competicion, String? letra, int equipoId})> asignaciones =
        const [],
  }) async {
    final data = await ApiClient.post(
      '/app/admin/ffcv/partidos/confirmar',
      autenticado: true,
      body: {
        'previsualizacion': previa.json,
        'asignaciones': [
          for (final a in asignaciones)
            {
              'competicion': a.competicion,
              'letra': a.letra,
              'equipoId': a.equipoId,
            },
        ],
      },
    );

    return ResultadoPartidosModel.fromJson(data as Map<String, dynamic>);
  }

  /// Sube el ListadoClasificaciones.xlsx y devuelve la vista previa; el servidor la guarda (30 minutos) para
  /// confirmarla.
  Future<PrevisualizacionClasificacionesModel> previsualizarClasificaciones({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final data = await ApiClient.postArchivo(
      '/app/admin/ffcv/clasificaciones/previsualizar',
      campo: 'archivo',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      autenticado: true,
    );

    return PrevisualizacionClasificacionesModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  /// Confirma la vista previa guardada para los equipos marcados.
  Future<ResultadoClasificacionesModel> confirmarClasificaciones(
    List<int> equipoIds,
  ) async {
    final data = await ApiClient.post(
      '/app/admin/ffcv/clasificaciones/confirmar',
      autenticado: true,
      body: {'equipoIds': equipoIds},
    );

    return ResultadoClasificacionesModel.fromJson(data as Map<String, dynamic>);
  }
}
