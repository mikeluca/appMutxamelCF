import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/imagenes_redes_model.dart';
import '../services/imagenes_redes_service.dart';
import 'imagenes_redes_vista.dart';

/// "Imágenes para redes" del panel Fin de semana: las miniaturas de la previa y de los resultados del
/// fin de semana que se está viendo, o cuándo se generan y un botón para generarlas ya.
class SeccionImagenesRedes extends StatefulWidget {
  final ImagenesRedesService servicio;

  /// El viernes del fin de semana que se está viendo.
  final DateTime viernes;

  const SeccionImagenesRedes({
    super.key,
    required this.servicio,
    required this.viernes,
  });

  @override
  State<SeccionImagenesRedes> createState() => _SeccionImagenesRedesState();
}

class _SeccionImagenesRedesState extends State<SeccionImagenesRedes> {
  late Future<ImagenesRedesModel> _futuro;

  /// El tipo que se está generando ahora (su botón queda en espera).
  String? _generando;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _futuro = widget.servicio.obtener(fecha: widget.viernes);
  }

  void _recargar() {
    setState(() {
      _futuro = widget.servicio.obtener(fecha: widget.viernes);
    });
  }

  Future<void> _generar(String tipo) async {
    final t = _t;
    final mensajero = ScaffoldMessenger.of(context);

    setState(() => _generando = tipo);

    try {
      final nuevas = await widget.servicio.regenerar(
        tipo: tipo,
        fecha: widget.viernes,
      );

      if (!mounted) return;

      setState(() {
        _futuro = Future.value(nuevas);
        _generando = null;
      });

      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nuevas.deTipo(tipo).isEmpty
                  ? t.socialImagesNothing
                  : t.socialImagesGenerated,
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      setState(() => _generando = null);

      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensajeDeAccion(t, e))));
    }
  }

  Future<void> _abrir(
    ImagenesRedesModel datos,
    String tipo,
    ImagenRedesModel elegida,
  ) async {
    final imagenes = datos.deTipo(tipo);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagenesRedesVistaPage(
          servicio: widget.servicio,
          tipo: tipo,
          desde: widget.viernes,
          imagenes: imagenes,
          texto: datos.textoDe(tipo),
          indiceInicial: imagenes.indexWhere((i) => i.id == elegida.id),
        ),
      ),
    );

    // Pudo regenerarse desde la vista previa.
    if (mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      key: const ValueKey('seccion-imagenes-redes'),
      margin: const EdgeInsets.only(top: 12),
      elevation: 1,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t.socialImagesTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<ImagenesRedesModel>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final datos = snapshot.data;

                if (snapshot.hasError || datos == null) {
                  return _construirError();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _construirTipo(datos, tipoImagenPrevia),
                    _construirTipo(datos, tipoImagenResultados),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(_t.socialImagesLoadError)),
          TextButton(onPressed: _recargar, child: Text(_t.retry)),
        ],
      ),
    );
  }

  Widget _construirTipo(ImagenesRedesModel datos, String tipo) {
    final t = _t;
    final imagenes = datos.deTipo(tipo);
    final esPrevia = tipo == tipoImagenPrevia;
    final generando = _generando == tipo;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            esPrevia ? t.socialImagesPreview : t.socialImagesResults,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (imagenes.isEmpty) ...[
            Text(
              esPrevia
                  ? t.socialImagesEmptyPreview
                  : t.socialImagesEmptyResults,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: ValueKey('generar-$tipo'),
              onPressed: _generando != null ? null : () => _generar(tipo),
              icon: generando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(t.socialImagesGenerateNow),
            ),
          ] else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagenes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _Miniatura(
                  servicio: widget.servicio,
                  imagen: imagenes[i],
                  etiqueta: _etiqueta(imagenes[i]),
                  onTap: () => _abrir(datos, tipo, imagenes[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _etiqueta(ImagenRedesModel imagen) {
    final nombre = nombreModalidadImagen(_t, imagen.modalidad);

    return imagen.totalPaginas > 1
        ? '$nombre ${_t.socialImagesPageOf(imagen.pagina, imagen.totalPaginas)}'
        : nombre;
  }
}

class _Miniatura extends StatelessWidget {
  final ImagenesRedesService servicio;
  final ImagenRedesModel imagen;
  final String etiqueta;
  final VoidCallback onTap;

  const _Miniatura({
    required this.servicio,
    required this.imagen,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('imagen-redes-${imagen.id}'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List>(
                  future: servicio.descargarPng(imagen),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        width: 120,
                        cacheWidth: 360,
                        gaplessPlayback: true,
                      );
                    }

                    return Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: snapshot.hasError
                          ? const Icon(Icons.broken_image_outlined)
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
