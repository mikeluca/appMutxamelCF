import 'package:material_ui/material_ui.dart';

/// El rectángulo (en coordenadas globales) desde el que se abre el menú de compartir. En iPad, share_plus lo necesita
/// para anclar el menú: sin él falla. Es el del botón que lo lanza ([contexto] es el de ese botón); si no se puede
/// medir, un punto en el centro de la pantalla.
Rect origenDeCompartir(BuildContext? contexto) {
  final caja = contexto?.findRenderObject();

  if (contexto != null &&
      contexto.mounted &&
      caja is RenderBox &&
      caja.attached &&
      caja.hasSize &&
      !caja.size.isEmpty) {
    return caja.localToGlobal(Offset.zero) & caja.size;
  }

  final tamano = contexto != null && contexto.mounted
      ? MediaQuery.maybeSizeOf(contexto)
      : null;
  final centro = tamano == null
      ? const Offset(1, 1)
      : Offset(tamano.width / 2, tamano.height / 2);

  return Rect.fromCenter(center: centro, width: 1, height: 1);
}
