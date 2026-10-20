import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../models/estadisticas_equipo_model.dart';
import '../services/estadisticas_equipo_service.dart';

/// Amarillas y rojas de cada jugador del equipo en la temporada activa, con un
/// aviso cuando está a una amarilla de la sanción o ya la tiene posible.
class TarjetasEquipoPage extends StatefulWidget {
  final PerfilEquipo equipo;
  final EstadisticasEquipoService? servicio;

  const TarjetasEquipoPage({super.key, required this.equipo, this.servicio});

  @override
  State<TarjetasEquipoPage> createState() => _TarjetasEquipoPageState();
}

class _TarjetasEquipoPageState extends State<TarjetasEquipoPage> {
  static const Color _ambar = Color(0xFFF59E0B);
  static const Color _rojo = Color(0xFFDC2626);

  late final EstadisticasEquipoService _servicio =
      widget.servicio ?? EstadisticasEquipoService();

  late Future<List<TarjetasJugadorModel>> _futuro;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerTarjetas(widget.equipo.id);
  }

  Future<void> _recargar() async {
    final nuevo = _servicio.obtenerTarjetas(widget.equipo.id);

    setState(() {
      _futuro = nuevo;
    });

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.teamCardsTitle)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<TarjetasJugadorModel>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _construirError();
            }

            final jugadores = snapshot.data ?? [];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (jugadores.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      _t.cardsNoPlayers,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _colors.onSurfaceVariant),
                    ),
                  )
                else
                  for (final jugador in jugadores) ...[
                    _construirJugador(jugador),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 8),
                Text(
                  _t.cardsFooterNote,
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

  Widget _construirJugador(TarjetasJugadorModel jugador) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                jugador.dorsal?.toString() ?? '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jugador.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                  ),
                  if (_etiquetaDeEstado(jugador.estado) != null) ...[
                    const SizedBox(height: 6),
                    _construirChip(jugador.estado),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _construirTarjeta(
              color: const Color(0xFFFACC15),
              cantidad: jugador.amarillas,
              etiqueta: _t.yellowCardsLabel,
            ),
            const SizedBox(width: 12),
            _construirTarjeta(
              color: _rojo,
              cantidad: jugador.rojas,
              etiqueta: _t.redCardsLabel,
            ),
          ],
        ),
      ),
    );
  }

  String? _etiquetaDeEstado(String estado) {
    return switch (estado) {
      estadoTarjetaAUna => _t.cardsStatusOneAway,
      estadoTarjetaSancionPosible => _t.cardsStatusSanction,
      _ => null,
    };
  }

  Widget _construirChip(String estado) {
    final color = estado == estadoTarjetaSancionPosible ? _rojo : _ambar;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        _etiquetaDeEstado(estado)!,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _construirTarjeta({
    required Color color,
    required int cantidad,
    required String etiqueta,
  }) {
    return Semantics(
      label: '$etiqueta: $cantidad',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$cantidad',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          _t.connectionError,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: _colors.onSurface),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
            label: Text(_t.retry),
          ),
        ),
      ],
    );
  }
}
