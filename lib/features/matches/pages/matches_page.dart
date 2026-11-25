import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/escudo_rival.dart';
import '../../../core/utils/como_llegar.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/pages/ficha_partido_page.dart';
import '../models/match_model.dart';
import '../widgets/fila_dos_botones.dart';
import '../widgets/boton_anadir_calendario.dart';
import '../../../core/utils/evento_partido.dart';
import '../../teams/pages/team_standings_page.dart';
import '../services/match_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final MatchService _matchService = MatchService();

  late Future<List<MatchModel>> _matchesFuture;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    _matchesFuture = _matchService.obtenerResultados();
  }

  Future<void> _recargar() async {
    setState(() {
      _matchesFuture = _matchService.obtenerResultados();
    });

    await _matchesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.navMatches)),
      body: FutureBuilder<List<MatchModel>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          final partidos = snapshot.data ?? [];

          if (partidos.isEmpty) {
            return Center(child: Text(_t.matchesNoMatchesAvailable));
          }

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Text(
                  _t.matchesCalendarTitle,
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _t.matchesCalendarSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 20),

                // La lista ya llega del backend agrupada por
                // categoría y ordenada por fecha descendente dentro
                // de cada una: aquí solo detectamos los cambios de
                // categoría para insertar los encabezados de sección,
                // sin reordenar nada en el cliente.
                ..._construirListaPartidos(partidos),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _construirListaPartidos(List<MatchModel> partidos) {
    final widgets = <Widget>[];
    String? categoriaAnterior;

    for (final partido in partidos) {
      if (partido.categoria != categoriaAnterior) {
        if (categoriaAnterior != null) {
          widgets.add(const SizedBox(height: 8));
        }

        widgets.add(_construirEncabezadoCategoria(partido.categoria));
        categoriaAnterior = partido.categoria;
      }

      widgets.add(PartidoListaCard(partido: partido));
    }

    return widgets;
  }

  Widget _construirEncabezadoCategoria(String categoria) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        categoria.trim().isEmpty ? _t.matchesNoCategory : categoria,
        style: TextStyle(
          color: _colors.onSurfaceVariant,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: _colors.primary),

            const SizedBox(height: 16),

            Text(_t.matchesLoadError, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _matchesFuture = _matchService.obtenerResultados();
                });
              },
              child: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de un partido en la pestaña Partidos. Pública solo para poder
/// probarla en tests de widget.
class PartidoListaCard extends StatelessWidget {
  final MatchModel partido;

  const PartidoListaCard({super.key, required this.partido});

  ColorScheme _colors(BuildContext context) => Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    final Widget tarjeta;

    if (partido.estaDescansando) {
      tarjeta = _buildDescansoCard(context);
    } else if (partido.estaJugado) {
      tarjeta = _buildResultadoCard(context);
    } else if (partido.pendienteResultado) {
      tarjeta = _buildPendienteCard(context);
    } else {
      tarjeta = _buildProximoCard(context);
    }

    return _envolverConEtiquetaTipo(context, tarjeta);
  }

  /// El relleno de la tarjeta (compacto: ocupa poco alto en la lista).
  static const EdgeInsets _relleno = EdgeInsets.fromLTRB(14, 12, 14, 8);

  /// El cuerpo de la tarjeta. Los partidos del Primer Equipo con ficha son pulsables (el efecto cae dentro de la
  /// tarjeta) y llevan un chevron al final de la cabecera; los demás equipos, como siempre.
  Widget _cuerpo(BuildContext context, {required Widget child}) {
    if (!partido.tieneFicha) {
      return Padding(padding: _relleno, child: child);
    }

    return Semantics(
      button: true,
      label: AppLocalizations.of(
        context,
      ).matchViewMatchAgainst(partido.rivalVisible),
      child: InkWell(
        key: const ValueKey('abrir-ficha'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => FichaPartidoPage.abrir(context, partido.id!),
        // El mismo relleno que las demás tarjetas (el contenido mide lo mismo); el chevron va en la cabecera.
        child: Padding(padding: _relleno, child: child),
      ),
    );
  }

  // ============================================================
  // TIPO DE PARTIDO (Liga, Amistoso, Copa, Torneo)
  // ============================================================

  /// Borde de color según el tipo de partido. Null (sin tratamiento
  /// especial) si el tipo es desconocido/no informado.
  ShapeBorder? get _shapeTipo {
    final color = AppColors.colorTipoPartido(partido.tipo);

    if (color == null) return null;

    return RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      side: BorderSide(color: color, width: 2),
    );
  }

  /// Superpone una pequeña etiqueta con el tipo de partido en la
  /// esquina de la tarjeta, para no depender solo del color del
  /// borde. No se muestra si el tipo es desconocido/no informado.
  Widget _envolverConEtiquetaTipo(BuildContext context, Widget tarjeta) {
    final etiqueta = AppColors.etiquetaTipoPartido(partido.tipo);
    final color = AppColors.colorTipoPartido(partido.tipo);

    if (etiqueta == null || color == null) {
      return tarjeta;
    }

    return Stack(
      children: [
        tarjeta,
        Positioned(
          top: 8,
          // Con ficha, el chevron ocupa el borde derecho de la cabecera: la etiqueta se pone a su izquierda.
          right: partido.tieneFicha ? 36 : 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProximoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: _shapeTipo,
      child: _cuerpo(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              AppLocalizations.of(context).matchUpcoming,
              Icons.sports_soccer,
            ),

            const SizedBox(height: 10),

            _buildEquipos(context),

            const SizedBox(height: 8),

            // Fecha y hora en una sola línea: "Domingo 22/11/2026 · 17:30".
            if (partido.dia != null ||
                (partido.hora != null && partido.hora!.isNotEmpty))
              _buildInfoRow(
                context,
                Icons.calendar_today_outlined,
                formatearFechaHoraEnUnaLinea(
                  partido.dia,
                  partido.hora,
                  AppLocalizations.of(context),
                ),
              ),

            if (partido.campo != null && partido.campo!.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.location_on_outlined,
                partido.campo!,
                trailing: BotonComoLlegar(
                  lugar: partido.campo,
                  local: partido.local,
                  enCasaElsOms: partido.enCasaElsOms,
                ),
              ),

            ..._filaAcciones(context),
          ],
        ),
      ),
    );
  }

  static const EdgeInsets _rellenoBotonFila = EdgeInsets.symmetric(
    horizontal: 8,
  );

  /// El pie de la tarjeta de un partido por jugar: "Añadir a mi calendario" a la izquierda y "Ver clasificación" a la
  /// derecha en la misma fila. Si no caben (pantalla pequeña o letra grande) bajan uno debajo del otro, sin cortarse.
  /// Sin clasificación, el del calendario queda solo en la fila.
  List<Widget> _filaAcciones(BuildContext context) {
    final calendario = partido.dia != null && !partido.cancelado
        ? BotonAnadirCalendario(
            padding: _rellenoBotonFila,
            construir: (t) async => EventoPartido.desdeMatch(partido, t),
          )
        : null;
    final clasificacion = _botonClasificacionWidget(
      context,
      igualAlCalendario: true,
    );

    if (calendario == null) return _botonClasificacion(context);
    if (clasificacion == null) return [calendario];

    return [
      FilaDosBotones(
        key: const ValueKey('fila-calendario-clasificacion'),
        izquierda: calendario,
        derecha: clasificacion,
      ),
    ];
  }

  /// "Ver clasificación" al pie de la tarjeta, alineado a la derecha. Solo
  /// si el partido trae el equipo. No afecta a lo que haga la propia tarjeta.
  List<Widget> _botonClasificacion(BuildContext context) {
    final boton = _botonClasificacionWidget(context);

    if (boton == null) return const [];

    return [Align(alignment: Alignment.centerRight, child: boton)];
  }

  Widget? _botonClasificacionWidget(
    BuildContext context, {
    bool igualAlCalendario = false,
  }) {
    final equipoId = partido.equipoId;

    if (equipoId == null) return null;

    return TextButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TeamStandingsPage(
            equipoId: equipoId,
            nombreEquipo: partido.equipo,
          ),
        ),
      ),
      icon: Icon(
        Icons.leaderboard_outlined,
        size: igualAlCalendario ? 18 : null,
      ),
      style: igualAlCalendario
          ? TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: _rellenoBotonFila,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      label: Text(AppLocalizations.of(context).viewStandings),
    );
  }

  /// El nombre de un equipo con su escudo pequeño delante: el del club rival (o el nuestro si el rival es un filial y
  /// para el Mutxamel) o el genérico. Lleva el escudo pequeño: es una lista.
  Widget _equipoConEscudo(
    BuildContext context,
    String nombre, {
    required bool esRival,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EscudoRival(
          url: esRival ? partido.escudoRivalUrl : null,
          esPropio: !esRival || partido.rivalEsPropio,
          tamano: 28,
          colorGenerico: _colors(context).outline,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            nombre,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _colors(context).onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultadoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: _shapeTipo,
      child: _cuerpo(
        context,
        child: Column(
          children: [
            _buildHeader(
              context,
              AppLocalizations.of(context).matchesResult,
              Icons.sports_soccer,
            ),

            const SizedBox(height: 10),

            _equipoConEscudo(context, partido.equipo, esRival: false),

            const SizedBox(height: 4),

            Text(
              partido.resultado ?? '',
              style: const TextStyle(
                color: AppColors.azul,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            _equipoConEscudo(context, partido.rivalVisible, esRival: true),

            if (partido.dia != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatearFecha(context, partido.dia!),
                style: TextStyle(color: _colors(context).onSurfaceVariant),
              ),
            ],

            ..._botonClasificacion(context),
          ],
        ),
      ),
    );
  }

  /// Partido ya jugado al que todavía no se le ha puesto el resultado: mismo
  /// diseño que el de resultado, con los equipos en orden local | visitante
  /// y "Pendiente de resultado" en gris en lugar del marcador.
  Widget _buildPendienteCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: _shapeTipo,
      child: _cuerpo(
        context,
        child: Column(
          children: [
            _buildHeader(context, t.matchesResult, Icons.sports_soccer),

            const SizedBox(height: 10),

            _equipoConEscudo(
              context,
              partido.local ? partido.equipo : partido.rivalVisible,
              esRival: !partido.local,
            ),

            const SizedBox(height: 4),

            Text(
              t.matchResultPending,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _colors(context).onSurfaceVariant,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            _equipoConEscudo(
              context,
              partido.local ? partido.rivalVisible : partido.equipo,
              esRival: partido.local,
            ),

            if (partido.dia != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatearFecha(context, partido.dia!),
                style: TextStyle(color: _colors(context).onSurfaceVariant),
              ),
            ],

            ..._botonClasificacion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDescansoCard(BuildContext context) {
    // El club usa 'DESCANSA' para señalar deliberadamente una jornada
    // de descanso. Si el rival llega vacío es que, sencillamente,
    // no hay ningún partido registrado para ese equipo.
    final descansaExplicitamente =
        partido.rival.trim().toUpperCase() == 'DESCANSA';

    final t = AppLocalizations.of(context);

    final texto = partido.descansa
        ? t.matchTeamRests
        : descansaExplicitamente
        ? t.matchesRestsThisRound
        : t.matchTeamHasNoMatch;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: _shapeTipo,
      child: _cuerpo(
        context,
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  partido.descansa
                      ? Icons.bedtime_outlined
                      : Icons.free_breakfast_outlined,
                  color: AppColors.azulOscuro,
                  size: 32,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partido.equipo,
                        style: TextStyle(
                          color: _colors(context).onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        texto,
                        style: TextStyle(
                          color: _colors(context).onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            ..._botonClasificacion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String texto, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: AppColors.dorado),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _colors(context).onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),

        // El partido tiene ficha: el chevron va pegado a la derecha, alineado con el texto de la cabecera.
        if (partido.tieneFicha) ...[
          Icon(
            Icons.chevron_right,
            key: const ValueKey('chevron-ficha'),
            color: _colors(context).primary,
          ),
        ],
      ],
    );
  }

  Widget _buildEquipos(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _equipoConEscudo(context, partido.equipo, esRival: false),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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

  Widget _buildInfoRow(
    BuildContext context,
    IconData icono,
    String texto, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
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

  String _formatearFecha(BuildContext context, DateTime fecha) =>
      formatearFechaConDiaSemana(fecha, AppLocalizations.of(context));
}
