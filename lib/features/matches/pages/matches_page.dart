import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final MatchService _matchService = MatchService();

  late Future<List<MatchModel>> _matchesFuture;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();

    _matchesFuture = _matchService.obtenerResultados();
  }

  Future<void> _recargar() async {
    setState(() {
      _matchesFuture = _matchService.obtenerResultados();
    });

    await _matchesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Partidos')),
      body: FutureBuilder<List<MatchModel>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          final partidos = snapshot.data ?? [];

          if (partidos.isEmpty) {
            return const Center(child: Text('No hay partidos disponibles.'));
          }

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'CALENDARIO',
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Partidos y resultados de nuestros equipos',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 20),

                ...partidos.map((partido) => _MatchCard(partido: partido)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: _colors.primary),

            const SizedBox(height: 16),

            const Text(
              'No se han podido cargar los partidos.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _matchesFuture = _matchService.obtenerResultados();
                });
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel partido;

  const _MatchCard({required this.partido});

  ColorScheme _colors(BuildContext context) => Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    if (partido.estaDescansando) {
      return _buildDescansoCard(context);
    }

    if (partido.estaJugado) {
      return _buildResultadoCard(context);
    }

    return _buildProximoCard(context);
  }

  Widget _buildProximoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, 'PRÓXIMO PARTIDO', Icons.sports_soccer),

            const SizedBox(height: 16),

            _buildEquipos(context),

            const SizedBox(height: 16),

            if (partido.dia != null)
              _buildInfoRow(
                context,
                Icons.calendar_today_outlined,
                _formatearFecha(partido.dia!),
              ),

            if (partido.hora != null && partido.hora!.isNotEmpty)
              _buildInfoRow(context, Icons.access_time, partido.hora!),

            if (partido.campo != null && partido.campo!.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.location_on_outlined,
                partido.campo!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context, 'RESULTADO', Icons.sports_soccer),

            const SizedBox(height: 16),

            Text(
              partido.equipo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _colors(context).onSurface,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              partido.resultado ?? '',
              style: const TextStyle(
                color: AppColors.azul,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              partido.rival,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            if (partido.dia != null) ...[
              const SizedBox(height: 12),
              Text(
                _formatearFecha(partido.dia!),
                style: TextStyle(color: _colors(context).onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescansoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.free_breakfast_outlined,
              color: AppColors.azulOscuro,
              size: 32,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partido.equipo,
                    style: TextStyle(
                      color: _colors(context).onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Descansa esta jornada',
                    style: TextStyle(color: _colors(context).onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String texto, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: AppColors.dorado),

        const SizedBox(width: 8),

        Text(
          texto,
          style: TextStyle(
            color: _colors(context).onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),

        const Spacer(),

        Text(
          partido.categoria,
          style: TextStyle(
            color: _colors(context).onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipos(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            partido.equipo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _colors(context).onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'VS',
            style: TextStyle(
              color: AppColors.dorado,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        Expanded(
          child: Text(
            partido.rival,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _colors(context).onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.azul),

          const SizedBox(width: 8),

          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }
}
