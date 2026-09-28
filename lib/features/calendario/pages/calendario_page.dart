import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../auth/services/perfil_service.dart';
import '../../teams/models/team_model.dart';
import '../../teams/services/team_services.dart';
import '../model/calendario_model.dart';
import '../services/calendario_service.dart';

/// Vista de solo lectura del calendario (entrenamientos + partidos) de
/// los equipos del usuario: un acordeón por cada equipo al que está
/// vinculado (deduplicado), igual que en "Mis partidos". Para
/// coordinador/administrador se listan todos los equipos del club.
class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _EquipoCalendarioEntrada {
  final String equipo;
  final String? jugador;
  final int? jugadorId;
  final int? equipoId;

  const _EquipoCalendarioEntrada({
    required this.equipo,
    this.jugador,
    this.jugadorId,
    this.equipoId,
  });
}

class _CalendarioPageState extends State<CalendarioPage> {
  final CalendarioService _calendarioService = CalendarioService();

  PerfilApp? _perfil;
  List<_EquipoCalendarioEntrada> _equipos = [];

  bool _cargando = true;
  String? _error;

  // Se incrementa en cada recarga para forzar que las secciones del
  // acordeón se reconstruyan desde cero (colapsadas).
  int _generacion = 0;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();

      // El perfil solo trae el NOMBRE del equipo de cada jugador (no su
      // id), así que resolvemos el id contra el listado completo de
      // equipos del club, igual de válido tanto para familiares/jugadores
      // como para la vista global de coordinador/administrador.
      final todosLosEquipos = await TeamService().obtenerEquipos();

      final esGestionGlobal =
          perfil.tieneRol('COORDINADOR') || perfil.tieneRol('ADMIN_APP');

      final resultado = <_EquipoCalendarioEntrada>[];
      final procesados = <String>{};

      if (esGestionGlobal) {
        for (final equipo in todosLosEquipos) {
          if (equipo.nombre.trim().isEmpty) continue;

          final clave = equipo.nombre.trim().toUpperCase();

          if (procesados.add(clave)) {
            resultado.add(
              _EquipoCalendarioEntrada(
                equipo: equipo.nombre.trim(),
                equipoId: equipo.id,
              ),
            );
          }
        }
      } else {
        for (final jugador in perfil.jugadores) {
          final equipo = jugador.equipo;

          if (equipo == null || equipo.trim().isEmpty) continue;

          final clave = '${equipo.trim().toUpperCase()}|${jugador.id}';

          if (procesados.add(clave)) {
            resultado.add(
              _EquipoCalendarioEntrada(
                equipo: equipo.trim(),
                jugador: jugador.nombreCompleto,
                jugadorId: jugador.id,
                equipoId: _buscarEquipoId(todosLosEquipos, equipo.trim()),
              ),
            );
          }
        }

        // Equipos que el usuario entrena/coordina directamente.
        for (final equipo in perfil.equipos) {
          if (equipo.nombre.trim().isEmpty) continue;

          final clave = equipo.nombre.trim().toUpperCase();

          if (procesados.add(clave)) {
            resultado.add(
              _EquipoCalendarioEntrada(
                equipo: equipo.nombre.trim(),
                equipoId: equipo.id,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _equipos = resultado;
        _cargando = false;
        _error = null;
        _generacion++;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  int? _buscarEquipoId(List<TeamModel> equipos, String nombre) {
    final clave = nombre.trim().toUpperCase();

    for (final equipo in equipos) {
      if (equipo.nombre.trim().toUpperCase() == clave) {
        return equipo.id;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final esGestionGlobal =
        _perfil?.tieneRol('COORDINADOR') == true ||
        _perfil?.tieneRol('ADMIN_APP') == true;

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(
          titulo: esGestionGlobal
              ? _t.calendarAllTeamsTitle
              : _t.clubPageCalendar,
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

    final equipos = _equipos;

    if (equipos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.event_note_outlined, size: 64, color: _colors.primary),
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
      onRefresh: _cargarDatos,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: equipos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final entrada = equipos[index];

          return _EquipoCalendarioSeccion(
            key: ValueKey(
              '$_generacion-${entrada.equipo}-${entrada.jugador}-$index',
            ),
            calendarioService: _calendarioService,
            titulo: _tituloTexto(entrada),
            equipoId: entrada.equipoId,
            jugadorId: entrada.jugadorId,
          );
        },
      ),
    );
  }

  String _tituloTexto(_EquipoCalendarioEntrada entrada) {
    final tieneJugador =
        entrada.jugador != null && entrada.jugador!.trim().isNotEmpty;

    return tieneJugador ? '${entrada.equipo} - ${entrada.jugador}' : entrada.equipo;
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
              _t.calendarLoadError,
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

                _cargarDatos();
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

// ============================================================
// SECCIÓN DE ACORDEÓN POR EQUIPO
// ============================================================

class _EquipoCalendarioSeccion extends StatefulWidget {
  final CalendarioService calendarioService;
  final String titulo;
  final int? equipoId;
  final int? jugadorId;

  const _EquipoCalendarioSeccion({
    super.key,
    required this.calendarioService,
    required this.titulo,
    required this.equipoId,
    required this.jugadorId,
  });

  @override
  State<_EquipoCalendarioSeccion> createState() =>
      _EquipoCalendarioSeccionState();
}

class _EquipoCalendarioSeccionState extends State<_EquipoCalendarioSeccion> {
  bool _cargando = false;
  bool _cargado = false;
  String? _error;
  List<ItemCalendario> _items = [];

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _cargar() async {
    final equipoId = widget.equipoId;

    if (equipoId == null) {
      setState(() {
        _error = _t.calendarLoadError;
        _cargado = true;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final hoy = DateTime.now();
      final desde = DateTime(hoy.year, hoy.month, hoy.day);
      // Ventana de dos meses: coincide con el horizonte de generación
      // de sesiones futuras del backend.
      final hasta = DateTime(hoy.year, hoy.month + 2, hoy.day);

      final calendario = await widget.calendarioService.obtenerCalendario(
        equipoId: equipoId,
        desde: desde,
        hasta: hasta,
        jugadorId: widget.jugadorId,
      );

      if (!mounted) return;

      setState(() {
        _items = calendario.itemsOrdenados;
        _cargando = false;
        _cargado = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
        _cargado = true;
      });
    }
  }

  Future<void> _justificarFalta(ItemCalendario item) async {
    final sesion = item.sesion;
    final jugadorId = widget.jugadorId;

    if (sesion == null || jugadorId == null) return;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => _JustificarFaltaDialog(
        calendarioService: widget.calendarioService,
        sesionId: sesion.id,
        jugadorId: jugadorId,
        motivoActual: sesion.justificado ? sesion.motivoJustificacion : null,
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.calendarJustifyAbsenceSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 5,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.dorado,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.titulo,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        onExpansionChanged: (expandido) {
          if (expandido && !_cargado && !_cargando) {
            _cargar();
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _construirContenidoSeccion(),
          ),
        ],
      ),
    );
  }

  Widget _construirContenidoSeccion() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Text(
            _t.calendarLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: _colors.onSurface),
          ),
          const SizedBox(height: 8),
          if (widget.equipoId != null)
            TextButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
        ],
      );
    }

    if (!_cargado) {
      return const SizedBox.shrink();
    }

    if (_items.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: _colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.event_busy, color: _colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t.calendarNoItems,
                  style: TextStyle(color: _colors.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hoy = DateTime.now();

    return Column(
      children: [
        for (final item in _items) ...[
          _construirTarjetaItem(item, hoy),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _construirTarjetaItem(ItemCalendario item, DateTime hoy) {
    final esFuturo = item.esFuturoRespectoA(hoy);
    final yaJustificado = item.sesion?.justificado == true;
    final puedeJustificar =
        item.esEntrenamiento &&
        widget.jugadorId != null &&
        !item.cancelado &&
        esFuturo;

    final icono = item.esEntrenamiento
        ? Icons.fitness_center
        : Icons.sports_soccer;

    final etiquetaTipo = item.esEntrenamiento
        ? _t.calendarSessionLabel
        : _t.calendarMatchLabel;

    final colorIcono = item.cancelado
        ? _colors.onSurfaceVariant
        : (item.esEntrenamiento ? AppColors.azul : AppColors.dorado);

    final subtitulo = item.esEntrenamiento
        ? (item.sesion?.lugar ?? '')
        : (item.partido?.rival ?? '');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: puedeJustificar ? () => _justificarFalta(item) : null,
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
                          _construirBadgeCancelado(),
                        ] else if (yaJustificado) ...[
                          const SizedBox(width: 8),
                          _construirBadgeJustificado(),
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
                    if (puedeJustificar) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 16,
                            color: _colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            yaJustificado
                                ? _t.calendarEditJustificationButton
                                : _t.calendarJustifyAbsenceButton,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBadgeCancelado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }

  Widget _construirBadgeJustificado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _t.calendarJustifiedBadge,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.green,
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
// DIÁLOGO DE JUSTIFICACIÓN DE FALTA
// ============================================================

class _JustificarFaltaDialog extends StatefulWidget {
  final CalendarioService calendarioService;
  final int sesionId;
  final int jugadorId;
  final String? motivoActual;

  const _JustificarFaltaDialog({
    required this.calendarioService,
    required this.sesionId,
    required this.jugadorId,
    this.motivoActual,
  });

  @override
  State<_JustificarFaltaDialog> createState() =>
      _JustificarFaltaDialogState();
}

class _JustificarFaltaDialogState extends State<_JustificarFaltaDialog> {
  late final TextEditingController _motivoController = TextEditingController(
    text: widget.motivoActual ?? '',
  );

  bool _enviando = false;
  String? _error;

  bool get _yaJustificado => widget.motivoActual != null;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final motivo = _motivoController.text.trim();

      await widget.calendarioService.justificarFalta(
        sesionId: widget.sesionId,
        jugadorId: widget.jugadorId,
        motivo: motivo.isEmpty ? null : motivo,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _yaJustificado
            ? _t.calendarEditJustificationTitle
            : _t.calendarJustifyAbsenceTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _yaJustificado
                  ? _t.calendarEditJustificationHint
                  : _t.calendarJustifyAbsenceHint,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _motivoController,
              enabled: !_enviando,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _t.calendarJustifyAbsenceReasonLabel,
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
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: Text(_t.cancel),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_t.calendarJustifyAbsenceSubmit),
        ),
      ],
    );
  }
}
