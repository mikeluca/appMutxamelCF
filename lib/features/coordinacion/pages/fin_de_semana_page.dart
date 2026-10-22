import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../convocatorias/pages/convocatoria_form_page.dart';
import '../../matches/models/match_model.dart';
import '../../matches/pages/resultado_partido_form_page.dart';
import '../models/coordinacion_model.dart';
import '../services/coordinacion_service.dart';

/// Panel del fin de semana para coordinación: partidos sin convocatoria,
/// resultados pendientes, equipos que descansan y equipos sin partido.
class FinDeSemanaPage extends StatefulWidget {
  final CoordinacionService? servicio;

  /// Solo para tests: sustituyen a los formularios reales (que piden datos a
  /// la red al abrirse).
  final Widget Function(PartidoPanelModel partido)? constructorConvocatoria;
  final Widget Function(PartidoPanelModel partido)? constructorResultado;

  const FinDeSemanaPage({
    super.key,
    this.servicio,
    this.constructorConvocatoria,
    this.constructorResultado,
  });

  @override
  State<FinDeSemanaPage> createState() => _FinDeSemanaPageState();
}

class _FinDeSemanaPageState extends State<FinDeSemanaPage> {
  static const Color _rojo = Color(0xFFDC2626);
  static const Color _ambar = Color(0xFFF59E0B);
  static const Color _verde = Color(0xFF16A34A);
  static const Color _gris = Color(0xFF6B7280);

  late final CoordinacionService _servicio =
      widget.servicio ?? CoordinacionService();

  late Future<FinDeSemanaModel> _futuro;

  /// Viernes del fin de semana que se está viendo; null hasta la primera carga
  /// (entonces manda el del servidor, que es el de hoy).
  DateTime? _viernes;

  /// Recordatorios ya enviados en esta sesión ("tipo:partidoId"): su botón pasa a
  /// "Recordado". Y los que están enviándose ahora.
  final Set<String> _recordados = {};
  final Set<String> _enviandoRecordatorio = {};

  /// Para ignorar la respuesta de una carga que ya se quedó antigua (flechas
  /// pulsadas seguidas).
  int _generacion = 0;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar(null);
  }

  Future<FinDeSemanaModel> _cargar(DateTime? fecha) async {
    final generacion = ++_generacion;

    final datos = await _servicio.obtenerFinDeSemana(fecha: fecha);

    if (generacion == _generacion) {
      _viernes = datos.desde;
    }

    return datos;
  }

  void _irA(DateTime? fecha) {
    setState(() {
      _futuro = _cargar(fecha);
    });
  }

  void _desplazar(int semanas) {
    final base = _viernes;

    if (base == null) return;

    // Por días de calendario: sumar Duration(days: 7) se desfasa una hora al
    // cruzar un cambio de horario.
    _irA(DateTime(base.year, base.month, base.day + 7 * semanas));
  }

  Future<void> _recargar() async {
    final nuevo = _cargar(_viernes);

    setState(() {
      _futuro = nuevo;
    });

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

    if (mounted) {
      await _recargar();
    }
  }

  void _abrirConvocatoria(PartidoPanelModel partido) {
    _abrir(
      widget.constructorConvocatoria?.call(partido) ??
          ConvocatoriaFormPage(
            equipo: PerfilEquipo(id: partido.equipoId, nombre: partido.equipo),
            partidoIdInicial: partido.partidoId,
          ),
    );
  }

  void _abrirResultado(PartidoPanelModel partido) {
    _abrir(
      widget.constructorResultado?.call(partido) ??
          ResultadoPartidoFormPage(
            partido: MatchModel(
              id: partido.partidoId,
              equipoId: partido.equipoId,
              categoria: '',
              equipo: partido.equipo,
              rival: partido.rival,
              dia: partido.dia,
              hora: partido.hora,
              local: partido.local,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPageWeekend)),
      body: Column(
        children: [
          _construirCabecera(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recargar,
              child: FutureBuilder<FinDeSemanaModel>(
                future: _futuro,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return _construirError(snapshot.error);
                  }

                  return _construirContenido(snapshot.data!);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabecera() {
    return FutureBuilder<FinDeSemanaModel>(
      future: _futuro,
      builder: (context, snapshot) {
        final datos = snapshot.data;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: _t.weekendPrevious,
                onPressed: datos == null ? null : () => _desplazar(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  datos == null
                      ? ''
                      : '${_fechaCorta(datos.desde)} - ${_fechaCorta(datos.hasta)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: _t.weekendNext,
                onPressed: datos == null ? null : () => _desplazar(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirContenido(FinDeSemanaModel datos) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (datos.todoAlDia) _construirTodoAlDia(),
        if (datos.sinConvocatoria.isNotEmpty)
          _construirSeccion(
            titulo: _t.weekendNoCallup,
            color: _rojo,
            cantidad: datos.sinConvocatoria.length,
            hijos: [
              for (final p in datos.sinConvocatoria)
                _construirPartido(
                  p,
                  subtitulo: '${_fechaCorta(p.dia)} ${p.hora ?? ''}'.trim(),
                  onTap: () => _abrirConvocatoria(p),
                  tipoRecordatorio: tipoRecordatorioConvocatoria,
                ),
            ],
          ),
        if (datos.resultadosPendientes.isNotEmpty)
          _construirSeccion(
            titulo: _t.weekendPendingResults,
            color: _ambar,
            cantidad: datos.resultadosPendientes.length,
            hijos: [
              for (final p in datos.resultadosPendientes)
                _construirPartido(
                  p,
                  subtitulo:
                      '${_fechaCorta(p.dia)} ${p.hora ?? ''} · '
                              '${_t.weekendDelayDays(p.diasDeRetraso)}'
                          .trim(),
                  onTap: () => _abrirResultado(p),
                  tipoRecordatorio: tipoRecordatorioResultado,
                ),
            ],
          ),
        if (datos.descansan.isNotEmpty)
          _construirSeccion(
            titulo: _t.weekendResting,
            color: _gris,
            cantidad: datos.descansan.length,
            hijos: [
              for (final e in datos.descansan)
                ListTile(
                  title: Text(e.equipo),
                  subtitle: e.jornada == null
                      ? null
                      : Text(_t.weekendRound(e.jornada!)),
                ),
            ],
          ),
        if (datos.sinPartido.isNotEmpty)
          _construirSeccion(
            titulo: _t.weekendNoMatch,
            color: _gris,
            cantidad: datos.sinPartido.length,
            nota: _t.weekendNoMatchNote,
            hijos: [
              for (final e in datos.sinPartido) ListTile(title: Text(e.equipo)),
            ],
          ),
        if (datos.ultimaImportacionFfcv != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _t.weekendLastImport(_fechaCorta(datos.ultimaImportacionFfcv)),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _construirTodoAlDia() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: _verde),
          const SizedBox(height: 12),
          Text(
            _t.weekendAllClear,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSeccion({
    required String titulo,
    required Color color,
    required int cantidad,
    required List<Widget> hijos,
    String? nota,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cantidad',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        children: [
          if (nota != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  nota,
                  style: TextStyle(color: _colors.onSurfaceVariant),
                ),
              ),
            ),
          ...hijos,
        ],
      ),
    );
  }

  Widget _construirPartido(
    PartidoPanelModel partido, {
    required String subtitulo,
    required VoidCallback onTap,
    required String tipoRecordatorio,
  }) {
    return ListTile(
      title: Text('${partido.equipo} - ${partido.rival}'),
      subtitle: Text(subtitulo),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirBotonRecordar(partido, tipoRecordatorio),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  /// "Recordar" al entrenador del equipo; tras enviarlo, "Recordado" (hasta salir de la
  /// pantalla) para no repetirlo sin querer.
  Widget _construirBotonRecordar(PartidoPanelModel partido, String tipo) {
    final clave = '$tipo:${partido.partidoId}';
    final recordado = _recordados.contains(clave);
    final enviando = _enviandoRecordatorio.contains(clave);

    return TextButton.icon(
      key: ValueKey('recordar-$clave'),
      onPressed: recordado || enviando ? null : () => _recordar(partido, tipo),
      icon: Icon(
        recordado
            ? Icons.notifications_active
            : Icons.notifications_active_outlined,
        size: 18,
      ),
      label: Text(recordado ? _t.weekendReminded : _t.weekendRemind),
    );
  }

  Future<void> _recordar(PartidoPanelModel partido, String tipo) async {
    final clave = '$tipo:${partido.partidoId}';

    setState(() => _enviandoRecordatorio.add(clave));

    String mensaje;

    try {
      final enviado = await _servicio.recordar(
        partidoId: partido.partidoId,
        tipo: tipo,
      );

      _recordados.add(clave);
      mensaje = _t.weekendReminderSent(enviado.destinatarios);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        mensaje = _t.weekendReminderNoCoaches;
      } else if (e.statusCode == 429) {
        // Ya se había enviado hace menos de 2 horas: se da por recordado.
        _recordados.add(clave);

        final datos = e.datos;
        final ultimo = datos is Map
            ? DateTime.tryParse(datos['ultimo']?.toString() ?? '')
            : null;

        mensaje = ultimo == null
            ? _t.weekendReminderError
            : _t.weekendReminderTooSoon(_horaCorta(ultimo));
      } else if (e.statusCode == 403) {
        mensaje = _t.noPermission;
      } else {
        mensaje = mensajeDeAccion(_t, e);
      }
    } catch (_) {
      mensaje = _t.weekendReminderError;
    }

    if (!mounted) return;

    setState(() => _enviandoRecordatorio.remove(clave));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  static String _horaCorta(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
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

  static String _fechaCorta(DateTime? fecha) {
    if (fecha == null) return '';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }
}
