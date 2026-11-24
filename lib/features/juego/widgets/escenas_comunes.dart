import 'package:material_ui/material_ui.dart';

import '../models/juego_modelos.dart';

/// Lo que comparten las escenas de los juegos: Flutter puro (widgets posicionados con las coordenadas del juego). Cada
/// escena mide [LogicaJuego.ancho] × alto unidades; quien las pone las escala a la pantalla (un FittedBox), así que los
/// gestos que reciben ya vienen en unidades de juego.

/// Un balón (la imagen de assets), centrado en [centro].
class BalonEnEscena extends StatelessWidget {
  const BalonEnEscena({
    super.key,
    required this.centro,
    required this.diametro,
    this.giro = 0,
  });

  final Offset centro;
  final double diametro;
  final double giro;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centro.dx - diametro / 2,
      top: centro.dy - diametro / 2,
      width: diametro,
      height: diametro,
      child: Transform.rotate(
        angle: giro,
        child: Image.asset(
          ImagenesMutxigol.balon,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Mutxigol en una pose, con el centro de la base en ([centroX], [base]).
class MutxigolEnEscena extends StatelessWidget {
  const MutxigolEnEscena({
    super.key,
    required this.equipacion,
    required this.pose,
    required this.centroX,
    required this.base,
    this.tamano = 170,
    this.espejo = false,
    this.giro = 0,
    this.alineacionGiro = Alignment.center,
    this.opacidad = 1,
  });

  final Equipacion equipacion;
  final PoseMutxigol pose;
  final double centroX;
  final double base;
  final double tamano;
  final bool espejo;

  /// Giro en radianes (Cabezazos lo inclina según la velocidad).
  final double giro;

  /// El punto sobre el que gira (por defecto, el centro de la imagen).
  final Alignment alineacionGiro;
  final double opacidad;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centroX - tamano / 2,
      top: base - tamano,
      width: tamano,
      height: tamano,
      child: Opacity(
        opacity: opacidad,
        child: Transform.rotate(
          angle: giro,
          alignment: alineacionGiro,
          child: Transform.flip(
            flipX: espejo,
            child: Image.asset(
              ImagenesMutxigol.pose(equipacion, pose),
              key: ValueKey('mutxigol-${pose.name}'),
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// El fondo de Atrapa: un campo de fútbol a franjas.
class CampoPainter extends CustomPainter {
  const CampoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final franja = size.height / 12;

    for (var i = 0; i < 12; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * franja, size.width, franja),
        Paint()
          ..color = i.isEven
              ? const Color(0xFF2E7D32)
              : const Color(0xFF388E3C),
      );
    }

    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(
      Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
      linea,
    );
  }

  @override
  bool shouldRepaint(CampoPainter oldDelegate) => false;
}

/// Un texto del juego: tamaño fijo y sombra, para que se lea sobre el campo.
class TextoJuego extends StatelessWidget {
  const TextoJuego(this.texto, {super.key, this.tamano = 15, this.color = Colors.white});

  final String texto;
  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: tamano,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(blurRadius: 4, color: Colors.black87)],
      ),
    );
  }
}
