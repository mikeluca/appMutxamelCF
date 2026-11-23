import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/cuenta_atras.dart';
import 'cuenta_atras_texto.dart' show CrearTemporizadorCuentaAtras;
import 'visibilidad_en_pantalla.dart';

/// La cuenta atrás de la tarjeta de Inicio en bloques: cuatro números grandes con su etiqueta debajo (Días, Horas,
/// Minutos, Segundos), con los segundos bajando cada segundo. Siempre con dos cifras salvo los días; con menos de 24 h
/// se oculta el bloque de Días y quedan tres.
///
/// Desde 30 minutos antes (y hasta que el partido empiece) no hay números: "Calentando…" y, pasada la hora sin empezar,
/// "A punto de empezar", como en [CuentaAtrasTexto]. Nunca números negativos. Un solo temporizador de 1 segundo, que
/// solo corre con la app en primer plano y el widget a la vista y se recalcula al volver (la hora se calcula siempre
/// de la hora de inicio, no se acumula). Sin hora válida no pinta nada.
class CuentaAtrasBloques extends StatefulWidget {
  final DateTime? dia;
  final String? hora;

  /// Solo para tests: la hora del móvil y el temporizador.
  final DateTime Function()? ahora;
  final CrearTemporizadorCuentaAtras? crearTemporizador;

  const CuentaAtrasBloques({
    super.key,
    required this.dia,
    required this.hora,
    this.ahora,
    this.crearTemporizador,
  });

  @override
  State<CuentaAtrasBloques> createState() => _CuentaAtrasBloquesState();
}

class _CuentaAtrasBloquesState extends State<CuentaAtrasBloques>
    with WidgetsBindingObserver, VisibilidadEnPantalla<CuentaAtrasBloques> {
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
  void didUpdateWidget(CuentaAtrasBloques anterior) {
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

  /// Corre mientras falte algo que contar (también en "Calentando…", para pasar a "A punto de empezar"), con la app en
  /// primer plano y a la vista.
  void _sincronizar() {
    final cuenta = _cuenta();
    final debeCorrer =
        cuenta != null &&
        cuenta.fase != FaseCuentaAtras.aPuntoDeEmpezar &&
        enPantalla;

    if (debeCorrer && _temporizador == null) {
      final crear = widget.crearTemporizador ?? Timer.periodic;

      _temporizador = crear(const Duration(seconds: 1), (_) {
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

    if (!cuenta.conNumeros) {
      return Text(
        cuenta.fase == FaseCuentaAtras.calentando
            ? t.countdownWarmingUp
            : t.countdownAboutToStart,
        key: const ValueKey('cuenta-atras'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    // Con menos de 24 horas no hay días: tres bloques.
    final conDias = cuenta.fase == FaseCuentaAtras.dias;

    String dos(int n) => n.toString().padLeft(2, '0');

    final bloques = <(String, String, String)>[
      if (conDias) ('dias', '${cuenta.dias}', t.countdownBlockDays),
      ('horas', dos(cuenta.horas), t.countdownBlockHours),
      ('minutos', dos(cuenta.minutos), t.countdownBlockMinutes),
      ('segundos', dos(cuenta.segundos), t.countdownBlockSeconds),
    ];

    return Semantics(
      key: const ValueKey('cuenta-atras'),
      label: switch (cuenta.fase) {
        FaseCuentaAtras.dias => t.countdownDaysHours(cuenta.dias, cuenta.horas),
        FaseCuentaAtras.horas => t.countdownHoursMinutes(
          cuenta.horas,
          cuenta.minutos,
        ),
        _ => t.countdownMinutes(cuenta.minutos),
      },
      excludeSemantics: true,
      child: Row(
        key: const ValueKey('cuenta-atras-bloques'),
        children: [
          for (var i = 0; i < bloques.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _Bloque(
                key: ValueKey('bloque-${bloques[i].$1}'),
                numero: bloques[i].$2,
                etiqueta: bloques[i].$3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un bloque: el número grande sobre un fondo suave y su etiqueta debajo. Con letra grande o en un iPhone pequeño, el
/// número y la etiqueta se encogen para caber (FittedBox), nunca se cortan.
class _Bloque extends StatelessWidget {
  final String numero;
  final String etiqueta;

  const _Bloque({super.key, required this.numero, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: colores.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              numero,
              key: const ValueKey('bloque-numero'),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colores.onPrimaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            etiqueta,
            maxLines: 1,
            style: TextStyle(fontSize: 12, color: colores.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
