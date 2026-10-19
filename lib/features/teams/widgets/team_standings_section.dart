import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/standings_model.dart';

/// Clasificación del grupo del equipo. Compacta (Pos, Equipo, PJ, Pts) y, si
/// hay sitio (pantalla ancha o móvil girado), con G/E/P/GF/GC. La fila del
/// Mutxamel se resalta con el color del club. Solo muestra el nombre de los
/// rivales: sus escudos no son nuestros.
class TeamStandingsSection extends StatelessWidget {
  final Future<StandingsModel?> future;

  const TeamStandingsSection({super.key, required this.future});

  /// Ancho disponible a partir del cual se añaden las columnas G/E/P/GF/GC.
  static const double _anchoMinimoCompleta = 460;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return FutureBuilder<StandingsModel?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return _mensaje(t.standingsLoadError);
        }

        final clasificacion = snapshot.data;

        if (clasificacion == null || clasificacion.filas.isEmpty) {
          return _mensaje(t.standingsEmpty);
        }

        return _buildTabla(context, t, clasificacion);
      },
    );
  }

  Widget _mensaje(String texto) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildTabla(
    BuildContext context,
    AppLocalizations t,
    StandingsModel clasificacion,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final completa = constraints.maxWidth >= _anchoMinimoCompleta;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _textoActualizacion(context, t, clasificacion),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (clasificacion.competicion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            clasificacion.competicion,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildCabecera(t, colors, completa),
                Divider(height: 1, color: colors.outlineVariant),
                for (final fila in clasificacion.filas) ...[
                  _buildFila(fila, colors, completa),
                  Divider(height: 1, color: colors.outlineVariant),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _textoActualizacion(
    BuildContext context,
    AppLocalizations t,
    StandingsModel clasificacion,
  ) {
    final fecha = clasificacion.fechaImportacion;
    final jornada = clasificacion.jornada;

    if (fecha == null) {
      return '';
    }

    final fechaTexto = DateFormat(
      'dd/MM',
      Localizations.localeOf(context).toString(),
    ).format(fecha);

    return jornada == null
        ? t.standingsUpdatedNoRound(fechaTexto)
        : t.standingsUpdated(jornada, fechaTexto);
  }

  Widget _buildCabecera(AppLocalizations t, ColorScheme colors, bool completa) {
    final estilo = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: colors.onSurfaceVariant,
    );

    return _fila(
      completa: completa,
      pos: Text(t.standingsColPos, style: estilo),
      equipo: Text(t.standingsColTeam, style: estilo),
      pj: Text(t.standingsColPlayed, style: estilo),
      pg: Text(t.standingsColWon, style: estilo),
      pe: Text(t.standingsColDrawn, style: estilo),
      pp: Text(t.standingsColLost, style: estilo),
      gf: Text(t.standingsColGoalsFor, style: estilo),
      gc: Text(t.standingsColGoalsAgainst, style: estilo),
      puntos: Text(t.standingsColPoints, style: estilo),
      colors: colors,
      resaltada: false,
    );
  }

  Widget _buildFila(StandingsRowModel f, ColorScheme colors, bool completa) {
    final estilo = TextStyle(
      fontSize: 14,
      fontWeight: f.esNuestro ? FontWeight.bold : FontWeight.normal,
      color: colors.onSurface,
    );

    return _fila(
      completa: completa,
      pos: Text('${f.posicion}', style: estilo),
      equipo: Text(
        f.equipo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: estilo,
      ),
      pj: Text('${f.pj}', style: estilo),
      pg: Text('${f.pg}', style: estilo),
      pe: Text('${f.pe}', style: estilo),
      pp: Text('${f.pp}', style: estilo),
      gf: Text('${f.gf}', style: estilo),
      gc: Text('${f.gc}', style: estilo),
      puntos: Text(
        '${f.puntos}',
        style: estilo.copyWith(fontWeight: FontWeight.bold),
      ),
      colors: colors,
      resaltada: f.esNuestro,
    );
  }

  Widget _fila({
    required bool completa,
    required Widget pos,
    required Widget equipo,
    required Widget pj,
    required Widget pg,
    required Widget pe,
    required Widget pp,
    required Widget gf,
    required Widget gc,
    required Widget puntos,
    required ColorScheme colors,
    required bool resaltada,
  }) {
    Widget celda(Widget hijo, double ancho) => SizedBox(
      width: ancho,
      child: Center(child: hijo),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        // Color del club (azul en claro, su variante clara en oscuro).
        color: resaltada ? colors.primary.withValues(alpha: 0.16) : null,
        border: resaltada
            ? Border(left: BorderSide(color: colors.primary, width: 3))
            : null,
      ),
      child: Row(
        children: [
          celda(pos, 30),
          const SizedBox(width: 6),
          Expanded(child: equipo),
          celda(pj, 32),
          if (completa) ...[
            celda(pg, 30),
            celda(pe, 30),
            celda(pp, 30),
            celda(gf, 36),
            celda(gc, 36),
          ],
          celda(puntos, 38),
        ],
      ),
    );
  }
}
