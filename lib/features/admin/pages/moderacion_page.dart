import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';

/// Cola de moderación (ADMIN_APP): mensajes reportados por los usuarios, con las
/// acciones de descartar, borrar el mensaje o desactivar al autor.
class ModeracionPage extends StatefulWidget {
  final AdminService? servicio;

  const ModeracionPage({super.key, this.servicio});

  @override
  State<ModeracionPage> createState() => _ModeracionPageState();
}

class _ModeracionPageState extends State<ModeracionPage> {
  static const Color _rojo = Color(0xFFDC2626);

  late final AdminService _servicio = widget.servicio ?? AdminService();

  late Future<List<ReporteModel>> _pendientes;
  late Future<List<ReporteModel>> _resueltos;

  /// Reportes con el texto desplegado.
  final Set<int> _desplegados = {};

  /// Hay una acción de moderación en curso: los botones quedan deshabilitados.
  bool _ejecutando = false;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _pendientes = _servicio.obtenerReportes();
    _resueltos = _servicio.obtenerReportes(resueltos: true);
  }

  void _recargarTodo() {
    setState(() {
      _pendientes = _servicio.obtenerReportes();
      _resueltos = _servicio.obtenerReportes(resueltos: true);
    });
  }

  Future<void> _refrescar(bool resueltos) async {
    final nuevo = _servicio.obtenerReportes(resueltos: resueltos);

    setState(() {
      if (resueltos) {
        _resueltos = nuevo;
      } else {
        _pendientes = nuevo;
      }
    });

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  /// Pide confirmación (con nota opcional) y, si se acepta, ejecuta la acción.
  Future<void> _confirmarYEjecutar({
    required String mensaje,
    required Future<void> Function(String? nota, bool borrarMensaje) accion,
    bool conBorrarMensaje = false,
  }) async {
    final controlador = TextEditingController();
    var borrarMensaje = true;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialogo) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensaje),
              const SizedBox(height: 12),
              TextField(
                controller: controlador,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _t.moderationNoteLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (conBorrarMensaje)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: borrarMensaje,
                  title: Text(_t.moderationAlsoDeleteMessage),
                  onChanged: (valor) =>
                      setStateDialogo(() => borrarMensaje = valor ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(_t.moderationConfirm),
            ),
          ],
        ),
      ),
    );

    // El controlador no se libera aquí: el diálogo todavía se está animando al
    // cerrarse y su TextField lo seguiría usando (no tiene oyentes propios, así que
    // el recolector de basura lo recoge sin más).
    final nota = controlador.text;

    if (confirmado != true || !mounted || _ejecutando) return;

    setState(() {
      _ejecutando = true;
    });

    try {
      await accion(nota, borrarMensaje);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.moderationResolvedDone)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeAccion(_t, e))));
    }

    if (mounted) {
      setState(() {
        _ejecutando = false;
      });

      _recargarTodo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: ClubAppBarTitle(titulo: _t.clubPageModeration),
          bottom: TabBar(
            tabs: [
              Tab(text: _t.moderationTabPending),
              Tab(text: _t.moderationTabResolved),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _construirLista(_pendientes, resueltos: false),
            _construirLista(_resueltos, resueltos: true),
          ],
        ),
      ),
    );
  }

  Widget _construirLista(
    Future<List<ReporteModel>> futuro, {
    required bool resueltos,
  }) {
    return RefreshIndicator(
      onRefresh: () => _refrescar(resueltos),
      child: FutureBuilder<List<ReporteModel>>(
        future: futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                Text(
                  mensajeDeError(_t, snapshot.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _refrescar(resueltos),
                    icon: const Icon(Icons.refresh),
                    label: Text(_t.retry),
                  ),
                ),
              ],
            );
          }

          final reportes = snapshot.data ?? const [];

          if (reportes.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(40),
              children: [
                Text(
                  resueltos
                      ? _t.moderationEmptyResolved
                      : _t.moderationEmptyPending,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _colors.onSurfaceVariant),
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              for (final reporte in reportes) ...[
                _construirTarjeta(reporte),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _construirTarjeta(ReporteModel r) {
    final desplegado = _desplegados.contains(r.id);

    return Card(
      key: ValueKey('reporte-${r.id}'),
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.titulo != null && r.titulo!.isNotEmpty)
              Text(
                r.titulo!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                r.contenido,
                maxLines: desplegado ? null : 3,
                overflow: desplegado ? null : TextOverflow.ellipsis,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() {
                  if (!_desplegados.remove(r.id)) _desplegados.add(r.id);
                }),
                child: Text(
                  desplegado ? _t.moderationShowLess : _t.moderationShowMore,
                ),
              ),
            ),
            Text(_t.moderationAuthor(r.autor)),
            Text(_t.moderationReporter(r.reportador)),
            Text(_t.moderationReason(_textoMotivo(r))),
            Text(
              '${_t.moderationMessageDate(_fecha(r.fechaMensaje))} · '
              '${_t.moderationReportDate(_fecha(r.fechaReporte))}',
              style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
            ),
            if (r.otrosReportesDelAutor > 0) ...[
              const SizedBox(height: 6),
              Text(
                _t.moderationAuthorReports(r.otrosReportesDelAutor + 1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _rojo,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (r.pendiente) _construirAcciones(r) else _construirResolucion(r),
          ],
        ),
      ),
    );
  }

  String _textoMotivo(ReporteModel r) {
    final motivo = r.motivo?.trim();

    return motivo == null || motivo.isEmpty ? _t.moderationNoReason : motivo;
  }

  Widget _construirAcciones(ReporteModel r) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton(
          onPressed: _ejecutando
              ? null
              : () => _confirmarYEjecutar(
                  mensaje: _t.moderationDiscardConfirm,
                  accion: (nota, _) => _servicio.descartar(r.id, nota: nota),
                ),
          child: Text(_t.moderationDiscard),
        ),
        OutlinedButton(
          onPressed: _ejecutando
              ? null
              : () => _confirmarYEjecutar(
                  mensaje: _t.moderationDeleteConfirm,
                  accion: (nota, _) =>
                      _servicio.borrarMensaje(r.id, nota: nota),
                ),
          child: Text(_t.moderationDeleteMessage),
        ),
        if (r.autorActivo && !r.autorEsAdmin)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _rojo),
            onPressed: _ejecutando
                ? null
                : () => _confirmarYEjecutar(
                    mensaje: _t.moderationDeactivateConfirm,
                    conBorrarMensaje: true,
                    accion: (nota, borrar) => _servicio.desactivarAutor(
                      r.id,
                      nota: nota,
                      borrarMensaje: borrar,
                    ),
                  ),
            child: Text(_t.moderationDeactivateAuthor),
          ),
      ],
    );
  }

  Widget _construirResolucion(ReporteModel r) {
    final estado = switch (r.estado) {
      estadoReporteDescartado => _t.moderationStateDiscarded,
      estadoReporteMensajeBorrado => _t.moderationStateMessageDeleted,
      estadoReporteAutorDesactivado => _t.moderationStateAuthorDeactivated,
      _ => r.estado,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(estado, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (r.resueltoPor != null)
          Text(
            _t.moderationResolvedBy(r.resueltoPor!, _fecha(r.fechaResolucion)),
            style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
          ),
        if (r.nota != null && r.nota!.isNotEmpty) Text(r.nota!),
      ],
    );
  }

  static String _fecha(DateTime? fecha) {
    if (fecha == null) return '';

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
}
