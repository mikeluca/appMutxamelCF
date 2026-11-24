import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/widget/escudo_rival.dart';
import '../logica/logica_juego.dart';
import '../logica/parejas_logica.dart';
import '../models/juego_modelos.dart';

/// El color del reverso de las cartas según la equipación.
Color colorDeEquipacion(Equipacion equipacion) => switch (equipacion) {
  Equipacion.azul => const Color(0xFF1565C0),
  Equipacion.rosa => const Color(0xFFD81B7A),
};

/// El tablero de Parejas: 4×4 cartas. Boca abajo llevan el escudo del Mutxamel sobre azul o rosa; al tocarlas se giran
/// (unos 250 ms) y enseñan el escudo del club con su nombre debajo.
class EscenaParejas extends StatelessWidget {
  const EscenaParejas({
    super.key,
    required this.logica,
    required this.equipacion,
    required this.activa,
  });

  final ParejasLogica logica;
  final Equipacion equipacion;
  final bool activa;

  static const double margenLateral = 16;
  static const double hueco = 8;
  static const double alturaCarta = 100;

  /// Lo que dura el giro de una carta.
  static const Duration duracionDelGiro = ParejasLogica.duracionDelGiro;

  /// Dónde empieza el tablero (por debajo del marcador).
  static const double arriba = 96;

  static double get anchoCarta =>
      (LogicaJuego.ancho - 2 * margenLateral - (ParejasLogica.columnas - 1) * hueco) /
      ParejasLogica.columnas;

  @override
  Widget build(BuildContext context) {
    final l = logica;
    final altoTablero =
        ParejasLogica.filas * alturaCarta + (ParejasLogica.filas - 1) * hueco;

    // Centrado en lo que queda debajo del marcador.
    final top = math.max(arriba, arriba + (l.alto - arriba - altoTablero) / 2 - 24);

    return Container(
      width: LogicaJuego.ancho,
      height: l.alto,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
      ),
      child: Stack(
        children: [
          for (final carta in l.cartas)
            Positioned(
              left:
                  margenLateral +
                  (carta.posicion % ParejasLogica.columnas) * (anchoCarta + hueco),
              top:
                  top +
                  (carta.posicion ~/ ParejasLogica.columnas) *
                      (alturaCarta + hueco),
              width: anchoCarta,
              height: alturaCarta,
              child: CartaEnTablero(
                key: ValueKey('carta-${carta.posicion}'),
                carta: carta,
                equipacion: equipacion,
                onTap: activa ? () => l.tocar(carta.posicion) : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Una carta con su giro y su rebote al emparejarse.
class CartaEnTablero extends StatefulWidget {
  const CartaEnTablero({
    super.key,
    required this.carta,
    required this.equipacion,
    required this.onTap,
  });

  final CartaParejas carta;
  final Equipacion equipacion;
  final VoidCallback? onTap;

  @override
  State<CartaEnTablero> createState() => _CartaEnTableroState();
}

class _CartaEnTableroState extends State<CartaEnTablero>
    with TickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: EscenaParejas.duracionDelGiro,
    value: _boca(widget.carta.estado) ? 1 : 0,
  );

  late final AnimationController _rebote = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  EstadoCarta _estadoAnterior = EstadoCarta.oculta;

  static bool _boca(EstadoCarta e) => e != EstadoCarta.oculta;

  @override
  void initState() {
    super.initState();

    _estadoAnterior = widget.carta.estado;
  }

  @override
  void didUpdateWidget(CartaEnTablero anterior) {
    super.didUpdateWidget(anterior);

    final estado = widget.carta.estado;

    if (estado == _estadoAnterior) return;

    _estadoAnterior = estado;

    if (_boca(estado)) {
      _giro.forward();
    } else {
      _giro.reverse();
    }

    if (estado == EstadoCarta.emparejada) {
      // Un pequeño rebote cuando acaba de girarse.
      _giro.forward().whenComplete(() {
        if (mounted) _rebote.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    _rebote.dispose();
    super.dispose();
  }

  Widget _reverso() {
    return Container(
      key: const ValueKey('carta-reverso'),
      decoration: BoxDecoration(
        color: colorDeEquipacion(widget.equipacion),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        ImagenesMutxigol.escudoClub,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }

  Widget _frente() {
    final escudo = widget.carta.escudo;

    return Container(
      key: const ValueKey('carta-frente'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.carta.estado == EstadoCarta.emparejada
              ? Colors.yellowAccent.shade700
              : colorDeEquipacion(widget.equipacion),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Column(
        children: [
          EscudoRival(url: escudo.escudoUrl, tamano: 46, sinGenerico: true),
          const SizedBox(height: 2),
          Expanded(
            child: Center(
              child: Text(
                escudo.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_giro, _rebote]),
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_giro.value);
          final angulo = math.pi * v;
          final muestraFrente = v > 0.5;
          final rebote = _rebote.isAnimating
              ? 1 + 0.12 * math.sin(math.pi * _rebote.value)
              : 1.0;

          return Transform.scale(
            scale: rebote,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(angulo),
              child: muestraFrente
                  // Girada del todo, la cara se ve del derecho (sin espejo).
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _frente(),
                    )
                  : _reverso(),
            ),
          );
        },
      ),
    );
  }
}
