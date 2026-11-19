import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/imagenes_redes_model.dart';
import '../services/imagenes_redes_service.dart';
import 'imagenes_redes_vista.dart';

/// Las imágenes de la previa o de los resultados (según [tipo]) del fin de semana que se está viendo: sus
/// miniaturas y "Volver a generar", o un botón para generarlas ya. Las genera a mano Retransmisión (o un
/// administrador de la app): ya no se generan solas.
class SeccionImagenesRedes extends StatefulWidget {
  final ImagenesRedesService servicio;

  /// El viernes del fin de semana que se está viendo.
  final DateTime viernes;

  /// [tipoImagenPrevia] o [tipoImagenResultados].
  final String tipo;

  /// Se llama si el servidor dice 403 (la cuenta ya no tiene permiso): la pantalla avisa y vuelve al menú.
  final VoidCallback? alDenegar;

  const SeccionImagenesRedes({
    super.key,
    required this.servicio,
    required this.viernes,
    required this.tipo,
    this.alDenegar,
  });

  @override
  State<SeccionImagenesRedes> createState() => _SeccionImagenesRedesState();
}

class _SeccionImagenesRedesState extends State<SeccionImagenesRedes> {
  late Future<ImagenesRedesModel> _futuro;

  /// Si se está generando ahora (su botón queda en espera).
  bool _generando = false;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  /// Un 403 no es un fallo de red: se avisa a la pantalla.
  bool _esDenegado(Object? error) =>
      error is ApiException && error.statusCode == 403;

  Future<ImagenesRedesModel> _cargar() async {
    try {
      return await widget.servicio.obtener(fecha: widget.viernes);
    } catch (e) {
      if (_esDenegado(e)) widget.alDenegar?.call();

      rethrow;
    }
  }

  void _recargar() {
    setState(() {
      _futuro = _cargar();
    });
  }

  Future<void> _generar() async {
    final t = _t;
    final tipo = widget.tipo;
    final mensajero = ScaffoldMessenger.of(context);

    setState(() => _generando = true);

    try {
      final nuevas = await widget.servicio.regenerar(
        tipo: tipo,
        fecha: widget.viernes,
      );

      if (!mounted) return;

      setState(() {
        _futuro = Future.value(nuevas);
        _generando = false;
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

      setState(() => _generando = false);

      if (_esDenegado(e)) {
        widget.alDenegar?.call();
        return;
      }

      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensajeDeAccion(t, e))));
    }
  }

  Future<void> _abrir(
    ImagenesRedesModel datos,
    ImagenRedesModel elegida,
  ) async {
    final imagenes = datos.deTipo(widget.tipo);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagenesRedesVistaPage(
          servicio: widget.servicio,
          tipo: widget.tipo,
          desde: widget.viernes,
          imagenes: imagenes,
          texto: datos.textoDe(widget.tipo),
          indiceInicial: imagenes.indexWhere((i) => i.id == elegida.id),
        ),
      ),
    );

    // Pudo regenerarse desde la vista previa.
    if (mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImagenesRedesModel>(
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

        return _construirTipo(datos);
      },
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

  /// Con imágenes ya hechas pide confirmar antes de sustituirlas.
  Future<void> _volverAGenerar() async {
    final t = _t;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('confirmar-regenerar-imagenes'),
        content: Text(t.socialImagesRegenerateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirmar-regenerar-si'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.socialImagesRegenerateAgain),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      await _generar();
    }
  }

  Widget _construirBotonGenerar({required bool conImagenes}) {
    return FilledButton.tonalIcon(
      key: ValueKey('generar-${widget.tipo}'),
      onPressed: _generando
          ? null
          : () => conImagenes ? _volverAGenerar() : _generar(),
      icon: _generando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(conImagenes ? Icons.refresh : Icons.auto_awesome),
      label: Text(
        conImagenes
            ? _t.socialImagesRegenerateAgain
            : _t.socialImagesGenerateNow,
      ),
    );
  }

  Widget _construirTipo(ImagenesRedesModel datos) {
    final t = _t;
    final imagenes = datos.deTipo(widget.tipo);
    final esPrevia = widget.tipo == tipoImagenPrevia;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagenes.isEmpty) ...[
            Text(
              esPrevia
                  ? t.socialImagesEmptyPreview
                  : t.socialImagesEmptyResults,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _construirBotonGenerar(conImagenes: false),
          ] else ...[
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
                  onTap: () => _abrir(datos, imagenes[i]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _construirBotonGenerar(conImagenes: true),
          ],
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
                  key: ValueKey('png-${imagen.id}-${imagen.version}'),
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
