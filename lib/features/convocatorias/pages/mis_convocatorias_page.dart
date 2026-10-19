import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/services/auth_manager.dart';
import '../model/mi_convocatoria_model.dart';
import '../services/convocatoria_service.dart';

/// Convocatorias de los jugadores del usuario (JUGADOR: la suya; FAMILIAR: la
/// de cada hijo) para los próximos 14 días, con "Va" / "No puede" mientras
/// dure el plazo. El servidor decide si se puede responder: la app solo
/// muestra lo que éste le dice (puedeResponder / limiteRespuesta).
class MisConvocatoriasPage extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real.
  final ConvocatoriaService? service;

  const MisConvocatoriasPage({super.key, this.service});

  @override
  State<MisConvocatoriasPage> createState() => _MisConvocatoriasPageState();
}

class _MisConvocatoriasPageState extends State<MisConvocatoriasPage> {
  late final ConvocatoriaService _service =
      widget.service ?? ConvocatoriaService();

  List<MiConvocatoriaModel> _convocatorias = [];
  bool _cargando = true;
  Object? _error;

  /// Convocatoria+jugador a los que se está enviando una respuesta.
  final Set<String> _enviando = {};

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final convocatorias = await _service.obtenerMias();

      if (!mounted) return;

      setState(() {
        _convocatorias = convocatorias;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  /// Un familiar siempre ve el nombre del hijo; un jugador solo si hay más
  /// de uno en la lista.
  bool get _mostrarNombres =>
      AuthManager.usuarioActual?.tieneRol('FAMILIAR') == true ||
      _convocatorias.map((c) => c.jugadorId).toSet().length > 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPageMyCallups)),
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

    if (_convocatorias.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.how_to_reg_outlined, size: 64, color: _colors.primary),
            const SizedBox(height: 20),
            Text(
              _t.callupNoUpcoming,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _colors.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // Agrupadas por partido: bajo cada partido, una fila por jugador.
    final porPartido = <int, List<MiConvocatoriaModel>>{};

    for (final convocatoria in _convocatorias) {
      porPartido
          .putIfAbsent(convocatoria.convocatoriaId, () => [])
          .add(convocatoria);
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          for (final grupo in porPartido.values) ...[
            _construirPartido(grupo),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _construirPartido(List<MiConvocatoriaModel> grupo) {
    final primera = grupo.first;

    final fecha = primera.fechaPartido == null
        ? ''
        : formatearFechaConDiaSemana(primera.fechaPartido!, _t);

    final partido = [
      fecha,
      if (primera.horaPartido?.isNotEmpty == true) primera.horaPartido!,
      if (primera.campo?.isNotEmpty == true) primera.campo!,
    ].where((p) => p.isNotEmpty).join(' · ');

    final convocatoria = [
      if (primera.horaConvocatoria?.isNotEmpty == true)
        primera.horaConvocatoria!,
      if (primera.lugarConvocatoria?.isNotEmpty == true)
        primera.lugarConvocatoria!,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primera.rival,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            if (primera.equipo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                primera.equipo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _colors.primary,
                ),
              ),
            ],
            if (partido.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _t.callupMatchLine(partido),
                style: TextStyle(color: _colors.onSurfaceVariant),
              ),
            ],
            if (convocatoria.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _t.callupMeetingLine(
                  primera.horaConvocatoria ?? '',
                  primera.lugarConvocatoria ?? '',
                ),
                style: TextStyle(color: _colors.onSurfaceVariant),
              ),
            ],
            for (final jugador in grupo) ...[
              const Divider(height: 28),
              _construirJugador(jugador),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirJugador(MiConvocatoriaModel c) {
    final clave = '${c.convocatoriaId}-${c.jugadorId}';
    final enviando = _enviando.contains(clave);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_mostrarNombres)
              Expanded(
                child: Text(
                  c.jugador,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _colors.onSurface,
                  ),
                ),
              )
            else
              const Spacer(),
            _construirEstado(c.respuesta),
          ],
        ),
        if (c.respuesta == MiConvocatoriaModel.respuestaNoPuede &&
            c.motivo?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            _t.callupReasonShown(c.motivo!),
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 10),
        if (c.cancelado)
          Text(
            _t.callupMatchCancelled,
            style: TextStyle(color: _colors.onSurfaceVariant),
          )
        else if (c.puedeResponder)
          Row(
            children: [
              Expanded(
                child: _botonRespuesta(
                  etiqueta: _t.callupAnswerGoing,
                  icono: Icons.check_circle_outline,
                  color: Colors.green,
                  seleccionado: c.respuesta == MiConvocatoriaModel.respuestaVa,
                  onPressed: enviando ? null : () => _responderVa(c),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _botonRespuesta(
                  etiqueta: _t.callupAnswerCannot,
                  icono: Icons.cancel_outlined,
                  color: Colors.red,
                  seleccionado:
                      c.respuesta == MiConvocatoriaModel.respuestaNoPuede,
                  onPressed: enviando ? null : () => _responderNoPuede(c),
                ),
              ),
            ],
          )
        else
          Text(
            _t.callupDeadlineClosed(_formatearLimite(c.limiteRespuesta)),
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _botonRespuesta({
    required String etiqueta,
    required IconData icono,
    required Color color,
    required bool seleccionado,
    required VoidCallback? onPressed,
  }) {
    if (seleccionado) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: onPressed,
        icon: Icon(icono),
        label: Text(etiqueta),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      onPressed: onPressed,
      icon: Icon(icono),
      label: Text(etiqueta),
    );
  }

  Widget _construirEstado(String? respuesta) {
    final (texto, color) = switch (respuesta) {
      MiConvocatoriaModel.respuestaVa => (_t.callupStatusGoing, Colors.green),
      MiConvocatoriaModel.respuestaNoPuede => (
        _t.callupStatusCannot,
        Colors.red,
      ),
      _ => (_t.callupStatusPending, Colors.amber.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatearLimite(DateTime? limite) {
    if (limite == null) {
      return '';
    }

    return DateFormat(
      'dd/MM HH:mm',
      Localizations.localeOf(context).toString(),
    ).format(limite);
  }

  Future<void> _responderVa(MiConvocatoriaModel c) =>
      _enviar(c, MiConvocatoriaModel.respuestaVa, null);

  Future<void> _responderNoPuede(MiConvocatoriaModel c) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => _MotivoDialog(motivoInicial: c.motivo),
    );

    if (motivo == null || !mounted) return;

    await _enviar(c, MiConvocatoriaModel.respuestaNoPuede, motivo);
  }

  Future<void> _enviar(
    MiConvocatoriaModel c,
    String respuesta,
    String? motivo,
  ) async {
    final clave = '${c.convocatoriaId}-${c.jugadorId}';

    setState(() => _enviando.add(clave));

    try {
      final actualizada = await _service.responder(
        convocatoriaId: c.convocatoriaId,
        jugadorId: c.jugadorId,
        respuesta: respuesta,
        motivo: motivo,
      );

      if (!mounted) return;

      setState(() {
        _enviando.remove(clave);
        _convocatorias = [
          for (final item in _convocatorias)
            if (item.convocatoriaId == c.convocatoriaId &&
                item.jugadorId == c.jugadorId)
              actualizada
            else
              item,
        ];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.callupAnswerSaved)));
    } catch (e) {
      if (!mounted) return;

      setState(() => _enviando.remove(clave));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.callupAnswerError(e.toString()))),
      );

      // Puede que el plazo haya terminado mientras tanto: se vuelve a leer.
      _cargar();
    }
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
              _t.callupsLoadFailed,
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

                _cargar();
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

/// Motivo de "No puede": obligatorio, entre 3 y 500 caracteres.
class _MotivoDialog extends StatefulWidget {
  final String? motivoInicial;

  const _MotivoDialog({this.motivoInicial});

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.motivoInicial ?? '',
  );

  String? _error;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aceptar() {
    final motivo = _controller.text.trim();

    if (motivo.length < 3) {
      setState(() => _error = _t.callupReasonRequired);
      return;
    }

    Navigator.pop(context, motivo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t.callupCannotDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: _t.callupReasonLabel,
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_t.cancel),
        ),
        FilledButton(onPressed: _aceptar, child: Text(_t.save)),
      ],
    );
  }
}
