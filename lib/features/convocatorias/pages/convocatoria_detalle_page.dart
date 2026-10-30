import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/backend_date.dart';
import '../../../core/utils/como_llegar.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../invitados/models/invitacion_model.dart';
import '../../invitados/services/invitados_service.dart';
import '../../invitados/widgets/invitado_widgets.dart';
import '../model/convocatoria_model.dart';
import '../services/convocatoria_service.dart';
import 'convocatoria_form_page.dart';

/// Detalle de una convocatoria para el entrenador: partido, hora y lugar, los
/// convocados y, si alguno ha justificado su ausencia, un aviso arriba con el
/// botón para editarla (y sustituirlo).
class ConvocatoriaDetallePage extends StatefulWidget {
  final PerfilEquipo equipo;
  final ConvocatoriaModel convocatoria;

  /// Solo para tests: sustituyen al servicio real y al formulario de edición.
  final ConvocatoriaService? service;
  final Widget Function(ConvocatoriaModel convocatoria)? formularioBuilder;
  final DateTime Function()? ahora;
  final InvitadosService? invitadosService;

  /// Se abre desde el aviso INVITACION_LIBERAR: esta es la convocatoria del equipo de
  /// origen y un jugador suyo ha sido invitado por otro equipo el mismo día. Se muestra
  /// el motivo y el botón para liberarlo.
  final LiberarInvitacion? liberar;

  const ConvocatoriaDetallePage({
    super.key,
    required this.equipo,
    required this.convocatoria,
    this.service,
    this.formularioBuilder,
    this.ahora,
    this.invitadosService,
    this.liberar,
  });

  @override
  State<ConvocatoriaDetallePage> createState() =>
      _ConvocatoriaDetallePageState();
}

class _ConvocatoriaDetallePageState extends State<ConvocatoriaDetallePage> {
  late final ConvocatoriaService _service =
      widget.service ?? ConvocatoriaService();

  late final InvitadosService _invitadosService =
      widget.invitadosService ?? InvitadosService();

  late ConvocatoriaModel _convocatoria = widget.convocatoria;

  /// Mientras se libera o se quita a un jugador invitado.
  bool _trabajando = false;

  /// Ya se ha liberado: el banner de la liberación desaparece.
  late bool _liberado = widget.liberar == null;

  Future<void> _recargar() async {
    try {
      final actualizada = await _service.obtenerPorId(_convocatoria.id);

      if (!mounted) return;

      setState(() => _convocatoria = actualizada);
    } catch (_) {
      // Se queda lo que había: la lista de atrás se recarga siempre al volver.
    }
  }

  ConvocatoriaJugadorModel? get _jugadorALiberar {
    final id = widget.liberar?.jugadorId;

    return id == null
        ? null
        : _convocatoria.jugadores.where((j) => j.jugadorId == id).firstOrNull;
  }

  /// Libera al jugador: lo quita de esta convocatoria y queda autorizado con el otro
  /// equipo (POST /app/invitaciones/{id}/liberar).
  Future<void> _liberarJugador() async {
    final liberar = widget.liberar;

    if (liberar == null || _trabajando) return;

    final nombre = _jugadorALiberar?.jugador ?? '';

    setState(() => _trabajando = true);

    try {
      await _invitadosService.liberar(liberar.invitacionId);

      if (!mounted) return;

      setState(() {
        _liberado = true;
        _trabajando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.invReleasedOriginSnack(nombre))),
      );

      await _recargar();
    } catch (e) {
      if (!mounted) return;

      setState(() => _trabajando = false);

      final conflicto = ConflictoInvitacion.desde(e);

      if (conflicto != null) {
        await mostrarConflictoInvitacion(context, conflicto, jugador: nombre);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeAccion(_t, e))));
    }
  }

  /// Quita a un invitado rechazado (o desestimado por su familia) para poder elegir a
  /// otro: guarda la convocatoria con la lista de invitados sin él.
  Future<void> _quitarInvitado(ConvocatoriaJugadorModel invitado) async {
    if (_trabajando) return;

    setState(() => _trabajando = true);

    try {
      await _service.actualizar(
        convocatoriaId: _convocatoria.id,
        partidoId: _convocatoria.partidoId,
        horaConvocatoria: _convocatoria.horaConvocatoria,
        lugarConvocatoria: _convocatoria.lugarConvocatoria,
        invitadosIds: _convocatoria.invitados
            .where((j) => !j.rechazado && j.jugadorId != invitado.jugadorId)
            .map((j) => j.jugadorId)
            .toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.invRemovedSnack)));

      await _recargar();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.invRemoveError)));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _editar() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            widget.formularioBuilder?.call(_convocatoria) ??
            ConvocatoriaFormPage(
              equipo: widget.equipo,
              convocatoria: _convocatoria,
            ),
      ),
    );

    if (guardado != true || !mounted) return;

    try {
      final actualizada = await _service.obtenerPorId(_convocatoria.id);

      if (!mounted) return;

      setState(() => _convocatoria = actualizada);
    } catch (_) {
      // Se queda lo que había: la lista de atrás se recarga siempre al volver.
    }
  }

  bool _eliminando = false;

  /// Solo se puede eliminar si el partido no tiene resultado y no es anterior a hoy.
  bool get _eliminable {
    if (_convocatoria.partidoConResultado) return false;

    final fecha = parseFechaTextoBackend(_convocatoria.fechaPartido);

    if (fecha == null) return true;

    final ahora = (widget.ahora ?? DateTime.now)();

    return !DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    ).isBefore(DateTime(ahora.year, ahora.month, ahora.day));
  }

  /// Elimina la convocatoria (con confirmación: se avisa a los convocados) y
  /// vuelve a la lista, que se recarga al volver.
  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.callupDeleteConfirmTitle),
        content: Text(_t.callupDeleteConfirmBody),
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

    setState(() => _eliminando = true);

    try {
      await _service.eliminar(_convocatoria.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.callupDeletedSnack)));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _eliminando = false);

      // El 400 trae el motivo ("el partido ya tiene resultado"...); el resto de
      // fallos, un mensaje genérico.
      final motivo = e is ApiException && e.statusCode == 400
          ? e.message
          : _t.callupDeleteError;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(motivo)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ausentes = _convocatoria.ausentes;

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: _t.callupDetailTitle),
        actions: [
          IconButton(
            tooltip: _t.editCallupTitle,
            onPressed: _editar,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          if (!_liberado) ...[
            _construirBannerLiberar(),
            const SizedBox(height: 16),
          ],
          if (_convocatoria.invitadosRechazados.isNotEmpty) ...[
            _construirBannerRechazados(
              _convocatoria.invitadosRechazados.length,
            ),
            const SizedBox(height: 16),
          ],
          if (ausentes.isNotEmpty) ...[
            _construirBanner(ausentes.length),
            const SizedBox(height: 16),
          ],
          _construirDatos(),
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
            _t.callupPlayersCount(_convocatoria.queJuegan.length),
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ..._convocatoria.jugadores.map(_construirJugador),
          if (_eliminable) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('eliminar-convocatoria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              onPressed: _eliminando ? null : _eliminar,
              icon: const Icon(Icons.delete_outline),
              label: Text(_t.callupDeleteButton),
            ),
          ],
        ],
      ),
    );
  }

  /// El jugador de este equipo ha sido invitado por otro el mismo día: se explica el
  /// solapamiento y se ofrece liberarlo (quitarlo de esta convocatoria).
  Widget _construirBannerLiberar() {
    final jugador = _jugadorALiberar;
    final nombre = jugador?.jugador ?? '';

    return Container(
      key: const ValueKey('banner-liberar-invitacion'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.swap_horiz, color: Colors.amber.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t.invReleaseBanner(nombre),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey('boton-liberar-invitacion'),
              onPressed: _trabajando || jugador == null
                  ? null
                  : _liberarJugador,
              icon: const Icon(Icons.how_to_reg_outlined),
              label: Text(_t.invReleaseButton(nombre)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBannerRechazados(int cantidad) {
    return Container(
      key: const ValueKey('banner-invitados-rechazados'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t.invRejectedBanner(cantidad),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _editar,
              icon: const Icon(Icons.edit_outlined),
              label: Text(_t.editCallupTitle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBanner(int cantidad) {
    return Container(
      key: const ValueKey('banner-ausencias'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t.callupAbsentBanner(cantidad),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _editar,
              icon: const Icon(Icons.edit_outlined),
              label: Text(_t.editCallupTitle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirDatos() {
    final fecha = parseFechaTextoBackend(_convocatoria.fechaPartido);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _convocatoria.rival,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t.callupMatchLine(
                fecha == null
                    ? _convocatoria.fechaPartido
                    : formatearFechaConDiaSemana(fecha, _t),
              ),
              style: TextStyle(color: _colors.onSurfaceVariant),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_convocatoria.horaPartido} · ${_convocatoria.campo}',
                    style: TextStyle(color: _colors.onSurfaceVariant),
                  ),
                ),
                BotonComoLlegar(lugar: _convocatoria.campo),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t.callupMeetingLine(
                      _convocatoria.horaConvocatoria,
                      _convocatoria.lugarConvocatoria,
                    ),
                    style: TextStyle(color: _colors.onSurfaceVariant),
                  ),
                ),
                BotonComoLlegar(lugar: _convocatoria.lugarConvocatoria),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirJugador(ConvocatoriaJugadorModel jugador) {
    final ausente = jugador.ausenciaJustificada;
    final rechazado = jugador.rechazado;
    final estado = jugador.invitado
        ? textoEstadoInvitacion(_t, jugador.estadoInvitacion)
        : null;
    final avisar = ausente || rechazado;
    final puedeQuitar = jugador.invitado && (ausente || rechazado);

    return Card(
      key: ValueKey('convocado-${jugador.jugadorId}'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: avisar
          ? Colors.redAccent.withValues(alpha: 0.08)
          : _colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: avisar ? Colors.redAccent : _colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              ausente
                  ? Icons.event_busy_outlined
                  : (jugador.invitado
                        ? Icons.person_add_alt_1_outlined
                        : Icons.person_outline),
              color: avisar ? Colors.redAccent : _colors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jugador.jugador,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                  ),
                  if (jugador.invitado) ...[
                    const SizedBox(height: 3),
                    EtiquetaInvitado(equipoOrigen: jugador.equipoOrigen ?? ''),
                  ],
                  if (estado != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      estado,
                      key: ValueKey('estado-invitacion-${jugador.jugadorId}'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: rechazado ? FontWeight.bold : null,
                        color: rechazado
                            ? Colors.redAccent
                            : _colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (rechazado &&
                      jugador.motivoRechazo?.trim().isNotEmpty == true)
                    Text(
                      _t.callupReasonShown(jugador.motivoRechazo!),
                      style: TextStyle(
                        fontSize: 13,
                        color: _colors.onSurfaceVariant,
                      ),
                    ),
                  if (ausente) ...[
                    const SizedBox(height: 3),
                    Text(
                      _t.matchAbsenceBadge,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    if (jugador.motivoAusencia?.trim().isNotEmpty == true)
                      Text(
                        _t.callupReasonShown(jugador.motivoAusencia!),
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.onSurfaceVariant,
                        ),
                      ),
                    if (jugador.invitado)
                      Text(
                        _t.invGuestAbsentHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: _colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (puedeQuitar)
              TextButton(
                key: ValueKey('quitar-invitado-${jugador.jugadorId}'),
                onPressed: _trabajando ? null : () => _quitarInvitado(jugador),
                child: Text(_t.invRemoveGuest),
              ),
          ],
        ),
      ),
    );
  }
}
