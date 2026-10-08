import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../services/comunicacion_service.dart';

/// Pide un motivo opcional y envía el reporte del mensaje al club.
/// Muestra el resultado en un SnackBar.
Future<void> mostrarDialogoReportarMensaje(
  BuildContext context, {
  required int comunicacionId,
}) async {
  final t = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final motivoController = TextEditingController();

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.reportDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.reportDialogBody),
          const SizedBox(height: 16),
          TextField(
            controller: motivoController,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: t.reportReasonHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t.reportSend),
        ),
      ],
    ),
  );

  final motivo = motivoController.text;
  motivoController.dispose();

  if (confirmado != true) return;

  try {
    await ComunicacionService.reportarComunicacion(
      comunicacionId,
      motivo: motivo,
    );

    messenger.showSnackBar(SnackBar(content: Text(t.reportSent)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(t.reportError)));
  }
}
