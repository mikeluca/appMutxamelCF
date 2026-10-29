import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/continuidad_model.dart';

/// "¿Seguirá X en la temporada Y?" con Sí / No / Aún no lo sé. Muestra
/// la respuesta actual y su fecha; se puede cambiar hasta el cierre de la
/// temporada.
class ContinuidadCard extends StatelessWidget {
  final ContinuidadJugadorModel jugador;

  /// true mientras se guarda una respuesta de este jugador.
  final bool guardando;

  /// Se llama con SIGUE, NO_SIGUE o DUDA.
  final ValueChanged<String> onResponder;

  const ContinuidadCard({
    super.key,
    required this.jugador,
    required this.onResponder,
    this.guardando = false,
  });

  static String etiquetaDeRespuesta(AppLocalizations t, String respuesta) {
    return switch (respuesta) {
      respuestaSigue => t.continuityYes,
      respuestaNoSigue => t.continuityNo,
      respuestaDuda => t.continuityMaybe,
      _ => t.continuityNotAnswered,
    };
  }

  static String _fecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final fecha = jugador.fechaRespuesta;

    return Card(
      key: ValueKey('continuidad-${jugador.jugadorId}'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.continuityQuestion(jugador.nombre, jugador.temporada),
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _boton(respuestaSigue, t.continuityYes),
                _boton(respuestaNoSigue, t.continuityNo),
                _boton(respuestaDuda, t.continuityMaybe),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              key: const ValueKey('continuidad-estado'),
              jugador.contestada
                  ? (fecha == null
                        ? t.continuityAnswered(
                            etiquetaDeRespuesta(t, jugador.respuesta),
                          )
                        : t.continuityAnsweredOn(
                            etiquetaDeRespuesta(t, jugador.respuesta),
                            _fecha(fecha),
                          ))
                  : t.continuityNotAnswered,
              style: TextStyle(
                color: jugador.contestada
                    ? colors.primary
                    : colors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.continuityChangeHint,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boton(String respuesta, String etiqueta) {
    final seleccionada = jugador.respuesta == respuesta;

    return ChoiceChip(
      key: ValueKey('continuidad-$respuesta'),
      label: Text(etiqueta),
      selected: seleccionada,
      selectedColor: AppColors.azul.withValues(alpha: 0.2),
      onSelected: guardando || seleccionada
          ? null
          : (_) => onResponder(respuesta),
    );
  }
}
