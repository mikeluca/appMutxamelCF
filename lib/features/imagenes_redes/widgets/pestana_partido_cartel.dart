import '../../../core/utils/nombre_equipo.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/origen_compartir.dart';
import '../../../core/widget/escudo_rival.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/partido_primer_equipo_model.dart';
import '../services/imagenes_redes_service.dart';
import '../utils/fin_de_semana_imagenes.dart';
import 'imagenes_redes_vista.dart';

/// Pestaña del cartel del próximo partido de un equipo (Primer Equipo o Filial, según [equipo]): el partido que devuelve
/// el backend y el cartel que genera el servidor con las opciones elegidas. Es la misma pantalla para los dos; solo
/// cambian la ruta, los textos y el nombre del fichero. El PNG solo vive en memoria (y en lo que el menú de compartir del sistema use para enviarlo).
class PestanaPartidoCartel extends StatefulWidget {
  final ImagenesRedesService servicio;

  /// De qué equipo es el cartel.
  final CartelEquipo equipo;

  /// Se llama si el servidor dice 403: la pantalla avisa y vuelve al menú.
  final VoidCallback? alDenegar;

  const PestanaPartidoCartel({
    super.key,
    required this.servicio,
    this.equipo = CartelEquipo.primerEquipo,
    this.alDenegar,
  });

  @override
  State<PestanaPartidoCartel> createState() => _PestanaPartidoCartelState();
}

class _PestanaPartidoCartelState extends State<PestanaPartidoCartel>
    with AutomaticKeepAliveClientMixin {
  late Future<PartidoPrimerEquipoModel> _futuro;

  /// Lo que está marcado ahora. Siempre empieza con los valores por defecto: no se guarda en el móvil.
  OpcionesCartel _opciones = const OpcionesCartel();

  /// Con qué opciones se generó [_png]; si difieren de [_opciones], la imagen está desactualizada.
  OpcionesCartel? _generadas;
  Uint8List? _png;
  bool _generando = false;
  Object? _error;

  /// El botón Compartir: el menú de compartir (iPad) se ancla a él.
  final GlobalKey _claveCompartir = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  AppLocalizations get _t => AppLocalizations.of(context);

  /// Las claves de los widgets: las del Primer Equipo de siempre y las del Filial con el prefijo "filial-" (las dos
  /// pestañas pueden estar montadas a la vez).
  String _k(String clave) =>
      widget.equipo == CartelEquipo.filial ? 'filial-$clave' : clave;

  String _textoSinPartido(AppLocalizations t) =>
      widget.equipo == CartelEquipo.filial
      ? t.socialImagesNoMatchReserve
      : t.socialImagesNoMatch;

  String _textoImagen(AppLocalizations t) =>
      widget.equipo == CartelEquipo.filial
      ? t.socialImagesPosterAltReserve
      : t.socialImagesPosterAlt;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  bool _esDenegado(Object? error) =>
      error is ApiException && error.statusCode == 403;

  Future<PartidoPrimerEquipoModel> _cargar() async {
    try {
      return await widget.servicio.obtenerPartido(widget.equipo);
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

  void _cambiar(OpcionesCartel opciones) {
    // No se pide nada: la imagen anterior queda marcada como desactualizada hasta pulsar Generar.
    setState(() => _opciones = opciones);
  }

  bool get _desactualizada => _png != null && _generadas != _opciones;

  Future<void> _generar() async {
    if (_generando) return;

    final pedidas = _opciones;

    setState(() {
      _generando = true;
      _error = null;
    });

    try {
      final png = await widget.servicio.generarCartel(widget.equipo, pedidas);

      if (!mounted) return;

      setState(() {
        _png = png;
        _generadas = pedidas;
        _generando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _generando = false;
        _error = e;
      });

      if (_esDenegado(e)) {
        widget.alDenegar?.call();
      } else if (e is ApiException && e.statusCode == 409) {
        // El partido empezó (o se canceló) mientras tanto: se vuelve a preguntar por él.
        _recargar();
      }
    }
  }

  String _textoError(Object? error) {
    final t = _t;

    if (error is ApiException && error.statusCode == 409) {
      return mensajeDeAccion(t, error);
    }

    return t.socialImagesPosterError;
  }

  /// El texto para publicar en el idioma elegido, sin los hashtags si está desmarcado.
  String _texto(PartidoPrimerEquipoModel partido, OpcionesCartel opciones) {
    final texto = partido.textoDe(opciones.idioma);

    return opciones.hashtags ? texto : textoSinHashtags(texto);
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _copiar(PartidoPrimerEquipoModel partido) async {
    await Clipboard.setData(ClipboardData(text: _texto(partido, _opciones)));

    if (mounted) _avisar(_t.socialImagesTextCopied);
  }

  Future<void> _compartir(PartidoPrimerEquipoModel partido) async {
    final png = _png;
    final generadas = _generadas;

    if (png == null || generadas == null) return;

    final t = _t;
    final origen = origenDeCompartir(_claveCompartir.currentContext ?? context);

    try {
      await CompartirImagenesRedes.compartir(
        [png],
        [
          '${widget.equipo.prefijoFichero}_${generadas.formato.api.toLowerCase()}.png',
        ],
        _texto(partido, generadas),
        origen,
      );
    } catch (_) {
      if (mounted) _avisar(t.socialImagesShareError);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<PartidoPrimerEquipoModel>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final partido = snapshot.data;

        if (snapshot.hasError || partido == null) {
          return _conPadding(
            Row(
              children: [
                Expanded(child: Text(_t.socialImagesPosterLoadError)),
                TextButton(
                  key: ValueKey(_k('cartel-reintentar-partido')),
                  onPressed: _recargar,
                  child: Text(_t.retry),
                ),
              ],
            ),
          );
        }

        if (!partido.disponible) {
          return _conPadding(_construirNoDisponible(partido));
        }

        return _construirContenido(partido);
      },
    );
  }

  Widget _conPadding(Widget hijo) {
    return ListView(padding: const EdgeInsets.all(16), children: [hijo]);
  }

  Widget _construirNoDisponible(PartidoPrimerEquipoModel partido) {
    final t = _t;
    final yaEmpezado = partido.motivo == motivoYaEmpezado;

    return Card(
      key: ValueKey(_k('cartel-no-disponible')),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              yaEmpezado ? Icons.sports_soccer : Icons.event_busy_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                yaEmpezado ? t.socialImagesMatchStarted : _textoSinPartido(t),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido(PartidoPrimerEquipoModel partido) {
    final t = _t;
    final colors = Theme.of(context).colorScheme;

    // Todo el contenido a la vez (no es largo): un ListView solo construiría lo que se ve.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TarjetaPartido(partido: partido, k: _k),
          const SizedBox(height: 16),
          _titulo(t.shareFormatLabel),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<FormatoCartel>(
              key: ValueKey(_k('cartel-formato')),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: FormatoCartel.publicacion,
                  label: Text(t.shareFormatPost),
                ),
                ButtonSegment(
                  value: FormatoCartel.historia,
                  label: Text(t.shareFormatStory),
                ),
              ],
              selected: {_opciones.formato},
              onSelectionChanged: (s) =>
                  _cambiar(_opciones.copiaCon(formato: s.first)),
            ),
          ),
          _titulo(t.socialImagesLanguageLabel),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<IdiomaCartel>(
              key: ValueKey(_k('cartel-idioma')),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: IdiomaCartel.es,
                  label: Text(t.socialImagesLanguageEs),
                ),
                ButtonSegment(
                  value: IdiomaCartel.ca,
                  label: Text(t.socialImagesLanguageCa),
                ),
              ],
              selected: {_opciones.idioma},
              onSelectionChanged: (s) =>
                  _cambiar(_opciones.copiaCon(idioma: s.first)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                key: ValueKey(_k('cartel-opcion-racha')),
                label: Text(t.shareToggleForm),
                selected: _opciones.racha,
                onSelected: (v) => _cambiar(_opciones.copiaCon(racha: v)),
              ),
              FilterChip(
                key: ValueKey(_k('cartel-opcion-qr')),
                label: Text(t.shareToggleQr),
                selected: _opciones.qr,
                onSelected: (v) => _cambiar(_opciones.copiaCon(qr: v)),
              ),
              FilterChip(
                key: ValueKey(_k('cartel-opcion-hashtags')),
                label: Text(t.shareToggleHashtags),
                selected: _opciones.hashtags,
                onSelected: (v) => _cambiar(_opciones.copiaCon(hashtags: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: ValueKey(_k('cartel-generar')),
            onPressed: _generando ? null : _generar,
            icon: _generando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(t.socialImagesGenerate),
          ),
          if (_error != null && !_generando) ...[
            const SizedBox(height: 12),
            Row(
              key: ValueKey(_k('cartel-error')),
              children: [
                Icon(Icons.error_outline, color: colors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _textoError(_error),
                    style: TextStyle(color: colors.error),
                  ),
                ),
                TextButton(
                  key: ValueKey(_k('cartel-reintentar')),
                  onPressed: _generar,
                  child: Text(t.retry),
                ),
              ],
            ),
          ],
          if (_generando || _png != null) ...[
            const SizedBox(height: 16),
            _construirImagen(),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                key: _claveCompartir,
                child: FilledButton.tonalIcon(
                  key: ValueKey(_k('cartel-compartir')),
                  onPressed: _png == null || _desactualizada || _generando
                      ? null
                      : () => _compartir(partido),
                  icon: const Icon(Icons.ios_share),
                  label: Text(t.socialImagesShare),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey(_k('cartel-copiar')),
                  onPressed: () => _copiar(partido),
                  icon: const Icon(Icons.copy),
                  label: Text(t.socialImagesCopyText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  /// La imagen en grande, con la proporción del formato con que se generó (o el que se pide, mientras carga).
  Widget _construirImagen() {
    final t = _t;
    final colors = Theme.of(context).colorScheme;
    final formato = (_generadas ?? _opciones).formato;
    final proporcion =
        (_generando && _png == null ? _opciones : _generadas ?? _opciones)
            .formato
            .proporcion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_desactualizada && !_generando)
          Container(
            key: ValueKey(_k('cartel-desactualizada')),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.socialImagesPosterOutdated,
                    style: TextStyle(color: colors.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              key: ValueKey(_k('cartel-imagen-${formato.api}')),
              aspectRatio: proporcion,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _generando
                    ? Container(
                        key: ValueKey(_k('cartel-cargando')),
                        color: colors.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      )
                    : Opacity(
                        opacity: _desactualizada ? 0.45 : 1,
                        child: Image.memory(
                          _png!,
                          key: ValueKey(_k('cartel-png')),
                          fit: BoxFit.contain,
                          semanticLabel: _textoImagen(t),
                          gaplessPlayback: true,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// El partido del backend: escudos (el Mutxamel a la izquierda si juega en casa), rival, día y hora, campo y
/// competición.
class _TarjetaPartido extends StatelessWidget {
  final PartidoPrimerEquipoModel partido;

  /// Las claves de sus widgets (distintas en cada cartel).
  final String Function(String) k;

  const _TarjetaPartido({required this.partido, required this.k});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final mutxamel = Column(
      children: [
        const EscudoRival(esPropio: true, tamano: 64),
        const SizedBox(height: 4),
        const Text(
          'Mutxamel C.F.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
    final rival = Column(
      children: [
        EscudoRival(url: partido.escudoRivalUrl, tamano: 64),
        const SizedBox(height: 4),
        Text(
          nombreRivalVisible(partido.rival),
          key: ValueKey(k('cartel-rival')),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );

    final fecha = [
      if (partido.dia != null)
        '${fechaCortaImagenes(partido.dia!)}/${partido.dia!.year}',
      if (partido.hora != null) partido.hora!,
    ].join(' · ');

    final competicion = [
      if (partido.competicion != null) partido.competicion!,
      if (partido.jornada != null) t.weekendRound(partido.jornada!),
    ].join(' · ');

    Widget linea(IconData icono, String texto, String clave) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, key: ValueKey(clave))),
        ],
      ),
    );

    return Card(
      key: ValueKey(k('cartel-tarjeta-partido')),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: partido.local ? mutxamel : rival),
                const Padding(
                  padding: EdgeInsets.only(top: 20, left: 8, right: 8),
                  child: Text(
                    'VS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Expanded(child: partido.local ? rival : mutxamel),
              ],
            ),
            const SizedBox(height: 8),
            if (fecha.isNotEmpty)
              linea(Icons.event_outlined, fecha, 'cartel-fecha'),
            if (partido.campo != null)
              linea(Icons.place_outlined, partido.campo!, 'cartel-campo'),
            if (competicion.isNotEmpty)
              linea(
                Icons.emoji_events_outlined,
                competicion,
                'cartel-competicion',
              ),
          ],
        ),
      ),
    );
  }
}
