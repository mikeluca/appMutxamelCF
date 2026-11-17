import 'package:flutter/material.dart';

import '../../../core/utils/anadir_al_calendario.dart';
import '../../../core/utils/evento_partido.dart';
import '../../../l10n/gen/app_localizations.dart';

/// "Añadir a mi calendario" de un partido que todavía no se ha jugado. [construir] monta el evento al pulsar (así, en
/// Mis partidos, puede pedir antes la convocatoria para las notas); si devuelve null no se añade nada.
class BotonAnadirCalendario extends StatefulWidget {
  final Future<EventoCalendario?> Function(AppLocalizations t) construir;

  const BotonAnadirCalendario({super.key, required this.construir});

  @override
  State<BotonAnadirCalendario> createState() => _BotonAnadirCalendarioState();
}

class _BotonAnadirCalendarioState extends State<BotonAnadirCalendario> {
  bool _ocupado = false;

  Future<void> _pulsar() async {
    if (_ocupado) return;

    final t = AppLocalizations.of(context);
    final contexto = context;

    setState(() => _ocupado = true);

    try {
      final evento = await widget.construir(t);

      if (evento != null && contexto.mounted) {
        await AnadirAlCalendario.anadir(contexto, evento);
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return TextButton.icon(
      key: const ValueKey('anadir-calendario'),
      onPressed: _ocupado ? null : _pulsar,
      icon: const Icon(Icons.event_available_outlined, size: 18),
      label: Text(t.calendarAddButton),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
