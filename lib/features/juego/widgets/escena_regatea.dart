import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../logica/atrapa_logica.dart' show TipoCaida;
import '../logica/logica_juego.dart';
import '../logica/regatea_logica.dart';
import '../models/juego_modelos.dart';
import 'dibujos_juego.dart';
import 'escenas_comunes.dart';

/// La perspectiva sencilla del campo de Regatea: [horizonte] arriba, el suelo donde corre Mutxigol abajo. Un objeto a
/// [distancia] se ve más arriba, más pequeño y más cerca del centro cuanto más lejos está.
class PerspectivaRegatea {
  const PerspectivaRegatea(this.alto);

  final double alto;

  /// La altura del horizonte.
  double get horizonte => alto * 0.26;

  /// La altura de los pies de Mutxigol.
  double get suelo => alto - 40;

  /// El ancho de un carril al pie de Mutxigol.
  static const double carrilCerca = 112;
  static const double carrilLejos = 6;

  /// Cuánto de cerca está algo a [distancia] (0 en el horizonte, 1 a los pies de Mutxigol; más de 1 si ya lo ha pasado).
  double cercania(double distancia) {
    final p = distancia / RegateaLogica.horizonte;

    if (p < 0) return 1 - p * 1.5;

    return math.pow(1 - math.min(p, 1), 1.7).toDouble();
  }

  double yDe(double distancia) =>
      horizonte + (suelo - horizonte) * cercania(distancia);

  double anchoDeCarril(double distancia) =>
      carrilLejos + (carrilCerca - carrilLejos) * cercania(distancia);

  /// El centro de un carril (puede ser fraccionario) a esa distancia.
  double xDe(double carril, double distancia) =>
      LogicaJuego.ancho / 2 + (carril - 1) * anchoDeCarril(distancia);

  /// El tamaño de un objeto de "1" al pie de Mutxigol, a esa distancia.
  double escala(double distancia) => 0.12 + 0.88 * math.min(cercania(distancia), 1.6);
}

/// El campo: cielo, césped a franjas que avanzan y las líneas de los 3 carriles convergiendo al horizonte.
class _CampoRegatea extends CustomPainter {
  const _CampoRegatea(this.perspectiva, this.recorrido);

  final PerspectivaRegatea perspectiva;
  final double recorrido;

  static const double franja = 250;

  @override
  void paint(Canvas canvas, Size size) {
    final h = perspectiva.horizonte;

    // El cielo.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, h)),
    );

    // Una grada lejana.
    canvas.drawRect(
      Rect.fromLTWH(0, h - 18, size.width, 18),
      Paint()..color = const Color(0xFF78909C),
    );

    // El césped a franjas: se mueven hacia Mutxigol con lo que se corre.
    final primera = (recorrido / franja).floor();

    for (var k = -1; k * franja < RegateaLogica.horizonte + franja; k++) {
      final lejos = math.min(k * franja - (recorrido % franja) + franja, RegateaLogica.horizonte);
      final cerca = math.max(k * franja - (recorrido % franja), -200.0);

      if (lejos <= cerca) continue;

      final arriba = perspectiva.yDe(lejos);
      final abajo = perspectiva.yDe(cerca);
      final par = (primera + k).isEven;

      canvas.drawRect(
        Rect.fromLTRB(0, arriba, size.width, abajo + 1),
        Paint()..color = par ? const Color(0xFF2E7D32) : const Color(0xFF388E3C),
      );
    }

    // Las líneas de los carriles.
    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final borde in [-0.5, 0.5, 1.5, 2.5]) {
      canvas.drawLine(
        Offset(perspectiva.xDe(borde, RegateaLogica.horizonte), h),
        Offset(perspectiva.xDe(borde, 0), perspectiva.suelo),
        linea..strokeWidth = (borde == -0.5 || borde == 2.5) ? 4 : 2,
      );
    }

    // Las bandas de fuera del campo, para que no quede césped liso hasta el borde.
    canvas.drawLine(
      Offset(perspectiva.xDe(-0.5, 0), perspectiva.suelo),
      Offset(perspectiva.xDe(-0.5, -400), perspectiva.yDe(-400)),
      linea..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(perspectiva.xDe(2.5, 0), perspectiva.suelo),
      Offset(perspectiva.xDe(2.5, -400), perspectiva.yDe(-400)),
      linea,
    );
  }

  @override
  bool shouldRepaint(_CampoRegatea oldDelegate) =>
      oldDelegate.recorrido != recorrido ||
      oldDelegate.perspectiva.alto != perspectiva.alto;
}

/// Regatea: el campo en perspectiva, los objetos, Mutxigol corriendo de espaldas y el balón delante de sus pies.
class EscenaRegatea extends StatefulWidget {
  const EscenaRegatea({
    super.key,
    required this.logica,
    required this.equipacion,
    required this.activa,
  });

  final RegateaLogica logica;
  final Equipacion equipacion;
  final bool activa;

  /// Lo que hay que deslizar el dedo (unidades de juego) para cambiar de carril.
  static const double umbralDeDeslizamiento = 28;

  @override
  State<EscenaRegatea> createState() => _EscenaRegateaState();
}

class _EscenaRegateaState extends State<EscenaRegatea> {
  double _acumulado = 0;

  void _deslizar(double dx) {
    if (!widget.activa) return;

    _acumulado += dx;

    if (_acumulado.abs() >= EscenaRegatea.umbralDeDeslizamiento) {
      widget.logica.cambiarCarril(_acumulado > 0 ? 1 : -1);
      _acumulado = 0;
    }
  }

  Widget _objeto(PerspectivaRegatea p, ObjetoPista o) {
    final d = o.distancia;
    final escala = p.escala(d);
    final centroX = p.xDe(o.carril.toDouble(), d);
    final base = p.yDe(d);

    final (ancho, alto) = switch (o.tipo) {
      TipoPista.defensa => (70 * escala, 110 * escala),
      TipoPista.cono => (48 * escala, 64 * escala),
      TipoPista.charco => (100 * escala, 50 * escala),
      TipoPista.balon => (40 * escala, 40 * escala),
      TipoPista.balonDorado => (44 * escala, 44 * escala),
    };

    final Widget hijo = switch (o.tipo) {
      TipoPista.defensa => const CustomPaint(painter: DefensaPainter()),
      TipoPista.cono => const CustomPaint(painter: ConoPainter()),
      TipoPista.charco => const CustomPaint(painter: CharcoPainter()),
      TipoPista.balon => Image.asset(
        ImagenesMutxigol.balon,
        gaplessPlayback: true,
      ),
      TipoPista.balonDorado => ObjetoDibujado(
        tipo: TipoCaida.balonDorado,
        tamano: ancho,
      ),
    };

    return Positioned(
      key: ValueKey('pista-${o.tipo.name}-${o.carril}'),
      left: centroX - ancho / 2,
      top: base - alto,
      width: ancho,
      height: alto,
      child: hijo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.logica;
    final p = PerspectivaRegatea(l.alto);

    final visibles = l.objetos.where((o) => o.distancia > -250).toList()
      ..sort((a, b) => b.distancia.compareTo(a.distancia));

    final x = p.xDe(l.posicionCarril, 0);
    final parpadeo = l.invulnerable && (l.invulnerableRestante * 10).floor().isEven;

    const pose = [
      PoseMutxigol.corriendo1,
      PoseMutxigol.corriendo2,
      PoseMutxigol.corriendo3,
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _acumulado = 0,
      onHorizontalDragUpdate: (d) => _deslizar(d.delta.dx),
      onHorizontalDragEnd: (_) => _acumulado = 0,
      child: SizedBox(
        width: LogicaJuego.ancho,
        height: l.alto,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _CampoRegatea(p, l.recorrido)),
              ),
              for (final o in visibles) _objeto(p, o),
              MutxigolEnEscena(
                equipacion: widget.equipacion,
                pose: pose[l.cuadroDeCarrera],
                centroX: x,
                base: p.suelo + 18,
                tamano: 150,
                opacidad: parpadeo ? 0.35 : 1,
              ),
              BalonEnEscena(
                centro: Offset(x, p.suelo - 8),
                diametro: 30,
                giro: l.recorrido / 18,
              ),
              if (l.frenado)
                Positioned(
                  left: 0,
                  right: 0,
                  top: p.suelo - 190,
                  child: Container(
                    key: const ValueKey('aviso-charco'),
                    alignment: Alignment.center,
                    child: Container(
                      width: 36,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

