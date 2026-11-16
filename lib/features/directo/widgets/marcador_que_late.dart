import 'package:flutter/material.dart';

import '../models/cambio_marcador.dart';
import 'visibilidad_en_pantalla.dart';

/// El marcador "2 - 1" de un partido en directo. Cuando sube un número que ya se veía del MISMO partido, ese
/// número entra con una animación corta (escala de 1,4 a 1 y desvanecido, 400 ms) y detrás del marcador sale un
/// destello de color: verde si es gol del Mutxamel, rojo si es del rival. Si baja (gol anulado) solo se actualiza,
/// sin destello. Mismas reglas que [CelebraGoles]: nada al abrir, nada en segundo plano ni con otra pantalla encima, y
/// con la animación reducida en el sistema el número cambia sin movimiento ni destello.
///
/// Sin goles (`null`) pinta [vacio] ("-").
class MarcadorQueLate extends StatefulWidget {
  final int? partidoId;
  final int? golesFavor;
  final int? golesContra;
  final bool mutxamelEsLocal;
  final TextStyle estilo;
  final String vacio;

  const MarcadorQueLate({
    super.key,
    required this.partidoId,
    required this.golesFavor,
    required this.golesContra,
    required this.mutxamelEsLocal,
    required this.estilo,
    this.vacio = '-',
  });

  static const Color verde = Color(0xFF2E9E4F);
  static const Color rojo = Color(0xFFD62828);

  @override
  State<MarcadorQueLate> createState() => _MarcadorQueLateState();
}

class _MarcadorQueLateState extends State<MarcadorQueLate>
    with
        WidgetsBindingObserver,
        VisibilidadEnPantalla<MarcadorQueLate>,
        SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Qué número entra (los 400 ms primeros del controlador) y de qué color es el destello.
  bool _entraFavor = false;
  bool _entraContra = false;
  Color? _colorDestello;

  @override
  void didUpdateWidget(MarcadorQueLate anterior) {
    super.didUpdateWidget(anterior);

    // Otro partido: lo que se veía deja de valer.
    if (anterior.partidoId != widget.partidoId) {
      _quitar();
      return;
    }

    final cambio = compararMarcador(
      favorAntes: anterior.golesFavor,
      contraAntes: anterior.golesContra,
      favor: widget.golesFavor,
      contra: widget.golesContra,
    );

    if (cambio == CambioMarcador.baja) {
      _quitar();
      return;
    }

    if (cambio == CambioMarcador.ninguno ||
        !enPantalla ||
        widget.partidoId == null ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }

    _entraFavor = (widget.golesFavor ?? 0) > (anterior.golesFavor ?? 0);
    _entraContra = (widget.golesContra ?? 0) > (anterior.golesContra ?? 0);
    _colorDestello = cambio == CambioMarcador.golNuestro
        ? MarcadorQueLate.verde
        : MarcadorQueLate.rojo;

    _controlador.forward(from: 0);
  }

  void _quitar() {
    _controlador.stop();
    _entraFavor = false;
    _entraContra = false;
    _colorDestello = null;
  }

  @override
  void alCambiarVisibilidad() {
    // Al taparse o irse a segundo plano no se queda a medias.
    if (!enPantalla && _controlador.isAnimating) {
      _controlador.value = 1;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Widget _numero(int valor, {required bool entra, required Key clave}) {
    final texto = Text('$valor', key: clave, style: widget.estilo);

    if (!entra) return texto;

    // Los primeros 400 ms de los 900 del controlador.
    final entrada = CurvedAnimation(
      parent: _controlador,
      curve: const Interval(0, 400 / 900, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: entrada,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.4, end: 1).animate(entrada),
        child: texto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favor = widget.golesFavor;
    final contra = widget.golesContra;

    if (favor == null || contra == null) {
      return Text(widget.vacio, style: widget.estilo);
    }

    final izquierdaEsFavor = widget.mutxamelEsLocal;

    final numeros = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _numero(
          izquierdaEsFavor ? favor : contra,
          entra: izquierdaEsFavor ? _entraFavor : _entraContra,
          clave: const ValueKey('marcador-local'),
        ),
        Text(' - ', style: widget.estilo),
        _numero(
          izquierdaEsFavor ? contra : favor,
          entra: izquierdaEsFavor ? _entraContra : _entraFavor,
          clave: const ValueKey('marcador-visitante'),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, hijo) {
        final color = _colorDestello;
        final destello = color != null && _controlador.isAnimating;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (destello)
              Positioned.fill(
                child: DecoratedBox(
                  key: ValueKey(
                    color == MarcadorQueLate.verde
                        ? 'destello-verde'
                        : 'destello-rojo',
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.55 * (1 - _controlador.value),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: hijo,
            ),
          ],
        );
      },
      child: numeros,
    );
  }
}
