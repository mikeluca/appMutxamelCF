import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/como_llegar.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../model/convocatoria_partido_model.dart';
import '../services/convocatoria_partido_service.dart';

/// La convocatoria de un partido vista por un jugador o un familiar: rival, fecha
/// y hora, local o visitante, la citación (con "Cómo llegar"), si el jugador está
/// convocado y la lista de convocados con el jugador del usuario resaltado.
class ConvocatoriaFamiliaPage extends StatefulWidget {
  final int partidoId;
  final int jugadorId;

  /// Nombre y apellidos del jugador del usuario, para resaltarlo en la lista.
  final String jugadorNombre;
  final String jugadorApellidos;

  /// Solo para tests: sustituye al servicio real.
  final ConvocatoriaPartidoService? service;

  const ConvocatoriaFamiliaPage({
    super.key,
    required this.partidoId,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.jugadorApellidos,
    this.service,
  });

  @override
  State<ConvocatoriaFamiliaPage> createState() =>
      _ConvocatoriaFamiliaPageState();
}

class _ConvocatoriaFamiliaPageState extends State<ConvocatoriaFamiliaPage> {
  late final ConvocatoriaPartidoService _service =
      widget.service ?? ConvocatoriaPartidoService();

  ConvocatoriaPartidoModel? _convocatoria;
  bool _cargando = true;

  /// true si el error es que la convocatoria ya no existe (404).
  bool _noDisponible = false;
  bool _error = false;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = false;
      _noDisponible = false;
    });

    try {
      final convocatoria = await _service.obtener(
        partidoId: widget.partidoId,
        jugadorId: widget.jugadorId,
      );

      if (!mounted) return;

      setState(() {
        _convocatoria = convocatoria;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _noDisponible = e is ApiException && e.statusCode == 404;
        _error = true;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.callupDetailTitle)),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final convocatoria = _convocatoria;

    if (_error || convocatoria == null) {
      return Center(
        key: const ValueKey('convocatoria-familia-error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _noDisponible ? _t.callupUnavailable : _t.callupFamilyLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _colors.onSurface,
                ),
              ),
              if (!_noDisponible) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh),
                  label: Text(_t.retry),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _construirCabecera(convocatoria),
          const SizedBox(height: 14),
          _construirCitacion(convocatoria),
          const SizedBox(height: 14),
          _construirEstado(convocatoria),
          const SizedBox(height: 24),
          Text(
            _t.callupPlayersTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t.callupPlayersCount(convocatoria.convocados.length),
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...convocatoria.convocados.map(_construirConvocado),
        ],
      ),
    );
  }

  Widget _tarjeta({required Widget child, Key? key}) {
    return Card(
      key: key,
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _construirCabecera(ConvocatoriaPartidoModel convocatoria) {
    final fecha = convocatoria.fecha == null
        ? null
        : formatearFechaConDiaSemana(convocatoria.fecha!, _t);

    final hora = convocatoria.hora?.trim() ?? '';
    final campo = convocatoria.campo?.trim() ?? '';

    return _tarjeta(
      key: const ValueKey('convocatoria-cabecera'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  convocatoria.rival,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
              ),
              _etiqueta(
                convocatoria.local ? _t.callupFamilyHome : _t.callupFamilyAway,
                AppColors.azul,
              ),
            ],
          ),
          if (fecha != null || hora.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [?fecha, if (hora.isNotEmpty) hora].join(' · '),
              style: TextStyle(color: _colors.onSurfaceVariant),
            ),
          ],
          if (campo.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: _colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    campo,
                    style: TextStyle(color: _colors.onSurfaceVariant),
                  ),
                ),
                BotonComoLlegar(lugar: campo),
              ],
            ),
        ],
      ),
    );
  }

  Widget _construirCitacion(ConvocatoriaPartidoModel convocatoria) {
    final hora = convocatoria.horaCitacion?.trim() ?? '';
    final lugar = convocatoria.lugarCitacion?.trim() ?? '';

    return _tarjeta(
      key: const ValueKey('convocatoria-citacion'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t.callupFamilyMeetingTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
          if (hora.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _t.callupFamilyMeetingTime(hora),
              style: TextStyle(color: _colors.onSurfaceVariant),
            ),
          ],
          if (lugar.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t.callupFamilyMeetingPlace(lugar),
                    style: TextStyle(color: _colors.onSurfaceVariant),
                  ),
                ),
                BotonComoLlegar(lugar: lugar),
              ],
            ),
        ],
      ),
    );
  }

  Widget _construirEstado(ConvocatoriaPartidoModel convocatoria) {
    final color = convocatoria.convocado
        ? Colors.green
        : _colors.onSurfaceVariant;

    return Row(
      key: const ValueKey('convocatoria-estado'),
      children: [
        Icon(
          convocatoria.convocado
              ? Icons.check_circle_outline
              : Icons.remove_circle_outline,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.jugadorNombre}: '
          '${convocatoria.convocado ? _t.calendarCalledUpBadge : _t.calendarNotCalledUpBadge}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _etiqueta(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _construirConvocado(ConvocadoPartidoModel convocado) {
    final propio = convocado.esJugador(
      widget.jugadorNombre,
      widget.jugadorApellidos,
    );

    return Card(
      key: ValueKey(
        propio ? 'convocado-propio' : 'convocado-${convocado.nombreCompleto}',
      ),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: propio
          ? AppColors.azul.withValues(alpha: 0.10)
          : _colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: propio ? AppColors.azul : _colors.outlineVariant,
          width: propio ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                convocado.dorsal?.toString() ?? '–',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: propio ? AppColors.azul : _colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                convocado.nombreCompleto,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: propio ? FontWeight.bold : FontWeight.w600,
                  color: _colors.onSurface,
                ),
              ),
            ),
            if (propio) _etiqueta(_t.callupFamilyYourPlayer, AppColors.azul),
          ],
        ),
      ),
    );
  }
}
