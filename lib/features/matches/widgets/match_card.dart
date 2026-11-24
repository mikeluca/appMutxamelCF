import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/escudo_rival.dart';
import '../../../core/utils/como_llegar.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../directo/widgets/cuenta_atras_bloques.dart';
import '../../../core/utils/evento_partido.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/pages/ficha_partido_page.dart';
import '../../ficha_partido/widgets/reloj_en_directo.dart';
import '../../directo/widgets/cuenta_atras_texto.dart';
import '../../directo/widgets/marcador_que_late.dart';
import '../models/match_model.dart';
import 'boton_anadir_calendario.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final bool mostrarPrimerEquipo;

  /// Solo para tests: la hora del móvil y el temporizador del reloj en directo.
  final DateTime Function()? ahora;
  final CrearTemporizador? crearTemporizador;

  /// Solo en Mis partidos: la convocatoria del usuario a este partido, para las notas del evento de calendario (hora y lugar de
  /// citacion y equipaje). Sin ella, el evento no lleva esas notas.
  final Future<NotasConvocatoria?> Function(MatchModel partido)?
  notasConvocatoria;

  const MatchCard({
    super.key,
    required this.match,
    this.mostrarPrimerEquipo = false,
    this.ahora,
    this.crearTemporizador,
    this.notasConvocatoria,
  });

  @override
  Widget build(BuildContext context) {
    if (match.estaDescansando) return _buildRestCard(context);
    if (match.enJuego) return _buildLiveMatchCard(context);
    if (match.estaJugado) return _buildPlayedMatchCard(context);
    if (match.pendienteResultado) return _buildPendingResultCard(context);

    return _buildUpcomingMatchCard(context);
  }

  /// El partido aun no se ha jugado, no esta cancelado y tiene dia: se puede anadir al calendario.
  bool get _sePuedeAnadirAlCalendario =>
      match.dia != null &&
      !match.cancelado &&
      !match.estaJugado &&
      !match.esPartidoPasado &&
      !match.estaDescansando;

  Widget _botonCalendario() {
    return BotonAnadirCalendario(
      construir: (t) async {
        final notas = await notasConvocatoria?.call(match);

        return EventoPartido.desdeMatch(match, t, convocatoria: notas);
      },
    );
  }

  /// La tarjeta del Primer Equipo de la portada abre la ficha del partido.
  bool get _abreFicha => mostrarPrimerEquipo && match.tieneFicha;

  /// Con ficha, el contenido de la tarjeta es pulsable (el efecto cae dentro de su Material) y lleva al pie
  /// "Ver partido" / "Seguir en directo"; el botón Cómo llegar sigue funcionando por su cuenta.
  Widget _tocable(BuildContext context, Widget contenido) {
    if (!_abreFicha) return contenido;

    final t = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: t.matchViewMatchAgainst(match.rivalVisible),
      child: InkWell(
        key: const ValueKey('abrir-ficha'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => FichaPartidoPage.abrir(context, match.id!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            contenido,
            const Divider(height: 1, thickness: 0.5),
            Padding(
              key: const ValueKey('pie-ficha'),
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    match.enJuego ? t.matchFollowLive : t.matchViewMatch,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIPO DE PARTIDO (Liga, Amistoso, Copa, Torneo)
  // ============================================================

  /// Borde de color según el tipo de partido. Null (sin tratamiento
  /// especial) si el tipo es desconocido/no informado.
  ShapeBorder? get _shapeTipo {
    final color = AppColors.colorTipoPartido(match.tipo);

    if (color == null) return null;

    return RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      side: BorderSide(color: color, width: 2),
    );
  }

  /// La etiqueta con el tipo de partido (Liga, Amistoso, Copa, Torneo): una píldora centrada justo encima de la fila del
  /// marcador, dentro de la tarjeta, para no depender solo del color del borde. Va en el flujo de la columna (no
  /// superpuesta), así que nunca tapa el botón Cómo llegar ni el botón de editar de Mis partidos. Null (sin hueco) si el
  /// tipo es desconocido/no informado.
  Widget? _etiquetaTipo() {
    final etiqueta = AppColors.etiquetaTipoPartido(match.tipo);
    final color = AppColors.colorTipoPartido(match.tipo);

    if (etiqueta == null || color == null) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Center(
        child: Container(
          key: const ValueKey('etiqueta-tipo-partido'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
    );
  }

  /// El relleno del cuerpo: con etiqueta se recorta el hueco de arriba (10 -> 4) para que la etiqueta quepa en él y la
  /// tarjeta apenas crezca.
  EdgeInsets get _relleno => AppColors.colorTipoPartido(match.tipo) == null
      ? _rellenoCuerpo
      : const EdgeInsets.fromLTRB(14, 4, 14, 8);
  // ============================================================
  // PRÓXIMO PARTIDO
  // ============================================================

  Widget _buildUpcomingMatchCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: _tocable(
        context,
        Column(
          children: [
            _buildHeader(
              mostrarPrimerEquipo ? t.matchUpcomingFirstTeam : t.matchUpcoming,
              color: AppColors.azul,
            ),

            Padding(
              padding: _relleno,
              child: Column(
                children: [
                  ?_etiquetaTipo(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeam(
                        context,
                        match.local ? match.equipo : match.rivalVisible,
                        isHomeTeam: match.local,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          t.matchVs,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dorado,
                          ),
                        ),
                      ),

                      _buildTeam(
                        context,
                        match.local ? match.rivalVisible : match.equipo,
                        isHomeTeam: !match.local,
                      ),
                    ],
                  ),

                  // La cuenta atrás de la tarjeta del Primer Equipo, en bloques (Días / Horas / Minutos / Segundos);
                  // en los últimos 30 minutos, "Calentando…" y "A punto de empezar". Sin hora, solo el día.
                  if (mostrarPrimerEquipo &&
                      CuentaAtrasTexto.aplica(match.dia, match.hora))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CuentaAtrasBloques(
                        dia: match.dia,
                        hora: match.hora,
                        ahora: ahora,
                        crearTemporizador: crearTemporizador,
                      ),
                    ),

                  const SizedBox(height: 10),

                  _buildMatchInformation(context),

                  if (_sePuedeAnadirAlCalendario) _botonCalendario(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PARTIDO EN JUEGO
  // ============================================================

  Widget _buildLiveMatchCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: _tocable(
        context,
        Column(
          children: [
            Container(
              key: const ValueKey('letrero-en-juego'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.red.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    t.matchLiveBanner,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: _relleno,
              child: Column(
                children: [
                  ?_etiquetaTipo(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeam(
                        context,
                        match.local ? match.equipo : match.rivalVisible,
                        isHomeTeam: match.local,
                      ),

                      _marcadorEnDirecto(context),

                      _buildTeam(
                        context,
                        match.local ? match.rivalVisible : match.equipo,
                        isHomeTeam: !match.local,
                      ),
                    ],
                  ),

                  // El reloj en directo (MM:ss con el punto rojo parpadeante y "1T" / "2T"); en el descanso, el texto
                  // de siempre.
                  if (match.reloj case final reloj? when !reloj.enDescanso)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: RelojEnDirecto(
                        reloj: reloj,
                        conParte: true,
                        ahora: ahora,
                        crearTemporizador: crearTemporizador,
                        estilo: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),

                  if (match.enDescanso)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        t.matchHalfTime,
                        key: const ValueKey('descanso'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  _buildMatchInformation(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// El marcador en directo; el número que sube late (ver [MarcadorQueLate]).
  Widget _marcadorEnDirecto(BuildContext context) {
    final estilo = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );

    if (match.golesFavor == null || match.golesContra == null) {
      return Text(
        '-',
        key: const ValueKey('marcador-en-directo'),
        style: estilo,
      );
    }

    return MarcadorQueLate(
      key: const ValueKey('marcador-en-directo'),
      partidoId: match.id,
      golesFavor: match.golesFavor,
      golesContra: match.golesContra,
      mutxamelEsLocal: match.local,
      estilo: estilo,
    );
  }

  // ============================================================
  // ÚLTIMO RESULTADO
  // ============================================================

  Widget _buildPlayedMatchCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: _tocable(
        context,
        Column(
          children: [
            _buildHeader(
              mostrarPrimerEquipo
                  ? t.matchLastResultFirstTeam
                  : t.matchLastResult,
              color: AppColors.azulOscuro,
            ),

            Padding(
              padding: _relleno,
              child: Column(
                children: [
                  ?_etiquetaTipo(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeam(
                        context,
                        match.local ? match.equipo : match.rivalVisible,
                        isHomeTeam: match.local,
                      ),

                      Text(
                        match.marcadorLocalVisitante ?? '-',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      _buildTeam(
                        context,
                        match.local ? match.rivalVisible : match.equipo,
                        isHomeTeam: !match.local,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Fecha, hora y campo
                  _buildMatchInformation(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // JUGADO, PENDIENTE DE RESULTADO
  // ============================================================

  Widget _buildPendingResultCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: _tocable(
        context,
        Column(
          children: [
            _buildHeader(
              mostrarPrimerEquipo
                  ? t.matchLastResultFirstTeam
                  : t.matchLastResult,
              color: AppColors.azulOscuro,
            ),

            Padding(
              padding: _relleno,
              child: Column(
                children: [
                  ?_etiquetaTipo(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeam(
                        context,
                        match.local ? match.equipo : match.rivalVisible,
                        isHomeTeam: match.local,
                      ),

                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            t.matchResultPending,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),

                      _buildTeam(
                        context,
                        match.local ? match.rivalVisible : match.equipo,
                        isHomeTeam: !match.local,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _buildMatchInformation(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIN PARTIDO
  // ============================================================

  Widget _buildRestCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    // El club usa 'DESCANSA' para señalar deliberadamente una jornada
    // de descanso. Si el rival llega vacío es que, sencillamente,
    // no hay ningún partido registrado para ese equipo.
    final descansaExplicitamente =
        match.rival.trim().toUpperCase() == 'DESCANSA';

    final textoCuerpo = match.descansa
        ? t.matchTeamRests
        : descansaExplicitamente
        ? t.matchNoMatchThisRound
        : t.matchTeamHasNoMatch;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _shapeTipo,
      child: _tocable(
        context,
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.dorado,
              child: Text(
                mostrarPrimerEquipo ? t.matchNoMatchFirstTeam : t.matchNoMatch,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ?_etiquetaTipo(),

                  if (match.descansa)
                    const Icon(
                      Icons.bedtime_outlined,
                      size: 70,
                      color: AppColors.azulOscuro,
                    )
                  else
                    Image.asset(
                      'assets/images/escudo.png',
                      width: 70,
                      height: 85,
                      fit: BoxFit.contain,
                    ),

                  const SizedBox(height: 10),

                  Text(
                    match.equipo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(textoCuerpo, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CABECERA
  // ============================================================

  /// El relleno del cuerpo de las tarjetas (compacto: la tarjeta de Inicio ocupa poco alto).
  static const EdgeInsets _rellenoCuerpo = EdgeInsets.fromLTRB(14, 10, 14, 8);

  Widget _buildHeader(String title, {required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: color,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ============================================================
  // EQUIPOS
  // ============================================================

  Widget _buildTeam(
    BuildContext context,
    String name, {
    required bool isHomeTeam,
  }) {
    // Hasta 105 de ancho, y menos si no cabe (iPhone pequeño o letra grande): sin desbordar.
    return Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 105),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isHomeTeam)
              Image.asset(
                'assets/images/escudo.png',
                width: 44,
                height: 54,
                fit: BoxFit.contain,
              )
            else
              // El rival: su escudo de la red, el nuestro si es un filial, o el genérico.
              SizedBox(
                height: 54,
                child: Center(
                  child: EscudoRival(
                    url: match.escudoRivalUrl,
                    esPropio: match.rivalEsPropio,
                    tamano: 44,
                  ),
                ),
              ),

            const SizedBox(height: 4),

            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMACIÓN DEL PARTIDO
  // ============================================================

  Widget _buildMatchInformation(BuildContext context) {
    // Fecha y hora en una sola línea ("Domingo 22/11/2026 · 17:30"). La fecha se calcula en el cliente a partir de
    // match.dia (para anteponer el nombre del día y respetar el idioma activo); diaFormateado queda como respaldo si
    // match.dia no viniera informado.
    final fechaHora = formatearFechaHoraEnUnaLinea(
      match.dia,
      match.hora,
      AppLocalizations.of(context),
      respaldoFecha: match.diaFormateado,
    );

    return Column(
      children: [
        if (fechaHora.isNotEmpty)
          _buildInfoRow(context, Icons.calendar_today_outlined, fechaHora),

        if (match.campo?.isNotEmpty == true)
          _buildInfoRow(
            context,
            Icons.location_on_outlined,
            match.campo!,
            trailing: BotonComoLlegar(lugar: match.campo, local: match.local),
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: AppColors.azul),

          const SizedBox(width: 7),

          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          ?trailing,
        ],
      ),
    );
  }
}
