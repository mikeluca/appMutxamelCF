import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/origen_compartir.dart';
import '../../../core/widget/escudo_rival.dart';
import 'datos_compartir.dart';
import 'tarjeta_compartir.dart';

export 'datos_compartir.dart';
export 'tarjeta_compartir.dart';

/// Envía la imagen y el texto al menú de compartir del sistema. Los tests lo sustituyen.
typedef EnviarACompartir =
    Future<void> Function(Uint8List png, String texto, Rect origen);

/// Genera la imagen del partido con un widget fuera de pantalla (RepaintBoundary → PNG) y la comparte. No guarda en la
/// galería ni pide permisos: el menú de compartir del sistema ya permite guardarla.
class CompartirPartido {
  CompartirPartido._();

  @visibleForTesting
  static EnviarACompartir enviar = (png, texto, origen) async {
    await SharePlus.instance.share(
      ShareParams(
        text: texto,
        sharePositionOrigin: origen,
        files: [
          XFile.fromData(png, mimeType: 'image/png', name: 'partido.png'),
        ],
        fileNameOverrides: const ['partido.png'],
      ),
    );
  };

  /// Genera la imagen del partido y abre el menú de compartir, con el texto que la acompaña. Lanza si no se puede
  /// (el llamador avisa al usuario).
  static Future<void> compartir(
    BuildContext context,
    DatosCompartir datos, {
    OpcionesCompartir opciones = const OpcionesCompartir(),

    /// Desde dónde se abre el menú (iPad lo necesita): el rectángulo del botón. Sin él, el de [context].
    Rect? origen,
  }) async {
    // Se mide antes de generar la imagen: después ya podría no estar la pantalla.
    final ancla = origen ?? origenDeCompartir(context);
    final png = await generarPng(context, datos, opciones: opciones);

    await enviar(
      png,
      datos.textoCompartir(conGoleadores: opciones.goleadores),
      ancla,
    );
  }

  /// Cuánto se espera al escudo del rival antes de usar el genérico.
  static const Duration esperaMaxima = Duration(seconds: 3);

  /// Descarga (o lee de la caché) el escudo del rival; false si falla o tarda más de [espera]. Los tests lo sustituyen.
  @visibleForTesting
  static Future<bool> Function(BuildContext, String, Duration) precargarEscudo =
      (contexto, url, espera) async {
        var fallo = false;

        try {
          await precacheImage(
            CachedNetworkImageProvider(url),
            contexto,
            onError: (_, _) => fallo = true,
          ).timeout(espera);
        } catch (_) {
          return false;
        }

        return !fallo;
      };

  /// La tarjeta de [datos] como PNG de 1080 px de ancho (1350 o 1920 de alto según [opciones]). Se pinta en una capa
  /// fuera de la pantalla (a la izquierda del borde) con el tamaño de letra del sistema ignorado, para que siempre
  /// salga igual.
  static Future<Uint8List> generarPng(
    BuildContext context,
    DatosCompartir datos, {
    OpcionesCompartir opciones = const OpcionesCompartir(),
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final clave = GlobalKey();

    // Con el escudo ya en la caché de imágenes entra en el primer fotograma.
    await precacheImage(const AssetImage('assets/images/escudo.png'), context);

    // El escudo del rival se espera (hasta 3 s); si falla o tarda más, la imagen sale con el genérico.
    final urlRival = EscudoRival.urlCompleta(datos.escudoRivalUrl);

    if (urlRival != null && !datos.rivalEsPropio) {
      if (!context.mounted) throw StateError('La pantalla ya no está');

      final cargado = await precargarEscudo(context, urlRival, esperaMaxima);

      if (!cargado) datos = datos.conEscudoRival(null);
    }

    final entrada = OverlayEntry(
      builder: (contextoCapa) => Positioned(
        left: -TarjetaCompartir.ancho * 2,
        top: 0,
        width: TarjetaCompartir.ancho,
        height: opciones.formato.alto,
        child: MediaQuery(
          data: MediaQuery.of(
            contextoCapa,
          ).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
          child: RepaintBoundary(
            key: clave,
            child: TarjetaCompartir(datos: datos, opciones: opciones),
          ),
        ),
      ),
    );

    overlay.insert(entrada);

    try {
      await WidgetsBinding.instance.endOfFrame;

      final limite =
          clave.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (limite == null) {
        throw StateError('No se pudo pintar la imagen del partido');
      }

      final imagen = await limite.toImage(pixelRatio: 1);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);

      imagen.dispose();

      if (bytes == null) {
        throw StateError('No se pudo codificar la imagen del partido');
      }

      return bytes.buffer.asUint8List();
    } finally {
      entrada.remove();
      entrada.dispose();
    }
  }
}
