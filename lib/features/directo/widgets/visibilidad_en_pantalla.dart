import 'package:flutter/widgets.dart';

/// Para los widgets que solo deben reaccionar (animar, vibrar, correr un temporizador) cuando se ven de verdad:
/// con la app en primer plano y sin otra pantalla encima (con una ruta tapándolos, `TickerMode` se desactiva).
///
/// Uso: `class _X extends State<X> with WidgetsBindingObserver, VisibilidadEnPantalla<X>`.
mixin VisibilidadEnPantalla<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  bool _enPrimerPlano = true;
  bool _visible = true;

  /// true si la app está en primer plano y este widget no está tapado por otra pantalla.
  bool get enPantalla => _enPrimerPlano && _visible;

  /// Se llama cuando [enPantalla] puede haber cambiado.
  void alCambiarVisibilidad() {}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final estado = WidgetsBinding.instance.lifecycleState;
    _enPrimerPlano = estado == null || estado == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final antes = enPantalla;
    _visible = TickerMode.valuesOf(context).enabled;

    if (antes != enPantalla) {
      alCambiarVisibilidad();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final antes = enPantalla;
    _enPrimerPlano = state == AppLifecycleState.resumed;

    if (antes != enPantalla) {
      alCambiarVisibilidad();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
