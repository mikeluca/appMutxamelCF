import 'package:flutter/material.dart';

/// Un jugador colocado en el campo: su fila (1 = portero, después las líneas de atrás adelante), su columna
/// (de izquierda a derecha dentro de la fila) y lo que se pinta en esa posición.
class PosicionEnCampo {
  final int fila;
  final int columna;
  final Widget child;

  const PosicionEnCampo({
    required this.fila,
    required this.columna,
    required this.child,
  });
}

/// Campo de fútbol dibujado con un [CustomPainter] (sin imágenes): el portero abajo y los delanteros arriba.
/// [formacion] ("4-5-1") sale arriba a la derecha. Cada [PosicionEnCampo] se reparte según su fila y las
/// columnas que haya en ella.
class CampoFutbol extends StatelessWidget {
  static const double relacionAspecto = 0.78;

  final List<PosicionEnCampo> jugadores;
  final String? formacion;

  /// TamaÃ±o de cada jugador (mÃ¡s pequeÃ±o en la vista previa de la retransmisiÃ³n).
  final double anchoJugador;
  final double altoJugador;

  /// Número de filas del campo; si es null, la mayor fila de [jugadores].
  final int? filas;

  const CampoFutbol({
    super.key,
    required this.jugadores,
    this.formacion,
    this.filas,
    this.anchoJugador = 76,
    this.altoJugador = 84,
  });

  @override
  Widget build(BuildContext context) {
    final totalFilas = filas ??
        jugadores.fold<int>(1, (mayor, j) => j.fila > mayor ? j.fila : mayor);

    final porFila = <int, int>{};
    for (final jugador in jugadores) {
      porFila.update(jugador.fila, (n) => n + 1, ifAbsent: () => 1);
    }

    return AspectRatio(
      aspectRatio: relacionAspecto,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;
            final alto = constraints.maxHeight;

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('campo-pintado'),
                    painter: const _CampoPainter(),
                  ),
                ),
                if (formacion != null && formacion!.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Text(
                      formacion!,
                      key: const ValueKey('campo-formacion'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                      ),
                    ),
                  ),
                for (final jugador in jugadores)
                  Positioned(
                    key: ValueKey('posicion-${jugador.fila}-${jugador.columna}'),
                    left:
                        ancho * jugador.columna / (porFila[jugador.fila]! + 1) -
                        anchoJugador / 2,
                    top:
                        alto * (1 - (jugador.fila - 0.5) / totalFilas) -
                        altoJugador / 2,
                    width: anchoJugador,
                    height: altoJugador,
                    child: jugador.child,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CampoPainter extends CustomPainter {
  const _CampoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final claro = Paint()..color = const Color(0xFF2E8B3D);
    final oscuro = Paint()..color = const Color(0xFF287A35);

    // Franjas de césped.
    const franjas = 10;
    final altoFranja = size.height / franjas;

    for (var i = 0; i < franjas; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * altoFranja, size.width, altoFranja + 1),
        i.isEven ? claro : oscuro,
      );
    }

    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final margen = size.width * 0.05;
    final campo = Rect.fromLTRB(
      margen,
      margen,
      size.width - margen,
      size.height - margen,
    );

    canvas.drawRect(campo, linea);

    // Línea de medio campo y círculo central.
    canvas.drawLine(
      Offset(campo.left, campo.center.dy),
      Offset(campo.right, campo.center.dy),
      linea,
    );
    canvas.drawCircle(campo.center, size.width * 0.14, linea);
    canvas.drawCircle(
      campo.center,
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // Áreas grande y pequeña de cada portería.
    final anchoArea = campo.width * 0.56;
    final altoArea = campo.height * 0.15;
    final anchoPequena = campo.width * 0.28;
    final altoPequena = campo.height * 0.06;

    for (final arriba in [true, false]) {
      final y = arriba ? campo.top : campo.bottom;
      final signo = arriba ? 1.0 : -1.0;

      canvas.drawRect(
        Rect.fromPoints(
          Offset(campo.center.dx - anchoArea / 2, y),
          Offset(campo.center.dx + anchoArea / 2, y + signo * altoArea),
        ),
        linea,
      );
      canvas.drawRect(
        Rect.fromPoints(
          Offset(campo.center.dx - anchoPequena / 2, y),
          Offset(campo.center.dx + anchoPequena / 2, y + signo * altoPequena),
        ),
        linea,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
