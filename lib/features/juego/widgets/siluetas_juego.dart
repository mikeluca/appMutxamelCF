import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/juego_modelos.dart';

/// Las siluetas que comparten los juegos (Cabezazos las apila en sus columnas).

/// Los colores de una equipación del club, los mismos que las imágenes de Mutxigol: mangas, pantalón y medias del mismo
/// color (azul entero o rosa entero) y los vivos (el ribete de las mangas y una línea fina entre camiseta y pantalón):
/// blancos en la azul, grises en la rosa.
class KitDefensa {
  const KitDefensa(this.base, this.vivos);

  final Color base;
  final Color vivos;

  static const KitDefensa azul = KitDefensa(Color(0xFF1E5BC6), Color(0xFFFFFFFF));
  static const KitDefensa rosa = KitDefensa(Color(0xFFE0359A), Color(0xFFBDBDBD));

  static KitDefensa de(Equipacion equipacion) =>
      equipacion == Equipacion.azul ? azul : rosa;
}

/// Las camisetas de los defensas (con el escudo del club y el patrocinador), decodificadas una sola vez: se cargan al
/// entrar en Cabezazos y el painter las usa sin decodificar nada en cada fotograma.
class CamisetasDefensa {
  CamisetasDefensa._();

  static final Map<Equipacion, ui.Image> _cargadas = {};
  static final Map<Equipacion, Future<ui.Image?>> _cargando = {};

  /// La camiseta de esa equipación si ya está cargada.
  static ui.Image? de(Equipacion equipacion) => _cargadas[equipacion];

  /// Carga (una vez) la camiseta de [equipacion]; null si no se ha podido.
  static Future<ui.Image?> cargar(Equipacion equipacion) {
    final hecha = _cargadas[equipacion];

    if (hecha != null) return Future.value(hecha);

    return _cargando[equipacion] ??= _decodificar(equipacion);
  }

  static Future<ui.Image?> _decodificar(Equipacion equipacion) async {
    try {
      final datos = await rootBundle.load(ImagenesMutxigol.camisetaDefensa(equipacion));
      final codec = await ui.instantiateImageCodec(datos.buffer.asUint8List());
      final imagen = (await codec.getNextFrame()).image;

      _cargadas[equipacion] = imagen;

      return imagen;
    } catch (_) {
      _cargando.remove(equipacion);

      return null;
    }
  }

  /// Solo para tests: pone o quita una camiseta a mano.
  @visibleForTesting
  static void ponerParaTests(Equipacion equipacion, ui.Image? imagen) {
    if (imagen == null) {
      _cargadas.remove(equipacion);
      _cargando.remove(equipacion);
    } else {
      _cargadas[equipacion] = imagen;
    }
  }
}

/// Defensas ya dibujados a su tamaño en píxeles reales, por equipación y alto: en pantalla hay muchos a la vez, así que
/// cada uno se pinta con un solo drawImageRect en vez de todos sus trazos. Se generan bajo demanda (mientras no están, el
/// defensa se dibuja directamente) y no se vuelven a generar.
class CacheDefensas {
  CacheDefensas._();

  /// Píxeles por unidad de juego de las imágenes cacheadas (de sobra para un móvil de 3× con el juego a escala ~1).
  static const double pixelesPorUnidad = 3;

  static final Map<(Equipacion, int), ui.Image> _hechas = {};
  static final Set<(Equipacion, int)> _enCurso = {};

  /// Los altos se agrupan de 2 en 2 (la diferencia, de una unidad, no se nota) para no generar una imagen por altura.
  static int cubeta(double alto) => ((alto / 2).round() * 2).clamp(2, 400);

  /// El defensa ya dibujado para ese alto, o null (y se pone a generar) si todavía no está.
  static ui.Image? obtener(Equipacion equipacion, double alto, ui.Image? camiseta) {
    if (camiseta == null) return null;

    final clave = (equipacion, cubeta(alto));
    final hecha = _hechas[clave];

    if (hecha != null) return hecha;

    if (_enCurso.add(clave)) _generar(clave, camiseta);

    return null;
  }

  static Future<void> _generar((Equipacion, int) clave, ui.Image camiseta) async {
    try {
      final alto = clave.$2.toDouble();
      final grabador = ui.PictureRecorder();
      final canvas = Canvas(grabador)..scale(pixelesPorUnidad);

      DefensaPainter(equipacion: clave.$1, camiseta: camiseta).pintarDirecto(
        canvas,
        Size(DefensaPainter.anchoBase, alto),
      );

      _hechas[clave] = await grabador.endRecording().toImage(
        (DefensaPainter.anchoBase * pixelesPorUnidad).ceil(),
        (alto * pixelesPorUnidad).ceil(),
      );
    } catch (_) {
      // Sin caché se dibuja directamente.
    } finally {
      _enCurso.remove(clave);
    }
  }

  @visibleForTesting
  static int get generadas => _hechas.length;

  @visibleForTesting
  static void vaciar() {
    _hechas.clear();
    _enCurso.clear();
  }
}

/// Un defensa rival: silueta sencilla de jugador con la equipación real del club que NO ha elegido el jugador (si Mutxigol
/// va de azul, los defensas de rosa y al revés). La camiseta es la imagen de la equipación, con el escudo del club y el
/// patrocinador, dentro del mismo recuadro de la camiseta; mangas, pantalón y medias son del color base del kit (con un
/// ribete de los vivos en las mangas). Si la imagen aún no está cargada, camiseta lisa del color base.
///
/// Las proporciones son las de [FormaDefensa] (la forma de choque): cabeza redonda arriba y cuerpo del 20 al 80 % del
/// ancho.
class DefensaPainter extends CustomPainter {
  const DefensaPainter({
    this.equipacion = Equipacion.rosa,
    this.camiseta,
    this.cacheada,
  });

  /// El ancho con el que se dibujan las defensas (el de la columna).
  static const double anchoBase = 62;

  /// La equipación del defensa (ya la contraria a la de Mutxigol).
  final Equipacion equipacion;

  /// La imagen de la camiseta (840 × 480) de esa equipación; null mientras no está cargada.
  final ui.Image? camiseta;

  /// El defensa entero ya dibujado a este alto (de [CacheDefensas]); si está, se pinta con un solo drawImageRect.
  final ui.Image? cacheada;

  @override
  void paint(Canvas canvas, Size size) {
    final hecha = cacheada;

    if (hecha != null) {
      canvas.drawImageRect(
        hecha,
        Rect.fromLTWH(0, 0, hecha.width.toDouble(), hecha.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );

      return;
    }

    pintarDirecto(canvas, size);
  }

  /// Dibuja el defensa trazo a trazo (sin la caché).
  void pintarDirecto(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final kit = KitDefensa.de(equipacion);
    final piel = Paint()..color = const Color(0xFFD7A57C);
    final base = Paint()..color = kit.base;
    final vivos = Paint()..color = kit.vivos;

    // La sombra.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.12, h * 0.92, w * 0.76, h * 0.08),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Pantalón y medias: del mismo color que la camiseta.
    canvas.drawRect(Rect.fromLTWH(w * 0.26, h * 0.54, w * 0.48, h * 0.14), base);

    for (final x in [0.30, 0.54]) {
      canvas.drawRect(Rect.fromLTWH(w * x, h * 0.66, w * 0.16, h * 0.22), base);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (x - 0.03), h * 0.87, w * 0.22, h * 0.07),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF212121),
      );
    }

    // Los brazos (piel) con la manga corta del color base y un ribete fino de los vivos.
    for (final x in [0.08, 0.78]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * 0.30, w * 0.14, h * 0.28),
          const Radius.circular(4),
        ),
        piel,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * 0.28, w * 0.14, h * 0.12),
          const Radius.circular(3),
        ),
        base,
      );
      canvas.drawRect(Rect.fromLTWH(w * x, h * 0.38, w * 0.14, h * 0.025), vivos);
    }

    // La camiseta: la imagen de la equipación dentro de su recuadro (o lisa si aún no está).
    final recuadro = Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.56, h * 0.30);
    final camisetaRRect = RRect.fromRectAndRadius(recuadro, Radius.circular(w * 0.06));
    final imagen = camiseta;

    if (imagen == null) {
      canvas.drawRRect(camisetaRRect, base);
    } else {
      canvas.save();
      canvas.clipRRect(camisetaRRect);
      canvas.drawImageRect(
        imagen,
        Rect.fromLTWH(0, 0, imagen.width.toDouble(), imagen.height.toDouble()),
        recuadro,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }

    // La línea fina que separa la camiseta del pantalón.
    canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.540, w * 0.56, h * 0.020), vivos);

    // La cabeza y el pelo.
    canvas.drawCircle(Offset(w * 0.5, h * 0.16), w * 0.15, piel);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.15), radius: w * 0.15),
      3.14159,
      3.14159,
      true,
      Paint()..color = const Color(0xFF3E2723),
    );
  }

  @override
  bool shouldRepaint(DefensaPainter oldDelegate) =>
      oldDelegate.equipacion != equipacion ||
      oldDelegate.camiseta != camiseta ||
      oldDelegate.cacheada != cacheada;
}
