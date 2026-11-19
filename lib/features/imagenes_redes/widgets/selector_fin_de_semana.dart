import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../utils/fin_de_semana_imagenes.dart';

/// Las flechas anterior/siguiente con el fin de semana (viernes - domingo), como en el panel Fin de semana.
class SelectorFinDeSemana extends StatelessWidget {
  /// El viernes del fin de semana que se está viendo.
  final DateTime viernes;
  final ValueChanged<DateTime> alCambiar;

  const SelectorFinDeSemana({
    super.key,
    required this.viernes,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final domingo = desplazarDias(viernes, 2);

    return Row(
      children: [
        IconButton(
          key: const ValueKey('selector-anterior'),
          tooltip: t.weekendPrevious,
          onPressed: () => alCambiar(desplazarSemanas(viernes, -1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${fechaCortaImagenes(viernes)} - ${fechaCortaImagenes(domingo)}',
            key: const ValueKey('selector-fecha'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('selector-siguiente'),
          tooltip: t.weekendNext,
          onPressed: () => alCambiar(desplazarSemanas(viernes, 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
