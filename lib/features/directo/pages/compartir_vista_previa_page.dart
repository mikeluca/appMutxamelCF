import 'package:material_ui/material_ui.dart';

import '../../../core/utils/origen_compartir.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/models/ficha_partido_model.dart';
import '../widgets/compartir_partido.dart';

/// Pantalla completa con la imagen de compartir en vivo y sus controles: formato (publicación o historia), estilo
/// (azul club, oscuro o claro) y los interruptores de goleadores, racha y QR. El botón "Compartir" genera el PNG y
/// abre el menú de compartir del sistema.
class CompartirVistaPreviaPage extends StatefulWidget {
  final FichaPartido ficha;

  /// La hora con la que se calcula el reloj de un partido en juego; los tests la fijan.
  final DateTime Function() ahora;

  const CompartirVistaPreviaPage({
    super.key,
    required this.ficha,
    this.ahora = DateTime.now,
  });

  @override
  State<CompartirVistaPreviaPage> createState() =>
      _CompartirVistaPreviaPageState();
}

class _CompartirVistaPreviaPageState extends State<CompartirVistaPreviaPage> {
  OpcionesCompartir _opciones = const OpcionesCompartir();
  bool _enviando = false;

  /// El botón Compartir: el menú de compartir (iPad) se ancla a él.
  final GlobalKey _claveCompartir = GlobalKey();

  Future<void> _compartir(AppLocalizations t) async {
    final mensajes = ScaffoldMessenger.of(context);
    final origen = origenDeCompartir(_claveCompartir.currentContext ?? context);

    setState(() => _enviando = true);

    try {
      // Con el reloj del momento de generarla.
      final datos = DatosCompartir.desdeFicha(
        widget.ficha,
        t,
        ahora: widget.ahora(),
      );

      await CompartirPartido.compartir(
        context,
        datos,
        opciones: _opciones,
        origen: origen,
      );
    } catch (e) {
      debugPrint('NO SE PUDO COMPARTIR EL PARTIDO: $e');

      mensajes.showSnackBar(SnackBar(content: Text(t.shareError)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _interruptor(
    String clave,
    String texto,
    bool valor,
    bool disponible,
    ValueChanged<bool> alCambiar,
  ) {
    if (!disponible) return const SizedBox.shrink();

    return FilterChip(
      key: ValueKey(clave),
      label: Text(texto),
      selected: valor,
      onSelected: alCambiar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final datos = DatosCompartir.desdeFicha(
      widget.ficha,
      t,
      ahora: widget.ahora(),
    );
    final alturaPantalla = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: AppBar(title: Text(t.shareTooltip)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Center(
                  child: FittedBox(
                    key: const ValueKey('compartir-vista-previa'),
                    fit: BoxFit.contain,
                    child: TarjetaCompartir(datos: datos, opciones: _opciones),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: alturaPantalla * 0.42),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titulo(t.shareFormatLabel),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<FormatoCompartir>(
                        key: const ValueKey('compartir-formato'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: FormatoCompartir.publicacion,
                            label: Text(t.shareFormatPost),
                          ),
                          ButtonSegment(
                            value: FormatoCompartir.historia,
                            label: Text(t.shareFormatStory),
                          ),
                        ],
                        selected: {_opciones.formato},
                        onSelectionChanged: (s) => setState(
                          () =>
                              _opciones = _opciones.copiaCon(formato: s.first),
                        ),
                      ),
                    ),
                    _titulo(t.shareStyleLabel),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<EstiloCompartir>(
                        key: const ValueKey('compartir-estilo'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: EstiloCompartir.club,
                            label: Text(t.shareStyleClub),
                          ),
                          ButtonSegment(
                            value: EstiloCompartir.oscuro,
                            label: Text(t.shareStyleDark),
                          ),
                          ButtonSegment(
                            value: EstiloCompartir.claro,
                            label: Text(t.shareStyleLight),
                          ),
                        ],
                        selected: {_opciones.estilo},
                        onSelectionChanged: (s) => setState(
                          () => _opciones = _opciones.copiaCon(estilo: s.first),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _interruptor(
                          'compartir-opcion-goleadores',
                          t.shareToggleScorers,
                          _opciones.goleadores,
                          datos.tieneGoleadores,
                          (v) => setState(
                            () => _opciones = _opciones.copiaCon(goleadores: v),
                          ),
                        ),
                        _interruptor(
                          'compartir-opcion-racha',
                          t.shareToggleForm,
                          _opciones.racha,
                          datos.tieneRacha,
                          (v) => setState(
                            () => _opciones = _opciones.copiaCon(racha: v),
                          ),
                        ),
                        _interruptor(
                          'compartir-opcion-qr',
                          t.shareToggleQr,
                          _opciones.qr,
                          true,
                          (v) => setState(
                            () => _opciones = _opciones.copiaCon(qr: v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                key: _claveCompartir,
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('compartir-boton'),
                  onPressed: _enviando ? null : () => _compartir(t),
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(t.shareButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
