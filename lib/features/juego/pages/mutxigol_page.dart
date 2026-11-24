import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/services/auth_manager.dart';
import '../estado_mutxigol.dart';
import '../models/juego_modelos.dart';
import '../services/juego_service.dart';
import '../tiempo_juego.dart';
import '../widgets/dialogo_alias.dart';
import '../widgets/leyenda_atrapa.dart';
import 'partida_juego_page.dart';
import 'ranking_juego_page.dart';

/// La pestaña Mutxigol: la mascota con su equipación, los tres juegos (con tu récord si hay sesión), el ranking y el
/// alias. Sin sesión se puede jugar pero no se guarda nada; la equipación vale mientras la app está abierta.
class MutxigolPage extends StatefulWidget {
  const MutxigolPage({super.key, this.servicio = const JuegoService()});

  final JuegoService servicio;

  @override
  State<MutxigolPage> createState() => _MutxigolPageState();
}

class _MutxigolPageState extends State<MutxigolPage> {
  PerfilJuego? _perfil;

  /// El perfil se está cargando.
  bool _cargando = false;

  /// La cuenta no puede usar el juego (sin roles: 403): se trata como "sin sesión".
  bool _sinPermiso = false;

  bool _errorDeCarga = false;

  /// Con sesión y con permiso para guardar puntuaciones.
  bool get _conSesion => AuthManager.estaAutenticado && !_sinPermiso;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    AuthManager.cambios.addListener(_alCambiarLaSesion);

    if (AuthManager.estaAutenticado) _cargarPerfil();
  }

  @override
  void dispose() {
    AuthManager.cambios.removeListener(_alCambiarLaSesion);
    super.dispose();
  }

  void _alCambiarLaSesion() {
    if (!mounted) return;

    if (AuthManager.estaAutenticado) {
      _cargarPerfil();
    } else {
      setState(() {
        _perfil = null;
        _sinPermiso = false;
        _errorDeCarga = false;
      });
    }
  }

  Future<void> _cargarPerfil() async {
    if (_cargando) return;

    setState(() {
      _cargando = true;
      _errorDeCarga = false;
    });

    try {
      final perfil = await widget.servicio.perfil();

      if (!mounted) return;

      // La equipación del perfil manda al iniciar sesión.
      EstadoMutxigol.equipacion.value = perfil.equipacion;

      setState(() {
        _perfil = perfil;
        _sinPermiso = false;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _sinPermiso = e is ApiException && e.statusCode == 403;
        _errorDeCarga = !_sinPermiso;
      });
    }
  }

  Future<void> _elegirEquipacion(Equipacion equipacion) async {
    EstadoMutxigol.equipacion.value = equipacion;

    if (!_conSesion) return;

    try {
      final perfil = await widget.servicio.actualizarPerfil(
        equipacion: equipacion,
      );

      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.gameKitSaveError)));
    }
  }

  Future<void> _editarAlias() async {
    final alias = await DialogoAlias.mostrar(
      context,
      servicio: widget.servicio,
      aliasActual: _perfil?.alias,
    );

    if (alias == null || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_t.gameAliasSaved)));

    await _cargarPerfil();
  }

  Future<void> _jugar(Juego juego) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PartidaJuegoPage(
          juego: juego,
          perfil: _perfil,
          conSesion: _conSesion,
          servicio: widget.servicio,
        ),
      ),
    );

    // Al volver puede haber cambiado el alias o el récord.
    if (mounted && _conSesion) await _cargarPerfil();
  }

  void _verRanking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RankingJuegoPage(
          servicio: widget.servicio,
          conSesion: _conSesion,
          perfil: _perfil,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.gameTitle)),
      body: ValueListenableBuilder<Equipacion>(
        valueListenable: EstadoMutxigol.equipacion,
        builder: (context, equipacion, _) => ListView(
          // El final no queda tapado por la barra flotante.
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Center(
              child: Image.asset(
                ImagenesMutxigol.pose(equipacion, PoseMutxigol.parado),
                key: const ValueKey('mutxigol-parado'),
                height: 190,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SegmentedButton<Equipacion>(
                key: const ValueKey('selector-equipacion'),
                segments: [
                  ButtonSegment(
                    value: Equipacion.azul,
                    label: Text(t.gameKitBlue),
                  ),
                  ButtonSegment(
                    value: Equipacion.rosa,
                    label: Text(t.gameKitPink),
                  ),
                ],
                selected: {equipacion},
                onSelectionChanged: (valor) => _elegirEquipacion(valor.first),
              ),
            ),
            const SizedBox(height: 12),
            _avisoDeAlias(),
            const SizedBox(height: 4),
            for (final juego in Juego.values)
              _TarjetaDeJuego(
                juego: juego,
                equipacion: equipacion,
                record: _conSesion ? _perfil?.record(juego) : null,
                onJugar: () => _jugar(juego),
              ),
            const SizedBox(height: 8),
            Center(
              child: FilledButton.icon(
                key: const ValueKey('boton-ranking'),
                onPressed: _verRanking,
                icon: const Icon(Icons.emoji_events_outlined),
                label: Text(t.gameRankingButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lo que se dice del alias: iniciar sesión, elegirlo, o el actual (con opción de cambiarlo).
  Widget _avisoDeAlias() {
    final t = _t;

    if (!_conSesion) {
      return _Aviso(
        key: const ValueKey('aviso-login'),
        icono: Icons.login,
        texto: t.gameLoginBanner,
      );
    }

    if (_cargando && _perfil == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorDeCarga && _perfil == null) {
      return _Aviso(
        key: const ValueKey('aviso-error'),
        icono: Icons.error_outline,
        texto: t.gameLoadError,
        accion: t.retry,
        onAccion: _cargarPerfil,
      );
    }

    final perfil = _perfil;

    if (perfil == null) return const SizedBox.shrink();

    if (!perfil.tieneAlias) {
      return _Aviso(
        key: const ValueKey('aviso-alias'),
        icono: Icons.badge_outlined,
        texto: t.gameChooseAliasBanner,
        accion: t.gameChooseAliasAction,
        onAccion: _editarAlias,
      );
    }

    return _Aviso(
      key: const ValueKey('tu-alias'),
      icono: Icons.badge_outlined,
      texto: t.gameYourAlias(perfil.alias!),
      accion: t.gameChangeAliasAction,
      onAccion: _editarAlias,
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    super.key,
    required this.icono,
    required this.texto,
    this.accion,
    this.onAccion,
  });

  final IconData icono;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono),
                const SizedBox(width: 10),
                Expanded(child: Text(texto)),
              ],
            ),
            if (accion != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('accion-aviso'),
                  onPressed: onAccion,
                  child: Text(accion!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaDeJuego extends StatelessWidget {
  const _TarjetaDeJuego({
    required this.juego,
    required this.equipacion,
    required this.record,
    required this.onJugar,
  });

  final Juego juego;
  final Equipacion equipacion;

  /// El récord histórico (null sin sesión: no se enseña): los puntos o, en Parejas, el mejor tiempo en ms.
  final int? record;
  final VoidCallback onJugar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final (titulo, como, pose) = switch (juego) {
      Juego.atrapa => (
        t.gameCatchName,
        t.gameCatchHow,
        PoseMutxigol.atrapando,
      ),
      Juego.regatea => (
        t.gameRunName,
        t.gameRunHow,
        PoseMutxigol.corriendo2,
      ),
      Juego.cabezazos => (
        t.gameHeadName,
        t.gameHeadHow,
        PoseMutxigol.salto,
      ),
      Juego.parejas => (
        t.gamePairsName,
        t.gamePairsHow,
        PoseMutxigol.cara,
      ),
    };

    return Card(
      key: ValueKey('tarjeta-${juego.codigo}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onJugar,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Image.asset(
                ImagenesMutxigol.pose(equipacion, pose),
                width: 92,
                height: 92,
                gaplessPlayback: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(como),
                    if (record != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record! > 0
                            ? (juego.esDeTiempo
                                  ? t.gameYourBestTime(formatearTiempo(record!))
                                  : t.gameYourRecord(record!))
                            : t.gameNoRecordYet,
                        key: ValueKey('record-${juego.codigo}'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    if (juego == Juego.atrapa)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          key: const ValueKey('como-se-juega-atrapa'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => LeyendaAtrapa.mostrar(context),
                          child: Text(t.gameHowToPlay),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}
