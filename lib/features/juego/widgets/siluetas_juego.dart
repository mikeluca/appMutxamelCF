import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Las siluetas que comparten los juegos (Cabezazos las apila en sus columnas).

/// Un defensa rival: silueta sencilla de jugador con la camiseta roja y blanca (sin ningún escudo real).
class DefensaPainter extends CustomPainter {
  const DefensaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final piel = Paint()..color = const Color(0xFFD7A57C);

    // La sombra.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.12, h * 0.92, w * 0.76, h * 0.08),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Las piernas y las botas.
    for (final x in [0.30, 0.54]) {
      canvas.drawRect(Rect.fromLTWH(w * x, h * 0.62, w * 0.16, h * 0.26), piel);
      canvas.drawRect(
        Rect.fromLTWH(w * x, h * 0.74, w * 0.16, h * 0.14),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (x - 0.03), h * 0.87, w * 0.22, h * 0.07),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF212121),
      );
    }

    // Los brazos.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.30, w * 0.14, h * 0.28),
        const Radius.circular(4),
      ),
      piel,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.78, h * 0.30, w * 0.14, h * 0.28),
        const Radius.circular(4),
      ),
      piel,
    );

    // Pantalón negro.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.26, h * 0.54, w * 0.48, h * 0.14),
      Paint()..color = const Color(0xFF212121),
    );

    // La camiseta a rayas rojas y blancas.
    final camiseta = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.56, h * 0.32),
      Radius.circular(w * 0.06),
    );

    canvas.save();
    canvas.clipRRect(camiseta);

    const rayas = 5;

    for (var i = 0; i < rayas; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          w * 0.22 + i * (w * 0.56 / rayas),
          h * 0.26,
          w * 0.56 / rayas,
          h * 0.32,
        ),
        Paint()..color = i.isEven ? const Color(0xFFD32F2F) : Colors.white,
      );
    }

    canvas.restore();

    // La cabeza y el pelo.
    canvas.drawCircle(Offset(w * 0.5, h * 0.16), w * 0.15, piel);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.15), radius: w * 0.15),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF3E2723),
    );
  }

  @override
  bool shouldRepaint(DefensaPainter oldDelegate) => false;
}
