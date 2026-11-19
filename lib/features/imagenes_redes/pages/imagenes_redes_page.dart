import 'package:material_ui/material_ui.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/imagenes_redes_model.dart';
import '../models/partido_primer_equipo_model.dart';
import '../services/imagenes_redes_service.dart';
import '../utils/fin_de_semana_imagenes.dart';
import '../widgets/pestana_partido_primer_equipo.dart';
import '../widgets/selector_fin_de_semana.dart';
import '../widgets/seccion_imagenes_redes.dart';

/// "Imágenes para redes" (Directo y RRSS, solo RETRANSMISION y ADMIN_APP): Previa, Resultados y Partido Primer Equipo.
/// Partido Filial está preparado pero oculto ([mostrarCartelFilial]).
class ImagenesRedesPage extends StatefulWidget {
  final ImagenesRedesService? servicio;

  /// La pestaña con la que se abre ([tipoImagenPrevia], [tipoImagenResultados] o [tipoImagenPartidoPrimerEquipo]); sin
  /// ella, Previa (o Resultados si [desde] es de un fin de semana que ya ha terminado).
  final String? tipoInicial;

  /// El viernes del fin de semana del aviso: con él se abre la pestaña de [tipoInicial].
  final DateTime? desde;

  /// El día de hoy; los tests lo fijan.
  final DateTime Function() ahora;

  const ImagenesRedesPage({
    super.key,
    this.servicio,
    this.tipoInicial,
    this.desde,
    this.ahora = DateTime.now,
  });

  @override
  State<ImagenesRedesPage> createState() => _ImagenesRedesPageState();
}

class _ImagenesRedesPageState extends State<ImagenesRedesPage>
    with SingleTickerProviderStateMixin {
  late final ImagenesRedesService _servicio =
      widget.servicio ?? ImagenesRedesService();

  late final TabController _controlador;
  late final String _tipoAbierto;
  bool _denegado = false;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    _tipoAbierto = _tipoDeApertura();
    _controlador = TabController(
      length: mostrarCartelFilial ? 4 : 3,
      vsync: this,
      initialIndex: _indiceDe(_tipoAbierto),
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  String _tipoDeApertura() {
    final tipo = widget.tipoInicial;

    if (tipo == tipoImagenPrevia ||
        tipo == tipoImagenResultados ||
        tipo == tipoImagenPartidoPrimerEquipo) {
      return tipo!;
    }

    // Sin pestaña (un aviso antiguo de la bandeja): la de los resultados si el fin de semana ya terminó.
    final desde = widget.desde;

    if (desde != null && finDeSemanaTerminado(desde, widget.ahora())) {
      return tipoImagenResultados;
    }

    return tipoImagenPrevia;
  }

  static int _indiceDe(String tipo) => switch (tipo) {
    tipoImagenResultados => 1,
    tipoImagenPartidoPrimerEquipo => 2,
    _ => 0,
  };

  /// El servidor dice 403: la cuenta ya no tiene el rol. Se avisa y se vuelve al menú, una sola vez.
  void _alDenegar() {
    if (_denegado) return;

    _denegado = true;

    final mensajero = ScaffoldMessenger.of(context);
    final texto = _t.socialImagesNoPermissionBack;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(texto)));

      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: t.socialImagesTitle),
        bottom: TabBar(
          key: const ValueKey('imagenes-redes-pestanas'),
          controller: _controlador,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              key: const ValueKey('pestana-previa'),
              text: t.socialImagesPreview,
            ),
            Tab(
              key: const ValueKey('pestana-resultados'),
              text: t.socialImagesResults,
            ),
            Tab(
              key: const ValueKey('pestana-primer-equipo'),
              text: t.socialImagesTabFirstTeam,
            ),
            if (mostrarCartelFilial)
              Tab(
                key: const ValueKey('pestana-filial'),
                text: t.socialImagesTabReserve,
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controlador,
        children: [
          _PestanaFinDeSemana(
            tipo: tipoImagenPrevia,
            servicio: _servicio,
            ahora: widget.ahora,
            viernesInicial: _tipoAbierto == tipoImagenPrevia
                ? widget.desde
                : null,
            alDenegar: _alDenegar,
          ),
          _PestanaFinDeSemana(
            tipo: tipoImagenResultados,
            servicio: _servicio,
            ahora: widget.ahora,
            viernesInicial: _tipoAbierto == tipoImagenResultados
                ? widget.desde
                : null,
            alDenegar: _alDenegar,
          ),
          PestanaPartidoPrimerEquipo(
            servicio: _servicio,
            alDenegar: _alDenegar,
          ),
          // Partido Filial: preparado, sin backend todavía.
          if (mostrarCartelFilial) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Previa o Resultados: el selector de fin de semana con flechas y las imágenes de ese fin de semana.
class _PestanaFinDeSemana extends StatefulWidget {
  final String tipo;
  final ImagenesRedesService servicio;
  final DateTime Function() ahora;

  /// El viernes del aviso; sin él, el de por defecto de la pestaña.
  final DateTime? viernesInicial;
  final VoidCallback alDenegar;

  const _PestanaFinDeSemana({
    required this.tipo,
    required this.servicio,
    required this.ahora,
    required this.viernesInicial,
    required this.alDenegar,
  });

  @override
  State<_PestanaFinDeSemana> createState() => _PestanaFinDeSemanaState();
}

class _PestanaFinDeSemanaState extends State<_PestanaFinDeSemana>
    with AutomaticKeepAliveClientMixin {
  late DateTime _viernes = _inicial();

  @override
  bool get wantKeepAlive => true;

  DateTime _inicial() {
    final aviso = widget.viernesInicial;

    if (aviso != null) return viernesReciente(aviso);

    return widget.tipo == tipoImagenResultados
        ? viernesPorDefectoResultados(widget.ahora())
        : viernesPorDefectoPrevia(widget.ahora());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SelectorFinDeSemana(
          viernes: _viernes,
          alCambiar: (v) => setState(() => _viernes = v),
        ),
        SeccionImagenesRedes(
          // Otro fin de semana, otra sección (vuelve a pedir sus imágenes).
          key: ValueKey('imagenes-${widget.tipo}-$_viernes'),
          servicio: widget.servicio,
          viernes: _viernes,
          tipo: widget.tipo,
          alDenegar: widget.alDenegar,
        ),
      ],
    );
  }
}
