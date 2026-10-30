import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/invitacion_model.dart';
import '../services/invitados_service.dart';
import '../widgets/invitado_widgets.dart';

/// Coordinación (COORDINADOR y ADMIN_APP): los jugadores de otros equipos invitados a
/// una convocatoria que esperan el visto bueno o que su entrenador los libere. Se
/// puede aprobar, rechazar (con motivo opcional) y, si esperan a su entrenador,
/// liberar.
class InvitacionesPage extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real.
  final InvitadosService? service;

  const InvitacionesPage({super.key, this.service});

  @override
  State<InvitacionesPage> createState() => _InvitacionesPageState();
}

class _InvitacionesPageState extends State<InvitacionesPage> {
  late final InvitadosService _service = widget.service ?? InvitadosService();

  late Future<List<InvitacionPendienteModel>> _futuro;

  /// Las invitaciones con una acción en curso (sus botones se desactivan).
  final Set<int> _ocupadas = {};

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    _futuro = _service.obtenerPendientes();
  }

  Future<void> _recargar() async {
    setState(() {
      _futuro = _service.obtenerPendientes();
    });

    try {
      await _futuro;
    } catch (_) {
      // El error se pinta en la propia pantalla.
    }
  }

  /// Ejecuta [accion] sobre la invitación, avisa del resultado y recarga la lista.
  Future<void> _ejecutar(
    InvitacionPendienteModel invitacion,
    Future<String> Function() accion,
  ) async {
    setState(() => _ocupadas.add(invitacion.id));

    try {
      final mensaje = await accion();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      if (!mounted) return;

      final conflicto = ConflictoInvitacion.desde(e);

      if (conflicto != null) {
        await mostrarConflictoInvitacion(
          context,
          conflicto,
          jugador: invitacion.jugador,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is Exception ? mensajeDeAccion(_t, e) : _t.invActionError,
            ),
          ),
        );
      }
    }

    if (!mounted) return;

    setState(() => _ocupadas.remove(invitacion.id));

    await _recargar();
  }

  Future<void> _aprobar(InvitacionPendienteModel invitacion) {
    return _ejecutar(invitacion, () async {
      final resultado = await _service.aprobar(invitacion.id);

      return resultado.estado == EstadoInvitacion.pendienteEntrenador
          ? _t.invApprovedWaitingSnack
          : _t.invApprovedSnack;
    });
  }

  Future<void> _rechazar(InvitacionPendienteModel invitacion) async {
    // null = cancelado; el texto (vacío si no hay motivo) = confirmado.
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _RechazarInvitacionDialog(),
    );

    if (motivo == null || !mounted) return;

    await _ejecutar(invitacion, () async {
      await _service.rechazar(invitacion.id, motivo: motivo);

      return _t.invRejectedSnack;
    });
  }

  Future<void> _liberar(InvitacionPendienteModel invitacion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.invReleaseConfirmTitle(invitacion.jugador)),
        content: Text(_t.invReleaseConfirmBody(invitacion.equipoOrigen)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            key: const ValueKey('invitacion-liberar-confirmar'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.invRelease),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    await _ejecutar(invitacion, () async {
      await _service.liberar(invitacion.id);

      return _t.invReleasedSnack;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPageInvitations)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<InvitacionPendienteModel>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _construirError(snapshot.error);
            }

            final invitaciones = snapshot.data ?? [];

            if (invitaciones.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.group_add_outlined,
                    size: 64,
                    color: _colors.primary,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _t.invPageEmpty,
                      key: const ValueKey('invitaciones-vacio'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _colors.onSurface,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: invitaciones.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _construirInvitacion(invitaciones[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _construirInvitacion(InvitacionPendienteModel invitacion) {
    final ocupada = _ocupadas.contains(invitacion.id);
    final esperaEntrenador =
        invitacion.estado == EstadoInvitacion.pendienteEntrenador;

    final fecha = invitacion.fechaPartido == null
        ? ''
        : formatearFechaConDiaSemana(invitacion.fechaPartido!, _t);

    final partidos = invitacion.solapamiento
        .map((p) => '${p.hora} ${p.rival}'.trim())
        .join(', ');

    return Card(
      key: ValueKey('invitacion-${invitacion.id}'),
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: invitacion.plazoVencido
              ? Colors.redAccent
              : _colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitacion.jugador,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _t.invFromTo(invitacion.equipoOrigen, invitacion.equipoDestino),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _colors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t.invMatchLine(fecha, invitacion.horaPartido, invitacion.rival),
              style: TextStyle(color: _colors.onSurface),
            ),
            if (invitacion.convoca.isNotEmpty)
              Text(
                _t.invConvokedBy(invitacion.convoca),
                style: TextStyle(color: _colors.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            _etiqueta(
              textoEstadoInvitacion(_t, invitacion.estado) ?? '',
              esperaEntrenador ? Colors.amber.shade800 : AppColors.azul,
            ),
            const SizedBox(height: 8),
            _linea(
              Icons.sports_soccer_outlined,
              invitacion.solapamiento.isEmpty
                  ? _t.invOverlapNone
                  : _t.invOverlapYes(partidos),
            ),
            if (invitacion.jugadorConvocadoEnOrigen)
              _linea(Icons.how_to_reg_outlined, _t.invOverlapConvoked),
            if (invitacion.otraInvitacion != null)
              _linea(
                Icons.warning_amber_rounded,
                _t.invOtherInvitation(invitacion.otraInvitacion!.equipoDestino),
                color: Colors.amber.shade800,
                clave: ValueKey('otra-invitacion-${invitacion.id}'),
              ),
            if (invitacion.plazoVencido)
              _linea(
                Icons.timer_outlined,
                _t.invDeadlineExpired,
                color: Colors.redAccent,
                clave: ValueKey('plazo-vencido-${invitacion.id}'),
              ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!esperaEntrenador)
                  TextButton(
                    key: ValueKey('invitacion-rechazar-${invitacion.id}'),
                    onPressed: ocupada ? null : () => _rechazar(invitacion),
                    child: Text(_t.invReject),
                  ),
                if (esperaEntrenador)
                  FilledButton(
                    key: ValueKey('invitacion-liberar-${invitacion.id}'),
                    onPressed: ocupada ? null : () => _liberar(invitacion),
                    child: Text(_t.invRelease),
                  )
                else
                  FilledButton(
                    key: ValueKey('invitacion-aprobar-${invitacion.id}'),
                    onPressed: ocupada ? null : () => _aprobar(invitacion),
                    child: Text(_t.invApprove),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linea(IconData icono, String texto, {Color? color, Key? clave}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        key: clave,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color ?? _colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: color ?? _colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiqueta(String texto, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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

/// Pide el motivo (opcional) de un rechazo. Se cierra con el motivo escrito, vacío si no
/// se escribe nada, o con null si se cancela. Es un widget aparte para que el
/// controlador del texto viva lo que dura el diálogo (también mientras se cierra).
class _RechazarInvitacionDialog extends StatefulWidget {
  const _RechazarInvitacionDialog();

  @override
  State<_RechazarInvitacionDialog> createState() =>
      _RechazarInvitacionDialogState();
}

class _RechazarInvitacionDialogState extends State<_RechazarInvitacionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.invRejectTitle),
      content: TextField(
        key: const ValueKey('invitacion-motivo'),
        controller: _controller,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: t.invRejectReasonLabel,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey('invitacion-rechazar-confirmar'),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(t.invReject),
        ),
      ],
    );
  }
}
