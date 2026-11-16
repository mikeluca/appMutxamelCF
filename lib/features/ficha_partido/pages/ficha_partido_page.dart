import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/services/push_notification_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/ficha_partido_model.dart';
import '../services/ficha_partido_service.dart';
import '../widgets/ficha_alineacion.dart';
import '../widgets/ficha_cabecera.dart';
import '../widgets/ficha_detalle.dart';
import '../widgets/ficha_forma.dart';
import '../../directo/services/seguir_partido_service.dart';
import '../../directo/widgets/boton_seguir_partido.dart';
import '../../directo/widgets/celebra_goles.dart';
import '../../directo/pages/compartir_vista_previa_page.dart';

/// Ficha pública de un partido del Primer Equipo (sin sesión): cabecera fija y las pestañas Detalle, Alineación y
/// Últ. partidos (forma del equipo). Mientras el partido está en juego o en el descanso y la pantalla está a la vista, se recarga
/// cada 30 segundos y al llegar un push del directo; al salir o con la app en segundo plano se para.
class FichaPartidoPage extends StatefulWidget {
  static const Duration intervaloEnDirecto = Duration(seconds: 30);

  final int partidoId;

  /// Solo para tests: sustituyen al servicio real, a los avisos de push y al intervalo.
  final FichaPartidoService? service;
  final Stream<void>? avisosDeResultados;
  final Duration intervalo;

  /// Solo para tests: el servicio de "Seguir este partido" (por defecto, el real).
  final SeguirPartidoService? seguirService;

  const FichaPartidoPage({
    super.key,
    required this.partidoId,
    this.service,
    this.avisosDeResultados,
    this.intervalo = intervaloEnDirecto,
    this.seguirService,
  });

  /// Las fichas que están abiertas ahora mismo (la más reciente, al final).
  static final List<_FichaPartidoPageState> _abiertas = [];

  /// true si la ficha de ese partido es la pantalla actual (la que el usuario está viendo).
  static bool estaVisible(int partidoId) => _abiertas.any(
    (a) =>
        a.widget.partidoId == partidoId &&
        a.mounted &&
        (a._ruta?.isCurrent ?? false),
  );

  /// Abre la ficha del partido. Si la ficha de ese mismo partido ya está abierta no se apila otra: se vuelve a
  /// ella (cerrando lo que tenga encima) y se refresca.
  static Future<void> abrir(
    BuildContext context,
    int partidoId, {
    FichaPartidoService? service,
  }) => abrirEn(Navigator.of(context), partidoId, service: service);

  /// Igual que [abrir], con el navegador ya resuelto (el de la app, para los avisos).
  static Future<void> abrirEn(
    NavigatorState navigator,
    int partidoId, {
    FichaPartidoService? service,
  }) {
    for (final abierta in _abiertas.reversed) {
      if (abierta.widget.partidoId == partidoId && abierta.mounted) {
        final ruta = abierta._ruta;

        if (ruta != null && ruta.isActive) {
          navigator.popUntil((r) => r == ruta);
          abierta._recargar(silencioso: true);

          return Future<void>.value();
        }
      }
    }

    return navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FichaPartidoPage(partidoId: partidoId, service: service),
      ),
    );
  }

  @override
  State<FichaPartidoPage> createState() => _FichaPartidoPageState();
}

class _FichaPartidoPageState extends State<FichaPartidoPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final FichaPartidoService _service =
      widget.service ?? FichaPartidoService();
  late final TabController _pestanas = TabController(length: 3, vsync: this);
  late final SeguirPartidoService _seguir =
      widget.seguirService ?? PushNotificationService.seguirPartidos;

  FichaPartido? _ficha;
  bool _cargando = true;
  Object? _error;

  Timer? _temporizador;
  StreamSubscription<void>? _avisos;
  bool _enPrimerPlano = true;
  bool _pausada = false;
  bool _recargando = false;
  bool _iniciada = false;
  ModalRoute<dynamic>? _ruta;

  @override
  void initState() {
    super.initState();

    FichaPartidoPage._abiertas.add(this);

    WidgetsBinding.instance.addObserver(this);

    _avisos =
        (widget.avisosDeResultados ??
                PushNotificationService.avisosDeResultados)
            .listen((_) {
              if (_ficha?.cabecera.estado.seEstaJugando ?? false) {
                _recargar(silencioso: true);
              }
            });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _ruta = ModalRoute.of(context);

    if (!_iniciada) {
      _iniciada = true;
      _recargar();
    }
  }

  @override
  void dispose() {
    FichaPartidoPage._abiertas.remove(this);
    WidgetsBinding.instance.removeObserver(this);
    _avisos?.cancel();
    _temporizador?.cancel();
    _pestanas.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _enPrimerPlano = state == AppLifecycleState.resumed;

    if (_enPrimerPlano && (_ficha?.cabecera.estado.seEstaJugando ?? false)) {
      _recargar(silencioso: true);
    }

    _sincronizarTemporizador();
  }

  /// Pide la ficha. Con [silencioso] (y algo ya a la vista) no pasa por la pantalla de carga y, si falla, se queda
  /// lo que se veía.
  Future<void> _recargar({bool silencioso = false}) async {
    if (_recargando || !mounted) return;

    _recargando = true;

    final idioma = Localizations.localeOf(context).languageCode;
    final sinCargando = silencioso && _ficha != null;

    if (!sinCargando) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final ficha = await _service.obtenerFicha(
        widget.partidoId,
        idioma: idioma,
      );

      if (!mounted) return;

      setState(() {
        _ficha = ficha;
        _cargando = false;
        _error = null;
      });

      // Terminado o cancelado: ya no hay avisos que seguir.
      if (ficha.cabecera.estado == EstadoFicha.finalizado ||
          ficha.cabecera.estado == EstadoFicha.cancelado) {
        unawaited(
          _seguir.bajaSiTermino(widget.partidoId).catchError((_) {}),
        );
      }
    } catch (e) {
      if (!mounted || sinCargando) return;

      setState(() {
        _cargando = false;
        _error = e;
      });
    } finally {
      _recargando = false;

      if (mounted) _sincronizarTemporizador();
    }
  }

  /// El temporizador solo corre con el partido en juego o en el descanso y la pantalla a la vista.
  void _sincronizarTemporizador() {
    final debePedir =
        (_ficha?.cabecera.estado.seEstaJugando ?? false) &&
        _enPrimerPlano &&
        !_pausada;

    if (debePedir && _temporizador == null) {
      _temporizador = Timer.periodic(
        widget.intervalo,
        (_) => _recargar(silencioso: true),
      );
    } else if (!debePedir) {
      _temporizador?.cancel();
      _temporizador = null;
    }
  }

  /// Tocar un partido de la forma abre su ficha; mientras, esta se queda sin recargarse.
  Future<void> _abrirOtraFicha(int partidoId) async {
    _pausada = true;
    _sincronizarTemporizador();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FichaPartidoPage(
          partidoId: partidoId,
          service: widget.service,
          avisosDeResultados: widget.avisosDeResultados,
          intervalo: widget.intervalo,
          seguirService: widget.seguirService,
        ),
      ),
    );

    if (!mounted) return;

    _pausada = false;
    _recargar(silencioso: true);
    _sincronizarTemporizador();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.fichaTitle),
        backgroundColor: const Color(0xFF0B3D5C),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            key: const ValueKey('boton-compartir'),
            icon: const Icon(Icons.share),
            tooltip: t.shareTooltip,
            onPressed: _ficha == null ? null : _compartir,
          ),
        ],
      ),
      body: _construirCuerpo(t),
    );
  }

  Widget _construirCuerpo(AppLocalizations t) {
    final ficha = _ficha;

    if (ficha == null) {
      if (_cargando) {
        return const Center(child: CircularProgressIndicator());
      }

      return _construirError(t);
    }

    final cabecera = ficha.cabecera;
    final terminado =
        cabecera.estado == EstadoFicha.finalizado ||
        cabecera.estado == EstadoFicha.cancelado;

    final cuerpo = Column(
      children: [
        FichaCabecera(cabecera: cabecera),
        if (!terminado)
          BotonSeguirPartido(
            partidoId: widget.partidoId,
            fecha: cabecera.dia,
            service: _seguir,
          ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          child: TabBar(
            controller: _pestanas,
            tabs: [
              Tab(
                key: const ValueKey('pestana-detalle'),
                text: t.fichaTabDetail,
              ),
              Tab(
                key: const ValueKey('pestana-alineacion'),
                text: t.fichaTabLineup,
              ),
              Tab(key: const ValueKey('pestana-forma'), text: t.fichaTabForm),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _pestanas,
            children: [
              _conRefresco(FichaDetalle(ficha: ficha)),
              _conRefresco(FichaAlineacion(alineacion: ficha.alineacion)),
              _conRefresco(
                FichaForma(forma: ficha.forma, alTocar: _abrirOtraFicha),
              ),
            ],
          ),
        ),
      ],
    );

    // El goleador es el del último gol del Mutxamel (lo último va primero) y el dorsal el del último del rival.
    String? goleador;
    int? dorsalRival;

    for (final e in ficha.eventos) {
      if (goleador == null && e.tipo == EventoFicha.golFavor) {
        goleador = e.jugador;
      }

      if (dorsalRival == null && e.tipo == EventoFicha.golContra) {
        dorsalRival = e.dorsalRival;
      }
    }

    return CelebraGoles(
      partidoId: cabecera.partidoId == 0 ? null : cabecera.partidoId,
      golesFavor: cabecera.golesFavor,
      golesContra: cabecera.golesContra,
      mutxamelEsLocal: cabecera.mutxamelEsLocal,
      goleador: goleador,
      dorsalRival: dorsalRival,
      child: cuerpo,
    );
  }

  /// Genera la imagen del partido y abre el menú de compartir del sistema.
  Future<void> _compartir() async {
    final ficha = _ficha;

    if (ficha == null) return;

    // La vista previa genera la imagen y la comparte (y avisa si falla).
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CompartirVistaPreviaPage(ficha: ficha),
      ),
    );
  }

  Widget _conRefresco(Widget contenido) {
    return RefreshIndicator(onRefresh: _recargar, child: contenido);
  }

  Widget _construirError(AppLocalizations t) {
    final noDisponible =
        _error is ApiException && (_error as ApiException).statusCode == 404;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              noDisponible ? t.fichaNotAvailable : t.fichaLoadError,
              key: const ValueKey('ficha-error'),
              textAlign: TextAlign.center,
            ),
            if (!noDisponible) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _recargar, child: Text(t.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
