import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/team_model.dart';
import '../services/team_services.dart';
import 'team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final TeamService _teamService = TeamService();

  late Future<List<TeamModel>> _futureTeams;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();

    _futureTeams = _teamService.obtenerEquipos();
  }

  Future<void> _recargar() async {
    setState(() {
      _futureTeams = _teamService.obtenerEquipos();
    });

    await _futureTeams;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: ClubAppBarTitle(titulo: 'Equipos'),
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<TeamModel>>(
          future: _futureTeams,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _TeamsLoading();
            }

            if (snapshot.hasError) {
              return _TeamsError(
                onRetry: () {
                  setState(() {
                    _futureTeams = _teamService.obtenerEquipos();
                  });
                },
              );
            }

            final equipos = snapshot.data ?? [];

            if (equipos.isEmpty) {
              return const _TeamsEmpty();
            }

            return _buildTeamsList(equipos);
          },
        ),
      ),
    );
  }

  Widget _buildTeamsList(List<TeamModel> equipos) {
    final Map<String, List<TeamModel>> equiposPorCategoria = {};

    for (final equipo in equipos) {
      equiposPorCategoria.putIfAbsent(equipo.categoria, () => []).add(equipo);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Text(
          'Nuestros equipos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Consulta las plantillas y la información '
          'de cada equipo del club.',
          style: TextStyle(fontSize: 14, color: _colors.onSurfaceVariant),
        ),

        const SizedBox(height: 24),

        ...equiposPorCategoria.entries.map((entry) {
          return _buildCategorySection(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildCategorySection(String categoria, List<TeamModel> equipos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.dorado,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categoria,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...equipos.map(
            (equipo) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTeamCard(equipo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TeamModel equipo) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(equipo: equipo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.azul.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Image.asset(
                    'assets/images/escudo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipo.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right, color: AppColors.azul),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamsLoading extends StatelessWidget {
  const _TeamsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _TeamsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TeamsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 14),
                  const Text(
                    'No se han podido cargar '
                    'los equipos.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamsEmpty extends StatelessWidget {
  const _TeamsEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 400,
          child: Center(child: Text('No hay equipos disponibles.')),
        ),
      ],
    );
  }
}
