import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/match_model.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final bool mostrarPrimerEquipo;

  const MatchCard({
    super.key,
    required this.match,
    this.mostrarPrimerEquipo = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget tarjeta;

    if (match.estaDescansando) {
      tarjeta = _buildRestCard(context);
    } else if (match.estaJugado) {
      tarjeta = _buildPlayedMatchCard(context);
    } else {
      tarjeta = _buildUpcomingMatchCard(context);
    }

    return _envolverConEtiquetaTipo(context, tarjeta);
  }

  // ============================================================
  // TIPO DE PARTIDO (Liga, Amistoso, Copa, Torneo)
  // ============================================================

  /// Borde de color según el tipo de partido. Null (sin tratamiento
  /// especial) si el tipo es desconocido/no informado.
  ShapeBorder? get _shapeTipo {
    final color = AppColors.colorTipoPartido(match.tipo);

    if (color == null) return null;

    return RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      side: BorderSide(color: color, width: 2),
    );
  }

  /// Superpone una pequeña etiqueta con el tipo de partido (Liga,
  /// Amistoso, Copa, Torneo) en la esquina de la tarjeta, para no
  /// depender solo del color del borde. No se muestra si el tipo
  /// es desconocido/no informado.
  ///
  /// Se coloca en la esquina INFERIOR derecha (y no en la superior,
  /// como en la pestaña "Partidos") porque en "Mis Partidos" esta
  /// misma tarjeta se envuelve, desde fuera, en un botón de editar
  /// superpuesto arriba a la derecha (ver
  /// `_EquipoSeccion._construirTarjetaPartido` en mis_partidos_page.dart);
  /// dejando el globo del tipo abajo se evita que ambos se solapen.
  Widget _envolverConEtiquetaTipo(BuildContext context, Widget tarjeta) {
    final etiqueta = AppColors.etiquetaTipoPartido(match.tipo);
    final color = AppColors.colorTipoPartido(match.tipo);

    if (etiqueta == null || color == null) {
      return tarjeta;
    }

    return Stack(
      children: [
        tarjeta,
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRÓXIMO PARTIDO
  // ============================================================

  Widget _buildUpcomingMatchCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: Column(
        children: [
          _buildHeader(
            mostrarPrimerEquipo
                ? t.matchUpcomingFirstTeam
                : t.matchUpcoming,
            color: AppColors.azul,
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeam(context, match.equipo, isHomeTeam: true),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        t.matchVs,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dorado,
                        ),
                      ),
                    ),

                    _buildTeam(context, match.rival, isHomeTeam: false),
                  ],
                ),

                const SizedBox(height: 20),

                _buildMatchInformation(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÚLTIMO RESULTADO
  // ============================================================

  Widget _buildPlayedMatchCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: Column(
        children: [
          _buildHeader(
            mostrarPrimerEquipo
                ? t.matchLastResultFirstTeam
                : t.matchLastResult,
            color: AppColors.azulOscuro,
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeam(context, match.equipo, isHomeTeam: true),

                    Text(
                      match.resultado ?? '-',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    _buildTeam(context, match.rival, isHomeTeam: false),
                  ],
                ),

                const SizedBox(height: 20),

                // Fecha, hora y campo
                _buildMatchInformation(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIN PARTIDO
  // ============================================================

  Widget _buildRestCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    // El club usa 'DESCANSA' para señalar deliberadamente una jornada
    // de descanso. Si el rival llega vacío es que, sencillamente,
    // no hay ningún partido registrado para ese equipo.
    final descansaExplicitamente =
        match.rival.trim().toUpperCase() == 'DESCANSA';

    final textoCuerpo = descansaExplicitamente
        ? t.matchNoMatchThisRound
        : t.matchTeamHasNoMatch;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: AppColors.dorado,
            child: Text(
              mostrarPrimerEquipo ? t.matchNoMatchFirstTeam : t.matchNoMatch,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/escudo.png',
                  width: 70,
                  height: 85,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 10),

                Text(
                  match.equipo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 6),

                Text(textoCuerpo, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CABECERA
  // ============================================================

  Widget _buildHeader(String title, {required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: color,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ============================================================
  // EQUIPOS
  // ============================================================

  Widget _buildTeam(
    BuildContext context,
    String name, {
    required bool isHomeTeam,
  }) {
    return SizedBox(
      width: 105,
      child: Column(
        children: [
          if (isHomeTeam)
            Image.asset(
              'assets/images/escudo.png',
              width: 58,
              height: 70,
              fit: BoxFit.contain,
            )
          else
            Icon(
              Icons.shield_outlined,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),

          const SizedBox(height: 8),

          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMACIÓN DEL PARTIDO
  // ============================================================

  Widget _buildMatchInformation(BuildContext context) {
    return Column(
      children: [
        if (match.diaFormateado?.isNotEmpty == true)
          _buildInfoRow(
            context,
            Icons.calendar_today_outlined,
            match.diaFormateado!,
          ),

        if (match.hora?.isNotEmpty == true)
          _buildInfoRow(context, Icons.schedule_outlined, match.hora!),

        if (match.campo?.isNotEmpty == true)
          _buildInfoRow(context, Icons.location_on_outlined, match.campo!),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: AppColors.azul),

          const SizedBox(width: 7),

          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
