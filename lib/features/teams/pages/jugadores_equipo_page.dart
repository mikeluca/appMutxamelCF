import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../teams/models/player_model.dart';
import '../../teams/services/team_services.dart';
import '../utils/posicion_jugador.dart';
import '../widgets/editar_jugador_sheet.dart';
import 'familiares_jugador_page.dart';

class JugadoresEquipoPage extends StatefulWidget {
  final PerfilEquipo equipo;

  /// Solo para tests: sustituye al servicio real.
  final TeamService? servicio;

  const JugadoresEquipoPage({super.key, required this.equipo, this.servicio});

  @override
  State<JugadoresEquipoPage> createState() => _JugadoresEquipoPageState();
}

class _JugadoresEquipoPageState extends State<JugadoresEquipoPage> {
  late final TeamService _teamService = widget.servicio ?? TeamService();

  late Future<List<PlayerModel>> _futureJugadores;

  /// La última lista cargada, para actualizarla al editar un jugador sin volver a pedirla.
  List<PlayerModel> _ultimaLista = const [];

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

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
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.playersMenuLabel)),
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
            _ultimaLista = jugadores;

            if (jugadores.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.groups_outlined, size: 64, color: _colors.primary),
                  const SizedBox(height: 20),
                  Text(
                    _t.noPlayersInTeam,
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

  Future<void> _editar(PlayerModel jugador) async {
    final actualizado = await mostrarEditarJugador(
      context,
      jugador: jugador,
      servicio: _teamService,
    );

    if (actualizado == null || !mounted) return;

    // Sin recargar la pantalla: se cambia el jugador en la lista y se reordena por dorsal (como la entrega el
    // servidor: de menor a mayor, los que no tienen al final; a igualdad, el orden que ya había).
    final lista = [
      for (final j in _ultimaLista) j.id == actualizado.id ? actualizado : j,
    ];
    final orden = {for (var i = 0; i < lista.length; i++) lista[i].id: i};

    lista.sort((a, b) {
      final da = a.dorsal;
      final db = b.dorsal;

      if (da == db) return orden[a.id]!.compareTo(orden[b.id]!);
      if (da == null) return 1;
      if (db == null) return -1;

      return da.compareTo(db);
    });

    setState(() {
      _futureJugadores = Future.value(lista);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_t.playerDataUpdated)));
  }

  Widget _construirJugador(PlayerModel jugador) {
    final posicion = textoPosicion(
      _t,
      codigo: jugador.posicionCodigo,
      texto: jugador.posicion,
    );

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

                    if (posicion != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        posicion,
                        style: TextStyle(
                          fontSize: 14,
                          color: _colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (jugador.editable)
                IconButton(
                  key: ValueKey('editar-jugador-${jugador.id}'),
                  tooltip: _t.playerEditTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editar(jugador),
                ),

              const SizedBox(width: 6),

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
                    _t.playersLoadError,
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
                    label: Text(_t.retry),
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
