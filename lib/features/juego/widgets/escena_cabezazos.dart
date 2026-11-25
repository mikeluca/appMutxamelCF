import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../logica/cabezazos_logica.dart';
import '../logica/formas_choque.dart';
import '../logica/logica_juego.dart';
import '../models/juego_modelos.dart';
import 'siluetas_juego.dart';
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

/// Solo en debug y apagado por defecto: dibuja encima de la escena las formas de choque (los círculos de Mutxigol y las
/// formas de los defensas) para comprobar que coinciden con lo que se ve.
const bool depurarChoqueCabezazos = false;

/// Las formas de choque dibujadas (solo se usa con [depurarChoqueCabezazos] en debug).
class _FormasDeChoque extends CustomPainter {
  const _FormasDeChoque(this.circulos, this.defensas);

  final List<CirculoChoque> circulos;
  final List<FormaDefensa> defensas;

  @override
  void paint(Canvas canvas, Size size) {
    final relleno = Paint()..color = const Color(0x55FF1744);
    final borde = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final c in circulos) {
      canvas.drawCircle(c.centro, c.r, relleno);
      canvas.drawCircle(c.centro, c.r, borde);
    }

    for (final d in defensas) {
      canvas.drawCircle(d.cabeza.centro, d.cabeza.r, relleno);
      canvas.drawCircle(d.cabeza.centro, d.cabeza.r, borde);

      final rr = RRect.fromRectAndRadius(d.cuerpo.rect, Radius.circular(d.cuerpo.radio));

      canvas.drawRRect(rr, relleno);
      canvas.drawRRect(rr, borde);
    }
  }

  @override
  bool shouldRepaint(_FormasDeChoque oldDelegate) => true;
}

/// Cabezazos: Mutxigol de perfil que salta con cada toque, entre columnas de defensas con la otra equipación.
class EscenaCabezazos extends StatelessWidget {
  const EscenaCabezazos({
    super.key,
    required this.logica,
    required this.equipacion,
    required this.activa,
  });

  final CabezazosLogica logica;

  /// La equipación de Mutxigol; los defensas llevan la otra.
  final Equipacion equipacion;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = logica;
    final contraria = equipacion.opuesta;
    final camiseta = CamisetasDefensa.de(contraria);
    const tam = CabezazosLogica.tamanoImagen;

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
                for (final r in b.recuadros)
                  Positioned(
                    left: r.left,
                    top: r.top,
                    width: r.width,
                    height: r.height,
                    child: CustomPaint(
                      painter: DefensaPainter(
                        equipacion: contraria,
                        camiseta: camiseta,
                        cacheada: CacheDefensas.obtener(contraria, r.height, camiseta),
                      ),
                    ),
                  ),
              MutxigolEnEscena(
                equipacion: equipacion,
                pose: PoseMutxigol.salto,
                // El pivote (centro del tronco) está en ([xMutxigol], [y]); la imagen gira alrededor de él.
                centroX: CabezazosLogica.xMutxigol - CabezazosLogica.pivoteDx * tam,
                base: l.y - CabezazosLogica.pivoteDy * tam + tam / 2,
                tamano: tam,
                giro: l.angulo,
                alineacionGiro: Alignment(
                  2 * CabezazosLogica.pivoteDx,
                  2 * CabezazosLogica.pivoteDy,
                ),
              ),
              if (kDebugMode && depurarChoqueCabezazos)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _FormasDeChoque(l.circulosEnMundo, [
                        for (final b in l.barreras) ...b.formas,
                      ]),
                    ),
                  ),
                ),
              if (l.esperando)
                Positioned(
                  key: const ValueKey('toca-para-saltar'),
                  left: 20,
                  right: 20,
                  top: l.y + CabezazosLogica.altoDeLaForma / 2 + 40,
                  child: TextoJuego(t.gameHeadHint, tamano: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
