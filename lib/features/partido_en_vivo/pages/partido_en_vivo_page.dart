import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ClubAppBarTitle(titulo: 'Partido en directo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Cada botón manda un aviso en directo a todos los usuarios de '
            'la app. Revisa bien antes de pulsar: no se puede deshacer.',
            style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _construirBotonAlineacion(),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.sports_soccer,
            titulo: 'Inicio de partido',
            mensajeConfirmacion: '¿Avisar de que empieza el partido?',
            accion: _service.enviarInicioPartido,
          ),
          const SizedBox(height: 12),
          _construirBotonGolFavor(),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.sentiment_dissatisfied_outlined,
            titulo: 'Gol en contra',
            mensajeConfirmacion: '¿Avisar de un gol en contra?',
            accion: _service.enviarGolContra,
          ),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.pause_circle_outline,
            titulo: 'Descanso',
            mensajeConfirmacion: '¿Avisar del descanso?',
            accion: _service.enviarDescanso,
          ),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.play_circle_outline,
            titulo: 'Segunda parte',
            mensajeConfirmacion: '¿Avisar del inicio de la segunda parte?',
            accion: _service.enviarSegundaParte,
          ),
          const SizedBox(height: 12),
          _construirBotonConfirmacion(
            icono: Icons.flag_outlined,
            titulo: 'Final de partido',
            mensajeConfirmacion: '¿Avisar de que ha finalizado el partido?',
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
      titulo: 'Alineación',
      onPressed: _abrirDialogoAlineacion,
    );
  }

  Widget _construirBotonGolFavor() {
    return _construirBoton(
      icono: Icons.emoji_events_outlined,
      titulo: 'Gol a favor',
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

    await _ejecutar(accion, 'Aviso de "$titulo" enviado.');
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
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
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
        title: const Text('Alineación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: onceController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Once inicial',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: suplentesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Suplentes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    if (onceController.text.trim().isEmpty ||
        suplentesController.text.trim().isEmpty) {
      _mostrarMensaje('Rellena el once inicial y los suplentes.');
      return;
    }

    await _ejecutar(
      () => _service.enviarAlineacion(
        onceInicial: onceController.text.trim(),
        suplentes: suplentesController.text.trim(),
      ),
      'Alineación enviada.',
    );
  }

  Future<void> _abrirDialogoGolFavor() async {
    final autorController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gol a favor'),
        content: TextField(
          controller: autorController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Autor del gol',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    if (autorController.text.trim().isEmpty) {
      _mostrarMensaje('Escribe el autor del gol.');
      return;
    }

    await _ejecutar(
      () => _service.enviarGolFavor(autorController.text.trim()),
      'Gol enviado.',
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

      _mostrarMensaje('No se ha podido enviar el aviso: $e');
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
