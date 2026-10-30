import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../invitados/services/invitados_service.dart';
import '../services/justificacion_partido_service.dart';

/// Diálogo para justificar la ausencia de un jugador a un partido (motivo obligatorio,
/// de 3 a 500 caracteres). Con [invitado] el jugador juega ese partido como invitado de
/// otro equipo: se avisa solo al entrenador que lo convocó (POST
/// /app/partidos/{id}/invitados/{jugadorId}/desestimar) en lugar de al cuerpo técnico.
///
/// Se cierra con true si se ha guardado.
class JustificarAusenciaPartidoDialog extends StatefulWidget {
  final JustificacionPartidoService servicio;
  final InvitadosService? invitadosService;
  final int partidoId;
  final int jugadorId;

  /// El jugador es un invitado de otro equipo en este partido.
  final bool invitado;

  /// El motivo ya guardado si se está editando; null si es una justificación nueva.
  final String? motivoActual;

  const JustificarAusenciaPartidoDialog({
    super.key,
    required this.servicio,
    this.invitadosService,
    required this.partidoId,
    required this.jugadorId,
    this.invitado = false,
    this.motivoActual,
  });

  @override
  State<JustificarAusenciaPartidoDialog> createState() =>
      _JustificarAusenciaPartidoDialogState();
}

class _JustificarAusenciaPartidoDialogState
    extends State<JustificarAusenciaPartidoDialog> {
  late final TextEditingController _motivoController = TextEditingController(
    text: widget.motivoActual ?? '',
  );

  bool _enviando = false;
  String? _error;

  bool get _editando => widget.motivoActual != null;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final motivo = _motivoController.text.trim();

    // El backend exige de 3 a 500 caracteres; se avisa antes de enviar.
    if (motivo.length < 3) {
      setState(() => _error = _t.matchAbsenceReasonRequired);
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      if (widget.invitado) {
        await (widget.invitadosService ?? InvitadosService()).desestimar(
          partidoId: widget.partidoId,
          jugadorId: widget.jugadorId,
          motivo: motivo,
        );
      } else {
        await widget.servicio.justificar(
          partidoId: widget.partidoId,
          jugadorId: widget.jugadorId,
          motivo: motivo,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      // Sin e.toString(): un mensaje genérico, no la excepción en pantalla.
      setState(() {
        _error = _t.matchAbsenceError;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.invitado
            ? _t.invCannotGo
            : (_editando
                  ? _t.matchAbsenceEditTitle
                  : _t.matchAbsenceJustifyTitle),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.invitado ? _t.invCannotGoHint : _t.matchAbsenceHint),
            const SizedBox(height: 14),
            TextField(
              controller: _motivoController,
              enabled: !_enviando,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: _t.matchAbsenceReasonLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: Text(_t.cancel),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_t.calendarJustifyAbsenceSubmit),
        ),
      ],
    );
  }
}
