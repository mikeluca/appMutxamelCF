import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../convocatorias/services/convocatoria_service.dart';
import '../../teams/services/team_services.dart';
import '../models/match_model.dart';
import '../models/partido_estadisticas_model.dart';
import '../services/match_service.dart';

/// Formulario para introducir (o editar) el resultado y las estadísticas
/// por jugador (goles, asistencias, tarjetas) de un partido ya jugado.
///
/// La plantilla de jugadores a rellenar se determina así: si existe una
/// convocatoria para este partido, se usan sus jugadores; si no, se usa
/// la plantilla completa del equipo. Cualquier estadística ya guardada
/// se precarga casando por jugadorId (no por posición en la lista), ya
/// que la plantilla puede haber cambiado desde la última vez que se
/// guardó el resultado.
class ResultadoPartidoFormPage extends StatefulWidget {
  final MatchModel partido;

  const ResultadoPartidoFormPage({super.key, required this.partido});

  @override
  State<ResultadoPartidoFormPage> createState() =>
      _ResultadoPartidoFormPageState();
}

class _DatosResultadoPartido {
  final List<RosterJugadorModel> roster;
  final PartidoEstadisticasModel guardadas;

  _DatosResultadoPartido(this.roster, this.guardadas);
}

/// Fila editable de un jugador de la plantilla: mantiene sus propios
/// controladores para no perder lo que el usuario está escribiendo en
/// cada reconstrucción del widget.
class _FilaEstadistica {
  final int jugadorId;
  final String nombre;
  final TextEditingController golesController;
  final TextEditingController asistenciasController;
  final TextEditingController amarillasController;
  bool roja;

  _FilaEstadistica({
    required this.jugadorId,
    required this.nombre,
    required this.golesController,
    required this.asistenciasController,
    required this.amarillasController,
    required this.roja,
  });

  void dispose() {
    golesController.dispose();
    asistenciasController.dispose();
    amarillasController.dispose();
  }
}

class _ResultadoPartidoFormPageState extends State<ResultadoPartidoFormPage> {
  final TeamService _teamService = TeamService();
  final ConvocatoriaService _convocatoriaService = ConvocatoriaService();
  final MatchService _matchService = MatchService();

  late final Future<_DatosResultadoPartido> _futureDatos;

  final TextEditingController _golesFavorController = TextEditingController();
  final TextEditingController _golesContraController =
      TextEditingController();

  final List<_FilaEstadistica> _filas = [];
  bool _filasInicializadas = false;

  bool _guardando = false;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _futureDatos = _cargarDatos();
  }

  Future<_DatosResultadoPartido> _cargarDatos() async {
    final partidoId = widget.partido.id!;
    final equipoId = widget.partido.equipoId!;

    final resultados = await Future.wait([
      _obtenerRoster(equipoId, partidoId),
      _matchService.obtenerEstadisticas(partidoId),
    ]);

    return _DatosResultadoPartido(
      resultados[0] as List<RosterJugadorModel>,
      resultados[1] as PartidoEstadisticasModel,
    );
  }

  /// Si existe una convocatoria vinculada a este partido, sus jugadores
  /// son la plantilla del formulario; si no, se usa la plantilla
  /// completa del equipo.
  Future<List<RosterJugadorModel>> _obtenerRoster(
    int equipoId,
    int partidoId,
  ) async {
    final convocatorias = await _convocatoriaService.obtenerPorEquipo(
      equipoId,
    );

    for (final convocatoria in convocatorias) {
      if (convocatoria.partidoId == partidoId) {
        return convocatoria.jugadores
            .map(
              (jugador) => RosterJugadorModel(
                jugadorId: jugador.jugadorId,
                jugador: jugador.jugador,
              ),
            )
            .toList();
      }
    }

    final jugadores = await _teamService.obtenerJugadores(equipoId);

    return jugadores
        .map(
          (jugador) => RosterJugadorModel(
            jugadorId: jugador.id,
            jugador: jugador.nombreCompleto,
          ),
        )
        .toList();
  }

  void _inicializarFilas(_DatosResultadoPartido datos) {
    if (_filasInicializadas) return;
    _filasInicializadas = true;

    _golesFavorController.text = (datos.guardadas.golesFavor ?? 0).toString();
    _golesContraController.text = (datos.guardadas.golesContra ?? 0)
        .toString();

    final combinadas = fusionarRosterConEstadisticas(
      roster: datos.roster,
      guardadas: datos.guardadas.jugadores,
    );

    for (final estadistica in combinadas) {
      _filas.add(
        _FilaEstadistica(
          jugadorId: estadistica.jugadorId,
          nombre: estadistica.jugador,
          golesController: TextEditingController(
            text: estadistica.goles.toString(),
          ),
          asistenciasController: TextEditingController(
            text: estadistica.asistencias.toString(),
          ),
          amarillasController: TextEditingController(
            text: estadistica.tarjetasAmarillas.toString(),
          ),
          roja: estadistica.tarjetaRoja,
        ),
      );
    }
  }

  @override
  void dispose() {
    _golesFavorController.dispose();
    _golesContraController.dispose();

    for (final fila in _filas) {
      fila.dispose();
    }

    super.dispose();
  }

  int _parseNoNegativo(String texto) {
    final valor = int.tryParse(texto.trim()) ?? 0;

    return valor < 0 ? 0 : valor;
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    setState(() {
      _guardando = true;
    });

    try {
      final golesFavor = _parseNoNegativo(_golesFavorController.text);
      final golesContra = _parseNoNegativo(_golesContraController.text);

      final jugadores = _filas
          .map(
            (fila) => EstadisticaJugadorModel(
              jugadorId: fila.jugadorId,
              jugador: fila.nombre,
              goles: _parseNoNegativo(fila.golesController.text),
              asistencias: _parseNoNegativo(fila.asistenciasController.text),
              tarjetasAmarillas: _parseNoNegativo(
                fila.amarillasController.text,
              ),
              tarjetaRoja: fila.roja,
            ),
          )
          .toList();

      await _matchService.guardarEstadisticas(
        partidoId: widget.partido.id!,
        golesFavor: golesFavor,
        golesContra: golesContra,
        jugadores: jugadores,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.matchResultSavedSuccess)));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.matchResultSaveError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: _t.matchResultFormTitle),
      ),
      body: FutureBuilder<_DatosResultadoPartido>(
        future: _futureDatos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _construirError(snapshot.error);
          }

          final datos = snapshot.data!;
          _inicializarFilas(datos);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    _construirCabecera(),
                    const SizedBox(height: 24),
                    _construirTituloJugadores(),
                    const SizedBox(height: 12),
                    if (_filas.isEmpty)
                      _construirSinJugadores()
                    else
                      ..._filas.map(_construirFilaJugador),
                  ],
                ),
              ),
              _construirBotonGuardar(),
            ],
          );
        },
      ),
    );
  }

  Widget _construirCabecera() {
    final partido = widget.partido;

    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${partido.equipo} - ${partido.rival}',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            if (partido.dia != null ||
                partido.diaFormateado?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                partido.dia != null
                    ? formatearFechaConDiaSemana(partido.dia!, _t)
                    : partido.diaFormateado!,
                style: TextStyle(fontSize: 13, color: _colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _construirCampoEntero(
                    controller: _golesFavorController,
                    etiqueta: _t.matchResultGoalsForLabel,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _construirCampoEntero(
                    controller: _golesContraController,
                    etiqueta: _t.matchResultGoalsAgainstLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCampoEntero({
    required TextEditingController controller,
    required String etiqueta,
  }) {
    return TextField(
      controller: controller,
      enabled: !_guardando,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _construirTituloJugadores() {
    return Text(
      _t.matchResultPlayersTitle,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _colors.onSurface,
      ),
    );
  }

  Widget _construirFilaJugador(_FilaEstadistica fila) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _colors.primaryContainer,
                  child: Text(
                    fila.nombre.isNotEmpty ? fila.nombre[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fila.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _construirCampoEnteroCompacto(
                    controller: fila.golesController,
                    etiqueta: _t.matchResultGoalsShort,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _construirCampoEnteroCompacto(
                    controller: fila.asistenciasController,
                    etiqueta: _t.matchResultAssistsShort,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _construirCampoEnteroCompacto(
                    controller: fila.amarillasController,
                    etiqueta: _t.matchResultYellowCardsShort,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _construirTarjetaRoja(fila),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCampoEnteroCompacto({
    required TextEditingController controller,
    required String etiqueta,
  }) {
    return TextField(
      controller: controller,
      enabled: !_guardando,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: etiqueta,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _construirTarjetaRoja(_FilaEstadistica fila) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _guardando
          ? null
          : () {
              setState(() {
                fila.roja = !fila.roja;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: _colors.outline),
          borderRadius: BorderRadius.circular(8),
          color: fila.roja
              ? Colors.redAccent.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.crop_portrait,
              size: 18,
              color: fila.roja ? Colors.redAccent : _colors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              _t.matchResultRedCardShort,
              style: TextStyle(
                fontSize: 11,
                color: fila.roja ? Colors.redAccent : _colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotonGuardar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_t.matchResultSaveButton),
          ),
        ),
      ),
    );
  }

  Widget _construirSinJugadores() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _t.noPlayersAvailableForTeam,
          textAlign: TextAlign.center,
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _construirError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _t.matchResultLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
