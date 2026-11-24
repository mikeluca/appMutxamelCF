import 'package:material_ui/material_ui.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/services/auth_manager.dart';
import '../models/juego_modelos.dart';
import '../services/juego_service.dart';

/// El ranking de Mutxigol: una pestaña por juego, "Esta semana" / "Histórico" y los 50 mejores (posición, alias y
/// puntos). Se ve sin sesión. Con sesión, tu fila sale resaltada y, si estás fuera del top 50, tu posición al final.
class RankingJuegoPage extends StatefulWidget {
  const RankingJuegoPage({
    super.key,
    this.juegoInicial = Juego.penaltis,
    this.servicio = const JuegoService(),
    this.conSesion,
    this.perfil,
  });

  final Juego juegoInicial;
  final JuegoService servicio;

  /// Solo para tests: si hay sesión (por defecto, la de la app).
  final bool? conSesion;

  /// El perfil del juego si quien lo abre ya lo tiene (si no, se pide con sesión).
  final PerfilJuego? perfil;

  @override
  State<RankingJuegoPage> createState() => _RankingJuegoPageState();
}

class _RankingJuegoPageState extends State<RankingJuegoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(
    length: Juego.values.length,
    vsync: this,
    initialIndex: widget.juegoInicial.index,
  );

  PeriodoRanking _periodo = PeriodoRanking.semana;

  final Map<(Juego, PeriodoRanking), Future<List<FilaRanking>>> _cargas = {};

  PerfilJuego? _perfil;

  /// Sube al reintentar: cada intento es una carga nueva (otra clave en el FutureBuilder).
  int _intento = 0;

  bool get _conSesion => widget.conSesion ?? AuthManager.estaAutenticado;

  @override
  void initState() {
    super.initState();

    _perfil = widget.perfil;

    if (_perfil == null && _conSesion) _cargarPerfil();
  }

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await widget.servicio.perfil();

      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Sin perfil el ranking se ve igual, solo que sin tu fila.
    }
  }

  Future<List<FilaRanking>> _filas(Juego juego) => _cargas.putIfAbsent(
    (juego, _periodo),
    () => widget.servicio.ranking(juego, _periodo),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    String nombre(Juego j) => switch (j) {
      Juego.penaltis => t.gamePenaltiesShort,
      Juego.toques => t.gameTouchesShort,
      Juego.atrapa => t.gameCatchShort,
    };

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: t.gameRankingTitle),
        bottom: TabBar(
          controller: _pestanas,
          tabs: [for (final j in Juego.values) Tab(text: nombre(j))],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<PeriodoRanking>(
              key: const ValueKey('selector-periodo'),
              segments: [
                ButtonSegment(
                  value: PeriodoRanking.semana,
                  label: Text(t.gameThisWeek),
                ),
                ButtonSegment(
                  value: PeriodoRanking.historico,
                  label: Text(t.gameAllTime),
                ),
              ],
              selected: {_periodo},
              onSelectionChanged: (valor) =>
                  setState(() => _periodo = valor.first),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _pestanas,
              children: [
                // Perezoso: solo se pide el ranking de la pestaña que se mira.
                for (final juego in Juego.values)
                  Builder(builder: (_) => _listaDe(juego)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaDe(Juego juego) {
    final t = AppLocalizations.of(context);

    return FutureBuilder<List<FilaRanking>>(
      key: ValueKey('ranking-${juego.codigo}-${_periodo.codigo}-$_intento'),
      future: _filas(juego),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mensajeDeError(t, snapshot.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _cargas.remove((juego, _periodo));
                      _intento++;
                    }),
                    child: Text(t.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final filas = snapshot.data ?? const [];
        final alias = _perfil?.alias?.trim().toLowerCase();
        final tuMarca = _perfil?.marcas(juego).dePeriodo(_periodo);

        final estaEnElTop =
            alias != null &&
            filas.any((f) => f.alias.trim().toLowerCase() == alias);

        // Fuera del top 50: su posición al final (no si el perfil está oculto: no tiene posición).
        final mostrarAparte =
            !estaEnElTop &&
            tuMarca != null &&
            tuMarca.posicion != null &&
            _perfil != null &&
            _perfil!.tieneAlias;

        if (filas.isEmpty && !mostrarAparte) {
          return Center(child: Text(t.gameRankingEmpty));
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            for (final fila in filas)
              _FilaDeRanking(
                posicion: fila.posicion,
                alias: fila.alias,
                puntos: fila.puntos,
                esTuya:
                    alias != null && fila.alias.trim().toLowerCase() == alias,
              ),
            if (mostrarAparte) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Center(child: Text('⋮')),
              ),
              _FilaDeRanking(
                key: const ValueKey('tu-posicion'),
                posicion: tuMarca.posicion!,
                alias: _perfil!.alias!,
                puntos: tuMarca.puntos,
                esTuya: true,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FilaDeRanking extends StatelessWidget {
  const _FilaDeRanking({
    super.key,
    required this.posicion,
    required this.alias,
    required this.puntos,
    required this.esTuya,
  });

  final int posicion;
  final String alias;
  final int puntos;
  final bool esTuya;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;

    return Card(
      key: esTuya ? const ValueKey('tu-fila') : null,
      color: esTuya ? colores.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '#$posicion',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                esTuya ? '$alias · ${t.gameYou}' : alias,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: esTuya ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text('$puntos', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
