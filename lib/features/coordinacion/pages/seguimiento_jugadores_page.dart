import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/coordinacion_model.dart';
import '../services/coordinacion_service.dart';

/// Jugadores con muchas faltas o mal comportamiento en entrenamientos. Datos
/// solo para coordinación: no se avisa a las familias desde aquí.
class SeguimientoJugadoresPage extends StatefulWidget {
  final CoordinacionService? servicio;

  const SeguimientoJugadoresPage({super.key, this.servicio});

  @override
  State<SeguimientoJugadoresPage> createState() =>
      _SeguimientoJugadoresPageState();
}

class _SeguimientoJugadoresPageState extends State<SeguimientoJugadoresPage> {
  static const Color _rojo = Color(0xFFDC2626);
  static const Color _ambar = Color(0xFFF59E0B);

  late final CoordinacionService _servicio =
      widget.servicio ?? CoordinacionService();

  late Future<List<SeguimientoJugadorModel>> _futuro;

  String _periodo = periodoSeguimiento30d;

  /// null = todos los equipos.
  String? _equipo;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerSeguimiento(periodo: _periodo);
  }

  void _cambiarPeriodo(String periodo) {
    if (periodo == _periodo) return;

    setState(() {
      _periodo = periodo;
      _equipo = null;
      _futuro = _servicio.obtenerSeguimiento(periodo: periodo);
    });
  }

  Future<void> _recargar() async {
    final nuevo = _servicio.obtenerSeguimiento(periodo: _periodo);

    setState(() {
      _futuro = nuevo;
    });

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  void _abrirDetalle(SeguimientoJugadorModel jugador) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeguimientoJugadorDetallePage(
          jugador: jugador,
          periodo: _periodo,
          servicio: _servicio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPagePlayerTracking)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<SeguimientoJugadorModel>>(
          future: _futuro,
          builder: (context, snapshot) {
            final cargando =
                snapshot.connectionState == ConnectionState.waiting;
            final jugadores = snapshot.data ?? const [];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _construirSelectorPeriodo(),
                const SizedBox(height: 12),
                _construirFiltroEquipo(jugadores),
                const SizedBox(height: 12),
                if (cargando)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  _construirError()
                else
                  ..._construirLista(jugadores),
                const SizedBox(height: 16),
                Text(
                  _t.trackingCoordinationOnly,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _colors.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _construirSelectorPeriodo() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: periodoSeguimiento30d,
          label: Text(_t.trackingPeriod30),
        ),
        ButtonSegment(
          value: periodoSeguimientoTemporada,
          label: Text(_t.trackingPeriodSeason),
        ),
      ],
      selected: {_periodo},
      onSelectionChanged: (seleccion) => _cambiarPeriodo(seleccion.first),
    );
  }

  Widget _construirFiltroEquipo(List<SeguimientoJugadorModel> jugadores) {
    final equipos = {for (final j in jugadores) j.equipo}.toList()..sort();

    // El equipo elegido puede haber desaparecido al cambiar de periodo.
    final valor = equipos.contains(_equipo) ? _equipo : null;

    return DropdownButtonFormField<String?>(
      key: ValueKey('filtro-$_periodo-${equipos.length}'),
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(_t.trackingAllTeams),
        ),
        for (final equipo in equipos)
          DropdownMenuItem<String?>(value: equipo, child: Text(equipo)),
      ],
      onChanged: (equipo) {
        setState(() {
          _equipo = equipo;
        });
      },
    );
  }

  List<Widget> _construirLista(List<SeguimientoJugadorModel> jugadores) {
    final visibles = _equipo == null
        ? jugadores
        : jugadores.where((j) => j.equipo == _equipo).toList();

    if (visibles.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            _t.trackingEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ),
      ];
    }

    return [
      for (final jugador in visibles) ...[
        _construirTarjeta(jugador),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _construirTarjeta(SeguimientoJugadorModel jugador) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalle(jugador),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jugador.nombre,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                jugador.equipo,
                style: TextStyle(color: _colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (jugador.faltas > 0)
                    _construirChip(
                      _t.trackingFaultsChip(jugador.faltas),
                      _rojo,
                    ),
                  if (jugador.malComportamiento > 0)
                    _construirChip(
                      _t.trackingMisconductChip(jugador.malComportamiento),
                      _ambar,
                    ),
                ],
              ),
              if (jugador.ultimaIncidencia != null) ...[
                const SizedBox(height: 8),
                Text(
                  _t.trackingLastIncident(fechaCorta(jugador.ultimaIncidencia)),
                  style: TextStyle(
                    fontSize: 12,
                    color: _colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirChip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _construirError() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          _t.connectionError,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: _colors.onSurface),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _recargar,
          icon: const Icon(Icons.refresh),
          label: Text(_t.retry),
        ),
      ],
    );
  }
}

/// Las incidencias (fecha y estado) de un jugador en el periodo.
class SeguimientoJugadorDetallePage extends StatefulWidget {
  final SeguimientoJugadorModel jugador;
  final String periodo;
  final CoordinacionService? servicio;

  const SeguimientoJugadorDetallePage({
    super.key,
    required this.jugador,
    required this.periodo,
    this.servicio,
  });

  @override
  State<SeguimientoJugadorDetallePage> createState() =>
      _SeguimientoJugadorDetallePageState();
}

class _SeguimientoJugadorDetallePageState
    extends State<SeguimientoJugadorDetallePage> {
  late final CoordinacionService _servicio =
      widget.servicio ?? CoordinacionService();

  late Future<SeguimientoDetalleModel> _futuro;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = _servicio.obtenerDetalle(
      widget.jugador.jugadorId,
      periodo: widget.periodo,
    );
  }

  String _etiquetaEstado(String estado) {
    return switch (estado) {
      'FALTA' => _t.attendanceStatusAbsent,
      'FALTA_JUSTIFICADA' => _t.attendanceStatusJustifiedAbsence,
      'MAL_COMPORTAMIENTO' => _t.attendanceStatusMisconduct,
      'RETRASO' => _t.attendanceStatusLate,
      'PRESENTE' => _t.attendanceStatusPresent,
      _ => estado,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: widget.jugador.nombre)),
      body: FutureBuilder<SeguimientoDetalleModel>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_t.connectionError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(_cargar),
                      icon: const Icon(Icons.refresh),
                      label: Text(_t.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final incidencias = snapshot.data!.incidencias;

          if (incidencias.isEmpty) {
            return Center(
              child: Text(
                _t.trackingNoIncidents,
                style: TextStyle(color: _colors.onSurfaceVariant),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final incidencia in incidencias)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(fechaCorta(incidencia.fecha)),
                    trailing: Text(
                      _etiquetaEstado(incidencia.estado),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// dd/MM/yyyy; vacío si no hay fecha.
String fechaCorta(DateTime? fecha) {
  if (fecha == null) return '';

  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');

  return '$dia/$mes/${fecha.year}';
}
