import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../logica/atrapa_logica.dart';
import '../models/juego_modelos.dart';

/// Los dibujos del juego: todo con CustomPainter (nada de imágenes) salvo el balón normal y el escudo del club, que son
/// los assets de siempre. Cada uno se dibuja dentro de un cuadrado y se escala a su tamaño.

/// Un objeto de Atrapa balones del tamaño [tamano] (la escena y la leyenda lo usan igual).
class ObjetoDibujado extends StatelessWidget {
  const ObjetoDibujado({super.key, required this.tipo, this.tamano = 40});

  final TipoCaida tipo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final hijo = switch (tipo) {
      TipoCaida.balon => Image.asset(
        ImagenesMutxigol.balon,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
      TipoCaida.balonEfecto => CustomPaint(
        painter: const _BalonConEfecto(),
        child: Padding(
          padding: EdgeInsets.all(tamano * 0.12),
          child: Image.asset(
            ImagenesMutxigol.balon,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
      TipoCaida.escudo => Image.asset(
        ImagenesMutxigol.escudoClub,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
      TipoCaida.balonPinchado => const CustomPaint(painter: _BalonPinchado()),
      TipoCaida.balonDorado => const CustomPaint(painter: _BalonDorado()),
      TipoCaida.tarjetaRoja => const CustomPaint(
        painter: _Tarjeta(Color(0xFFD32F2F)),
      ),
      TipoCaida.tarjetaAmarilla => const CustomPaint(
        painter: _Tarjeta(Color(0xFFFFEB3B)),
      ),
      TipoCaida.bota => const CustomPaint(painter: _Bota()),
      TipoCaida.silbato => const CustomPaint(painter: _Silbato()),
    };

    return SizedBox(
      key: ValueKey('objeto-${tipo.name}'),
      width: tamano,
      height: tamano,
      child: hijo,
    );
  }
}

/// Los pentágonos de un balón de fútbol sobre un círculo de [radio] en [c].
void _pentagonos(Canvas canvas, Offset c, double radio, Color color) {
  final p = Paint()..color = color;

  Path pentagono(Offset centro, double r, double giro) {
    final path = Path();

    for (var i = 0; i < 5; i++) {
      final a = giro + i * 2 * math.pi / 5 - math.pi / 2;
      final punto = centro + Offset(math.cos(a), math.sin(a)) * r;

      i == 0 ? path.moveTo(punto.dx, punto.dy) : path.lineTo(punto.dx, punto.dy);
    }

    return path..close();
  }

  canvas.drawPath(pentagono(c, radio * 0.34, 0), p);

  for (var i = 0; i < 5; i++) {
    final a = i * 2 * math.pi / 5 - math.pi / 2;

    canvas.drawPath(
      pentagono(c + Offset(math.cos(a), math.sin(a)) * radio * 0.86, radio * 0.22, a),
      p,
    );
  }
}

/// Una estela curva detrás del balón con efecto.
class _BalonConEfecto extends CustomPainter {
  const _BalonConEfecto();

  @override
  void paint(Canvas canvas, Size size) {
    final estela = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.05)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.02,
        size.width * 0.9,
        size.height * 0.3,
      );

    canvas.drawPath(path, estela);
    canvas.drawPath(
      path.shift(Offset(-size.width * 0.06, size.height * 0.08)),
      estela..strokeWidth = size.width * 0.04,
    );
  }

  @override
  bool shouldRepaint(_BalonConEfecto oldDelegate) => false;
}

/// El balón pinchado: aplastado y gris.
class _BalonPinchado extends CustomPainter {
  const _BalonPinchado();

  @override
  void paint(Canvas canvas, Size size) {
    final cuerpo = Rect.fromLTWH(
      size.width * 0.04,
      size.height * 0.40,
      size.width * 0.92,
      size.height * 0.52,
    );

    canvas.drawOval(
      cuerpo.shift(Offset(0, size.height * 0.04)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawOval(cuerpo, Paint()..color = const Color(0xFF9E9E9E));
    canvas.drawOval(
      cuerpo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04
        ..color = const Color(0xFF616161),
    );

    // Los parches, aplastados.
    final parche = Paint()..color = const Color(0xFF616161);

    canvas.drawOval(
      Rect.fromCenter(
        center: cuerpo.center,
        width: size.width * 0.28,
        height: size.height * 0.16,
      ),
      parche,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: cuerpo.center + Offset(-size.width * 0.28, 0),
        width: size.width * 0.14,
        height: size.height * 0.1,
      ),
      parche,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: cuerpo.center + Offset(size.width * 0.28, 0),
        width: size.width * 0.14,
        height: size.height * 0.1,
      ),
      parche,
    );

    // El aire que se escapa.
    final aire = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.04;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.30),
      Offset(size.width * 0.5, size.height * 0.10),
      aire,
    );
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.32),
      Offset(size.width * 0.28, size.height * 0.16),
      aire,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.32),
      Offset(size.width * 0.72, size.height * 0.16),
      aire,
    );
  }

  @override
  bool shouldRepaint(_BalonPinchado oldDelegate) => false;
}

/// El balón dorado.
class _BalonDorado extends CustomPainter {
  const _BalonDorado();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFFF59D), Color(0xFFFFC107), Color(0xFFB8860B)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    _pentagonos(canvas, c, r, const Color(0xFF8D6E00));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8D6E00),
    );

    // El brillo.
    final brillo = Paint()..color = Colors.white.withValues(alpha: 0.85);

    canvas.drawCircle(c + Offset(-r * 0.45, -r * 0.5), r * 0.1, brillo);
  }

  @override
  bool shouldRepaint(_BalonDorado oldDelegate) => false;
}

/// Una tarjeta (roja o amarilla), algo inclinada.
class _Tarjeta extends CustomPainter {
  const _Tarjeta(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.25);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * 0.62,
      height: size.height * 0.88,
    );
    final borde = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.1));

    canvas.drawRRect(
      borde.shift(Offset(size.width * 0.03, size.height * 0.04)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    canvas.drawRRect(borde, Paint()..color = color);
    canvas.drawRRect(
      borde,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06
        ..color = Colors.white,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_Tarjeta oldDelegate) => oldDelegate.color != color;
}

/// Una bota de tacos, de perfil.
class _Bota extends CustomPainter {
  const _Bota();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bota = Path()
      ..moveTo(w * 0.22, h * 0.10)
      ..lineTo(w * 0.52, h * 0.10)
      ..lineTo(w * 0.54, h * 0.50)
      ..cubicTo(w * 0.66, h * 0.52, w * 0.80, h * 0.50, w * 0.94, h * 0.68)
      ..lineTo(w * 0.94, h * 0.78)
      ..lineTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.10, h * 0.50)
      ..close();

    canvas.drawPath(bota, Paint()..color = const Color(0xFF263238));
    canvas.drawPath(
      bota,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );

    // La suela y los cordones.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, h * 0.74, w * 0.86, h * 0.08),
      Paint()..color = const Color(0xFFFF6F00),
    );

    final cordon = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;

    for (var i = 0; i < 3; i++) {
      final y = h * (0.22 + i * 0.1);

      canvas.drawLine(Offset(w * 0.28, y), Offset(w * 0.48, y), cordon);
    }

    // Los tacos.
    final taco = Paint()..color = const Color(0xFFCFD8DC);

    for (final x in [0.16, 0.38, 0.62, 0.84]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (x - 0.04), h * 0.82, w * 0.08, h * 0.12),
          const Radius.circular(2),
        ),
        taco,
      );
    }
  }

  @override
  bool shouldRepaint(_Bota oldDelegate) => false;
}

/// El silbato del árbitro.
class _Silbato extends CustomPainter {
  const _Silbato();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w * 0.42, h * 0.58);

    // La boquilla.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.22, w * 0.5, h * 0.24),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF212121),
    );

    // El cuerpo.
    canvas.drawCircle(c, w * 0.32, Paint()..color = const Color(0xFFB0BEC5));
    canvas.drawCircle(
      c,
      w * 0.32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF455A64),
    );
    canvas.drawCircle(c, w * 0.11, Paint()..color = const Color(0xFF263238));

    // La anilla del cordón.
    canvas.drawCircle(
      Offset(w * 0.1, h * 0.28),
      w * 0.09,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF455A64),
    );
  }

  @override
  bool shouldRepaint(_Silbato oldDelegate) => false;
}

// ======================================================================
// Obstáculos de Regatea
// ======================================================================

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

/// Un cono naranja con su franja blanca.
class ConoPainter extends CustomPainter {
  const ConoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromLTWH(w * 0.05, h * 0.88, w * 0.9, h * 0.12),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // La base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.78, w * 0.84, h * 0.14),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE65100),
    );

    final cono = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.84, h * 0.8)
      ..lineTo(w * 0.16, h * 0.8)
      ..close();

    canvas.drawPath(cono, Paint()..color = const Color(0xFFFF6D00));

    canvas.save();
    canvas.clipPath(cono);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.36, w, h * 0.16),
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ConoPainter oldDelegate) => false;
}

/// Un charco de agua.
class CharcoPainter extends CustomPainter {
  const CharcoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(w * 0.04, h * 0.25, w * 0.92, h * 0.6);

    canvas.drawOval(rect, Paint()..color = const Color(0xFF1565C0));
    canvas.drawOval(
      rect.deflate(w * 0.05),
      Paint()..color = const Color(0xFF42A5F5),
    );

    final brillo = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, h * 0.05);

    canvas.drawArc(
      Rect.fromLTWH(w * 0.22, h * 0.38, w * 0.34, h * 0.22),
      math.pi,
      math.pi * 0.8,
      false,
      brillo,
    );
  }

  @override
  bool shouldRepaint(CharcoPainter oldDelegate) => false;
}
