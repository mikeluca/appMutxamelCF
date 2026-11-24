import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../logica/cabezazos_logica.dart';
import '../logica/logica_juego.dart';
import '../models/juego_modelos.dart';
import 'dibujos_juego.dart';
import 'escenas_comunes.dart';

/// El fondo de Cabezazos: cielo, nubes y grada con desplazamiento paralaje suave, y el césped de abajo.
class _FondoCabezazos extends CustomPainter {
  const _FondoCabezazos(this.recorrido, this.suelo);

  final double recorrido;
  final double suelo;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, suelo),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFFE1F5FE)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, suelo)),
    );

    // Las nubes, muy lentas.
    final nube = Paint()..color = Colors.white.withValues(alpha: 0.85);
    const periodoNubes = 260.0;
    final desfaseNubes = (recorrido * 0.08) % periodoNubes;

    for (var i = -1; i < 3; i++) {
      final x = i * periodoNubes - desfaseNubes + 40;
      final y = suelo * (0.14 + 0.09 * ((i + 1) % 3));

      canvas.drawOval(Rect.fromLTWH(x, y, 90, 26), nube);
      canvas.drawOval(Rect.fromLTWH(x + 22, y - 12, 54, 26), nube);
    }

    // La grada: un muro con filas de aficionados (puntos de colores), algo más rápida.
    final alturaGrada = suelo * 0.30;
    final topeGrada = suelo - alturaGrada;

    canvas.drawRect(
      Rect.fromLTWH(0, topeGrada, size.width, alturaGrada),
      Paint()..color = const Color(0xFF90A4AE),
    );

    const periodoGrada = 36.0;
    final desfaseGrada = (recorrido * 0.3) % periodoGrada;
    const colores = [
      Color(0xFF1565C0),
      Color(0xFFFFFFFF),
      Color(0xFFE57373),
      Color(0xFFFFCA28),
    ];

    for (var fila = 0; fila * 20 + 14 < alturaGrada; fila++) {
      for (var i = -1; i * periodoGrada < size.width + periodoGrada; i++) {
        final x = i * periodoGrada - desfaseGrada + (fila.isEven ? 0 : periodoGrada / 2);

        canvas.drawCircle(
          Offset(x + 8, topeGrada + 12 + fila * 20),
          5,
          Paint()..color = colores[(i + fila).abs() % colores.length],
        );
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(0, topeGrada, size.width, 4),
      Paint()..color = const Color(0xFF546E7A),
    );

    // El césped, a franjas que avanzan.
    const franja = 40.0;
    final desfaseCesped = recorrido % (franja * 2);

    for (var i = -2; i * franja < size.width + franja * 2; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * franja - desfaseCesped, suelo, franja, size.height - suelo),
        Paint()
          ..color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF388E3C),
      );
    }
  }

  @override
  bool shouldRepaint(_FondoCabezazos oldDelegate) =>
      oldDelegate.recorrido != recorrido || oldDelegate.suelo != suelo;
}

/// Cabezazos: Mutxigol de perfil que salta con cada toque, entre columnas de defensas.
class EscenaCabezazos extends StatelessWidget {
  const EscenaCabezazos({
    super.key,
    required this.logica,
    required this.equipacion,
    required this.activa,
  });

  final CabezazosLogica logica;
  final Equipacion equipacion;
  final bool activa;

  /// El alto de cada defensa de la columna.
  static const double altoDefensa = 68;

  /// El tamaño con el que se dibuja a Mutxigol (su caja de choque es algo menor).
  static const double tamanoMutxigol = 92;

  Widget _columna(double desde, double hasta, {required bool haciaArriba}) {
    final total = hasta - desde;

    if (total <= 0) return const SizedBox.shrink();

    final cuantas = (total / altoDefensa).ceil();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < cuantas; i++)
          Positioned(
            left: 0,
            top: haciaArriba
                ? hasta - (i + 1) * altoDefensa
                : desde + i * altoDefensa,
            width: CabezazosLogica.anchoBarrera,
            height: altoDefensa,
            child: const CustomPaint(painter: DefensaPainter()),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = logica;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (activa) l.tocar();
      },
      child: SizedBox(
        width: LogicaJuego.ancho,
        height: l.alto,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _FondoCabezazos(l.recorrido, l.suelo)),
              ),
              for (final b in l.barreras)
                Positioned(
                  key: const ValueKey('barrera'),
                  left: b.x,
                  top: 0,
                  width: CabezazosLogica.anchoBarrera,
                  height: l.suelo,
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: _columna(0, b.techoDelHueco, haciaArriba: true),
                        ),
                        Positioned.fill(
                          child: _columna(b.sueloDelHueco, l.suelo, haciaArriba: false),
                        ),
                      ],
                    ),
                  ),
                ),
              MutxigolEnEscena(
                equipacion: equipacion,
                pose: PoseMutxigol.salto,
                centroX: CabezazosLogica.xMutxigol,
                base: l.y + tamanoMutxigol / 2,
                tamano: tamanoMutxigol,
                // La inclinación: hacia arriba (positiva) gira en sentido contrario a las agujas del reloj.
                giro: -l.inclinacionGrados * math.pi / 180,
              ),
              if (l.esperando)
                Positioned(
                  key: const ValueKey('toca-para-saltar'),
                  left: 20,
                  right: 20,
                  top: l.alto * 0.4 + 64,
                  child: TextoJuego(t.gameHeadHint, tamano: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
