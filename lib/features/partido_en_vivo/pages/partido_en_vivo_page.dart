import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../services/partido_en_vivo_service.dart';

class PartidoEnVivoPage extends StatefulWidget {
  const PartidoEnVivoPage({super.key});

  @override
  State<PartidoEnVivoPage> createState() => _PartidoEnVivoPageState();
}

class _PartidoEnVivoPageState extends State<PartidoEnVivoPage> {
  final PartidoEnVivoService _service = PartidoEnVivoService();

  bool _enviando = false;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: _t.liveMatchTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _t.liveMatchWarning,
            style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _construirBotonAlineacion(),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.sports_soccer,
            titulo: _t.liveEventKickoff,
            mensajeConfirmacion: _t.liveConfirmKickoff,
            accion: _service.enviarInicioPartido,
          ),
          const SizedBox(height: 12),
          _construirBotonGolFavor(),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.sentiment_dissatisfied_outlined,
            titulo: _t.liveEventGoalAgainst,
            mensajeConfirmacion: _t.liveConfirmGoalAgainst,
            accion: _service.enviarGolContra,
          ),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.pause_circle_outline,
            titulo: _t.liveEventHalftime,
            mensajeConfirmacion: _t.liveConfirmHalftime,
            accion: _service.enviarDescanso,
          ),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.play_circle_outline,
            titulo: _t.liveEventSecondHalf,
            mensajeConfirmacion: _t.liveConfirmSecondHalf,
            accion: _service.enviarSegundaParte,
          ),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.flag_outlined,
            titulo: _t.liveEventFulltime,
            mensajeConfirmacion: _t.liveConfirmFulltime,
            accion: _service.enviarFinalPartido,
          ),
        ],
      ),
    );
  }

  Widget _construirBoton({
    required IconData icono,
    required String titulo,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _enviando ? null : onPressed,
        icon: Icon(icono),
        label: Text(titulo, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _construirBotonConfirmacion({
    required IconData icono,
    required String titulo,
    required String mensajeConfirmacion,
    required Future<void> Function() accion,
  }) {
    return _construirBoton(
      icono: icono,
      titulo: titulo,
      onPressed: () => _confirmarYEnviar(titulo, mensajeConfirmacion, accion),
    );
  }

  Widget _construirBotonAlineacion() {
    return _construirBoton(
      icono: Icons.list_alt,
      titulo: _t.liveLineupButton,
      onPressed: _abrirDialogoAlineacion,
    );
  }

  Widget _construirBotonGolFavor() {
    return _construirBoton(
      icono: Icons.emoji_events_outlined,
      titulo: _t.liveGoalForButton,
      onPressed: _abrirDialogoGolFavor,
    );
  }

  Future<void> _confirmarYEnviar(
    String titulo,
    String mensajeConfirmacion,
    Future<void> Function() accion,
  ) async {
    final confirmado = await _mostrarConfirmacion(titulo, mensajeConfirmacion);

    if (confirmado != true) return;

    await _ejecutar(accion, _t.liveNotificationSentMessage(titulo));
  }

  Future<bool?> _mostrarConfirmacion(String titulo, String mensaje) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.send),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirDialogoAlineacion() async {
    final onceController = TextEditingController();
    final suplentesController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.liveLineupButton),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: onceController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _t.liveStartingLineupLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: suplentesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _t.liveSubstitutesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.send),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    if (onceController.text.trim().isEmpty ||
        suplentesController.text.trim().isEmpty) {
      _mostrarMensaje(_t.liveFillLineupError);
      return;
    }

    await _ejecutar(
      () => _service.enviarAlineacion(
        onceInicial: onceController.text.trim(),
        suplentes: suplentesController.text.trim(),
      ),
      _t.liveLineupSentMessage,
    );
  }

  Future<void> _abrirDialogoGolFavor() async {
    final autorController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.liveGoalForButton),
        content: TextField(
          controller: autorController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _t.liveGoalAuthorLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.send),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    if (autorController.text.trim().isEmpty) {
      _mostrarMensaje(_t.liveEnterGoalAuthorError);
      return;
    }

    await _ejecutar(
      () => _service.enviarGolFavor(autorController.text.trim()),
      _t.liveGoalSentMessage,
    );
  }

  Future<void> _ejecutar(
    Future<void> Function() accion,
    String mensajeExito,
  ) async {
    setState(() => _enviando = true);

    try {
      await accion();

      if (!mounted) return;

      _mostrarMensaje(mensajeExito);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(_t.liveSendError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
