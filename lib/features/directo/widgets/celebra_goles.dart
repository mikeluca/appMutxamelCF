import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/cambio_marcador.dart';
import 'partido_visible.dart';
import 'visibilidad_en_pantalla.dart';

/// Envuelve la pantalla de un partido (la ficha o la tarjeta del Primer Equipo de la portada) y celebra los goles:
///
/// * gol del Mutxamel: animación a pantalla completa unos 3 s ("¡GOOOL!", el escudo, el marcador nuevo y, si se
///   conoce, el goleador) y vibración fuerte; tocarla la cierra antes;
/// * gol del rival: un aviso corto arriba ("Gol del rival · 2-1", con el dorsal si lo trae) y vibración suave.
///
/// Solo celebra cuando el marcador SUBE respecto al que ya se mostraba del MISMO partido y la pantalla se ve (app
/// en primer plano y sin otra pantalla encima). Al abrir no celebra nada; si el marcador baja (gol anulado) solo se
/// actualiza; si llegan dos goles a la vez es una sola celebración con el marcador final. Con la animación
/// reducida en el sistema no hay movimiento: solo el aviso (también para el gol propio) y la vibración.
class CelebraGoles extends StatefulWidget {
  /// El partido (null si no se conoce: entonces no se celebra nada).
  final int? partidoId;
  final int? golesFavor;
  final int? golesContra;
  final bool mutxamelEsLocal;

  /// El goleador del último gol del Mutxamel (en la ficha) y el dorsal del último gol del rival, si lo trae.
  final String? goleador;
  final int? dorsalRival;

  /// Cuánto dura la celebración antes de cerrarse sola.
  final Duration duracion;

  final Widget child;

  const CelebraGoles({
    super.key,
    required this.partidoId,
    required this.golesFavor,
    required this.golesContra,
    required this.mutxamelEsLocal,
    this.goleador,
    this.dorsalRival,
    this.duracion = const Duration(seconds: 3),
    required this.child,
  });

  @override
  State<CelebraGoles> createState() => _CelebraGolesState();
}

class _CelebraGolesState extends State<CelebraGoles>
    with WidgetsBindingObserver, VisibilidadEnPantalla<CelebraGoles> {
  int? _favorVisto;
  int? _contraVisto;

  OverlayEntry? _entrada;
  Timer? _cierre;

  @override
  void initState() {
    super.initState();

    // Lo que hay al abrir es la línea base: nunca se celebra.
    _favorVisto = widget.golesFavor;
    _contraVisto = widget.golesContra;
  }

  @override
  void alCambiarVisibilidad() {
    PartidoVisible.actualizar(this, enPantalla ? widget.partidoId : null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PartidoVisible.actualizar(this, enPantalla ? widget.partidoId : null);
  }

  @override
  void didUpdateWidget(CelebraGoles anterior) {
    super.didUpdateWidget(anterior);

    PartidoVisible.actualizar(this, enPantalla ? widget.partidoId : null);

    // Otro partido: lo que se veía deja de valer.
    if (anterior.partidoId != widget.partidoId) {
      _favorVisto = widget.golesFavor;
      _contraVisto = widget.golesContra;
      _cerrar();
      return;
    }

    final cambio = compararMarcador(
      favorAntes: _favorVisto,
      contraAntes: _contraVisto,
      favor: widget.golesFavor,
      contra: widget.golesContra,
    );

    _favorVisto = widget.golesFavor;
    _contraVisto = widget.golesContra;

    // Con otra pantalla encima o con la app en segundo plano solo se actualiza lo que se ve.
    if (!enPantalla || widget.partidoId == null) return;

    switch (cambio) {
      case CambioMarcador.golNuestro:
        _celebrarGolNuestro();
      case CambioMarcador.golRival:
        _avisarGolRival();
      case CambioMarcador.ninguno:
      case CambioMarcador.baja:
        break;
    }
  }

  @override
  void dispose() {
    PartidoVisible.actualizar(this, null);
    _cerrar();
    super.dispose();
  }

  /// "2-1" con el local a la izquierda, como se ve en la pantalla.
  String get _marcador {
    final favor = widget.golesFavor ?? 0;
    final contra = widget.golesContra ?? 0;

    return widget.mutxamelEsLocal ? '$favor-$contra' : '$contra-$favor';
  }

  void _celebrarGolNuestro() {
    HapticFeedback.heavyImpact();

    if (MediaQuery.disableAnimationsOf(context)) {
      _mostrar(
        (context) => _AvisoGol(
          clave: 'aviso-gol-nuestro',
          texto: AppLocalizations.of(
            context,
          ).goalOurBanner(_marcador),
          color: const Color(0xFF2E7D32),
          animar: false,
        ),
      );
      return;
    }

    final marcador = _marcador;
    final goleador = widget.goleador;

    _mostrar(
      (context) => _CelebracionGol(
        marcador: marcador,
        goleador: goleador,
        alTocar: _cerrar,
      ),
    );
  }

  void _avisarGolRival() {
    HapticFeedback.lightImpact();

    final marcador = _marcador;
    final dorsal = widget.dorsalRival;
    final animar = !MediaQuery.disableAnimationsOf(context);

    _mostrar((context) {
      final t = AppLocalizations.of(context);
      final texto = dorsal == null
          ? t.goalRivalBanner(marcador)
          : '${t.goalRivalBanner(marcador)} · ${t.fichaDorsal(dorsal.toString())}';

      return _AvisoGol(
        clave: 'aviso-gol-rival',
        texto: texto,
        color: const Color(0xFFC62828),
        animar: animar,
      );
    });
  }

  void _mostrar(WidgetBuilder construir) {
    _cerrar();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);

    if (overlay == null) return;

    final entrada = OverlayEntry(builder: construir);
    _entrada = entrada;

    // Estamos dentro de la actualización del árbol: la capa se toca al terminar el fotograma.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _entrada != entrada) return;

      overlay.insert(entrada);
      _cierre = Timer(widget.duracion, _cerrar);
    });
  }

  void _cerrar() {
    _cierre?.cancel();
    _cierre = null;
    final entrada = _entrada;
    _entrada = null;

    if (entrada != null) {
      if (entrada.mounted) entrada.remove();
      entrada.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// La celebración a pantalla completa: fondo con los colores del club, "¡GOOOL!" grande, el escudo, el marcador y el
/// goleador. Entra con un golpe de escala y se desvanece al aparecer.
class _CelebracionGol extends StatelessWidget {
  final String marcador;
  final String? goleador;
  final VoidCallback alTocar;

  const _CelebracionGol({
    required this.marcador,
    required this.goleador,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Positioned.fill(
      child: GestureDetector(
        key: const ValueKey('celebracion-gol'),
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          builder: (context, valor, hijo) => Opacity(
            opacity: valor.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.6 + 0.4 * valor, child: hijo),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF20B3D5C), Color(0xF2071F30)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t.goalCelebrationTitle,
                          key: const ValueKey('celebracion-titulo'),
                          style: const TextStyle(
                            color: AppColors.dorado,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/images/escudo.png',
                        key: const ValueKey('celebracion-escudo'),
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        marcador,
                        key: const ValueKey('celebracion-marcador'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (goleador != null && goleador!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          goleador!,
                          key: const ValueKey('celebracion-goleador'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El aviso corto de arriba: el gol del rival y, con la animación reducida, también el nuestro.
class _AvisoGol extends StatelessWidget {
  final String clave;
  final String texto;
  final Color color;
  final bool animar;

  const _AvisoGol({
    required this.clave,
    required this.texto,
    required this.color,
    required this.animar,
  });

  @override
  Widget build(BuildContext context) {
    final aviso = Material(
      key: ValueKey(clave),
      color: color,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_soccer, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: animar
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 250),
                  builder: (context, valor, hijo) => Opacity(
                    opacity: valor,
                    child: Transform.translate(
                      offset: Offset(0, -16 * (1 - valor)),
                      child: hijo,
                    ),
                  ),
                  child: aviso,
                )
              : aviso,
        ),
      ),
    );
  }
}
