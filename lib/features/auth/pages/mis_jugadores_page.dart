import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../teams/models/player_model.dart';
import '../../teams/models/team_model.dart';
import '../../teams/services/team_services.dart';
import '../models/perfil_app.dart';
import '../models/resumen_temporada_model.dart';
import '../services/perfil_service.dart';
import '../services/resumen_temporada_service.dart';
import '../widgets/resumen_temporada_section.dart';

class MisJugadoresPage extends StatefulWidget {
  /// true para un usuario JUGADOR: la pantalla es "Mi ficha" (sin el recuento
  /// de jugadores vinculados). Con false es "Mis jugadores", para familias.
  final bool soloMiFicha;

  /// Solo para tests: sustituyen a las llamadas reales al backend.
  final Future<PerfilApp> Function()? cargarPerfil;
  final TeamService? teamService;
  final ResumenTemporadaService? resumenService;

  const MisJugadoresPage({
    super.key,
    this.soloMiFicha = false,
    this.cargarPerfil,
    this.teamService,
    this.resumenService,
  });

  @override
  State<MisJugadoresPage> createState() => _MisJugadoresPageState();
}

class _MisJugadoresPageState extends State<MisJugadoresPage> {
  late final TeamService _teamService = widget.teamService ?? TeamService();
  late final ResumenTemporadaService _resumenService =
      widget.resumenService ?? ResumenTemporadaService();

  PerfilApp? _perfil;
  Map<int, PlayerModel> _jugadoresConFoto = {};
  Map<int, ResumenTemporadaModel?> _resumenes = {};

  /// Jugadores cuyo resumen de temporada todavía no ha llegado.
  Set<int> _resumenesPendientes = {};

  /// Número de la carga en curso: una respuesta de una carga anterior (por un
  /// refresco o un reintento) no debe pisar a la actual.
  int _carga = 0;

  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargarJugadores();
  }

  /// El perfil se pinta en cuanto llega. Las fotos y el resumen de cada
  /// jugador se piden después, en paralelo y cada uno por su cuenta: la ficha
  /// no espera a ninguno de ellos y, si fallan, sigue sin ellos.
  Future<void> _cargarJugadores() async {
    final carga = ++_carga;

    try {
      final perfil =
          await (widget.cargarPerfil ?? PerfilService.obtenerPerfil)();

      if (!mounted || carga != _carga) return;

      setState(() {
        _perfil = perfil;
        _resumenes = {};
        _resumenesPendientes = {for (final j in perfil.jugadores) j.id};
        _cargando = false;
        _error = null;
      });

      await Future.wait([
        _cargarFotos(perfil, carga),
        ...perfil.jugadores.map((j) => _cargarResumen(j.id, carga)),
      ]);
    } catch (e) {
      if (!mounted || carga != _carga) return;

      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// El resumen es opcional: si falla (o no hay temporada), esa ficha dice que
  /// todavía no hay datos.
  Future<void> _cargarResumen(int jugadorId, int carga) async {
    ResumenTemporadaModel? resumen;

    try {
      resumen = await _resumenService.obtenerResumen(jugadorId);
    } catch (_) {
      resumen = null;
    }

    if (!mounted || carga != _carga) return;

    setState(() {
      _resumenes = {..._resumenes, jugadorId: resumen};
      _resumenesPendientes = {..._resumenesPendientes}..remove(jugadorId);
    });
  }

  /// La foto sale de la lista pública del equipo. Cada jugador se pinta con su
  /// foto en cuanto se conoce; mientras tanto (o si falla) lleva la imagen por
  /// defecto.
  Future<void> _cargarFotos(PerfilApp perfil, int carga) async {
    try {
      // El perfil ya trae el id del equipo; el listado de equipos solo hace
      // falta para un jugador cuyo equipo no se pudo resolver por id.
      final equipos = perfil.jugadores.any((j) => j.equipoId == null)
          ? await _teamService.obtenerEquipos()
          : <TeamModel>[];

      for (final jugador in perfil.jugadores) {
        var equipoId = jugador.equipoId;

        if (equipoId == null) {
          final equipoNombre = jugador.equipo?.trim();

          if (equipoNombre == null || equipoNombre.isEmpty) {
            continue;
          }

          equipoId = equipos
              .where(
                (e) =>
                    e.nombre.trim().toUpperCase() == equipoNombre.toUpperCase(),
              )
              .firstOrNull
              ?.id;
        }

        if (equipoId == null) {
          continue;
        }

        final jugadoresEquipo = await _teamService.obtenerJugadores(equipoId);

        if (!mounted || carga != _carga) return;

        for (final jugadorPublico in jugadoresEquipo) {
          if (jugadorPublico.id == jugador.id) {
            setState(() {
              _jugadoresConFoto = {
                ..._jugadoresConFoto,
                jugador.id: jugadorPublico,
              };
            });
            break;
          }
        }
      }
    } catch (_) {
      // Sin foto la ficha sigue siendo útil: se queda la imagen por defecto.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(
          titulo: widget.soloMiFicha ? _t.clubPageMyCard : _t.clubPageMyPlayers,
        ),
      ),
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
            _t.noPlayersLinked,
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
          if (!widget.soloMiFicha) ...[
            Text(
              _t.clubPageMyPlayers,
              style: TextStyle(
                color: _colors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t.playersLinkedCount(jugadores.length),
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 20),
          ],

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

                // Resumen corto de cada hijo ("Entrenamientos 18/20 · 3
                // goles"); en "Mi ficha" ya está todo en la sección completa.
                if (!widget.soloMiFicha &&
                    ResumenTemporadaSection.resumenCorto(
                          _t,
                          _resumenes[jugador.id],
                        ) !=
                        null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ResumenTemporadaSection.resumenCorto(
                      _t,
                      _resumenes[jugador.id],
                    )!,
                    style: TextStyle(
                      color: _colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                _construirDato(
                  icono: Icons.groups_outlined,
                  titulo: _t.fieldTeam,
                  // Un jugador sin equipo o dado de baja llega con equipo a null.
                  valor: (jugador.equipo ?? '').trim().isEmpty
                      ? _t.playerNoTeamThisSeason
                      : jugador.equipo,
                ),

                _construirDato(
                  icono: Icons.sports_soccer,
                  titulo: _t.fieldSport,
                  valor: jugador.deporte == 'F'
                      ? _t.sportFootball
                      : (jugador.deporte ?? '-'),
                ),

                _construirDato(
                  icono: Icons.looks_3_outlined,
                  titulo: _t.fieldDorsal,
                  valor: jugador.dorsal?.toString(),
                ),

                _construirDato(
                  icono: Icons.accessibility_new_outlined,
                  titulo: _t.fieldPosition,
                  valor: jugador.posicion,
                ),

                const Divider(height: 32),

                ResumenTemporadaSection(
                  resumen: _resumenes[jugador.id],
                  cargando: _resumenesPendientes.contains(jugador.id),
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
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}
