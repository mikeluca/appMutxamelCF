import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/backend_date.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../model/entrenamiento_model.dart';

/// Tarjeta de un entrenamiento. Con [destacado] se resalta como el próximo
/// entrenamiento del equipo (borde de color y etiqueta).
class EntrenamientoCard extends StatelessWidget {
  final EntrenamientoModel entrenamiento;
  final bool destacado;
  final VoidCallback onTap;

  const EntrenamientoCard({
    super.key,
    required this.entrenamiento,
    required this.onTap,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: destacado ? 4 : 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: destacado
            ? const BorderSide(color: AppColors.azul, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (destacado) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.azul,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t.trainingsNextBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: destacado ? AppColors.azul : AppColors.azulOscuro,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fact_check,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatearFecha(entrenamiento.fecha, t),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.playersCountSimple(
                            entrenamiento.asistencias.length,
                          ),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatearFecha(String fecha, AppLocalizations t) {
    final date = parseFechaTextoBackend(fecha);

    if (date == null) {
      return fecha;
    }

    return formatearFechaConDiaSemana(date, t);
  }
}
