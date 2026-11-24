import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../logica/atrapa_logica.dart';
import '../logica/logica_juego.dart';
import '../models/juego_modelos.dart';
import 'dibujos_juego.dart';
import 'escenas_comunes.dart';

/// Atrapa balones: el campo, lo que cae y Mutxigol, que se arrastra a izquierda y derecha.
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

  /// El tamaño con el que se dibuja cada objeto.
  static double tamanoDe(TipoCaida tipo) => switch (tipo) {
    TipoCaida.tarjetaRoja || TipoCaida.tarjetaAmarilla => 44,
    TipoCaida.bota || TipoCaida.silbato => 46,
    _ => 42,
  };

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
            const Positioned.fill(child: CustomPaint(painter: CampoPainter())),
            for (final objeto in l.objetos)
              Positioned(
                left: objeto.x - tamanoDe(objeto.tipo) / 2,
                top: objeto.y - tamanoDe(objeto.tipo) / 2,
                child: Transform.rotate(
                  angle: switch (objeto.tipo) {
                    TipoCaida.balon || TipoCaida.balonDorado => objeto.y / 20,
                    TipoCaida.balonEfecto => objeto.y / 14 * objeto.sentido,
                    TipoCaida.bota => objeto.vx > 0 ? 0.5 : -0.5,
                    _ => 0,
                  },
                  child: ObjetoDibujado(
                    tipo: objeto.tipo,
                    tamano: tamanoDe(objeto.tipo),
                  ),
                ),
              ),
            MutxigolEnEscena(
              equipacion: equipacion,
              pose: PoseMutxigol.atrapando,
              centroX: l.x,
              base: l.alto - AtrapaLogica.baseMutxigol,
              tamano: AtrapaLogica.tamanoMutxigol,
              opacidad: l.congelado ? 0.75 : 1,
            ),
            // El aviso visual del silbato: Mutxigol quieto.
            if (l.congelado)
              Positioned(
                key: const ValueKey('aviso-silbato'),
                left: l.x - 40,
                top: l.alto - 165,
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ObjetoDibujado(tipo: TipoCaida.silbato, tamano: 36),
                    TextoJuego(
                      t.gameCatchFrozen(l.congeladoRestante.ceil()),
                      tamano: 14,
                      color: Colors.yellowAccent,
                    ),
                  ],
                ),
              ),
            if (l.puntos == 0 && l.segundos < 4)
              Positioned(
                left: 20,
                right: 20,
                top: 220,
                child: TextoJuego(t.gameCatchHint, tamano: 18),
              ),
          ],
        ),
      ),
    );
  }
}
