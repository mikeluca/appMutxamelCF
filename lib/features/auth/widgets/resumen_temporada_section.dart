import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/resumen_temporada_model.dart';

/// Estadísticas de la temporada en la ficha del jugador: tarjetas pequeñas
/// (goles, asistencias, tarjetas, convocatorias), asistencia a entrenamientos
/// y respuestas a convocatorias. Sin temporada activa o sin datos, dice que
/// todavía no hay datos.
class ResumenTemporadaSection extends StatelessWidget {
  /// null si no se pudo cargar o no hay temporada.
  final ResumenTemporadaModel? resumen;

  /// true mientras el resumen todavía se está pidiendo: en su lugar se pinta un
  /// indicador pequeño y no el "sin datos" (que sería falso).
  final bool cargando;

  const ResumenTemporadaSection({
    super.key,
    required this.resumen,
    this.cargando = false,
  });

  /// "Entrenamientos 18/20 · 3 goles" para la tarjeta de cada hijo; null si no
  /// hay datos que resumir.
  static String? resumenCorto(AppLocalizations t, ResumenTemporadaModel? r) {
    if (r == null || !r.hayDatos) {
      return null;
    }

    final partes = [
      if (r.entrenamientosTotal > 0)
        t.seasonShortTrainings(
          r.entrenamientosAsistidos,
          r.entrenamientosTotal,
        ),
      t.seasonShortGoals(r.goles),
    ];

    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final r = resumen;

    final titulo = r?.temporada != null
        ? t.seasonTitle(r!.temporada!)
        : t.seasonTitleNoName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (cargando)
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              key: ValueKey('resumen-temporada-cargando'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (r == null || !r.hayDatos)
          Text(
            t.seasonNoData,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          )
        else ...[
          _tarjetas(context, t, r),
          const SizedBox(height: 18),
          _bloque(
            context,
            t.seasonTrainingsTitle,
            r.porcentaje == null
                ? [t.seasonTrainingsNone]
                : [
                    t.seasonTrainingsLine(
                      r.entrenamientosAsistidos,
                      r.entrenamientosTotal,
                      r.porcentaje!,
                    ),
                    '${t.seasonAbsences(r.faltas)} · '
                        '${t.seasonExcused(r.justificadas)}',
                  ],
          ),
          const SizedBox(height: 14),
          _bloque(context, t.seasonCallupsTitle, [
            t.seasonCallupsLine(
              r.convocatoriasVa,
              r.convocatoriasNoPuede,
              r.convocatoriasSinResponder,
            ),
          ]),
        ],
      ],
    );
  }

  Widget _tarjetas(
    BuildContext context,
    AppLocalizations t,
    ResumenTemporadaModel r,
  ) {
    final datos = [
      (t.seasonGoals, r.goles),
      (t.seasonAssists, r.asistencias),
      (t.seasonYellows, r.amarillas),
      (t.seasonReds, r.rojas),
      (t.seasonCallupsCard, r.convocado),
    ];

    return Row(
      children: [
        for (var i = 0; i < datos.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _tarjeta(context, datos[i].$1, datos[i].$2)),
        ],
      ],
    );
  }

  Widget _tarjeta(BuildContext context, String etiqueta, int valor) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(
              color: colors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              etiqueta,
              maxLines: 1,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloque(BuildContext context, String titulo, List<String> lineas) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < lineas.length; i++)
          Text(
            lineas[i],
            style: TextStyle(
              color: i == 0 ? colors.onSurface : colors.onSurfaceVariant,
              fontSize: i == 0 ? 15 : 13,
              fontWeight: i == 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
      ],
    );
  }
}
