import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/cuenta_atras.dart';
import 'visibilidad_en_pantalla.dart';

/// Crea el temporizador periódico de la cuenta atrás; los tests lo sustituyen para ver cuándo corre y cuándo se para.
typedef CrearTemporizadorCuentaAtras =
    Timer Function(Duration intervalo, void Function(Timer) alTic);

/// "Empieza en 2 d 4 h" / "Empieza en 3 h 15 min" / "Calentando…" / "A punto de empezar" para un partido próximo,
/// repintado cada minuto con un temporizador local. El temporizador solo corre con la app en primer plano y el
/// widget a la vista, y se para al llegar a "A punto de empezar". Sin hora válida no pinta nada (la pantalla se queda
/// solo con el día, como antes).
class CuentaAtrasTexto extends StatefulWidget {
  final DateTime? dia;
  final String? hora;
  final TextStyle? estilo;

  /// Solo para tests: la hora del móvil y el temporizador.
  final DateTime Function()? ahora;
  final CrearTemporizadorCuentaAtras? crearTemporizador;

  const CuentaAtrasTexto({
    super.key,
    required this.dia,
    required this.hora,
    this.estilo,
    this.ahora,
    this.crearTemporizador,
  });

  /// true si hay día y hora válidos para contar atrás.
  static bool aplica(DateTime? dia, String? hora) =>
      HoraMadrid.instante(dia, hora) != null;

  @override
  State<CuentaAtrasTexto> createState() => _CuentaAtrasTextoState();
}

class _CuentaAtrasTextoState extends State<CuentaAtrasTexto>
    with WidgetsBindingObserver, VisibilidadEnPantalla<CuentaAtrasTexto> {
  Timer? _temporizador;

  DateTime _ahora() => (widget.ahora ?? DateTime.now)().toUtc();

  DateTime? get _inicio => HoraMadrid.instante(widget.dia, widget.hora);

  CuentaAtras? _cuenta() {
    final inicio = _inicio;

    return inicio == null ? null : CuentaAtras.calcular(inicio, _ahora());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  @override
  void didUpdateWidget(CuentaAtrasTexto anterior) {
    super.didUpdateWidget(anterior);
    _sincronizar();
  }

  @override
  void alCambiarVisibilidad() {
    // Al volver se repinta con la hora de ahora.
    if (enPantalla && mounted) setState(() {});

    _sincronizar();
  }

  @override
  void dispose() {
    _parar();
    super.dispose();
  }

  /// Corre solo mientras falte algo que contar, con la app en primer plano y a la vista.
  void _sincronizar() {
    final cuenta = _cuenta();
    final debeCorrer =
        cuenta != null &&
        cuenta.fase != FaseCuentaAtras.aPuntoDeEmpezar &&
        enPantalla;

    if (debeCorrer && _temporizador == null) {
      final crear = widget.crearTemporizador ?? Timer.periodic;

      _temporizador = crear(const Duration(minutes: 1), (_) {
        if (!mounted) return;

        setState(() {});

        if (_cuenta()?.fase == FaseCuentaAtras.aPuntoDeEmpezar) _parar();
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
    final cuenta = _cuenta();

    if (cuenta == null) return const SizedBox.shrink();

    final t = AppLocalizations.of(context);

    final texto = switch (cuenta.fase) {
      FaseCuentaAtras.dias => t.countdownDaysHours(cuenta.dias, cuenta.horas),
      FaseCuentaAtras.horas => t.countdownHoursMinutes(
        cuenta.horas,
        cuenta.minutos,
      ),
      FaseCuentaAtras.minutos => t.countdownMinutes(cuenta.minutos),
      FaseCuentaAtras.calentando => t.countdownWarmingUp,
      FaseCuentaAtras.aPuntoDeEmpezar => t.countdownAboutToStart,
    };

    return Text(
      texto,
      key: const ValueKey('cuenta-atras'),
      textAlign: TextAlign.center,
      style: widget.estilo,
    );
  }
}
