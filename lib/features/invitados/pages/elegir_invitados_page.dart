import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/invitacion_model.dart';
import '../services/invitados_service.dart';

/// Elige jugadores de otros equipos para invitarlos a la convocatoria de un partido:
/// primero el equipo (los que permite el servidor para este partido) y luego sus
/// jugadores. La selección (máximo [maximoInvitados]) se conserva al cambiar de
/// equipo y se devuelve al pulsar "Listo" o volver atrás.
///
/// Devuelve la lista de [InvitadoElegido] elegidos (sin los rechazados, que el
/// formulario conserva aparte).
class ElegirInvitadosPage extends StatefulWidget {
  final int partidoId;

  /// Lo que ya estaba elegido (sin los rechazados).
  final List<InvitadoElegido> seleccion;

  /// Solo para tests: sustituye al servicio real.
  final InvitadosService? service;

  const ElegirInvitadosPage({
    super.key,
    required this.partidoId,
    this.seleccion = const [],
    this.service,
  });

  @override
  State<ElegirInvitadosPage> createState() => _ElegirInvitadosPageState();
}

class _ElegirInvitadosPageState extends State<ElegirInvitadosPage> {
  late final InvitadosService _service = widget.service ?? InvitadosService();

  late final Map<int, InvitadoElegido> _seleccion = {
    for (final elegido in widget.seleccion) elegido.jugadorId: elegido,
  };

  late Future<List<EquipoInvitableModel>> _futureEquipos;
  Future<List<JugadorInvitableModel>>? _futureJugadores;

  /// El equipo cuyos jugadores se están viendo; null = la lista de equipos.
  EquipoInvitableModel? _equipo;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  int get _cuenta => _seleccion.values.where((e) => e.cuenta).length;

  @override
  void initState() {
    super.initState();

    _futureEquipos = _service.obtenerEquipos(widget.partidoId);
  }

  void _abrirEquipo(EquipoInvitableModel equipo) {
    setState(() {
      _equipo = equipo;
      _futureJugadores = _service.obtenerJugadores(
        widget.partidoId,
        equipo.equipoId,
      );
    });
  }

  void _alternar(JugadorInvitableModel jugador, EquipoInvitableModel equipo) {
    final elegido = _seleccion[jugador.jugadorId];

    if (elegido != null && !elegido.rechazado) {
      setState(() => _seleccion.remove(jugador.jugadorId));
      return;
    }

    if (_cuenta >= maximoInvitados) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.invMaxReached(maximoInvitados))),
      );
      return;
    }

    setState(() {
      _seleccion[jugador.jugadorId] = InvitadoElegido(
        jugadorId: jugador.jugadorId,
        nombre: jugador.nombre,
        equipoOrigenId: equipo.equipoId,
        equipoOrigen: equipo.nombre,
      );
    });
  }

  void _terminar() {
    Navigator.pop(
      context,
      _seleccion.values.where((e) => !e.rechazado).toList(),
    );
  }

  /// Volver atrás desde los jugadores de un equipo lleva a la lista de equipos; desde
  /// la lista, cierra la pantalla devolviendo la selección.
  void _atras() {
    if (_equipo != null) {
      setState(() {
        _equipo = null;
        _futureJugadores = null;
      });
      return;
    }

    _terminar();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _atras),
          title: ClubAppBarTitle(titulo: _t.invGuestsTitle),
        ),
        body: Column(
          children: [
            _construirContador(),
            Expanded(
              child: _equipo == null
                  ? _construirEquipos()
                  : _construirJugadores(_equipo!),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    key: const ValueKey('invitados-listo'),
                    onPressed: _terminar,
                    child: Text(_t.invConfirmSelection),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContador() {
    return Padding(
      key: const ValueKey('invitados-contador'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Icon(Icons.group_add_outlined, color: _colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t.invGuestsCounter(_cuenta, maximoInvitados),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _cuenta >= maximoInvitados
                    ? _colors.error
                    : _colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEquipos() {
    return FutureBuilder<List<EquipoInvitableModel>>(
      future: _futureEquipos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _construirError(snapshot.error, () {
            setState(() {
              _futureEquipos = _service.obtenerEquipos(widget.partidoId);
            });
          });
        }

        final equipos = snapshot.data ?? [];

        if (equipos.isEmpty) {
          return _construirVacio(_t.invNoTeams);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _t.invPickTeamPrompt,
                style: TextStyle(color: _colors.onSurfaceVariant),
              ),
            ),
            ...equipos.map(_construirEquipo),
          ],
        );
      },
    );
  }

  Widget _construirEquipo(EquipoInvitableModel equipo) {
    final elegidos = _seleccion.values
        .where((e) => !e.rechazado && e.equipoOrigenId == equipo.equipoId)
        .length;

    return Card(
      key: ValueKey('invitables-equipo-${equipo.equipoId}'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => _abrirEquipo(equipo),
        leading: const Icon(Icons.groups_outlined),
        title: Text(
          equipo.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: elegidos > 0
            ? Badge(label: Text('$elegidos'))
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _construirJugadores(EquipoInvitableModel equipo) {
    return FutureBuilder<List<JugadorInvitableModel>>(
      future: _futureJugadores,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _construirError(snapshot.error, () => _abrirEquipo(equipo));
        }

        final jugadores = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                equipo.nombre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _colors.onSurface,
                ),
              ),
            ),
            if (jugadores.isEmpty)
              _construirVacio(_t.invNoPlayers)
            else
              ...jugadores.map((j) => _construirJugador(j, equipo)),
          ],
        );
      },
    );
  }

  Widget _construirJugador(
    JugadorInvitableModel jugador,
    EquipoInvitableModel equipo,
  ) {
    final elegido = _seleccion[jugador.jugadorId];
    final marcado = elegido != null && !elegido.rechazado;
    final bloqueado = jugador.bloqueado && !marcado;

    return Card(
      key: ValueKey('invitable-${jugador.jugadorId}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: bloqueado
          ? _colors.surfaceContainerHighest
          : (marcado ? _colors.primaryContainer : _colors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: marcado ? _colors.primary : _colors.outlineVariant,
        ),
      ),
      child: ListTile(
        enabled: !bloqueado,
        onTap: bloqueado ? null : () => _alternar(jugador, equipo),
        leading: SizedBox(
          width: 28,
          child: Text(
            jugador.dorsal?.toString() ?? '-',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _colors.primary,
            ),
          ),
        ),
        title: Text(
          jugador.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: bloqueado
            ? Text(
                (jugador.motivoBloqueo?.trim().isNotEmpty ?? false)
                    ? jugador.motivoBloqueo!
                    : _t.invBlockedDefault,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              )
            : null,
        trailing: Icon(
          bloqueado
              ? Icons.block
              : (marcado ? Icons.check_circle : Icons.radio_button_unchecked),
          color: marcado ? _colors.primary : _colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _construirVacio(String texto) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _construirError(Object? error, VoidCallback reintentar) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(mensajeDeAccion(_t, error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: reintentar,
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}
