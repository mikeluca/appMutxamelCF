import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../models/standings_model.dart';
import '../services/team_services.dart';
import '../widgets/team_standings_section.dart';

/// Clasificación del grupo de un equipo. Se abre desde las tarjetas de la
/// pestaña Partidos.
class TeamStandingsPage extends StatefulWidget {
  final int equipoId;
  final String nombreEquipo;

  const TeamStandingsPage({
    super.key,
    required this.equipoId,
    required this.nombreEquipo,
  });

  @override
  State<TeamStandingsPage> createState() => _TeamStandingsPageState();
}

class _TeamStandingsPageState extends State<TeamStandingsPage> {
  final TeamService _teamService = TeamService();

  late Future<StandingsModel?> _futureStandings;

  @override
  void initState() {
    super.initState();

    _futureStandings = _teamService.obtenerClasificacion(widget.equipoId);
  }

  Future<void> _recargar() async {
    final nueva = _teamService.obtenerClasificacion(widget.equipoId);

    setState(() => _futureStandings = nueva);

    // Si falla, el error ya se muestra en la propia sección.
    await nueva.catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: widget.nombreEquipo)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [TeamStandingsSection(future: _futureStandings)],
        ),
      ),
    );
  }
}
