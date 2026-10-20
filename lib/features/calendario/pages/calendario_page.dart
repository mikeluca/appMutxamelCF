import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../auth/services/perfil_service.dart';
import '../../entrenamientos/utils/estado_asistencia_utils.dart';
import '../../matches/models/match_model.dart';
import '../../matches/services/justificacion_partido_service.dart';
import '../../teams/models/team_model.dart';
import '../../teams/services/team_services.dart';
import '../model/calendario_model.dart';
import '../services/calendario_service.dart';
import '../widgets/calendario_mensual.dart';

/// Vista de solo lectura de UN ÚNICO calendario con los entrenamientos y
/// partidos de TODOS los equipos a los que el usuario está vinculado
/// (varios jugadores/equipos aparecen mezclados en el mismo calendario,
/// cada evento indicando a qué equipo -y jugador, si aplica- pertenece).
/// Para coordinador/administrador se incluyen todos los equipos del club.
class CalendarioPage extends StatefulWidget {
  /// Solo para tests: sustituyen a las llamadas reales al backend.
  final CalendarioService? calendarioService;
  final TeamService? teamService;
  final Future<PerfilApp> Function()? cargarPerfil;

  final JustificacionPartidoService? justificacionPartidoService;

  /// Solo para tests: el "hoy" con el que se decide si un evento es futuro.
  final DateTime Function()? ahora;

  /// Día que aparece seleccionado al abrir (hoy si es null): al tocar el aviso
  /// de una convocatoria se abre en el día del partido.
  final DateTime? diaInicial;

  const CalendarioPage({
    super.key,
    this.calendarioService,
    this.teamService,
    this.cargarPerfil,
    this.justificacionPartidoService,
    this.ahora,
    this.diaInicial,
  });

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

/// Un evento del calendario combinado, con el contexto de a qué
/// jugador pertenece (si aplica) para poder justificar su falta y
/// para mostrar "Equipo — Jugador" en la tarjeta. El nombre del equipo
/// ya viene incluido en item.sesion/item.partido.
class _EventoUsuario {
  final ItemCalendario item;
  final String? jugadorNombre;
  final int? jugadorId;

  const _EventoUsuario({
    required this.item,
    this.jugadorNombre,
    this.jugadorId,
  });
}

class _CalendarioPageState extends State<CalendarioPage> {
  late final CalendarioService _calendarioService =
      widget.calendarioService ?? CalendarioService();
  late final JustificacionPartidoService _justificacionPartidoService =
      widget.justificacionPartidoService ?? JustificacionPartidoService();

  PerfilApp? _perfil;
  List<_EquipoCalendarioEntrada> _equipos = [];
  List<_EventoUsuario> _eventos = [];

  // Ventana de fechas consultada: fija para toda la vida de la página
  // (calculada una vez, la primera vez que se cargan datos) para que
  // el calendario visual (firstDay/lastDay) no "salte" en cada
  // recarga.
  late DateTime _desde;
  late final DateTime _hasta;

  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    final hoy = DateTime.now();
    // Los entrenamientos solo se generan hacia delante, así que la
    // parte futura de la ventana (hoy + 2 meses) coincide con el
    // horizonte de generación del backend.
    _hasta = DateTime(hoy.year, hoy.month + 2, hoy.day);

    _cargarDatos();
  }

  /// Carga el calendario. Con [enSegundoPlano] (tras justificar, editar o
  /// retirar) no se cambia la vista por el indicador de carga: el calendario
  /// sigue en pantalla con el día seleccionado, y si la recarga falla se queda
  /// lo que había.
  Future<void> _cargarDatos({bool enSegundoPlano = false}) async {
    if (!enSegundoPlano) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      // Los partidos pasados se muestran solo desde el inicio de la
      // temporada activa (configurada por el club); si no hay ninguna
      // temporada activa configurada, se usa un año atrás como
      // respaldo razonable.
      final temporada = await _calendarioService.obtenerTemporadaActiva();
      final hoy = DateTime.now();

      _desde =
          temporada?.fechaInicio ?? DateTime(hoy.year - 1, hoy.month, hoy.day);

      final perfil =
          await (widget.cargarPerfil ?? PerfilService.obtenerPerfil)();

      // El perfil solo trae el NOMBRE del equipo de cada jugador (no su
      // id), así que resolvemos el id contra el listado completo de
      // equipos del club, igual de válido tanto para familiares/jugadores
      // como para la vista global de coordinador/administrador.
      final todosLosEquipos = await (widget.teamService ?? TeamService())
          .obtenerEquipos();

      final esGestionGlobal =
          perfil.tieneRol('COORDINADOR') || perfil.tieneRol('ADMIN_APP');

      final equipos = <_EquipoCalendarioEntrada>[];
      final procesados = <String>{};

      if (esGestionGlobal) {
        for (final equipo in todosLosEquipos) {
          if (equipo.nombre.trim().isEmpty) continue;

          final clave = equipo.nombre.trim().toUpperCase();

          if (procesados.add(clave)) {
            equipos.add(
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
            equipos.add(
              _EquipoCalendarioEntrada(
                equipo: equipo.trim(),
                jugador: jugador.nombreCompleto,
                jugadorId: jugador.id,
                equipoId:
                    jugador.equipoId ??
                    _buscarEquipoId(todosLosEquipos, equipo.trim()),
              ),
            );
          }
        }

        // Equipos que el usuario entrena/coordina directamente.
        for (final equipo in perfil.equipos) {
          if (equipo.nombre.trim().isEmpty) continue;

          final clave = equipo.nombre.trim().toUpperCase();

          if (procesados.add(clave)) {
            equipos.add(
              _EquipoCalendarioEntrada(
                equipo: equipo.nombre.trim(),
                equipoId: equipo.id,
              ),
            );
          }
        }
      }

      // En una recarga en segundo plano, que falle un equipo hace fallar la
      // recarga entera (se queda lo que había) en vez de dejar su hueco.
      final eventos = await _cargarEventos(equipos, estricto: enSegundoPlano);

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _equipos = equipos;
        _eventos = eventos;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || enSegundoPlano) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  /// Pide el calendario de cada equipo (en paralelo) y los combina en
  /// una única lista. Con el calendario de un jugador (JUGADOR/FAMILIAR)
  /// NADA se deduplica: tanto las sesiones como los partidos llevan el estado
  /// de justificación propio de CADA jugador, y dos hijos del mismo equipo
  /// deben ver su ficha (con su nombre) y justificar por separado. Solo los
  /// partidos del calendario de un equipo (entrenador/coordinador, sin
  /// jugador) se deduplican por id, también frente a los de un jugador.
  Future<List<_EventoUsuario>> _cargarEventos(
    List<_EquipoCalendarioEntrada> equipos, {
    bool estricto = false,
  }) async {
    final calendarios = await Future.wait(
      equipos.map((entrada) async {
        final equipoId = entrada.equipoId;

        if (equipoId == null) return null;

        try {
          return await _calendarioService.obtenerCalendario(
            equipoId: equipoId,
            desde: _desde,
            hasta: _hasta,
            jugadorId: entrada.jugadorId,
          );
        } catch (_) {
          // Si falla un equipo concreto no se bloquea la vista
          // completa: se omite y se muestran los demás (salvo en una
          // recarga estricta, donde se prefiere conservar lo anterior).
          if (estricto) rethrow;

          return null;
        }
      }),
    );

    final eventos = <_EventoUsuario>[];
    final partidosVistos = <int>{};

    for (var i = 0; i < equipos.length; i++) {
      final calendario = calendarios[i];

      if (calendario == null) continue;

      final entrada = equipos[i];

      for (final sesion in calendario.sesiones) {
        eventos.add(
          _EventoUsuario(
            item: ItemCalendario.deSesion(sesion),
            jugadorId: entrada.jugadorId,
            jugadorNombre: entrada.jugador,
          ),
        );
      }

      for (final partido in calendario.partidos) {
        if (partido.id != null &&
            !partidosVistos.add(partido.id!) &&
            entrada.jugadorId == null) {
          continue;
        }

        eventos.add(
          _EventoUsuario(
            item: ItemCalendario.dePartido(partido),
            jugadorId: entrada.jugadorId,
            jugadorNombre: entrada.jugador,
          ),
        );
      }
    }

    eventos.sort((a, b) {
      final comparacionFecha = a.item.fecha.compareTo(b.item.fecha);

      if (comparacionFecha != 0) return comparacionFecha;

      return (a.item.hora ?? '').compareTo(b.item.hora ?? '');
    });

    return eventos;
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

  Future<void> _justificarFalta(_EventoUsuario evento) async {
    final sesion = evento.item.sesion;
    final jugadorId = evento.jugadorId;

    if (sesion == null || jugadorId == null) return;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => _JustificarFaltaDialog(
        calendarioService: _calendarioService,
        sesionId: sesion.id,
        jugadorId: jugadorId,
        motivoActual: sesion.justificado ? sesion.motivoJustificacion : null,
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.calendarJustifyAbsenceSuccess)));

      // El estado "justificado" de esta sesión ha podido cambiar:
      // recargamos para reflejarlo en la tarjeta.
      _cargarDatos(enSegundoPlano: true);
    }
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

    if (_equipos.isEmpty) {
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          CalendarioMensual<_EventoUsuario>(
            items: _eventos,
            fechaDe: (evento) => evento.item.fecha,
            textoSinEventosDia: _t.calendarNoItems,
            locale: Localizations.localeOf(context).languageCode,
            primerDia: _desde,
            ultimoDia: _hasta,
            diaInicial: widget.diaInicial,
            itemBuilder: (context, evento) =>
                _construirTarjetaItem(evento, (widget.ahora ?? DateTime.now)()),
          ),
        ],
      ),
    );
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
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _equipoDe(ItemCalendario item) =>
      item.sesion?.equipo ?? item.partido?.equipo ?? '';

  Widget _construirTarjetaItem(_EventoUsuario evento, DateTime hoy) {
    final item = evento.item;
    final esFuturo = item.esFuturoRespectoA(hoy);
    final yaJustificado = item.sesion?.justificado == true;
    final convocado = item.partido?.convocado;
    final asistencia = item.sesion?.asistencia;
    final puedeJustificar =
        item.esEntrenamiento &&
        evento.jugadorId != null &&
        !item.cancelado &&
        esFuturo;

    // Partido de un jugador (JUGADOR/FAMILIAR): se puede justificar su
    // ausencia, igual que la falta a un entrenamiento.
    final partidoDelJugador =
        !item.esEntrenamiento &&
        evento.jugadorId != null &&
        !item.cancelado &&
        item.partido?.id != null;

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

    final equipo = _equipoDe(item);
    final tieneJugador =
        evento.jugadorNombre != null && evento.jugadorNombre!.trim().isNotEmpty;
    final etiquetaEquipo = tieneJugador
        ? '$equipo — ${evento.jugadorNombre}'
        : equipo;

    final resultado = item.partido?.resultado?.trim();
    final tieneResultado =
        !item.esEntrenamiento && resultado != null && resultado.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: puedeJustificar ? () => _justificarFalta(evento) : null,
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
                        ] else if (asistencia != null) ...[
                          const SizedBox(width: 8),
                          _construirBadgeAsistencia(asistencia),
                        ] else if (convocado != null) ...[
                          const SizedBox(width: 8),
                          _construirBadgeConvocado(convocado),
                        ],
                      ],
                    ),
                    if (etiquetaEquipo.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        etiquetaEquipo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _colors.primary,
                        ),
                      ),
                    ],
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
                    if (tieneResultado) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_t.matchResultLabel}: $resultado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _colors.onSurface,
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
                    if (partidoDelJugador)
                      _construirAusenciaPartido(evento, item.partido!),
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

  // ============================================================
  // AUSENCIA JUSTIFICADA A PARTIDOS
  // ============================================================

  /// Estado de la ausencia del jugador a este partido y sus acciones: justificar
  /// mientras hay plazo; si ya está justificada, la etiqueta con el motivo y,
  /// dentro del plazo, "Editar motivo" y "Retirar"; fuera de plazo, el plazo
  /// cerrado.
  Widget _construirAusenciaPartido(_EventoUsuario evento, MatchModel partido) {
    final limite = partido.limiteJustificacion;

    if (partido.ausenciaJustificada) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _construirBadgeAusencia(),
            if (partido.motivoAusencia?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                _t.callupReasonShown(partido.motivoAusencia!),
                style: TextStyle(fontSize: 13, color: _colors.onSurfaceVariant),
              ),
            ],
            if (partido.puedeJustificar)
              Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => _justificarAusencia(evento, partido),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(_t.matchAbsenceEditButton),
                  ),
                  TextButton.icon(
                    onPressed: () => _retirarAusencia(evento, partido),
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text(_t.matchAbsenceWithdrawButton),
                  ),
                ],
              )
            else if (limite != null) ...[
              const SizedBox(height: 4),
              _construirPlazoCerrado(limite),
            ],
          ],
        ),
      );
    }

    if (partido.puedeJustificar) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () => _justificarAusencia(evento, partido),
          icon: const Icon(Icons.event_busy_outlined, size: 18),
          label: Text(_t.matchAbsenceJustifyButton),
        ),
      );
    }

    if (limite != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _construirPlazoCerrado(limite),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _construirPlazoCerrado(DateTime limite) {
    return Text(
      _t.matchAbsenceDeadlineClosed(_formatearLimite(limite)),
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: _colors.onSurfaceVariant,
      ),
    );
  }

  String _formatearLimite(DateTime limite) {
    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(limite.day)}/${dos(limite.month)} '
        '${dos(limite.hour)}:${dos(limite.minute)}';
  }

  Widget _construirBadgeAusencia() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _t.matchAbsenceBadge,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Future<void> _justificarAusencia(
    _EventoUsuario evento,
    MatchModel partido,
  ) async {
    final jugadorId = evento.jugadorId;

    if (partido.id == null || jugadorId == null) return;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => _JustificarAusenciaPartidoDialog(
        servicio: _justificacionPartidoService,
        partidoId: partido.id!,
        jugadorId: jugadorId,
        motivoActual: partido.ausenciaJustificada
            ? partido.motivoAusencia
            : null,
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.matchAbsenceJustifiedSnack)));

      _cargarDatos(enSegundoPlano: true);
    }
  }

  Future<void> _retirarAusencia(
    _EventoUsuario evento,
    MatchModel partido,
  ) async {
    final jugadorId = evento.jugadorId;

    if (partido.id == null || jugadorId == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.matchAbsenceWithdrawTitle),
        content: Text(_t.matchAbsenceWithdrawBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.matchAbsenceWithdrawConfirm),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await _justificacionPartidoService.retirar(
        partidoId: partido.id!,
        jugadorId: jugadorId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.matchAbsenceWithdrawnSnack)));

      _cargarDatos(enSegundoPlano: true);
    } catch (_) {
      if (!mounted) return;

      // Sin el detalle técnico del error: el usuario solo necesita saber que
      // no se guardó.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.matchAbsenceError)));
    }
  }

  Widget _construirBadgeConvocado(bool convocado) {
    final color = convocado ? Colors.green : _colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        convocado ? _t.calendarCalledUpBadge : _t.calendarNotCalledUpBadge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _construirBadgeAsistencia(String estado) {
    final color = colorEstadoAsistencia(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        labelEstadoAsistencia(_t, estado),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) =>
      formatearFechaConDiaSemana(fecha, _t);
}

// ============================================================
// DIÁLOGO DE JUSTIFICACIÓN DE AUSENCIA A UN PARTIDO
// ============================================================

class _JustificarAusenciaPartidoDialog extends StatefulWidget {
  final JustificacionPartidoService servicio;
  final int partidoId;
  final int jugadorId;

  /// El motivo ya guardado si se está editando; null si es una justificación nueva.
  final String? motivoActual;

  const _JustificarAusenciaPartidoDialog({
    required this.servicio,
    required this.partidoId,
    required this.jugadorId,
    this.motivoActual,
  });

  @override
  State<_JustificarAusenciaPartidoDialog> createState() =>
      _JustificarAusenciaPartidoDialogState();
}

class _JustificarAusenciaPartidoDialogState
    extends State<_JustificarAusenciaPartidoDialog> {
  late final TextEditingController _motivoController = TextEditingController(
    text: widget.motivoActual ?? '',
  );

  bool _enviando = false;
  String? _error;

  bool get _editando => widget.motivoActual != null;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final motivo = _motivoController.text.trim();

    // El backend exige de 3 a 500 caracteres; se avisa antes de enviar.
    if (motivo.length < 3) {
      setState(() => _error = _t.matchAbsenceReasonRequired);
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await widget.servicio.justificar(
        partidoId: widget.partidoId,
        jugadorId: widget.jugadorId,
        motivo: motivo,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      // Sin e.toString(): un mensaje genérico, no la excepción en pantalla.
      setState(() {
        _error = _t.matchAbsenceError;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _editando ? _t.matchAbsenceEditTitle : _t.matchAbsenceJustifyTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t.matchAbsenceHint),
            const SizedBox(height: 14),
            TextField(
              controller: _motivoController,
              enabled: !_enviando,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: _t.matchAbsenceReasonLabel,
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
  State<_JustificarFaltaDialog> createState() => _JustificarFaltaDialogState();
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
