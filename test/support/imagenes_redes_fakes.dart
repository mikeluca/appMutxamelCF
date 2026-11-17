import 'dart:typed_data';

import 'package:app_mutxamel_cf/features/coordinacion/models/imagenes_redes_model.dart';
import 'package:app_mutxamel_cf/features/coordinacion/services/imagenes_redes_service.dart';

/// Un servicio de imágenes para redes sin red: sin imágenes generadas. Los tests del panel Fin de semana lo usan para
/// que su sección "Imágenes para redes" no pida nada a la red (y el spinner no impida que la pantalla se asiente).
class FakeImagenesRedesService extends ImagenesRedesService {
  @override
  Future<ImagenesRedesModel> obtener({DateTime? fecha}) async {
    return const ImagenesRedesModel(
      desde: null,
      hasta: null,
      imagenes: [],
      textoPrevia: '',
      textoResultados: '',
    );
  }

  @override
  Future<Uint8List> descargarPng(ImagenRedesModel imagen) async => Uint8List(0);
}
