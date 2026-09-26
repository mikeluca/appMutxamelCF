import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/mensaje_conversacion_model.dart';
import '../services/comunicacion_service.dart';

class ChatPrivadoPage extends StatefulWidget {
  final int contraparteId;
  final String? contraparteNombre;
  final String? contraparteRol;

  const ChatPrivadoPage({
    super.key,
    required this.contraparteId,
    this.contraparteNombre,
    this.contraparteRol,
  });

  @override
  State<ChatPrivadoPage> createState() => _ChatPrivadoPageState();
}

class _ChatPrivadoPageState extends State<ChatPrivadoPage> {
  static const int _mensajesPorPagina = 20;

  List<MensajeConversacionModel> _mensajes = [];

  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  // Paginación por cursor: hasta que una página devuelva menos de
  // _mensajesPorPagina mensajes, asumimos que puede haber más
  // antiguos que cargar.
  bool _hayMasAntiguos = true;
  bool _cargandoMasAntiguos = false;

  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargarConversacion();

    _scrollController.addListener(() {
      // La lista usa reverse: true, así que acercarse a
      // maxScrollExtent es visualmente "llegar arriba del todo",
      // donde están los mensajes más antiguos ya cargados.
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _cargarMensajesAnteriores();
      }
    });
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarConversacion() async {
    try {
      final mensajes = await ComunicacionService.obtenerConversacion(
        widget.contraparteId,
      );

      if (!mounted) return;

      setState(() {
        _mensajes = mensajes;
        _error = null;
        _cargando = false;
        _hayMasAntiguos = mensajes.length >= _mensajesPorPagina;
      });

      // No bloqueamos la carga del chat por esto.
      unawaited(
        ComunicacionService.marcarConversacionLeida(widget.contraparteId),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _cargarMensajesAnteriores() async {
    if (!_hayMasAntiguos || _cargandoMasAntiguos || _mensajes.isEmpty) return;

    setState(() => _cargandoMasAntiguos = true);

    try {
      final anteriores = await ComunicacionService.obtenerConversacion(
        widget.contraparteId,
        antesId: _mensajes.first.id,
      );

      if (!mounted) return;

      setState(() {
        _mensajes = [...anteriores, ..._mensajes];
        _hayMasAntiguos = anteriores.length >= _mensajesPorPagina;
        _cargandoMasAntiguos = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _cargandoMasAntiguos = false);

      // No hace falta mostrar error bloqueante: si falla, el usuario
      // simplemente puede volver a intentar haciendo scroll otra vez.
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();

    if (texto.isEmpty || _enviando) {
      return;
    }

    setState(() => _enviando = true);

    try {
      await ComunicacionService.crearComunicacion(
        titulo: null,
        contenido: texto,
        equipoIds: const [],
        categorias: const [],
        destinatariosIds: [widget.contraparteId],
      );

      _mensajeController.clear();

      final mensajes = await ComunicacionService.obtenerConversacion(
        widget.contraparteId,
      );

      if (!mounted) return;

      setState(() {
        _mensajes = mensajes;
        _enviando = false;
        // El envío vuelve a traer los últimos _mensajesPorPagina
        // mensajes, lo que reinicia la paginación (se pierden las
        // páginas antiguas ya cargadas, es aceptable).
        _hayMasAntiguos = mensajes.length >= _mensajesPorPagina;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _enviando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.contraparteNombre ?? _t.chatDefaultTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (widget.contraparteRol != null)
              Text(
                widget.contraparteRol!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _construirContenido()),
          _construirCajaEnvio(),
        ],
      ),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.azul),
      );
    }

    if (_error != null) {
      return _construirError();
    }

    if (_mensajes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _t.chatNoMessages,
            textAlign: TextAlign.center,
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final mensajesInvertidos = _mensajes.reversed.toList();

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargarConversacion,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemCount: mensajesInvertidos.length + (_cargandoMasAntiguos ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == mensajesInvertidos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.azul,
                  ),
                ),
              ),
            );
          }

          return _construirBurbuja(mensajesInvertidos[index]);
        },
      ),
    );
  }

  Widget _construirBurbuja(MensajeConversacionModel mensaje) {
    final esMia = mensaje.esMia;

    final fondo = esMia ? AppColors.azul : _colors.surfaceContainerHighest;
    final colorTexto = esMia ? Colors.white : _colors.onSurface;
    final colorFecha = esMia ? Colors.white70 : _colors.onSurfaceVariant;

    return Align(
      alignment: esMia ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esMia ? 16 : 4),
            bottomRight: Radius.circular(esMia ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje.contenido
                  .replaceAll(r'\r\n', '\n')
                  .replaceAll(r'\n', '\n')
                  .replaceAll(r'\r', '\n'),
              style: TextStyle(color: colorTexto, fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              _formatearHora(mensaje.fecha),
              style: TextStyle(color: colorFecha, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCajaEnvio() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mensajeController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _t.chatMessageHint,
                  filled: true,
                  fillColor: _colors.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _enviarMensaje(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _enviando ? null : _enviarMensaje,
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              style: IconButton.styleFrom(backgroundColor: AppColors.azul),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearHora(DateTime? fecha) {
    if (fecha == null) {
      return '';
    }

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _colors.onSurface),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarConversacion();
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
