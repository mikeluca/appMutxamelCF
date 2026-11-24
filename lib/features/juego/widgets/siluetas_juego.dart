import 'package:material_ui/material_ui.dart';

import '../models/juego_modelos.dart';

/// Las siluetas que comparten los juegos (Cabezazos las apila en sus columnas).

/// Los colores de una equipación del club, los mismos que las imágenes de Mutxigol: camiseta, pantalón y medias del
/// mismo color (azul entero o rosa entero) y los vivos (franja diagonal y una línea fina entre camiseta y pantalón):
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

/// Un defensa rival: silueta sencilla de jugador con la equipación del club que NO ha elegido el jugador (si Mutxigol va
/// de azul, los defensas de rosa y al revés). Sin escudos ni patrocinadores: a este tamaño no se verían.
///
/// Las proporciones son las de [FormaDefensa] (la forma de choque): cabeza redonda arriba y cuerpo del 20 al 80 % del
/// ancho.
class DefensaPainter extends CustomPainter {
  const DefensaPainter({this.equipacion = Equipacion.rosa});

  /// La equipación del defensa (ya la contraria a la de Mutxigol).
  final Equipacion equipacion;

  @override
  void paint(Canvas canvas, Size size) {
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

    // Los brazos (piel) con la manga corta.
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
          Rect.fromLTWH(w * x, h * 0.28, w * 0.14, h * 0.10),
          const Radius.circular(3),
        ),
        base,
      );
    }

    // La camiseta con su franja diagonal.
    final camiseta = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.56, h * 0.30),
      Radius.circular(w * 0.06),
    );

    canvas.drawRRect(camiseta, base);

    canvas.save();
    canvas.clipRRect(camiseta);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, h * 0.32)
        ..lineTo(w * 0.40, h * 0.26)
        ..lineTo(w * 0.78, h * 0.50)
        ..lineTo(w * 0.78, h * 0.56)
        ..lineTo(w * 0.60, h * 0.56)
        ..close(),
      vivos,
    );
    canvas.restore();

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
    // El cuello, con el vivo de la camiseta.
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.255, w * 0.12, h * 0.014), vivos);
  }

  @override
  bool shouldRepaint(DefensaPainter oldDelegate) =>
      oldDelegate.equipacion != equipacion;
}
