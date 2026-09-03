import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../matches/models/match_model.dart';
import '../../matches/services/match_service.dart';
import '../../matches/widgets/match_card.dart';
import '../models/perfil_app.dart';
import '../services/perfil_service.dart';

class MisPartidosPage extends StatefulWidget {
  const MisPartidosPage({super.key});

  @override
  State<MisPartidosPage> createState() => _MisPartidosPageState();
}

class _MisPartidosPageState extends State<MisPartidosPage> {
  final MatchService _matchService = MatchService();

  PerfilApp? _perfil;
  List<MatchModel> _partidos = [];

  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();
      final todosLosPartidos = await _matchService.obtenerResultados();

      final nombresEquipos = <String>{};

      // Equipos procedentes de los jugadores.
      for (final jugador in perfil.jugadores) {
        final equipo = jugador.equipo;

        if (equipo != null && equipo.trim().isNotEmpty) {
          nombresEquipos.add(equipo.trim().toUpperCase());
        }
      }

      // Equipos procedentes directamente del perfil.
      // Esto es lo que necesitamos para entrenadores/coordinadores.
      for (final equipo in perfil.equipos) {
        if (equipo.nombre.trim().isNotEmpty) {
          nombresEquipos.add(equipo.nombre.trim().toUpperCase());
        }
      }

      final partidos = todosLosPartidos.where((partido) {
        return nombresEquipos.contains(partido.equipo.trim().toUpperCase());
      }).toList();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _partidos = partidos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis partidos')),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _construirError();
    }

    final equipos = _obtenerEquipos();

    if (equipos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.sports_soccer_outlined,
              size: 64,
              color: _colors.primary,
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No tienes equipos asociados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          for (final equipo in equipos) ...[
            _construirTituloEquipo(equipo),
            const SizedBox(height: 10),
            _construirPartidoEquipo(equipo),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  List<String> _obtenerEquipos() {
    final nombres = <String, String>{};

    // Equipos de jugadores.
    for (final jugador in _perfil?.jugadores ?? []) {
      final equipo = jugador.equipo;

      if (equipo != null && equipo.trim().isNotEmpty) {
        nombres.putIfAbsent(equipo.trim().toUpperCase(), () => equipo.trim());
      }
    }

    // Equipos directos del perfil.
    for (final equipo in _perfil?.equipos ?? []) {
      if (equipo.nombre.trim().isNotEmpty) {
        nombres.putIfAbsent(
          equipo.nombre.trim().toUpperCase(),
          () => equipo.nombre.trim(),
        );
      }
    }

    return nombres.values.toList();
  }

  Widget _construirTituloEquipo(String equipo) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.dorado,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            equipo,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirPartidoEquipo(String equipo) {
    final partidosEquipo = _partidos
        .where(
          (partido) =>
              partido.equipo.trim().toUpperCase() ==
              equipo.trim().toUpperCase(),
        )
        .toList();

    final partido = _seleccionarPartido(partidosEquipo);

    if (partido == null) {
      return Card(
        margin: EdgeInsets.zero,
        color: _colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.event_busy, color: _colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay partidos disponibles para este equipo.',
                  style: TextStyle(color: _colors.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MatchCard(match: partido);
  }

  MatchModel? _seleccionarPartido(List<MatchModel> partidos) {
    if (partidos.isEmpty) {
      return null;
    }

    // Primero buscamos el próximo partido.
    final proximos = partidos
        .where((partido) => partido.esProximoPartido)
        .toList();

    if (proximos.isNotEmpty) {
      proximos.sort((a, b) {
        final fechaA = a.dia ?? DateTime(9999);
        final fechaB = b.dia ?? DateTime(9999);
        return fechaA.compareTo(fechaB);
      });

      return proximos.first;
    }

    // Si no hay próximo, mostramos el último jugado.
    final jugados = partidos.where((partido) => partido.estaJugado).toList();

    if (jugados.isNotEmpty) {
      jugados.sort((a, b) {
        final fechaA = a.dia ?? DateTime(1900);
        final fechaB = b.dia ?? DateTime(1900);
        return fechaB.compareTo(fechaA);
      });

      return jugados.first;
    }

    // Si solo hay partidos de descanso.
    return partidos.first;
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'No se han podido cargar tus partidos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarDatos();
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
