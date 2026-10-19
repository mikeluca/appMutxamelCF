import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../teams/models/standings_model.dart';
import '../../teams/models/team_model.dart';
import '../../teams/pages/team_standings_page.dart';
import '../../teams/services/team_services.dart';
import '../models/perfil_app.dart';
import '../services/perfil_service.dart';

/// Un equipo cuya clasificación puede abrir el usuario.
class EntradaClasificacion {
  final int equipoId;
  final String nombre;
  final String? categoria;

  /// Nombres de los jugadores del usuario en este equipo (JUGADOR/FAMILIAR).
  final List<String> jugadores;

  const EntradaClasificacion({
    required this.equipoId,
    required this.nombre,
    this.categoria,
    this.jugadores = const [],
  });
}

bool esGestionGlobalClasificaciones(PerfilApp perfil) =>
    perfil.tieneRol('COORDINADOR') || perfil.tieneRol('ADMIN_APP');

/// Equipos cuya clasificación ve el usuario, sin duplicados por id.
///
/// COORDINADOR / ADMIN_APP (el rol más amplio gana): todos los equipos de
/// [todosLosEquipos], en su orden. El resto: los de sus jugadores
/// (JUGADOR/FAMILIAR; un equipo con varios jugadores es una sola entrada) y los
/// que entrena (ENTRENADOR). Se ignoran las entradas sin id.
List<EntradaClasificacion> construirEntradasClasificacion(
  PerfilApp perfil,
  List<TeamModel> todosLosEquipos,
) {
  if (esGestionGlobalClasificaciones(perfil)) {
    final vistos = <int>{};

    return [
      for (final equipo in todosLosEquipos)
        if (equipo.id > 0 && vistos.add(equipo.id))
          EntradaClasificacion(
            equipoId: equipo.id,
            nombre: equipo.nombre,
            categoria: equipo.categoria,
          ),
    ];
  }

  final porId = <int, EntradaClasificacion>{};

  for (final jugador in perfil.jugadores) {
    final id = jugador.equipoId;

    if (id == null) {
      continue;
    }

    final anterior = porId[id];
    final nombreJugador = jugador.nombreCompleto;

    porId[id] = EntradaClasificacion(
      equipoId: id,
      nombre: anterior?.nombre ?? (jugador.equipo ?? '').trim(),
      categoria: anterior?.categoria ?? jugador.categoria,
      jugadores: [
        ...?anterior?.jugadores,
        if (nombreJugador.isNotEmpty &&
            !(anterior?.jugadores.contains(nombreJugador) ?? false))
          nombreJugador,
      ],
    );
  }

  for (final equipo in perfil.equipos) {
    final anterior = porId[equipo.id];

    porId[equipo.id] = EntradaClasificacion(
      equipoId: equipo.id,
      nombre: equipo.nombre.trim().isNotEmpty
          ? equipo.nombre.trim()
          : (anterior?.nombre ?? ''),
      categoria: equipo.categoria ?? anterior?.categoria,
      jugadores: anterior?.jugadores ?? const [],
    );
  }

  return porId.values.toList();
}

class MisClasificacionesPage extends StatefulWidget {
  /// Solo para tests: sustituyen a las llamadas reales al backend.
  final Future<PerfilApp> Function()? cargarPerfil;
  final TeamService? teamService;

  const MisClasificacionesPage({
    super.key,
    this.cargarPerfil,
    this.teamService,
  });

  @override
  State<MisClasificacionesPage> createState() => _MisClasificacionesPageState();
}

class _MisClasificacionesPageState extends State<MisClasificacionesPage> {
  late final TeamService _teamService = widget.teamService ?? TeamService();

  bool _cargando = true;
  bool _esGlobal = false;
  Object? _error;

  List<EntradaClasificacion> _entradas = [];
  final Map<int, StandingsModel?> _clasificaciones = {};

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final perfil =
          await (widget.cargarPerfil ?? PerfilService.obtenerPerfil)();
      final global = esGestionGlobalClasificaciones(perfil);

      final todos = global
          ? await _teamService.obtenerEquipos()
          : <TeamModel>[];

      var entradas = construirEntradasClasificacion(perfil, todos);

      if (!mounted) return;

      // Con un solo equipo no hay nada que elegir: se abre su clasificación y
      // "atrás" vuelve al menú.
      if (entradas.length == 1) {
        final unica = entradas.first;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TeamStandingsPage(
              equipoId: unica.equipoId,
              nombreEquipo: unica.nombre,
              teamService: widget.teamService,
            ),
          ),
        );
        return;
      }

      // En paralelo; el fallo de un equipo solo deja ese equipo sin resumen.
      final resultados = await Future.wait(
        entradas.map(
          (e) => _teamService
              .obtenerClasificacion(e.equipoId)
              .then<StandingsModel?>((c) => c)
              .catchError((_) => null),
        ),
      );

      if (!mounted) return;

      final clasificaciones = <int, StandingsModel?>{
        for (var i = 0; i < entradas.length; i++)
          entradas[i].equipoId: resultados[i],
      };

      if (global) {
        // Los equipos sin clasificación, al final (orden estable).
        entradas = [
          ...entradas.where((e) => _tieneFilas(clasificaciones[e.equipoId])),
          ...entradas.where((e) => !_tieneFilas(clasificaciones[e.equipoId])),
        ];
      }

      setState(() {
        _esGlobal = global;
        _entradas = entradas;
        _clasificaciones
          ..clear()
          ..addAll(clasificaciones);
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  static bool _tieneFilas(StandingsModel? c) => c != null && c.filas.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(
          titulo: _esGlobal ? _t.allStandingsTitle : _t.clubPageMyStandings,
        ),
      ),
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

    if (_entradas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.leaderboard_outlined, size: 64, color: _colors.primary),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _t.noTeamsAssociated,
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
      onRefresh: _recargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: _entradas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) => _construirTarjeta(_entradas[index]),
      ),
    );
  }

  Future<void> _recargar() async {
    await _cargar();
  }

  Widget _construirTarjeta(EntradaClasificacion entrada) {
    final detalle = [
      if (entrada.categoria != null && entrada.categoria!.trim().isNotEmpty)
        entrada.categoria!.trim(),
      ...entrada.jugadores,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TeamStandingsPage(
              equipoId: entrada.equipoId,
              nombreEquipo: entrada.nombre,
              teamService: widget.teamService,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.leaderboard_outlined, color: _colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entrada.nombre,
                      style: TextStyle(
                        color: _colors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (detalle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: TextStyle(color: _colors.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _resumen(_clasificaciones[entrada.equipoId]),
                      style: TextStyle(
                        color: _colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  /// "3º · 12 pts · J6" a partir de la fila del club; sin datos, "Sin
  /// clasificación todavía".
  String _resumen(StandingsModel? clasificacion) {
    if (clasificacion == null || clasificacion.filas.isEmpty) {
      return _t.standingsNone;
    }

    final nuestra = clasificacion.filas.where((f) => f.esNuestro);

    if (nuestra.isEmpty) {
      return _t.standingsNone;
    }

    final fila = nuestra.first;
    final jornada = clasificacion.jornada;

    return jornada == null
        ? _t.standingsSummaryNoRound(fila.posicion, fila.puntos)
        : _t.standingsSummary(fila.posicion, fila.puntos, jornada);
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
              _t.standingsLoadError,
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

                _cargar();
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
