import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../auth/models/perfil_app.dart';
import '../../teams/models/player_model.dart';
import '../../teams/services/team_services.dart';
import 'familiares_jugador_page.dart';

class JugadoresEquipoPage extends StatefulWidget {
  final PerfilEquipo equipo;

  const JugadoresEquipoPage({super.key, required this.equipo});

  @override
  State<JugadoresEquipoPage> createState() => _JugadoresEquipoPageState();
}

class _JugadoresEquipoPageState extends State<JugadoresEquipoPage> {
  final TeamService _teamService = TeamService();

  late Future<List<PlayerModel>> _futureJugadores;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futureJugadores = _teamService.obtenerJugadoresGestion(widget.equipo.id);
  }

  Future<void> _recargar() async {
    setState(() {
      _futureJugadores = _teamService.obtenerJugadoresGestion(widget.equipo.id);
    });

    await _futureJugadores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Jugadores')),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<PlayerModel>>(
          future: _futureJugadores,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _construirError();
            }

            final jugadores = snapshot.data ?? [];

            if (jugadores.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.groups_outlined, size: 64, color: _colors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'No hay jugadores en este equipo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              itemCount: jugadores.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _construirJugador(jugadores[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _construirJugador(PlayerModel jugador) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FamiliaresJugadorPage(
                equipo: widget.equipo,
                jugador: jugador,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _construirFoto(jugador),

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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _colors.onSurface,
                      ),
                    ),

                    if (jugador.posicion?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(
                        jugador.posicion!,
                        style: TextStyle(
                          fontSize: 14,
                          color: _colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (jugador.dorsal != null)
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jugador.dorsal.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirFoto(PlayerModel jugador) {
    if (jugador.fotoBase64 == null || jugador.fotoBase64!.isEmpty) {
      return _construirFotoDefecto();
    }

    try {
      final bytes = base64Decode(jugador.fotoBase64!);

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _construirFotoDefecto();
          },
        ),
      );
    } catch (_) {
      return _construirFotoDefecto();
    }
  }

  Widget _construirFotoDefecto() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.person_outline, size: 36, color: _colors.primary),
    );
  }

  Widget _construirError() {
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
                  Icon(Icons.error_outline, size: 52, color: _colors.error),
                  const SizedBox(height: 16),
                  Text(
                    'No se han podido cargar los jugadores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _recargar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
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
