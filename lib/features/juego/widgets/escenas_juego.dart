import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../logica/atrapa_logica.dart';
import '../logica/logica_juego.dart';
import '../logica/penaltis_logica.dart';
import '../logica/toques_logica.dart';
import '../models/juego_modelos.dart';

/// Las escenas de los tres juegos: Flutter puro (widgets posicionados con las coordenadas del juego). Cada escena mide
/// [LogicaJuego.ancho] × alto unidades; quien las pone las escala a la pantalla (un FittedBox), así que los gestos que
/// reciben ya vienen en unidades de juego.

/// Un balón (la imagen de assets).
class _Balon extends StatelessWidget {
  const _Balon({required this.centro, required this.diametro, this.giro = 0});

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
class _Mutxigol extends StatelessWidget {
  const _Mutxigol({
    required this.equipacion,
    required this.pose,
    required this.centroX,
    required this.base,
    this.tamano = 170,
    this.espejo = false,
  });

  final Equipacion equipacion;
  final PoseMutxigol pose;
  final double centroX;
  final double base;
  final double tamano;
  final bool espejo;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centroX - tamano / 2,
      top: base - tamano,
      width: tamano,
      height: tamano,
      child: Transform.flip(
        flipX: espejo,
        child: Image.asset(
          ImagenesMutxigol.pose(equipacion, pose),
          key: ValueKey('mutxigol-${pose.name}'),
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// El fondo: un campo de fútbol a franjas.
class _Campo extends CustomPainter {
  const _Campo();

  @override
  void paint(Canvas canvas, Size size) {
    final franja = size.height / 12;

    for (var i = 0; i < 12; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * franja, size.width, franja),
        Paint()..color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF388E3C),
      );
    }

    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(Rect.fromLTWH(14, 14, size.width - 28, size.height - 28), linea);
  }

  @override
  bool shouldRepaint(_Campo oldDelegate) => false;
}

/// La portería: palos, red y las 6 zonas.
class _Porteria extends CustomPainter {
  const _Porteria({required this.zonaDestacada});

  final int? zonaDestacada;

  @override
  void paint(Canvas canvas, Size size) {
    const rect = PenaltisLogica.porteria;

    canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: 0.25));

    final red = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (var x = rect.left; x <= rect.right; x += 16) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), red);
    }

    for (var y = rect.top; y <= rect.bottom; y += 16) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), red);
    }

    if (zonaDestacada != null) {
      final centro = PenaltisLogica.centroDeZona(zonaDestacada!);
      final ancho = rect.width / PenaltisLogica.columnas;
      final alto = rect.height / PenaltisLogica.alturas;

      canvas.drawRect(
        Rect.fromCenter(center: centro, width: ancho, height: alto),
        Paint()..color = Colors.yellow.withValues(alpha: 0.30),
      );
    }

    final zonas = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    for (var c = 1; c < PenaltisLogica.columnas; c++) {
      final x = rect.left + rect.width / PenaltisLogica.columnas * c;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), zonas);
    }

    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      zonas,
    );

    final palos = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rect.bottomLeft, rect.topLeft, palos);
    canvas.drawLine(rect.topLeft, rect.topRight, palos);
    canvas.drawLine(rect.topRight, rect.bottomRight, palos);
  }

  @override
  bool shouldRepaint(_Porteria oldDelegate) =>
      oldDelegate.zonaDestacada != zonaDestacada;
}

/// Un texto del juego: tamaño fijo y sombra, para que se lea sobre el campo.
class _TextoJuego extends StatelessWidget {
  const _TextoJuego(this.texto, {this.tamano = 15, this.color = Colors.white});

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

// ======================================================================
// PENALTIS
// ======================================================================

class EscenaPenaltis extends StatefulWidget {
  const EscenaPenaltis({
    super.key,
    required this.logica,
    required this.equipacion,
    required this.activa,
  });

  final PenaltisLogica logica;
  final Equipacion equipacion;

  /// Solo se puede tirar con la partida en marcha (no en la cuenta atrás ni en pausa).
  final bool activa;

  @override
  State<EscenaPenaltis> createState() => _EscenaPenaltisState();
}

class _EscenaPenaltisState extends State<EscenaPenaltis> {
  Offset? _inicio;
  Offset? _ultimo;

  void _terminarGesto() {
    final inicio = _inicio;
    final fin = _ultimo;

    _inicio = null;
    _ultimo = null;

    if (widget.activa && inicio != null && fin != null) {
      widget.logica.disparar(inicio, fin);
    }
  }

  String _textoResultado(AppLocalizations t, ResultadoTiro r) => switch (r) {
    ResultadoTiro.gol => t.gameResultGoal,
    ResultadoTiro.parada => t.gameResultSaved,
    ResultadoTiro.flojo => t.gameResultWeak,
    ResultadoTiro.fuera => t.gameResultOut,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = widget.logica;
    final enJuego = l.fase != FasePenalti.apuntando;

    // El portero: de pie en el centro hasta que se tira y entonces se lanza hacia su zona.
    final destinoPortero = PenaltisLogica.centroDeZona(l.zonaPortero);
    final progreso = enJuego ? l.progresoVuelo : 0.0;
    final columna = l.zonaPortero % PenaltisLogica.columnas;
    final centroPortero = Offset.lerp(
      Offset(LogicaJuego.ancho / 2, 0),
      Offset(destinoPortero.dx, 0),
      progreso,
    )!.dx;
    final elevacion = enJuego && l.zonaPortero < PenaltisLogica.columnas
        ? 30 * progreso
        : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        _inicio = d.localPosition;
        _ultimo = d.localPosition;
      },
      onPanUpdate: (d) => _ultimo = d.localPosition,
      onPanEnd: (_) => _terminarGesto(),
      onPanCancel: () {
        _inicio = null;
        _ultimo = null;
      },
      child: SizedBox(
        width: LogicaJuego.ancho,
        height: l.alto,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: CustomPaint(painter: _Campo())),
            Positioned.fill(
              child: CustomPaint(
                painter: _Porteria(
                  zonaDestacada: l.fase == FasePenalti.resultado
                      ? l.zonaTiro
                      : null,
                ),
              ),
            ),
            _Mutxigol(
              equipacion: widget.equipacion,
              pose: enJuego ? PoseMutxigol.parada : PoseMutxigol.portero,
              centroX: centroPortero,
              base: PenaltisLogica.porteria.bottom + 12 - elevacion,
              tamano: 170,
              espejo: enJuego && columna == 0,
            ),
            _Balon(
              centro: l.balon,
              diametro: 44 - 12 * l.progresoVuelo,
              giro: l.progresoVuelo * math.pi * 4,
            ),
            if (l.fase == FasePenalti.apuntando && l.tiros == 0)
              Positioned(
                left: 20,
                right: 20,
                top: l.balonReposo.dy + 40,
                child: _TextoJuego(t.gamePenaltiesHint),
              ),
            if (l.fase == FasePenalti.resultado && l.resultado != null)
              Positioned(
                left: 0,
                right: 0,
                top: PenaltisLogica.porteria.bottom + 50,
                child: _TextoJuego(
                  _textoResultado(t, l.resultado!),
                  tamano: 34,
                  color: l.resultado == ResultadoTiro.gol
                      ? Colors.yellowAccent
                      : Colors.redAccent.shade100,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// TOQUES
// ======================================================================

class EscenaToques extends StatelessWidget {
  const EscenaToques({
    super.key,
    required this.logica,
    required this.equipacion,
    required this.activa,
  });

  final ToquesLogica logica;
  final Equipacion equipacion;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = logica;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (activa) l.tocar(e.localPosition);
      },
      child: SizedBox(
        width: LogicaJuego.ancho,
        height: l.alto,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: CustomPaint(painter: _Campo())),
            _Mutxigol(
              equipacion: equipacion,
              pose: PoseMutxigol.toques,
              centroX: LogicaJuego.ancho / 2,
              base: l.alto - 14,
              tamano: 180,
            ),
            _Balon(
              centro: l.balon,
              diametro: ToquesLogica.radioBalon * 2,
              giro: (l.balon.dx + l.balon.dy) / ToquesLogica.radioBalon,
            ),
            if (l.puntos == 0)
              Positioned(
                left: 20,
                right: 20,
                top: 260,
                child: _TextoJuego(t.gameTouchesHint, tamano: 20),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// ATRAPA BALONES
// ======================================================================

class EscenaAtrapa extends StatelessWidget {
  const EscenaAtrapa({
    super.key,
    required this.logica,
    required this.equipacion,
    required this.activa,
  });

  final AtrapaLogica logica;
  final Equipacion equipacion;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = logica;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        if (activa) l.moverA(d.localPosition.dx);
      },
      onPanUpdate: (d) {
        if (activa) l.moverA(d.localPosition.dx);
      },
      onTapDown: (d) {
        if (activa) l.moverA(d.localPosition.dx);
      },
      child: SizedBox(
        width: LogicaJuego.ancho,
        height: l.alto,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: CustomPaint(painter: _Campo())),
            for (final objeto in l.objetos)
              if (objeto.tipo == TipoCaida.balon)
                _Balon(
                  centro: Offset(objeto.x, objeto.y),
                  diametro: 40,
                  giro: objeto.y / 20,
                )
              else
                Positioned(
                  left: objeto.x - 14,
                  top: objeto.y - 19,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: Container(
                      key: const ValueKey('tarjeta-roja'),
                      width: 28,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
            _Mutxigol(
              equipacion: equipacion,
              pose: PoseMutxigol.atrapando,
              centroX: l.x,
              base: l.alto - 20,
              tamano: 150,
            ),
            if (l.puntos == 0 && l.segundos < 4)
              Positioned(
                left: 20,
                right: 20,
                top: 220,
                child: _TextoJuego(t.gameCatchHint, tamano: 18),
              ),
          ],
        ),
      ),
    );
  }
}
