import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../teams/models/player_model.dart';
import '../../teams/services/team_services.dart';
import '../models/perfil_app.dart';
import '../services/perfil_service.dart';

class MisJugadoresPage extends StatefulWidget {
  const MisJugadoresPage({super.key});

  @override
  State<MisJugadoresPage> createState() => _MisJugadoresPageState();
}

class _MisJugadoresPageState extends State<MisJugadoresPage> {
  final TeamService _teamService = TeamService();

  PerfilApp? _perfil;
  Map<int, PlayerModel> _jugadoresConFoto = {};

  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarJugadores();
  }

  Future<void> _cargarJugadores() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();

      final equipos = await _teamService.obtenerEquipos();

      final jugadoresConFoto = <int, PlayerModel>{};

      for (final jugador in perfil.jugadores) {
        final equipoNombre = jugador.equipo?.trim();

        if (equipoNombre == null || equipoNombre.isEmpty) {
          continue;
        }

        final equipo = equipos
            .where(
              (e) =>
                  e.nombre.trim().toUpperCase() == equipoNombre.toUpperCase(),
            )
            .firstOrNull;

        if (equipo == null) {
          continue;
        }

        final jugadoresEquipo = await _teamService.obtenerJugadores(equipo.id);

        for (final jugadorPublico in jugadoresEquipo) {
          if (jugadorPublico.id == jugador.id) {
            jugadoresConFoto[jugador.id] = jugadorPublico;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _jugadoresConFoto = jugadoresConFoto;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis jugadores')),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return Center(child: CircularProgressIndicator(color: AppColors.azul));
    }

    if (_error != null) {
      return _construirError();
    }

    final jugadores = _perfil?.jugadores ?? [];

    if (jugadores.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No tienes jugadores vinculados a tu cuenta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargarJugadores,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            'Mis jugadores',
            style: TextStyle(
              color: _colors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${jugadores.length} jugador${jugadores.length == 1 ? '' : 'es'} vinculado${jugadores.length == 1 ? '' : 's'}',
            style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),

          ...jugadores.map(
            (jugador) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: _construirTarjetaJugador(jugador),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaJugador(PerfilJugador jugador) {
    final jugadorConFoto = _jugadoresConFoto[jugador.id];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirFotografia(jugadorConFoto),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jugador.nombreCompleto,
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _construirDato(
                  icono: Icons.groups_outlined,
                  titulo: 'Equipo',
                  valor: jugador.equipo,
                ),

                _construirDato(
                  icono: Icons.sports_soccer,
                  titulo: 'Deporte',
                  valor: jugador.deporte == 'F'
                      ? 'Fútbol'
                      : (jugador.deporte ?? '-'),
                ),

                _construirDato(
                  icono: Icons.looks_3_outlined,
                  titulo: 'Dorsal',
                  valor: jugador.dorsal?.toString(),
                ),

                _construirDato(
                  icono: Icons.accessibility_new_outlined,
                  titulo: 'Posición',
                  valor: jugador.posicion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFotografia(PlayerModel? jugador) {
    if (jugador == null ||
        jugador.fotoBase64 == null ||
        jugador.fotoBase64!.isEmpty) {
      return _construirFotoPorDefecto();
    }

    try {
      final bytes = base64Decode(jugador.fotoBase64!);

      return SizedBox(
        width: double.infinity,
        height: 300,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _construirFotoPorDefecto();
          },
        ),
      );
    } catch (_) {
      return _construirFotoPorDefecto();
    }
  }

  Widget _construirFotoPorDefecto() {
    return Container(
      width: double.infinity,
      height: 300,
      color: AppColors.azulOscuro.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.person_outline, size: 100, color: AppColors.azul),
      ),
    );
  }

  Widget _construirDato({
    required IconData icono,
    required String titulo,
    required String? valor,
  }) {
    if (valor == null || valor.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppColors.azul, size: 21),
          const SizedBox(width: 12),
          SizedBox(
            width: 85,
            child: Text(
              titulo,
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                color: _colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarJugadores();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
