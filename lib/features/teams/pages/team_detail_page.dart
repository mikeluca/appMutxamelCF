import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/player_model.dart';
import '../models/staff_model.dart';
import '../models/team_model.dart';
import '../services/team_services.dart';

class TeamDetailPage extends StatefulWidget {
  final TeamModel equipo;

  const TeamDetailPage({super.key, required this.equipo});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  final TeamService _teamService = TeamService();

  late Future<List<PlayerModel>> _futurePlayers;
  late Future<List<StaffModel>> _futureStaff;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();

    _futurePlayers = _teamService.obtenerJugadores(widget.equipo.id);

    _futureStaff = _teamService.obtenerCuerpoTecnico(widget.equipo.id);
  }

  Future<void> _recargar() async {
    setState(() {
      _futurePlayers = _teamService.obtenerJugadores(widget.equipo.id);

      _futureStaff = _teamService.obtenerCuerpoTecnico(widget.equipo.id);
    });

    await Future.wait([_futurePlayers, _futureStaff]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: widget.equipo.nombre)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<PlayerModel>>(
          future: _futurePlayers,
          builder: (context, snapshotPlayers) {
            if (snapshotPlayers.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshotPlayers.hasError) {
              return _buildError();
            }

            final jugadores = snapshotPlayers.data ?? [];

            return FutureBuilder<List<StaffModel>>(
              future: _futureStaff,
              builder: (context, snapshotStaff) {
                if (snapshotStaff.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshotStaff.hasError) {
                  return _buildContent(jugadores, [], errorStaff: true);
                }

                final staff = snapshotStaff.data ?? [];

                return _buildContent(jugadores, staff);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    List<PlayerModel> jugadores,
    List<StaffModel> staff, {
    bool errorStaff = false,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _buildTeamHeader(),

        const SizedBox(height: 28),

        _buildSectionTitle('Plantilla'),

        const SizedBox(height: 14),

        if (jugadores.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay jugadores disponibles '
                'para este equipo.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...jugadores.map((jugador) => _buildPlayerCard(jugador)),

        const SizedBox(height: 24),

        _buildSectionTitle('Cuerpo técnico'),

        const SizedBox(height: 14),

        if (errorStaff)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se ha podido cargar el '
                'cuerpo técnico.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (staff.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay cuerpo técnico disponible '
                'para este equipo.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...staff.map((persona) => _buildStaffCard(persona)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
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
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset(
              'assets/images/escudo.png',
              width: 95,
              height: 110,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 12),

            Text(
              widget.equipo.nombre,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(PlayerModel jugador) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildPlayerPhoto(jugador),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jugador.nombreCompleto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _colors.onSurface,
                    ),
                  ),

                  if (jugador.posicion?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      jugador.posicion!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (jugador.dorsal != null)
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.azul,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${jugador.dorsal}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPhoto(PlayerModel jugador) {
    if (jugador.fotoBase64 == null || jugador.fotoBase64!.isEmpty) {
      return _buildDefaultPlayerPhoto();
    }

    try {
      final bytes = base64Decode(jugador.fotoBase64!);

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultPlayerPhoto();
          },
        ),
      );
    } catch (_) {
      return _buildDefaultPlayerPhoto();
    }
  }

  Widget _buildDefaultPlayerPhoto() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.azulOscuro.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person_outline, size: 32, color: AppColors.azul),
    );
  }

  Widget _buildStaffCard(StaffModel staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _buildStaffPhoto(staff),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.nombreCompleto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _colors.onSurface,
                    ),
                  ),

                  if (staff.puesto != null &&
                      staff.puesto!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      staff.puesto!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.azul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffPhoto(StaffModel staff) {
    if (staff.fotoBase64 == null || staff.fotoBase64!.isEmpty) {
      return _buildDefaultStaffPhoto();
    }

    try {
      final bytes = base64Decode(staff.fotoBase64!);

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultStaffPhoto();
          },
        ),
      );
    } catch (_) {
      return _buildDefaultStaffPhoto();
    }
  }

  Widget _buildDefaultStaffPhoto() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.azulOscuro.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_outline, size: 40, color: AppColors.azul),
    );
  }

  Widget _buildError() {
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
                    'No se ha podido cargar '
                    'la plantilla.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 14),

                  OutlinedButton(
                    onPressed: _recargar,
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
