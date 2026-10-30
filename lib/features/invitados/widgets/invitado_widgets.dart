import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/invitacion_model.dart';

/// El texto del estado de una invitación, tal como lo ve el entrenador que convocó
/// (null si está autorizada: sale como un convocado normal).
String? textoEstadoInvitacion(AppLocalizations t, EstadoInvitacion? estado) {
  return switch (estado) {
    EstadoInvitacion.pendienteCoordinacion => t.invStatePendingCoordination,
    EstadoInvitacion.pendienteEntrenador => t.invStatePendingCoach,
    EstadoInvitacion.rechazado => t.invStateRejected,
    EstadoInvitacion.autorizado || null => null,
  };
}

/// La etiqueta "Invitado · equipo de origen" (o solo "Invitado" sin equipo). Con
/// [texto] se pinta ese texto en lugar del de siempre.
class EtiquetaInvitado extends StatelessWidget {
  final String equipoOrigen;
  final String? texto;

  const EtiquetaInvitado({super.key, this.equipoOrigen = '', this.texto});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tertiary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto ??
            (equipoOrigen.trim().isEmpty
                ? t.invGuestBadge
                : t.invGuestTag(equipoOrigen)),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colors.tertiary,
        ),
      ),
    );
  }
}

/// El diálogo del 409 de las invitaciones, con el nombre del jugador y el equipo.
/// El texto sale del [ConflictoInvitacion.codigo], no del mensaje del servidor.
Future<void> mostrarConflictoInvitacion(
  BuildContext context,
  ConflictoInvitacion conflicto, {
  required String jugador,
}) {
  final t = AppLocalizations.of(context);

  final texto = conflicto.codigo == codigoJugadorInvitadoEseDia
      ? t.invConflictOwnPlayer(jugador, conflicto.equipoDestino)
      : t.invConflictAlreadyGuest(jugador, conflicto.equipoDestino);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('dialogo-conflicto-invitacion'),
      icon: const Icon(Icons.event_busy_outlined, color: Colors.redAccent),
      title: Text(t.invConflictTitle),
      content: Text(texto),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.invConflictOk),
        ),
      ],
    ),
  );
}
