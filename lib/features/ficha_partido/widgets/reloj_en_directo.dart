import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/reloj_directo.dart';
import 'ficha_cabecera.dart';

/// Crea el temporizador periódico del reloj; los tests lo sustituyen para comprobar cuándo corre y cuándo se para.
typedef CrearTemporizador =
    Timer Function(Duration intervalo, void Function(Timer) alTic);

/// El reloj del partido en directo: "MM:ss" con un punto rojo parpadeante, repintado cada segundo con un
/// temporizador local (no pide nada al servidor). En el descanso pone "Descanso" y no hay temporizador.
///
/// El temporizador solo corre con la app en primer plano y el widget a la vista (si otra pantalla lo tapa, o
/// al salir, se para) y se recalcula siempre desde [reloj] y la hora del móvil: al volver no hay error acumulado.
class RelojEnDirecto extends StatefulWidget {
  final RelojDirecto reloj;

  /// Solo para tests: la hora del móvil y el temporizador.
  final DateTime Function()? ahora;
  final CrearTemporizador? crearTemporizador;

  final TextStyle? estilo;
  final bool conPunto;

  const RelojEnDirecto({
    super.key,
    required this.reloj,
    this.ahora,
    this.crearTemporizador,
    this.estilo,
    this.conPunto = true,
  });

  @override
  State<RelojEnDirecto> createState() => _RelojEnDirectoState();
}

class _RelojEnDirectoState extends State<RelojEnDirecto>
    with WidgetsBindingObserver {
  Timer? _temporizador;
  bool _enPrimerPlano = true;
  bool _visible = true;

  DateTime _ahora() => (widget.ahora ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Con otra pantalla encima (o fuera de la vista) los ticks se desactivan.
    _visible = TickerMode.valuesOf(context).enabled;
    _sincronizar();
  }

  @override
  void didUpdateWidget(RelojEnDirecto anterior) {
    super.didUpdateWidget(anterior);
    _sincronizar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _parar();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _enPrimerPlano = state == AppLifecycleState.resumed;

    // Al volver se repinta con la hora de ahora (se calcula de los datos, no se acumula).
    if (_enPrimerPlano && mounted) {
      setState(() {});
    }

    _sincronizar();
  }

  /// Corre solo con tiempo que contar (no en el descanso), en primer plano y a la vista.
  void _sincronizar() {
    final debeCorrer = !widget.reloj.enDescanso && _enPrimerPlano && _visible;

    if (debeCorrer && _temporizador == null) {
      final crear = widget.crearTemporizador ?? Timer.periodic;

      _temporizador = crear(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!debeCorrer) {
      _parar();
    }
  }

  void _parar() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final estilo =
        widget.estilo ??
        DefaultTextStyle.of(
          context,
        ).style.copyWith(fontWeight: FontWeight.w600);

    if (widget.reloj.enDescanso) {
      return Text(
        t.fichaStatusHalftime,
        key: const ValueKey('reloj-descanso'),
        style: estilo,
      );
    }

    return Row(
      key: const ValueKey('reloj-en-directo'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.conPunto) ...[
          const PuntoEnDirecto(),
          const SizedBox(width: 6),
        ],
        Text(
          widget.reloj.texto(_ahora()) ?? '',
          key: const ValueKey('reloj-texto'),
          style: estilo.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
