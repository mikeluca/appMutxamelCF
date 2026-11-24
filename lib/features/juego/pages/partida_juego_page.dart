import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../envio_puntuacion.dart';
import '../estado_mutxigol.dart';
import '../logica/atrapa_logica.dart';
import '../logica/cabezazos_logica.dart';
import '../logica/logica_juego.dart';
import '../logica/parejas_logica.dart';
import '../logica/regatea_logica.dart';
import '../models/juego_modelos.dart';
import '../services/juego_service.dart';
import '../tiempo_juego.dart';
import '../widgets/dialogo_alias.dart';
import '../widgets/escena_atrapa.dart';
import '../widgets/escena_cabezazos.dart';
import '../widgets/escena_parejas.dart';
import '../widgets/escena_regatea.dart';
import '../widgets/fin_de_partida.dart';
import '../widgets/leyenda_atrapa.dart';
import 'ranking_juego_page.dart';

enum _FasePartida { leyenda, cuentaAtras, jugando, pausa, fin }

/// Una partida de uno de los minijuegos, en vertical y a pantalla completa: cuenta atrás de 3 segundos (menos en Parejas,
/// que empieza con la primera carta), botón de pausa y de salir, vibración ligera al marcar o perder y, al acabar, el fin
/// de partida con el envío de la puntuación. Se pausa sola con la app en segundo plano y se para al salir de la pantalla.
class PartidaJuegoPage extends StatefulWidget {
  const PartidaJuegoPage({
    super.key,
    required this.juego,
    this.perfil,
    this.conSesion = false,
    this.servicio = const JuegoService(),
    this.crearLogica,
  });

  final Juego juego;

  /// El perfil del juego si hay sesión y se ha podido cargar (alias y récords).
  final PerfilJuego? perfil;

  final bool conSesion;
  final JuegoService servicio;

  /// Solo para tests: la lógica con la que jugar (recibe el alto del campo).
  final LogicaJuego Function(double alto)? crearLogica;

  /// La cuenta atrás de antes de empezar.
  static const Duration cuentaAtras = Duration(seconds: 3);

  /// Un fotograma largo (por un tirón) no hace saltar el juego: como mucho avanza esto de una vez.
  static const Duration fotogramaMaximo = Duration(milliseconds: 50);

  @override
  State<PartidaJuegoPage> createState() => _PartidaJuegoPageState();
}

class _PartidaJuegoPageState extends State<PartidaJuegoPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_alFotograma);

  /// Cambia en cada fotograma: repinta el juego y el marcador sin reconstruir toda la página.
  final ValueNotifier<int> _fotograma = ValueNotifier<int>(0);

  LogicaJuego? _logica;
  late _FasePartida _fase;
  late _FasePartida _faseAntesDePausa;
  Duration _cuenta = PartidaJuegoPage.cuentaAtras;
  Duration _ultimo = Duration.zero;

  EnvioPuntuacion? _envio;
  late int _recordAnterior;
  late String? _alias;

  // Parejas: los escudos del tablero (vienen del backend).
  List<EscudoJuego>? _escudos;
  bool _cargandoEscudos = false;
  bool _errorDeEscudos = false;

  Equipacion get _equipacion => EstadoMutxigol.equipacion.value;

  bool get _esParejas => widget.juego == Juego.parejas;

  /// Atrapa enseña su leyenda antes de la primera partida de la sesión de la app.
  bool get _hayLeyendaInicial =>
      widget.juego == Juego.atrapa && !EstadoMutxigol.leyendaAtrapaVista;

  /// La fase en la que empieza (o vuelve a empezar) una partida.
  _FasePartida get _faseInicial => _esParejas
      ? _FasePartida.jugando
      : _hayLeyendaInicial
      ? _FasePartida.leyenda
      : _FasePartida.cuentaAtras;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _fase = _faseInicial;
    _faseAntesDePausa = _fase;
    _alias = widget.perfil?.alias;
    _recordAnterior = _recordConocido();
  }

  /// El mejor resultado que se conoce en este juego: el del perfil (con sesión) o el de esta sesión de la app (puntos
  /// o, en Parejas, el menor tiempo).
  int _recordConocido() {
    final delPerfil = widget.perfil?.record(widget.juego) ?? 0;
    final deLaSesion = EstadoMutxigol.recordDeLaSesion(widget.juego);

    if (delPerfil == 0) return deLaSesion;
    if (deLaSesion == 0) return delPerfil;

    return widget.juego.esDeTiempo
        ? (delPerfil < deLaSesion ? delPerfil : deLaSesion)
        : (delPerfil > deLaSesion ? delPerfil : deLaSesion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Las imágenes del juego, listas antes de empezar para que no parpadeen.
    final poses = switch (widget.juego) {
      Juego.atrapa => [PoseMutxigol.atrapando],
      Juego.regatea => [
        PoseMutxigol.corriendo1,
        PoseMutxigol.corriendo2,
        PoseMutxigol.corriendo3,
      ],
      Juego.cabezazos => [PoseMutxigol.salto],
      Juego.parejas => <PoseMutxigol>[],
    };

    for (final pose in [...poses, PoseMutxigol.celebrando, PoseMutxigol.triste]) {
      precacheImage(
        AssetImage(ImagenesMutxigol.pose(_equipacion, pose)),
        context,
      ).catchError((_) {});
    }

    precacheImage(const AssetImage(ImagenesMutxigol.balon), context)
        .catchError((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _fotograma.dispose();
    _envio?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // En segundo plano el juego se pausa (y se queda así hasta que el jugador lo reanude).
    if (estado != AppLifecycleState.resumed) _pausar();
  }

  // ---- La partida ----

  LogicaJuego _nuevaLogica(double alto) {
    final logica =
        widget.crearLogica?.call(alto) ??
        switch (widget.juego) {
          Juego.atrapa => AtrapaLogica(alto: alto),
          Juego.regatea => RegateaLogica(alto: alto),
          Juego.cabezazos => CabezazosLogica(alto: alto),
          Juego.parejas => ParejasLogica(alto: alto, escudos: _escudos!),
        };

    logica.alEvento = (evento) => switch (evento) {
      EventoJuego.punto => HapticFeedback.lightImpact(),
      EventoJuego.fallo => HapticFeedback.mediumImpact(),
    };

    return logica;
  }

  void _arrancar() {
    if (!mounted || _ticker.isActive || _fase == _FasePartida.leyenda) return;

    _ultimo = Duration.zero;
    _ticker.start();
  }

  void _alFotograma(Duration transcurrido) {
    var dt = transcurrido - _ultimo;

    _ultimo = transcurrido;

    if (dt > PartidaJuegoPage.fotogramaMaximo) {
      dt = PartidaJuegoPage.fotogramaMaximo;
    }

    if (_fase == _FasePartida.cuentaAtras) {
      _cuenta -= dt;

      if (_cuenta <= Duration.zero) {
        _fase = _FasePartida.jugando;
      }
    } else if (_fase == _FasePartida.jugando) {
      _logica!.tick(dt);

      if (_logica!.terminado) {
        _terminar();
        return;
      }
    }

    _fotograma.value++;
  }

  void _terminar() {
    _ticker.stop();

    final logica = _logica!;
    final tiempoMs = logica.tiempoJugado.inMilliseconds;

    EstadoMutxigol.anotarPuntuacion(
      widget.juego,
      widget.juego.esDeTiempo ? tiempoMs : logica.puntos,
    );

    final envio = EnvioPuntuacion(
      servicio: widget.servicio,
      juego: widget.juego,
      puntos: logica.puntos,
      duracion: logica.tiempoJugado,
      conSesion: widget.conSesion,
      alias: _alias,
    );

    _envio?.dispose();
    _envio = envio;
    envio.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() => _fase = _FasePartida.fin);

    envio.iniciar();
  }

  void _otraVez() {
    _envio?.dispose();

    setState(() {
      _envio = null;
      _logica = null;
      _escudos = null;
      _errorDeEscudos = false;
      _fase = _faseInicial;
      _faseAntesDePausa = _fase;
      _cuenta = PartidaJuegoPage.cuentaAtras;
      _recordAnterior = _recordConocido();
    });
  }

  /// Parejas: pide los 8 escudos del tablero. Con menos de 8 (o si falla) no se puede jugar.
  Future<void> _cargarEscudos() async {
    if (_cargandoEscudos) return;

    setState(() {
      _cargandoEscudos = true;
      _errorDeEscudos = false;
    });

    try {
      final escudos = await widget.servicio.escudos(
        cantidad: ParejasLogica.parejas,
      );

      if (!mounted) return;

      setState(() {
        _cargandoEscudos = false;
        _escudos = escudos;
        _errorDeEscudos = escudos.length < ParejasLogica.parejas;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargandoEscudos = false;
        _escudos = null;
        _errorDeEscudos = true;
      });
    }
  }

  void _pausar() {
    if (_fase != _FasePartida.cuentaAtras && _fase != _FasePartida.jugando) {
      return;
    }

    _ticker.stop();

    setState(() {
      _faseAntesDePausa = _fase;
      _fase = _FasePartida.pausa;
    });
  }

  void _reanudar() {
    if (_fase != _FasePartida.pausa) return;

    setState(() => _fase = _faseAntesDePausa);

    _arrancar();
  }

  void _cerrarLeyendaInicial() {
    EstadoMutxigol.leyendaAtrapaVista = true;

    setState(() => _fase = _FasePartida.cuentaAtras);

    _arrancar();
  }

  /// "¿Cómo se juega?" durante la partida: la pausa y enseña la leyenda.
  Future<void> _verLeyenda() async {
    _pausar();

    await LeyendaAtrapa.mostrar(context);
  }

  Future<void> _elegirAlias() async {
    final alias = await DialogoAlias.mostrar(
      context,
      servicio: widget.servicio,
      aliasActual: _alias,
    );

    if (alias == null || !mounted) return;

    _alias = alias;

    await _envio?.aliasElegido(alias);
  }

  void _verRanking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RankingJuegoPage(
          juegoInicial: widget.juego,
          servicio: widget.servicio,
          conSesion: widget.conSesion,
        ),
      ),
    );
  }

  // ---- La vista ----

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Stack(
        children: [
          Positioned.fill(
            // El juego tiene tamaños fijos: la letra grande del móvil no lo descoloca.
            child: MediaQuery.withNoTextScaling(
              child: LayoutBuilder(builder: _construirJuego),
            ),
          ),
          if (_fase == _FasePartida.leyenda)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: SafeArea(
                  child: Center(
                    child: LeyendaAtrapa(
                      textoBoton: t.gameLegendStart,
                      onCerrar: _cerrarLeyendaInicial,
                    ),
                  ),
                ),
              ),
            ),
          if (_fase == _FasePartida.fin && _envio != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      child: FinDePartida(
                        equipacion: _equipacion,
                        juego: widget.juego,
                        puntos: _logica!.puntos,
                        tiempoMs: _logica!.tiempoJugado.inMilliseconds,
                        recordAnterior: _recordAnterior,
                        envio: _envio!,
                        onOtraVez: _otraVez,
                        onRanking: _verRanking,
                        onElegirAlias: _elegirAlias,
                        onSalir: () => Navigator.maybePop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_fase == _FasePartida.pausa)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.gamePausedTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const ValueKey('reanudar'),
                            onPressed: _reanudar,
                            child: Text(t.gameResume),
                          ),
                          if (widget.juego == Juego.atrapa) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              key: const ValueKey('como-se-juega-pausa'),
                              onPressed: () => LeyendaAtrapa.mostrar(context),
                              child: Text(t.gameHowToPlay),
                            ),
                          ],
                          const SizedBox(height: 8),
                          OutlinedButton(
                            key: const ValueKey('salir-pausa'),
                            onPressed: () => Navigator.maybePop(context),
                            child: Text(t.gameExit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirJuego(BuildContext context, BoxConstraints restricciones) {
    final escala = restricciones.maxWidth / LogicaJuego.ancho;
    final alto = restricciones.maxHeight / escala;

    if (_logica == null) {
      // Parejas necesita antes los escudos del backend.
      if (_esParejas && widget.crearLogica == null) {
        if (_escudos == null && !_errorDeEscudos && !_cargandoEscudos) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _escudos == null) _cargarEscudos();
          });
        }

        if (_escudos == null || _errorDeEscudos) {
          return _esperandoEscudos(context);
        }
      }

      _logica = _nuevaLogica(alto);

      WidgetsBinding.instance.addPostFrameCallback((_) => _arrancar());
    }

    return ListenableBuilder(
      listenable: _fotograma,
      builder: (context, _) {
        final logica = _logica!;
        final activa = _fase == _FasePartida.jugando;
        final equipacion = _equipacion;

        final escena = switch (logica) {
          AtrapaLogica() => EscenaAtrapa(
            logica: logica,
            equipacion: equipacion,
            activa: activa,
          ),
          RegateaLogica() => EscenaRegatea(
            logica: logica,
            equipacion: equipacion,
            activa: activa,
          ),
          CabezazosLogica() => EscenaCabezazos(
            logica: logica,
            equipacion: equipacion,
            activa: activa,
          ),
          ParejasLogica() => EscenaParejas(
            logica: logica,
            equipacion: equipacion,
            activa: activa,
          ),
          _ => const SizedBox.shrink(),
        };

        return Stack(
          children: [
            Positioned.fill(
              child: FittedBox(fit: BoxFit.fill, child: escena),
            ),
            SafeArea(child: _marcador(context, logica)),
            if (_fase == _FasePartida.cuentaAtras) _cuentaAtras(),
          ],
        );
      },
    );
  }

  /// Parejas: cargando los escudos o, si no hay suficientes (o falló), el aviso con el botón de reintentar.
  Widget _esperandoEscudos(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Stack(
      children: [
        Center(
          child: _cargandoEscudos || (!_errorDeEscudos && _escudos == null)
              ? const CircularProgressIndicator(
                  key: ValueKey('cargando-escudos'),
                  color: Colors.white,
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.gamePairsNoShields,
                        key: const ValueKey('sin-escudos'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const ValueKey('reintentar-escudos'),
                        onPressed: () {
                          setState(() {
                            _escudos = null;
                            _errorDeEscudos = false;
                          });
                          _cargarEscudos();
                        },
                        child: Text(t.retry),
                      ),
                    ],
                  ),
                ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              key: const ValueKey('salir'),
              tooltip: t.gameExit,
              color: Colors.white,
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.close, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _marcador(BuildContext context, LogicaJuego logica) {
    final t = AppLocalizations.of(context);
    final vidas = logica.vidas;

    const sombra = [Shadow(blurRadius: 4, color: Colors.black87)];

    TextStyle estilo(double tamano) => TextStyle(
      color: Colors.white,
      fontSize: tamano,
      fontWeight: FontWeight.bold,
      shadows: sombra,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('pausa'),
            tooltip: t.gamePause,
            color: Colors.white,
            onPressed: _fase == _FasePartida.fin ? null : _pausar,
            icon: const Icon(Icons.pause_circle_outline, size: 30),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logica is ParejasLogica) ...[
                  Text(
                    formatearTiempo(logica.tiempoJugado.inMilliseconds),
                    key: const ValueKey('marcador-tiempo'),
                    style: estilo(24),
                  ),
                  Text(
                    t.gameAttempts(logica.intentos),
                    key: const ValueKey('marcador-intentos'),
                    style: estilo(14),
                  ),
                ] else
                  Text(
                    t.gameScoreLabel(logica.puntos),
                    key: const ValueKey('marcador-puntos'),
                    style: estilo(20),
                  ),
                if (vidas != null)
                  Row(
                    key: const ValueKey('marcador-vidas'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < vidas ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: Colors.redAccent.shade100,
                        ),
                    ],
                  ),
                if (logica is AtrapaLogica) _amarillas(logica, t),
              ],
            ),
          ),
          if (widget.juego == Juego.atrapa)
            IconButton(
              key: const ValueKey('como-se-juega'),
              tooltip: t.gameHowToPlay,
              color: Colors.white,
              onPressed: _fase == _FasePartida.fin ? null : _verLeyenda,
              icon: const Icon(Icons.help_outline, size: 28),
            ),
          IconButton(
            key: const ValueKey('salir'),
            tooltip: t.gameExit,
            color: Colors.white,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close, size: 30),
          ),
        ],
      ),
    );
  }

  /// El marcador de tarjetas amarillas de Atrapa (2 hacen perder una vida; se reinicia al perderla).
  Widget _amarillas(AtrapaLogica logica, AppLocalizations t) {
    return Row(
      key: const ValueKey('marcador-amarillas'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < AtrapaLogica.amarillasPorVida; i++)
          Container(
            key: ValueKey(
              'amarilla-$i-${i < logica.amarillas ? 'llena' : 'vacia'}',
            ),
            width: 12,
            height: 17,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: i < logica.amarillas
                  ? const Color(0xFFFFEB3B)
                  : Colors.transparent,
              border: Border.all(color: const Color(0xFFFFEB3B), width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _cuentaAtras() {
    final t = AppLocalizations.of(context);
    final segundos = (_cuenta.inMilliseconds / 1000).ceil().clamp(1, 3);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Text(
            '$segundos',
            key: const ValueKey('cuenta-atras'),
            semanticsLabel: t.gameGo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 96,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
            ),
          ),
        ),
      ),
    );
  }
}
