import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/como_llegar.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/escudo_rival.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../convocatorias/model/equipacion_model.dart';
import '../../convocatorias/widgets/equipaje_widgets.dart';
import '../models/proximo_partido.dart';

const Color _verde = Color(0xFF16A34A);
const Color _ambar = Color(0xFFD97706);

/// "Tu próximo partido" de Inicio: una tarjeta por entrada (persona y equipo). Con más de una, un carrusel horizontal con
/// puntos debajo; cada tarjeta mide lo que mide su contenido (el carrusel, lo de la más alta). Sin entradas no pinta nada.
class ProximoPartidoSeccion extends StatefulWidget {
  final List<ProximoPartido> entradas;
  final void Function(ProximoPartido entrada) onTocar;

  const ProximoPartidoSeccion({
    super.key,
    required this.entradas,
    required this.onTocar,
  });

  @override
  State<ProximoPartidoSeccion> createState() => _ProximoPartidoSeccionState();
}

class _ProximoPartidoSeccionState extends State<ProximoPartidoSeccion> {
  final PageController _paginas = PageController();
  int _pagina = 0;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProximoPartidoSeccion anterior) {
    super.didUpdateWidget(anterior);

    // Si la lista se acorta al recargar, no se queda el punto en una página que ya no existe.
    if (_pagina >= widget.entradas.length) {
      _pagina = widget.entradas.isEmpty ? 0 : widget.entradas.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entradas = widget.entradas;

    if (entradas.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('proximo-partido-seccion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),

        Text(
          AppLocalizations.of(context).nextMatchTitle,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        if (entradas.length == 1)
          TarjetaProximoPartido(
            entrada: entradas.first,
            onTocar: () => widget.onTocar(entradas.first),
          )
        else ...[
          _carrusel(),

          const SizedBox(height: 10),

          _puntos(colors),
        ],
      ],
    );
  }

  /// Las tarjetas invisibles dan al carrusel la altura de la más alta (con letra grande también); el PageView va encima.
  Widget _carrusel() {
    return Stack(
      children: [
        for (final entrada in widget.entradas)
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: SizedBox(
              width: double.infinity,
              child: TarjetaProximoPartido(entrada: entrada, onTocar: null),
            ),
          ),

        Positioned.fill(
          child: PageView.builder(
            key: const ValueKey('proximo-partido-carrusel'),
            controller: _paginas,
            itemCount: widget.entradas.length,
            onPageChanged: (i) => setState(() => _pagina = i),
            itemBuilder: (context, i) => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: TarjetaProximoPartido(
                  key: ValueKey('proximo-partido-tarjeta-$i'),
                  entrada: widget.entradas[i],
                  onTocar: () => widget.onTocar(widget.entradas[i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _puntos(ColorScheme colors) {
    return Row(
      key: const ValueKey('proximo-partido-puntos'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.entradas.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _pagina ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _pagina
                  ? colors.primary
                  : colors.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// La tarjeta compacta de una entrada, con el mismo estilo que las de la pestaña Partidos: para quién, los escudos, la
/// fecha, el campo con Cómo llegar y, debajo, el estado de la convocatoria. Con [onTocar] null no es pulsable.
class TarjetaProximoPartido extends StatelessWidget {
  final ProximoPartido entrada;
  final VoidCallback? onTocar;

  const TarjetaProximoPartido({super.key, required this.entrada, this.onTocar});

  @override
  Widget build(BuildContext context) {
    final partido = entrada.partido;
    final color = partido == null
        ? null
        : AppColors.colorTipoPartido(partido.tipo);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: color == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              side: BorderSide(color: color, width: 2),
            ),
      child: InkWell(
        onTap: entrada.descansa ? null : onTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _paraQuien(context),

              const SizedBox(height: 10),

              if (entrada.descansa || partido == null)
                _descansa(context)
              else ...[
                _equipos(context),

                const SizedBox(height: 8),

                _fila(
                  context,
                  Icons.calendar_today_outlined,
                  formatearFechaHoraEnUnaLinea(
                    partido.dia,
                    partido.hora,
                    AppLocalizations.of(context),
                    respaldoFecha: partido.diaFormateado,
                  ),
                ),

                if (partido.campo?.isNotEmpty == true)
                  _fila(
                    context,
                    Icons.location_on_outlined,
                    partido.campo!,
                    trailing: BotonComoLlegar(
                      lugar: partido.campo,
                      local: partido.local,
                      enCasaElsOms: partido.enCasaElsOms,
                    ),
                  ),

                if (entrada.convocatoria != null) ...[
                  const Divider(height: 14, thickness: 0.5),

                  ..._estado(context, entrada.convocatoria!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ cabecera y equipos

  Widget _paraQuien(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final texto = entrada.esEntrenador
        ? t.nextMatchCoachTeam(entrada.nombreEquipo)
        : '${entrada.nombreJugador ?? ''} · ${entrada.nombreEquipo}';

    return Row(
      children: [
        Icon(
          entrada.esEntrenador ? Icons.sports_outlined : Icons.person_outline,
          size: 18,
          color: AppColors.dorado,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            texto,
            key: const ValueKey('proximo-partido-para-quien'),
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _equipos(BuildContext context) {
    final partido = entrada.partido!;

    return Row(
      children: [
        Expanded(
          child: _equipoConEscudo(
            context,
            partido.equipo.isEmpty ? entrada.nombreEquipo : partido.equipo,
            esRival: false,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            AppLocalizations.of(context).matchVs,
            style: const TextStyle(
              color: AppColors.dorado,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        Expanded(
          child: _equipoConEscudo(context, partido.rivalVisible, esRival: true),
        ),
      ],
    );
  }

  Widget _equipoConEscudo(
    BuildContext context,
    String nombre, {
    required bool esRival,
  }) {
    final partido = entrada.partido!;
    final colors = Theme.of(context).colorScheme;

    final escudo = EscudoRival(
      url: esRival ? partido.escudoRivalUrl : null,
      esPropio: !esRival || partido.rivalEsPropio,
      tamano: 28,
      colorGenerico: colors.outline,
    );
    final texto = Flexible(
      child: Text(
        nombre,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // El Mutxamel a su lado (local a la izquierda, visitante a la derecha), como en las listas.
    final izquierda = esRival ? !partido.local : partido.local;
    final hijos = [escudo, const SizedBox(width: 8), texto];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: izquierda ? hijos : hijos.reversed.toList(),
    );
  }

  Widget _fila(
    BuildContext context,
    IconData icono,
    String texto, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.azul),

          const SizedBox(width: 8),

          Expanded(child: Text(texto)),

          ?trailing,
        ],
      ),
    );
  }

  Widget _descansa(BuildContext context) {
    return Row(
      key: const ValueKey('proximo-partido-descansa'),
      children: [
        const Icon(
          Icons.bedtime_outlined,
          size: 22,
          color: AppColors.azulOscuro,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            AppLocalizations.of(context).matchesRestsThisRound,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ estado de la convocatoria

  List<Widget> _estado(BuildContext context, ConvocatoriaProximoPartido c) {
    final t = AppLocalizations.of(context);

    switch (c.estado) {
      case ConvocatoriaProximoPartido.convocado:
        return _lineasConCitacion(context, c, t.nextMatchCalledUp);
      case ConvocatoriaProximoPartido.invitado:
        return _lineasConCitacion(
          context,
          c,
          t.nextMatchInvitedWith(c.equipoInvita ?? entrada.partido!.equipo),
        );
      case ConvocatoriaProximoPartido.noConvocado:
        return [
          _linea(
            context,
            Icons.remove_circle_outline,
            _ambar,
            Text(t.nextMatchNotCalledUp),
          ),
        ];
      case ConvocatoriaProximoPartido.ausenciaJustificada:
        return [
          _linea(
            context,
            Icons.event_busy_outlined,
            _ambar,
            Text(t.nextMatchAbsenceJustified),
          ),
        ];
      case ConvocatoriaProximoPartido.publicada:
        return [
          _linea(
            context,
            Icons.check_circle_outline,
            _verde,
            Text(t.nextMatchCallupPublished(c.numeroConvocados ?? 0)),
          ),
        ];
      default:
        return [
          _linea(
            context,
            entrada.esEntrenador
                ? Icons.edit_note_outlined
                : Icons.hourglass_empty,
            entrada.esEntrenador
                ? _ambar
                : Theme.of(context).colorScheme.onSurfaceVariant,
            Text(
              entrada.esEntrenador
                  ? t.nextMatchCallupUnpublished
                  : t.nextMatchNoCallup,
            ),
          ),
        ];
    }
  }

  /// "Convocado · Citación 9:15 en Camp Nou Los Olmos · Equipaje Primera" (con la muestra de color) y, si hay mochila,
  /// otra línea.
  List<Widget> _lineasConCitacion(
    BuildContext context,
    ConvocatoriaProximoPartido c,
    String principal,
  ) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final partes = <InlineSpan>[
      TextSpan(
        text: principal,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ];

    void anadir(InlineSpan parte) {
      partes.add(const TextSpan(text: ' · '));
      partes.add(parte);
    }

    final hora = c.horaCitacion;

    if (hora != null) {
      anadir(
        TextSpan(
          text: c.lugarCitacion == null
              ? t.nextMatchCitationNoPlace(hora)
              : t.nextMatchCitation(hora, c.lugarCitacion!),
        ),
      );
    }

    final equipaje = c.equipaje;

    if (equipaje != null) {
      anadir(_equipaje(t.nextMatchKit(equipaje.nombre), equipaje));
    }

    final mochila = c.equipajeMochila;

    return [
      _linea(
        context,
        Icons.check_circle_outline,
        _verde,
        Text.rich(TextSpan(children: partes)),
      ),

      if (mochila != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _linea(
            context,
            Icons.backpack_outlined,
            colors.onSurfaceVariant,
            Text.rich(_equipaje(t.nextMatchBackpack(mochila.nombre), mochila)),
          ),
        ),
    ];
  }

  /// El texto del equipaje y, a continuación, su muestra de color.
  InlineSpan _equipaje(String texto, EquipacionModel equipacion) {
    return TextSpan(
      children: [
        TextSpan(text: '$texto '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: MuestraColorEquipaje(equipacion: equipacion, tamano: 14),
        ),
      ],
    );
  }

  Widget _linea(
    BuildContext context,
    IconData icono,
    Color color,
    Widget texto,
  ) {
    return Row(
      key: const ValueKey('proximo-partido-estado'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icono, size: 18, color: color),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 13.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            child: texto,
          ),
        ),
      ],
    );
  }
}
