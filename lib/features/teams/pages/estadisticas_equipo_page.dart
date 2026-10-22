import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../models/estadisticas_equipo_model.dart';
import '../services/estadisticas_equipo_service.dart';

/// Estadísticas del equipo en la temporada activa: resultados, goleadores,
/// asistentes y asistencia a entrenamientos.
class EstadisticasEquipoPage extends StatefulWidget {
  final PerfilEquipo equipo;
  final EstadisticasEquipoService? servicio;

  const EstadisticasEquipoPage({
    super.key,
    required this.equipo,
    this.servicio,
  });

  @override
  State<EstadisticasEquipoPage> createState() => _EstadisticasEquipoPageState();
}

class _EstadisticasEquipoPageState extends State<EstadisticasEquipoPage> {
  /// Por debajo de este porcentaje la asistencia de un jugador se marca en ámbar.
  static const int umbralAsistenciaBaja = 75;

  static const Color _ambar = Color(0xFFF59E0B);

  late final EstadisticasEquipoService _servicio =
      widget.servicio ?? EstadisticasEquipoService();

  late Future<EstadisticasEquipoModel> _futuro;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerEstadisticas(widget.equipo.id);
  }

  Future<void> _recargar() async {
    final nuevo = _servicio.obtenerEstadisticas(widget.equipo.id);

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
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.teamStatsTitle)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<EstadisticasEquipoModel>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _construirError(snapshot.error);
            }

            final datos = snapshot.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _construirResumen(datos),
                const SizedBox(height: 24),
                if (datos.admiteEstadisticas) ...[
                  _construirSeccion(
                    _t.statsTopScorers,
                    datos.goleadores.isEmpty
                        ? [_construirVacio()]
                        : datos.goleadores
                              .map(
                                (j) => _construirFilaJugador(
                                  j,
                                  _t.statsGoalsCount(j.goles),
                                ),
                              )
                              .toList(),
                  ),
                  const SizedBox(height: 24),
                  _construirSeccion(
                    _t.statsTopAssisters,
                    datos.asistentes.isEmpty
                        ? [_construirVacio()]
                        : datos.asistentes
                              .map(
                                (j) => _construirFilaJugador(
                                  j,
                                  _t.statsAssistsCount(j.asistencias),
                                ),
                              )
                              .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                _construirSeccion(
                  _t.statsTrainingAttendance,
                  datos.entrenamientos.porJugador.isEmpty
                      ? [_construirVacio()]
                      : datos.entrenamientos.porJugador
                            .map(_construirFilaAsistencia)
                            .toList(),
                  nota: datos.entrenamientos.sesionesSinRevisar > 0
                      ? _t.statsUnreviewedNote(
                          datos.entrenamientos.sesionesSinRevisar,
                        )
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _construirResumen(EstadisticasEquipoModel datos) {
    final p = datos.partidos;
    final media = datos.entrenamientos.asistenciaMedia;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _construirDato(_t.statsPlayedShort, '${p.jugados}'),
        _construirDato(_t.statsWonShort, '${p.ganados}'),
        _construirDato(_t.statsDrawnShort, '${p.empatados}'),
        _construirDato(_t.statsLostShort, '${p.perdidos}'),
        _construirDato(_t.statsGoalsForShort, '${p.golesFavor}'),
        _construirDato(_t.statsGoalsAgainstShort, '${p.golesContra}'),
        _construirDato(
          _t.statsAttendanceAverage,
          media == null ? '-' : _t.statsPercent(media),
          ancho: 170,
        ),
      ],
    );
  }

  Widget _construirDato(String etiqueta, String valor, {double ancho = 80}) {
    return SizedBox(
      width: ancho,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        color: _colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirSeccion(String titulo, List<Widget> filas, {String? nota}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
        ),
        if (nota != null) ...[
          Container(
            key: const ValueKey('nota-sin-revisar'),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: _ambar.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(nota, style: const TextStyle(fontSize: 13)),
          ),
        ],
        const SizedBox(height: 10),
        ...filas,
      ],
    );
  }

  Widget _construirVacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        _t.statsNoData,
        style: TextStyle(color: _colors.onSurfaceVariant),
      ),
    );
  }

  Widget _construirFilaJugador(JugadorDestacadoModel jugador, String detalle) {
    return _construirFila(
      dorsal: jugador.dorsal?.toString() ?? '-',
      nombre: jugador.nombre,
      detalle: detalle,
    );
  }

  Widget _construirFilaAsistencia(AsistenciaJugadorModel jugador) {
    final porcentaje = jugador.porcentaje;
    final baja = porcentaje != null && porcentaje < umbralAsistenciaBaja;

    return _construirFila(
      nombre: jugador.nombre,
      detalle: _t.statsAttendedOf(jugador.asistidos, jugador.total),
      valor: porcentaje == null ? '-' : _t.statsPercent(porcentaje),
      colorValor: baja ? _ambar : null,
    );
  }

  Widget _construirFila({
    String? dorsal,
    required String nombre,
    required String detalle,
    String? valor,
    Color? colorValor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (dorsal != null)
              SizedBox(
                width: 32,
                child: Text(
                  dorsal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _colors.primary,
                  ),
                ),
              ),
            if (dorsal != null) const SizedBox(width: 8),
            Expanded(
              child: Text(
                nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _colors.onSurface,
                ),
              ),
            ),
            Text(detalle, style: TextStyle(color: _colors.onSurfaceVariant)),
            if (valor != null) ...[
              const SizedBox(width: 12),
              Text(
                valor,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorValor ?? _colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirError(Object? error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          mensajeDeError(_t, error),
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
