import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../models/imagenes_redes_model.dart';
import '../models/partido_primer_equipo_model.dart';

/// Imágenes para redes sociales (solo RRSS y ADMIN_APP).
class ImagenesRedesService {
  /// Los PNG ya descargados ("id:versión"): una versión nueva es otra clave.
  static final Map<String, Uint8List> _cache = {};

  /// Las imágenes del fin de semana de [fecha] (el servidor elige el
  /// viernes-domingo de referencia); sin fecha, el de hoy.
  Future<ImagenesRedesModel> obtener({DateTime? fecha}) async {
    final data = await ApiClient.get(
      '/app/imagenes-redes${_consulta(fecha)}',
      autenticado: true,
    );

    return ImagenesRedesModel.fromJson(data as Map<String, dynamic>);
  }

  /// El PNG de la imagen.
  Future<Uint8List> descargarPng(ImagenRedesModel imagen) async {
    final clave = '${imagen.id}:${imagen.version}';
    final guardado = _cache[clave];

    if (guardado != null) return guardado;

    final bytes = await ApiClient.getBytes(
      '/app/imagenes-redes/${imagen.id}/png',
      autenticado: true,
    );

    _cache[clave] = bytes;

    return bytes;
  }

  /// Genera ahora lo que haya en el sistema (partidos y resultados ya metidos),
  /// sin avisar a nadie.
  Future<ImagenesRedesModel> regenerar({
    required String tipo,
    DateTime? fecha,
  }) async {
    final consulta = fecha == null ? '' : '&fecha=${_fechaApi(fecha)}';

    final data = await ApiClient.post(
      '/app/imagenes-redes/regenerar?tipo=$tipo$consulta',
      autenticado: true,
    );

    return ImagenesRedesModel.fromJson(data as Map<String, dynamic>);
  }

  /// El próximo partido del equipo del cartel (o por qué no hay).
  Future<PartidoPrimerEquipoModel> obtenerPartido(CartelEquipo equipo) async {
    final data = await ApiClient.get(
      '/app/imagenes-redes/${equipo.ruta}',
      autenticado: true,
    );

    return PartidoPrimerEquipoModel.fromJson(data as Map<String, dynamic>);
  }

  /// El PNG del cartel del próximo partido de ese equipo con esas opciones. El servidor lo genera al momento y no se guarda ni
  /// aquí ni en ningún sitio: cada llamada pide uno nuevo.
  Future<Uint8List> generarCartel(
    CartelEquipo equipo,
    OpcionesCartel opciones,
  ) {
    return ApiClient.getBytes(
      '/app/imagenes-redes/${equipo.ruta}/png${opciones.consulta}',
      autenticado: true,
    );
  }

  static String _consulta(DateTime? fecha) =>
      fecha == null ? '' : '?fecha=${_fechaApi(fecha)}';

  static String _fechaApi(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '${fecha.year.toString().padLeft(4, '0')}-$mes-$dia';
  }
}
