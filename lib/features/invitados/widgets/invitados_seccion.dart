import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/invitacion_model.dart';
import 'invitado_widgets.dart';

/// "Jugadores de otros equipos" del formulario de convocatoria, debajo de los
/// jugadores del equipo: lo elegido (con su estado si ya estaba en la
/// convocatoria), el contador y el botón para añadir más.
class InvitadosSeccion extends StatelessWidget {
  final List<InvitadoElegido> invitados;

  /// Hay partido elegido: sin él no se pueden pedir los equipos permitidos.
  final bool hayPartido;
  final VoidCallback onAnadir;
  final void Function(InvitadoElegido invitado) onQuitar;

  const InvitadosSeccion({
    super.key,
    required this.invitados,
    required this.hayPartido,
    required this.onAnadir,
    required this.onQuitar,
  });

  int get _cuenta => invitados.where((i) => i.cuenta).length;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final completo = _cuenta >= maximoInvitados;

    return Column(
      key: const ValueKey('invitados-seccion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.invGuestsTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
            Text(
              t.invGuestsCounter(_cuenta, maximoInvitados),
              key: const ValueKey('invitados-seccion-contador'),
              style: TextStyle(
                fontSize: 12,
                color: completo ? colors.error : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          t.invGuestsHint,
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ...invitados.map((i) => _construirInvitado(context, i)),
        OutlinedButton.icon(
          key: const ValueKey('invitados-anadir'),
          onPressed: hayPartido && !completo ? onAnadir : null,
          icon: const Icon(Icons.group_add_outlined),
          label: Text(t.invAddButton),
        ),
        if (!hayPartido) ...[
          const SizedBox(height: 6),
          Text(
            t.invAddNeedsMatch,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ] else if (completo) ...[
          const SizedBox(height: 6),
          Text(
            t.invMaxReached(maximoInvitados),
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _construirInvitado(BuildContext context, InvitadoElegido invitado) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final estado =
        textoEstadoInvitacion(t, invitado.estado) ??
        (invitado.estado == null ? t.invStateToSend : null);

    final rechazado = invitado.rechazado;
    final color = rechazado ? Colors.redAccent : colors.onSurfaceVariant;

    return Card(
      key: ValueKey('invitado-${invitado.jugadorId}'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: rechazado
          ? Colors.redAccent.withValues(alpha: 0.08)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: rechazado ? Colors.redAccent : colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitado.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  EtiquetaInvitado(equipoOrigen: invitado.equipoOrigen),
                  if (estado != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      estado,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: rechazado ? FontWeight.bold : null,
                        color: color,
                      ),
                    ),
                  ],
                  if (rechazado &&
                      invitado.motivoRechazo?.trim().isNotEmpty == true)
                    Text(
                      t.callupReasonShown(invitado.motivoRechazo!),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (invitado.ausenciaJustificada) ...[
                    const SizedBox(height: 3),
                    Text(
                      t.matchAbsenceBadge,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    if (invitado.motivoAusencia?.trim().isNotEmpty == true)
                      Text(
                        t.callupReasonShown(invitado.motivoAusencia!),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      t.invGuestAbsentHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              key: ValueKey('invitado-quitar-${invitado.jugadorId}'),
              tooltip: t.invRemoveGuest,
              onPressed: () => onQuitar(invitado),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
