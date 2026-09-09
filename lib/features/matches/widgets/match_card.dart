import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    if (match.estaDescansando) {
      return _buildRestCard(context);
    }

    if (match.estaJugado) {
      return _buildPlayedMatchCard(context);
    }

    return _buildUpcomingMatchCard(context);
  }

  // ============================================================
  // PRÓXIMO PARTIDO
  // ============================================================

  Widget _buildUpcomingMatchCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(
            mostrarPrimerEquipo
                ? 'PRÓXIMO PARTIDO PRIMER EQUIPO'
                : 'PRÓXIMO PARTIDO',
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

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'VS',
                        style: TextStyle(
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(
            mostrarPrimerEquipo
                ? 'ÚLTIMO RESULTADO PRIMER EQUIPO'
                : 'ÚLTIMO RESULTADO',
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: AppColors.dorado,
            child: Text(
              mostrarPrimerEquipo ? 'SIN PARTIDO PRIMER EQUIPO' : 'SIN PARTIDO',
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

                const Text(
                  'No hay partido esta jornada',
                  style: TextStyle(fontSize: 15),
                ),
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
