import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../matches/models/match_model.dart';
import '../../matches/pages/resultado_partido_form_page.dart';
import '../model/calendario_model.dart';
import '../model/horario_entrenamiento_model.dart';
import '../model/justificacion_falta_model.dart';
import '../model/sesion_entrenamiento_model.dart';
import '../services/calendario_service.dart';
import '../widgets/calendario_mensual.dart';

/// Gestión del calendario de un equipo (vista de entrenador/coordinador):
/// configuración del horario semanal fijo de entrenamientos y listado de
/// las sesiones/partidos generados, con edición/cancelación.
class CalendarioGestionPage extends StatefulWidget {
  final PerfilEquipo equipo;

  const CalendarioGestionPage({super.key, required this.equipo});

  @override
  State<CalendarioGestionPage> createState() => _CalendarioGestionPageState();
}

class _DatosCalendarioGestion {
  final List<HorarioEntrenamientoModel> horarios;
  final CalendarioModel calendario;

  _DatosCalendarioGestion(this.horarios, this.calendario);
}

class _CalendarioGestionPageState extends State<CalendarioGestionPage> {
  final CalendarioService _service = CalendarioService();

  late Future<_DatosCalendarioGestion> _futureDatos;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futureDatos = _cargarDatos();
  }

  Future<_DatosCalendarioGestion> _cargarDatos() async {
    final hoy = DateTime.now();
    final desde = DateTime(hoy.year, hoy.month, hoy.day);
    // Misma ventana de dos meses que la generación de sesiones del backend.
    final hasta = DateTime(hoy.year, hoy.month + 2, hoy.day);

    final resultados = await Future.wait([
      _service.obtenerHorarios(widget.equipo.id),
      _service.obtenerCalendario(
        equipoId: widget.equipo.id,
        desde: desde,
        hasta: hasta,
      ),
    ]);

    return _DatosCalendarioGestion(
      resultados[0] as List<HorarioEntrenamientoModel>,
      resultados[1] as CalendarioModel,
    );
  }

  Future<void> _recargar() async {
    setState(_cargar);
    await _futureDatos;
  }

  String _etiquetaDia(int dia) {
    switch (dia) {
      case 1:
        return _t.weekdayMonday;
      case 2:
        return _t.weekdayTuesday;
      case 3:
        return _t.weekdayWednesday;
      case 4:
        return _t.weekdayThursday;
      case 5:
        return _t.weekdayFriday;
      case 6:
        return _t.weekdaySaturday;
      default:
        return _t.weekdaySunday;
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ============================================================
  // HORARIOS SEMANALES
  // ============================================================

  Future<void> _abrirFormularioHorario({
    HorarioEntrenamientoModel? existente,
  }) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _HorarioFormDialog(
        calendarioService: _service,
        equipoId: widget.equipo.id,
        horarioExistente: existente,
      ),
    );

    if (guardado == true && mounted) {
      _mostrarMensaje(_t.weeklyScheduleSavedSuccess);
      await _recargar();
    }
  }

  Future<void> _confirmarDesactivarHorario(
    HorarioEntrenamientoModel horario,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.weeklyScheduleDeactivateConfirmTitle),
        content: Text(_t.weeklyScheduleDeactivateConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.delete),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await _service.eliminarHorario(horario.id);

      if (!mounted) return;

      _mostrarMensaje(_t.weeklyScheduleDeactivatedSuccess);
      await _recargar();
    } catch (e) {
      _mostrarMensaje(_t.weeklyScheduleDeactivateError(e.toString()));
    }
  }

  // ============================================================
  // SESIONES DE ENTRENAMIENTO
  // ============================================================

  Future<void> _abrirFormularioSesion(SesionEntrenamientoModel sesion) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _SesionEditDialog(
        calendarioService: _service,
        sesion: sesion,
      ),
    );

    if (guardado == true && mounted) {
      _mostrarMensaje(_t.sessionEditSavedSuccess);
      await _recargar();
    }
  }

  Future<void> _confirmarCancelarSesion(
    SesionEntrenamientoModel sesion,
  ) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => _MotivoCancelacionDialog(
        titulo: _t.sessionCancelConfirmTitle,
        hint: _t.sessionCancelConfirmMessage,
      ),
    );

    if (motivo == null || !mounted) return;

    try {
      await _service.cancelarSesion(sesion.id, motivo);

      if (!mounted) return;

      _mostrarMensaje(_t.sessionCancelledSuccess);
      await _recargar();
    } catch (e) {
      _mostrarMensaje(_t.sessionCancelError(e.toString()));
    }
  }

  Future<void> _verJustificaciones(SesionEntrenamientoModel sesion) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _JustificacionesDialog(
        calendarioService: _service,
        sesionId: sesion.id,
      ),
    );
  }

  // ============================================================
  // PARTIDOS
  // ============================================================

  Future<void> _abrirFormularioResultadoPartido(MatchModel partido) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoPartidoFormPage(partido: partido),
      ),
    );

    if (guardado == true && mounted) {
      await _recargar();
    }
  }

  Future<void> _confirmarCancelarPartido(MatchModel partido) async {
    if (partido.id == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.matchCancelConfirmTitle),
        content: Text(_t.matchCancelConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.delete),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await _service.cancelarPartido(partido.id!);

      if (!mounted) return;

      _mostrarMensaje(_t.matchCancelledSuccess);
      await _recargar();
    } catch (e) {
      _mostrarMensaje(_t.matchCancelError(e.toString()));
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: _t.calendarManagementTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<_DatosCalendarioGestion>(
          future: _futureDatos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _construirError(snapshot.error);
            }

            final datos = snapshot.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text(
                  widget.equipo.nombre,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  _t.weeklyScheduleTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                if (datos.horarios.isEmpty)
                  _construirVacio(_t.weeklyScheduleEmpty)
                else
                  for (final horario in datos.horarios) ...[
                    _construirTarjetaHorario(horario),
                    const SizedBox(height: 10),
                  ],

                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirFormularioHorario(),
                    icon: const Icon(Icons.add),
                    label: Text(_t.weeklyScheduleAddButton),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  _t.upcomingItemsTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                CalendarioMensual<ItemCalendario>(
                  items: datos.calendario.itemsOrdenados,
                  fechaDe: (item) => item.fecha,
                  textoSinEventosDia: _t.upcomingItemsEmpty,
                  locale: Localizations.localeOf(context).languageCode,
                  itemBuilder: (context, item) => _construirTarjetaItem(item),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _construirVacio(String mensaje) {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          mensaje,
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _construirTarjetaHorario(HorarioEntrenamientoModel horario) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_repeat,
                color: _colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_etiquetaDia(horario.diaSemana)} · ${horario.hora}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _colors.onSurface,
                        ),
                      ),
                      if (!horario.activo) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _t.weeklyScheduleInactiveBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (horario.lugar != null && horario.lugar!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      horario.lugar!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: _t.weeklyScheduleEditTooltip,
              onPressed: () => _abrirFormularioHorario(existente: horario),
            ),
            if (horario.activo)
              IconButton(
                icon: const Icon(Icons.block, color: Colors.redAccent),
                tooltip: _t.weeklyScheduleDeactivateTooltip,
                onPressed: () => _confirmarDesactivarHorario(horario),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaItem(ItemCalendario item) {
    final icono = item.esEntrenamiento
        ? Icons.fitness_center
        : Icons.sports_soccer;

    final etiquetaTipo = item.esEntrenamiento
        ? _t.calendarSessionLabel
        : _t.calendarMatchLabel;

    final colorIcono = item.cancelado
        ? _colors.onSurfaceVariant
        : _colors.primary;

    final subtitulo = item.esEntrenamiento
        ? (item.sesion?.lugar ?? '')
        : (item.partido?.rival ?? '');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorIcono.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: colorIcono, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        etiquetaTipo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _colors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (item.cancelado) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _t.calendarCancelledBadge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearFecha(item.fecha) +
                        (item.hora != null && item.hora!.isNotEmpty
                            ? ' · ${item.hora}'
                            : ''),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: item.cancelado
                          ? _colors.onSurfaceVariant
                          : _colors.onSurface,
                      decoration: item.cancelado
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (subtitulo.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: _colors.onSurfaceVariant,
                        decoration: item.cancelado
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                  if (item.cancelado &&
                      (item.sesion?.motivoCancelacion?.trim().isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_t.cancelReasonLabel}: ${item.sesion!.motivoCancelacion}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _construirAccionesItem(item),
          ],
        ),
      ),
    );
  }

  Widget _construirAccionesItem(ItemCalendario item) {
    final botones = <Widget>[];

    if (item.esEntrenamiento && item.sesion != null) {
      final sesion = item.sesion!;

      if (!item.cancelado) {
        botones.add(
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: _t.sessionEditTooltip,
            onPressed: () => _abrirFormularioSesion(sesion),
          ),
        );
        botones.add(
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
            tooltip: _t.sessionCancelTooltip,
            onPressed: () => _confirmarCancelarSesion(sesion),
          ),
        );
      }

      botones.add(
        IconButton(
          icon: const Icon(Icons.groups_outlined),
          tooltip: _t.viewJustificationsTooltip,
          onPressed: () => _verJustificaciones(sesion),
        ),
      );
    } else if (item.partido != null && !item.cancelado) {
      final partido = item.partido!;

      if (partido.esPartidoPasado) {
        botones.add(
          IconButton(
            icon: const Icon(Icons.scoreboard_outlined),
            tooltip: partido.estaJugado
                ? _t.matchEditResultTooltip
                : _t.matchEnterResultTooltip,
            onPressed: () => _abrirFormularioResultadoPartido(partido),
          ),
        );
      }

      botones.add(
        IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
          tooltip: _t.matchCancelTooltip,
          onPressed: () => _confirmarCancelarPartido(partido),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: botones);
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
              _t.calendarManagementLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(_cargar);
              },
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final diasSemana = [
      _t.weekdayMonday,
      _t.weekdayTuesday,
      _t.weekdayWednesday,
      _t.weekdayThursday,
      _t.weekdayFriday,
      _t.weekdaySaturday,
      _t.weekdaySunday,
    ];

    final diaSemana = diasSemana[fecha.weekday - 1];

    return '$diaSemana ${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }
}

// ============================================================
// FORMULARIO DE HORARIO SEMANAL
// ============================================================

class _HorarioFormDialog extends StatefulWidget {
  final CalendarioService calendarioService;
  final int equipoId;
  final HorarioEntrenamientoModel? horarioExistente;

  const _HorarioFormDialog({
    required this.calendarioService,
    required this.equipoId,
    this.horarioExistente,
  });

  @override
  State<_HorarioFormDialog> createState() => _HorarioFormDialogState();
}

class _HorarioFormDialogState extends State<_HorarioFormDialog> {
  late final TextEditingController _lugarController;

  int _diaSemana = 1;
  TimeOfDay _hora = const TimeOfDay(hour: 18, minute: 0);
  bool _activo = true;

  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.horarioExistente != null;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    final horario = widget.horarioExistente;

    _lugarController = TextEditingController(text: horario?.lugar ?? '');
    _diaSemana = horario?.diaSemana ?? 1;
    _activo = horario?.activo ?? true;

    if (horario != null) {
      final partes = horario.hora.split(':');

      _hora = TimeOfDay(
        hour: int.tryParse(partes.isNotEmpty ? partes[0] : '') ?? 18,
        minute: int.tryParse(partes.length > 1 ? partes[1] : '') ?? 0,
      );
    }
  }

  @override
  void dispose() {
    _lugarController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);

    if (hora == null) return;

    setState(() {
      _hora = hora;
    });
  }

  String _etiquetaDia(int dia) {
    switch (dia) {
      case 1:
        return _t.weekdayMonday;
      case 2:
        return _t.weekdayTuesday;
      case 3:
        return _t.weekdayWednesday;
      case 4:
        return _t.weekdayThursday;
      case 5:
        return _t.weekdayFriday;
      case 6:
        return _t.weekdaySaturday;
      default:
        return _t.weekdaySunday;
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final hora =
          '${_hora.hour.toString().padLeft(2, '0')}:'
          '${_hora.minute.toString().padLeft(2, '0')}';

      final lugar = _lugarController.text.trim().isEmpty
          ? null
          : _lugarController.text.trim();

      if (_esEdicion) {
        await widget.calendarioService.actualizarHorario(
          horarioId: widget.horarioExistente!.id,
          diaSemana: _diaSemana,
          hora: hora,
          lugar: lugar,
          activo: _activo,
        );
      } else {
        await widget.calendarioService.crearHorario(
          equipoId: widget.equipoId,
          diaSemana: _diaSemana,
          hora: hora,
          lugar: lugar,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _esEdicion
            ? _t.weeklyScheduleFormTitleEdit
            : _t.weeklyScheduleFormTitleNew,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _diaSemana,
              decoration: InputDecoration(
                labelText: _t.weeklyScheduleDayLabel,
                border: const OutlineInputBorder(),
              ),
              items: List.generate(7, (index) => index + 1)
                  .map(
                    (dia) => DropdownMenuItem(
                      value: dia,
                      child: Text(_etiquetaDia(dia)),
                    ),
                  )
                  .toList(),
              onChanged: _guardando
                  ? null
                  : (valor) {
                      if (valor == null) return;

                      setState(() {
                        _diaSemana = valor;
                      });
                    },
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _guardando ? null : _seleccionarHora,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _t.weeklyScheduleTimeLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                child: Text(_hora.format(context)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _lugarController,
              enabled: !_guardando,
              decoration: InputDecoration(
                labelText: _t.weeklySchedulePlaceLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_esEdicion) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_t.weeklyScheduleActiveLabel),
                value: _activo,
                onChanged: _guardando
                    ? null
                    : (valor) {
                        setState(() {
                          _activo = valor;
                        });
                      },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: Text(_t.cancel),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_t.save),
        ),
      ],
    );
  }
}

// ============================================================
// EDICIÓN DE UNA SESIÓN (HORA/LUGAR)
// ============================================================

class _SesionEditDialog extends StatefulWidget {
  final CalendarioService calendarioService;
  final SesionEntrenamientoModel sesion;

  const _SesionEditDialog({
    required this.calendarioService,
    required this.sesion,
  });

  @override
  State<_SesionEditDialog> createState() => _SesionEditDialogState();
}

class _SesionEditDialogState extends State<_SesionEditDialog> {
  late final TextEditingController _lugarController;
  late TimeOfDay _hora;

  bool _guardando = false;
  String? _error;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    _lugarController = TextEditingController(text: widget.sesion.lugar ?? '');

    final partes = (widget.sesion.hora ?? '').split(':');

    _hora = TimeOfDay(
      hour: int.tryParse(partes.isNotEmpty ? partes[0] : '') ?? 18,
      minute: int.tryParse(partes.length > 1 ? partes[1] : '') ?? 0,
    );
  }

  @override
  void dispose() {
    _lugarController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);

    if (hora == null) return;

    setState(() {
      _hora = hora;
    });
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final hora =
          '${_hora.hour.toString().padLeft(2, '0')}:'
          '${_hora.minute.toString().padLeft(2, '0')}';

      final lugar = _lugarController.text.trim().isEmpty
          ? null
          : _lugarController.text.trim();

      await widget.calendarioService.actualizarSesion(
        sesionId: widget.sesion.id,
        hora: hora,
        lugar: lugar,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t.sessionEditFormTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _guardando ? null : _seleccionarHora,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _t.weeklyScheduleTimeLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                child: Text(_hora.format(context)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _lugarController,
              enabled: !_guardando,
              decoration: InputDecoration(
                labelText: _t.weeklySchedulePlaceLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: Text(_t.cancel),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_t.save),
        ),
      ],
    );
  }
}

// ============================================================
// LISTADO DE JUSTIFICACIONES DE UNA SESIÓN
// ============================================================

class _JustificacionesDialog extends StatefulWidget {
  final CalendarioService calendarioService;
  final int sesionId;

  const _JustificacionesDialog({
    required this.calendarioService,
    required this.sesionId,
  });

  @override
  State<_JustificacionesDialog> createState() =>
      _JustificacionesDialogState();
}

class _JustificacionesDialogState extends State<_JustificacionesDialog> {
  late final Future<List<JustificacionFaltaModel>> _future;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    _future = widget.calendarioService.obtenerJustificaciones(
      widget.sesionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_t.viewJustificationsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<JustificacionFaltaModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _t.viewJustificationsLoadError,
                  style: TextStyle(color: colors.onSurface),
                ),
              );
            }

            final justificaciones = snapshot.data ?? [];

            if (justificaciones.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _t.viewJustificationsEmpty,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: justificaciones
                    .map(
                      (justificacion) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              justificacion.jugador,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              justificacion.motivo?.trim().isNotEmpty == true
                                  ? justificacion.motivo!
                                  : _t.justificationNoReasonGiven,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_t.close),
        ),
      ],
    );
  }
}

// ============================================================
// MOTIVO DE CANCELACIÓN (obligatorio, reutilizado por sesión y partido)
// ============================================================

class _MotivoCancelacionDialog extends StatefulWidget {
  final String titulo;
  final String hint;

  const _MotivoCancelacionDialog({required this.titulo, required this.hint});

  @override
  State<_MotivoCancelacionDialog> createState() =>
      _MotivoCancelacionDialogState();
}

class _MotivoCancelacionDialogState extends State<_MotivoCancelacionDialog> {
  final TextEditingController _motivoController = TextEditingController();

  String? _error;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final motivo = _motivoController.text.trim();

    if (motivo.isEmpty) {
      setState(() {
        _error = _t.cancelReasonRequiredError;
      });
      return;
    }

    Navigator.pop(context, motivo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.hint),
          const SizedBox(height: 14),
          TextField(
            controller: _motivoController,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: _t.cancelReasonLabel,
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_t.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: _confirmar,
          child: Text(_t.delete),
        ),
      ],
    );
  }
}
