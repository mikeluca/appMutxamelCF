import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/origen_compartir.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/imagenes_redes_model.dart';
import '../services/imagenes_redes_service.dart';

/// Envía los PNG y el texto al menú de compartir del sistema. Los tests lo sustituyen.
typedef EnviarImagenesRedes =
    Future<void> Function(
      List<Uint8List> pngs,
      List<String> nombres,
      String texto,
      Rect origen,
    );

class CompartirImagenesRedes {
  CompartirImagenesRedes._();

  @visibleForTesting
  static EnviarImagenesRedes enviar = (pngs, nombres, texto, origen) async {
    await SharePlus.instance.share(
      ShareParams(
        text: texto,
        sharePositionOrigin: origen,
        files: [
          for (var i = 0; i < pngs.length; i++)
            XFile.fromData(pngs[i], mimeType: 'image/png', name: nombres[i]),
        ],
        fileNameOverrides: nombres,
      ),
    );
  };
}

/// El nombre de la modalidad ("F11" → "Fútbol 11") en el idioma de la app.
String nombreModalidadImagen(AppLocalizations t, String modalidad) {
  return switch (modalidad) {
    'F8' => t.socialImagesF8,
    'F5' => t.socialImagesF5,
    _ => t.socialImagesF11,
  };
}

/// Vista previa a pantalla completa de las imágenes de una publicación (previa o
/// resultados): se pasan de lado y se pueden compartir todas juntas con el texto
/// sugerido, copiar el texto o regenerar.
class ImagenesRedesVistaPage extends StatefulWidget {
  final ImagenesRedesService servicio;
  final String tipo;

  /// El viernes del fin de semana (para regenerar el mismo).
  final DateTime? desde;
  final List<ImagenRedesModel> imagenes;
  final String texto;
  final int indiceInicial;

  const ImagenesRedesVistaPage({
    super.key,
    required this.servicio,
    required this.tipo,
    required this.desde,
    required this.imagenes,
    required this.texto,
    this.indiceInicial = 0,
  });

  @override
  State<ImagenesRedesVistaPage> createState() => _ImagenesRedesVistaPageState();
}

class _ImagenesRedesVistaPageState extends State<ImagenesRedesVistaPage> {
  late List<ImagenRedesModel> _imagenes = widget.imagenes;
  late String _texto = widget.texto;
  late int _actual = widget.indiceInicial.clamp(0, widget.imagenes.length - 1);
  late final PageController _controlador = PageController(initialPage: _actual);

  bool _ocupado = false;

  /// El botón Compartir: el menú de compartir (iPad) se ancla a él.
  final GlobalKey _claveCompartir = GlobalKey();

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  String get _titulo {
    final t = _t;
    final tipo = widget.tipo == tipoImagenResultados
        ? t.socialImagesResults
        : t.socialImagesPreview;

    if (_imagenes.isEmpty) return tipo;

    final imagen = _imagenes[_actual.clamp(0, _imagenes.length - 1)];
    final pagina = imagen.totalPaginas > 1
        ? ' ${t.socialImagesPageOf(imagen.pagina, imagen.totalPaginas)}'
        : '';

    return '$tipo · ${nombreModalidadImagen(t, imagen.modalidad)}$pagina';
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _compartir() async {
    if (_ocupado) return;

    final t = _t;
    final origen = origenDeCompartir(_claveCompartir.currentContext ?? context);

    setState(() => _ocupado = true);

    try {
      final pngs = <Uint8List>[];
      final nombres = <String>[];

      for (final imagen in _imagenes) {
        pngs.add(await widget.servicio.descargarPng(imagen));
        nombres.add(
          '${widget.tipo.toLowerCase()}_${imagen.modalidad.toLowerCase()}'
          '_${imagen.pagina}.png',
        );
      }

      await CompartirImagenesRedes.enviar(pngs, nombres, _texto, origen);
    } catch (_) {
      if (mounted) _avisar(t.socialImagesShareError);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _copiarTexto() async {
    await Clipboard.setData(ClipboardData(text: _texto));

    if (mounted) _avisar(_t.socialImagesTextCopied);
  }

  Future<void> _regenerar() async {
    if (_ocupado) return;

    final t = _t;

    setState(() => _ocupado = true);

    try {
      final nuevas = await widget.servicio.regenerar(
        tipo: widget.tipo,
        fecha: widget.desde,
      );
      final imagenes = nuevas.deTipo(widget.tipo);

      if (!mounted) return;

      if (imagenes.isEmpty) {
        _avisar(t.socialImagesNothing);
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _imagenes = imagenes;
        _texto = nuevas.textoDe(widget.tipo);
        _actual = _actual.clamp(0, imagenes.length - 1);
      });

      _avisar(t.socialImagesGenerated);
    } catch (e) {
      if (mounted) _avisar(mensajeDeAccion(t, e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_titulo, style: const TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controlador,
              itemCount: _imagenes.length,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (context, i) => _Pagina(
                key: ValueKey('vista-imagen-${_imagenes[i].id}'),
                servicio: widget.servicio,
                imagen: _imagenes[i],
              ),
            ),
          ),
          if (_imagenes.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_actual + 1} / ${_imagenes.length}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    key: _claveCompartir,
                    child: FilledButton.icon(
                      key: const ValueKey('imagenes-compartir'),
                      onPressed: _ocupado || _imagenes.isEmpty
                          ? null
                          : _compartir,
                      icon: const Icon(Icons.ios_share),
                      label: Text(t.socialImagesShare),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    key: const ValueKey('imagenes-copiar'),
                    tooltip: t.socialImagesCopyText,
                    color: Colors.white,
                    onPressed: _copiarTexto,
                    icon: const Icon(Icons.copy),
                  ),
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    key: const ValueKey('imagenes-regenerar'),
                    tooltip: t.socialImagesRegenerate,
                    color: Colors.white,
                    onPressed: _ocupado ? null : _regenerar,
                    icon: _ocupado
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagina extends StatelessWidget {
  final ImagenesRedesService servicio;
  final ImagenRedesModel imagen;

  const _Pagina({super.key, required this.servicio, required this.imagen});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: servicio.descargarPng(imagen),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context).socialImagesLoadError,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}
