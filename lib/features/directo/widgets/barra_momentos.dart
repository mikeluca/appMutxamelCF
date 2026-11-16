import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/models/ficha_partido_model.dart';
import '../../ficha_partido/models/reloj_directo.dart';
import '../models/momentos_partido.dart';
import 'visibilidad_en_pantalla.dart';

/// Crea el temporizador de la marca del minuto actual; los tests lo sustituyen.
typedef CrearTemporizadorMarca =
    Timer Function(Duration intervalo, void Function(Timer) alTic);

/// La barra de momentos del partido: una línea de 0 a 2·minutosParte (marcas en 0, la mitad con "DESC." y el final)
/// con un icono en el minuto de cada hecho: balón para los goles, rectángulo amarillo o rojo para las tarjetas y
/// flechas para los cambios. Los del equipo local van arriba y los del visitante abajo. En directo lleva una marca
/// del minuto actual con el reloj que avanza. Tocar un icono muestra un globo con el detalle.
///
/// Sin hechos con minuto no se muestra. Dibujada solo con widgets, sin imágenes externas.
class BarraMomentos extends StatelessWidget {
  final FichaPartido ficha;

  /// Solo para tests: la hora del móvil y el temporizador de la marca del minuto actual.
  final DateTime Function()? ahora;
  final CrearTemporizadorMarca? crearTemporizador;

  const BarraMomentos({
    super.key,
    required this.ficha,
    this.ahora,
    this.crearTemporizador,
  });

  static const double _alturaCarril = 54;
  static const double _tamanoIcono = 30;

  @override
  Widget build(BuildContext context) {
    final cabecera = ficha.cabecera;
    final minutosParte = cabecera.minutosParte;

    final momentos = colocarMomentos(
      ficha.eventos,
      minutosParte: minutosParte,
      mutxamelEsLocal: cabecera.mutxamelEsLocal,
      fase: cabecera.reloj?.fase,
    );

    if (momentos.isEmpty) return const SizedBox.shrink();

    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final total = minutosParte * 2;
    final reloj = cabecera.reloj;

    // Con letra grande las etiquetas crecen: se deja sitio.
    final escala = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final alturaEtiquetas = 22.0 * escala;

    return Semantics(
      container: true,
      label: t.momentsBarLabel,
      child: Padding(
        key: const ValueKey('barra-momentos'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final ancho = restricciones.maxWidth;
            final alto = _alturaCarril * 2 + alturaEtiquetas;

            double x(double fraccion) => (fraccion * ancho).clamp(
              _tamanoIcono / 2,
              ancho - _tamanoIcono / 2,
            );

            return SizedBox(
              height: alto,
              width: ancho,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // La línea central y sus tres marcas.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _alturaCarril - 1,
                    child: Container(height: 3, color: colors.outlineVariant),
                  ),
                  for (final fraccion in const [0.0, 0.5, 1.0])
                    Positioned(
                      left: (fraccion * ancho - 1).clamp(0, ancho - 2),
                      top: _alturaCarril - 8,
                      child: Container(
                        width: 2,
                        height: 19,
                        color: colors.outline,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _alturaCarril * 2 - 4,
                    height: alturaEtiquetas,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _Etiqueta(
                          x: 0,
                          ancho: ancho,
                          alineacion: Alignment.centerLeft,
                          texto: "0'",
                        ),
                        _Etiqueta(
                          x: ancho / 2,
                          ancho: ancho,
                          alineacion: Alignment.center,
                          texto: t.momentsHalftimeShort,
                          clave: 'momentos-mitad',
                        ),
                        _Etiqueta(
                          x: ancho,
                          ancho: ancho,
                          alineacion: Alignment.centerRight,
                          texto: "$total'",
                          clave: 'momentos-final',
                        ),
                      ],
                    ),
                  ),
                  for (final momento in momentos)
                    Positioned(
                      key: ValueKey('momento-${momento.indice}'),
                      left: x(momento.fraccion) - _tamanoIcono / 2,
                      top: momento.arriba
                          ? _alturaCarril - 12 - _tamanoIcono -
                                momento.fila * (_tamanoIcono - 4)
                          : _alturaCarril + 12 +
                                momento.fila * (_tamanoIcono - 4),
                      width: _tamanoIcono,
                      height: _tamanoIcono,
                      child: Tooltip(
                        message: _detalle(t, momento.evento),
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 3),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _icono(momento.evento),
                          ),
                        ),
                      ),
                    ),
                  if (reloj != null)
                    _MarcaMinutoActual(
                      reloj: reloj,
                      minutosParte: minutosParte,
                      ancho: ancho,
                      alto: _alturaCarril * 2,
                      ahora: ahora,
                      crearTemporizador: crearTemporizador,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _icono(EventoFicha evento) {
    switch (evento.tipo) {
      case EventoFicha.golFavor:
      case EventoFicha.golContra:
        return const Icon(Icons.sports_soccer, size: 22);
      case EventoFicha.cambio:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward, size: 12, color: Color(0xFF2E9E4F)),
            Icon(Icons.arrow_downward, size: 12, color: Color(0xFFD62828)),
          ],
        );
      case EventoFicha.tarjetaRoja:
        return evento.dobleAmarilla
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RectanguloTarjeta(roja: false),
                  SizedBox(width: 2),
                  _RectanguloTarjeta(roja: false),
                  SizedBox(width: 2),
                  _RectanguloTarjeta(roja: true),
                ],
              )
            : const _RectanguloTarjeta(roja: true);
      default:
        return const _RectanguloTarjeta(roja: false);
    }
  }

  /// El globo: "23' Pepe", "67' Cambio: entra Juanma, sale Luis"...
  static String _detalle(AppLocalizations t, EventoFicha e) {
    final minuto = e.minuto == null ? '' : "${e.minuto}' ";

    switch (e.tipo) {
      case EventoFicha.golFavor:
        return '$minuto${e.jugador ?? t.fichaGoal}';
      case EventoFicha.golContra:
        return '$minuto${t.fichaGoalAgainst}'
            '${e.dorsalRival == null ? '' : ' · ${t.fichaDorsal(e.dorsalRival.toString())}'}';
      case EventoFicha.cambio:
        return '$minuto${t.momentSubstitution(e.jugadorEntra ?? '', e.jugador ?? '')}';
      default:
        final tarjeta = e.dobleAmarilla
            ? t.fichaSecondYellow
            : (e.tipo == EventoFicha.tarjetaRoja
                  ? t.fichaRedCard
                  : t.fichaYellowCard);
        final quien = e.rival
            ? (e.dorsalRival == null
                  ? ''
                  : ' · ${t.fichaDorsal(e.dorsalRival.toString())}')
            : (e.jugador == null ? '' : ' · ${e.jugador}');

        return '$minuto$tarjeta$quien';
    }
  }
}

/// El rectángulo de una tarjeta, sin las claves de la lista del Detalle (en la pantalla salen los dos a la vez).
class _RectanguloTarjeta extends StatelessWidget {
  final bool roja;

  const _RectanguloTarjeta({required this.roja});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 16,
      decoration: BoxDecoration(
        color: roja ? const Color(0xFFD62828) : const Color(0xFFF2C500),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final double x;
  final double ancho;
  final Alignment alineacion;
  final String texto;
  final String? clave;

  const _Etiqueta({
    required this.x,
    required this.ancho,
    required this.alineacion,
    required this.texto,
    this.clave,
  });

  @override
  Widget build(BuildContext context) {
    const caja = 56.0;
    final izquierda = alineacion == Alignment.centerLeft
        ? 0.0
        : alineacion == Alignment.centerRight
        ? ancho - caja
        : x - caja / 2;

    return Positioned(
      left: izquierda,
      width: caja,
      top: 0,
      bottom: 0,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alineacion,
        child: Text(
          texto,
          key: clave == null ? null : ValueKey(clave),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// La marca vertical del minuto actual con el reloj que avanza (repintada cada segundo con un temporizador local que
/// solo corre con la app en primer plano y la pantalla a la vista). En el descanso se queda en la mitad.
class _MarcaMinutoActual extends StatefulWidget {
  final RelojDirecto reloj;
  final int minutosParte;
  final double ancho;
  final double alto;
  final DateTime Function()? ahora;
  final CrearTemporizadorMarca? crearTemporizador;

  const _MarcaMinutoActual({
    required this.reloj,
    required this.minutosParte,
    required this.ancho,
    required this.alto,
    this.ahora,
    this.crearTemporizador,
  });

  @override
  State<_MarcaMinutoActual> createState() => _MarcaMinutoActualState();
}

class _MarcaMinutoActualState extends State<_MarcaMinutoActual>
    with WidgetsBindingObserver, VisibilidadEnPantalla<_MarcaMinutoActual> {
  Timer? _temporizador;

  DateTime _ahora() => (widget.ahora ?? DateTime.now)();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  @override
  void didUpdateWidget(_MarcaMinutoActual anterior) {
    super.didUpdateWidget(anterior);
    _sincronizar();
  }

  @override
  void alCambiarVisibilidad() {
    if (enPantalla && mounted) setState(() {});

    _sincronizar();
  }

  void _sincronizar() {
    final debeCorrer = !widget.reloj.enDescanso && enPantalla;

    if (debeCorrer && _temporizador == null) {
      final crear = widget.crearTemporizador ?? Timer.periodic;

      _temporizador = crear(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!debeCorrer) {
      _temporizador?.cancel();
      _temporizador = null;
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.minutosParte * 2;
    final tiempo = widget.reloj.tiempo(_ahora());

    // En el descanso, en la mitad; en juego, en su minuto sin salirse de la barra.
    final minutos = tiempo == null
        ? widget.minutosParte.toDouble()
        : (tiempo.inMilliseconds / 60000).clamp(0, total).toDouble();

    final texto = tiempo == null
        ? AppLocalizations.of(context).momentsHalftimeShort
        : (widget.reloj.texto(_ahora()) ?? '');

    const caja = 52.0;
    final x = (minutos / total) * widget.ancho;
    final izquierda = (x - caja / 2).clamp(0.0, widget.ancho - caja);
    final color = Theme.of(context).colorScheme.error;

    return Positioned(
      key: const ValueKey('marca-minuto-actual'),
      left: izquierda,
      width: caja,
      top: 0,
      height: widget.alto + 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                texto,
                key: const ValueKey('marca-minuto-texto'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment(
                ((x - izquierda) / caja) * 2 - 1,
                0,
              ),
              child: Container(width: 2, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
