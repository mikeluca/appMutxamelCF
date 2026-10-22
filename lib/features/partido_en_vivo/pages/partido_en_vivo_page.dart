import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/partido_en_vivo_models.dart';
import '../services/partido_en_vivo_service.dart';

/// Panel del retransmisor (rol RETRANSMISION): se elige el partido de hoy del
/// Primer Equipo y cada botón registra un evento de ESE partido. El marcador,
/// la fase y los goleadores los calcula el servidor; los botones solo se
/// habilitan en el orden válido y el último aviso se puede deshacer durante 2
/// minutos.
class PartidoEnVivoPage extends StatefulWidget {
  /// Solo para tests: sustituyen al servicio real y al reloj del dispositivo.
  final PartidoEnVivoService? service;
  final DateTime Function()? ahora;

  const PartidoEnVivoPage({super.key, this.service, this.ahora});

  @override
  State<PartidoEnVivoPage> createState() => _PartidoEnVivoPageState();
}

/// Autor elegido para un gol: un jugador o un texto ("Otro" / "p.p.").
class _AutorGol {
  final int? jugadorId;
  final String? texto;

  /// El minuto escrito en el diálogo del gol; null si se dejó vacío (lo calcula el servidor).
  final int? minuto;

  const _AutorGol.jugador(int this.jugadorId, {this.minuto}) : texto = null;

  const _AutorGol.texto(String this.texto, {this.minuto}) : jugadorId = null;

  _AutorGol conMinuto(int? minuto) => jugadorId != null
      ? _AutorGol.jugador(jugadorId!, minuto: minuto)
      : _AutorGol.texto(texto!, minuto: minuto);
}

/// Lee el campo "Minuto": vacío es válido (sin minuto); si no, un entero entre 0 y 150.
({bool valido, int? minuto}) _leerMinuto(String texto) {
  final limpio = texto.trim();

  if (limpio.isEmpty) {
    return (valido: true, minuto: null);
  }

  final minuto = int.tryParse(limpio);

  if (minuto == null || minuto < 0 || minuto > 150) {
    return (valido: false, minuto: null);
  }

  return (valido: true, minuto: minuto);
}

class _PartidoEnVivoPageState extends State<PartidoEnVivoPage>
    with WidgetsBindingObserver {
  late final PartidoEnVivoService _service =
      widget.service ?? PartidoEnVivoService();

  List<PartidoEnVivoDisponible>? _partidos;
  Object? _errorPartidos;
  bool _cargando = true;

  PartidoEnVivoDisponible? _partido;
  EstadoPartidoEnVivo? _estado;

  bool _enviando = false;

  /// Mientras se piden los convocados para elegir al autor del gol, el botón de
  /// gol está deshabilitado (otro toque abriría una segunda hoja).
  bool _cargandoConvocados = false;

  Timer? _temporizador;
  Duration? _restante;

  /// Cuándo acaba el "deshacer": ahora (reloj del móvil) más los segundos que
  /// dice el servidor. No depende de que los dos relojes coincidan.
  DateTime? _finDeshacer;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  DateTime _ahora() => (widget.ahora ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPartidos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizador?.cancel();
    super.dispose();
  }

  /// Al volver a la app se relee el estado: otro retransmisor o la caducidad
  /// del "deshacer" pueden haberlo cambiado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _partido != null) {
      _refrescar();
    }
  }

  Future<void> _cargarPartidos() async {
    setState(() {
      _cargando = true;
      _errorPartidos = null;
    });

    try {
      final partidos = await _service.obtenerPartidosDisponibles();

      if (!mounted) return;

      setState(() {
        _partidos = partidos;
        _cargando = false;
      });

      // Con un solo partido no hay nada que elegir.
      if (partidos.length == 1) {
        await _seleccionar(partidos.first);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorPartidos = e;
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionar(PartidoEnVivoDisponible partido) async {
    setState(() {
      _partido = partido;
      _estado = null;
    });

    await _refrescar();
  }

  void _cambiarDePartido() {
    _temporizador?.cancel();

    setState(() {
      _partido = null;
      _estado = null;
      _restante = null;
    });
  }

  /// Vuelve a pedir el estado al servidor.
  Future<void> _refrescar() async {
    final partido = _partido;

    if (partido == null) return;

    try {
      final estado = await _service.obtenerEstado(partido.id);

      if (!mounted || _partido?.id != partido.id) return;

      _aplicarEstado(estado);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(_t.liveSendError(e.toString()));
    }
  }

  void _aplicarEstado(EstadoPartidoEnVivo estado) {
    setState(() => _estado = estado);

    _reiniciarCuentaAtras();
  }

  // ------------------------------------------------------------------
  // Cuenta atrás de "Deshacer"
  // ------------------------------------------------------------------

  Duration? _restanteDe(DateTime? fin) {
    if (fin == null) {
      return null;
    }

    final restante = fin.difference(_ahora());

    return restante > Duration.zero ? restante : null;
  }

  void _reiniciarCuentaAtras() {
    _temporizador?.cancel();

    final estado = _estado;
    final segundos = estado?.deshacibleId == null
        ? null
        : estado?.deshacibleSegundos;

    _finDeshacer = segundos == null || segundos <= 0
        ? null
        : _ahora().add(Duration(seconds: segundos));

    _restante = _restanteDe(_finDeshacer);

    if (_restante == null) return;

    _temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final restante = _restanteDe(_finDeshacer);

      setState(() => _restante = restante);

      if (restante == null) {
        timer.cancel();
      }
    });
  }

  String _formatear(Duration duracion) {
    final minutos = duracion.inMinutes;
    final segundos = (duracion.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutos:$segundos';
  }

  // ------------------------------------------------------------------
  // Construcción
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final puedeCambiar = (_partidos?.length ?? 0) > 1 && _partido != null;

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: _t.liveMatchTitle),
        actions: [
          if (puedeCambiar)
            IconButton(
              tooltip: _t.liveChangeMatch,
              icon: const Icon(Icons.swap_horiz),
              onPressed: _enviando ? null : _cambiarDePartido,
            ),
        ],
      ),
      body: _construirContenido(),
      // Fuera del cuerpo para que el SnackBar de cada aviso salga POR ENCIMA y
      // no tape el botón de deshacer.
      bottomNavigationBar: _partido == null ? null : _construirBarraDeshacer(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorPartidos != null) {
      return _construirError();
    }

    final partidos = _partidos ?? const [];

    if (partidos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarPartidos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.sports_soccer_outlined,
              size: 64,
              color: _colors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              _t.liveNoMatchesToday,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _colors.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    if (_partido == null) {
      return _construirSelector(partidos);
    }

    return RefreshIndicator(
      onRefresh: _refrescar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: _construirPanel(),
      ),
    );
  }

  Widget _construirSelector(List<PartidoEnVivoDisponible> partidos) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _t.liveChooseMatch,
          style: TextStyle(
            color: _colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        for (final partido in partidos) ...[
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(Icons.sports_soccer, color: _colors.primary),
              title: Text(
                partido.rival,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                [
                  if (partido.hora?.isNotEmpty == true) partido.hora!,
                  partido.local ? _t.liveMatchHome : _t.liveMatchAway,
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _seleccionar(partido),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<Widget> _construirPanel() {
    final estado = _estado;
    final fase = estado?.fase;

    final enCurso =
        fase == FasePartido.primeraParte || fase == FasePartido.segundaParte;

    return [
      _construirMarcador(),
      const SizedBox(height: 16),
      _construirGoleadores(),
      const SizedBox(height: 20),
      Text(
        _t.liveMatchWarning,
        style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
      ),
      const SizedBox(height: 20),
      _construirBoton(
        icono: Icons.list_alt,
        titulo: _t.liveLineupButton,
        necesitaEstado: false,
        onPressed: _abrirDialogoAlineacion,
      ),
      const SizedBox(height: 12),
      _construirBotonConfirmacion(
        icono: Icons.sports_soccer,
        titulo: _t.liveEventKickoff,
        mensajeConfirmacion: _t.liveConfirmKickoff,
        habilitado: fase == FasePartido.sinEmpezar,
        accion: (id) => _service.enviarInicioPartido(id),
      ),
      const SizedBox(height: 12),
      _construirBoton(
        icono: Icons.emoji_events_outlined,
        titulo: _t.liveGoalForButton,
        habilitado: enCurso && !_cargandoConvocados,
        onPressed: _abrirSelectorAutor,
      ),
      const SizedBox(height: 12),
      _construirBoton(
        icono: Icons.sentiment_dissatisfied_outlined,
        titulo: _t.liveEventGoalAgainst,
        habilitado: enCurso,
        onPressed: _confirmarGolContra,
      ),
      const SizedBox(height: 12),
      _construirBotonConfirmacion(
        icono: Icons.pause_circle_outline,
        titulo: _t.liveEventHalftime,
        mensajeConfirmacion: _t.liveConfirmHalftime,
        habilitado: fase == FasePartido.primeraParte,
        accion: (id) => _service.enviarDescanso(id),
      ),
      const SizedBox(height: 12),
      _construirBotonConfirmacion(
        icono: Icons.play_circle_outline,
        titulo: _t.liveEventSecondHalf,
        mensajeConfirmacion: _t.liveConfirmSecondHalf,
        habilitado: fase == FasePartido.descanso,
        accion: (id) => _service.enviarSegundaParte(id),
      ),
      const SizedBox(height: 12),
      _construirBotonConfirmacion(
        icono: Icons.flag_outlined,
        titulo: _t.liveEventFulltime,
        mensajeConfirmacion: _t.liveConfirmFulltime,
        habilitado:
            fase != null &&
            fase != FasePartido.sinEmpezar &&
            fase != FasePartido.finalPartido,
        accion: (id) => _service.enviarFinalPartido(id),
      ),
    ];
  }

  /// "Mutxamel 2 - 1 Rival", en orden local | visitante.
  String _textoMarcador() {
    final partido = _partido!;
    final estado = _estado;

    final rival = estado?.rival.isNotEmpty == true
        ? estado!.rival
        : partido.rival;
    final local = estado?.local ?? partido.local;
    final favor = estado?.golesFavor ?? 0;
    final contra = estado?.golesContra ?? 0;

    return local
        ? 'Mutxamel $favor - $contra $rival'
        : '$rival $contra - $favor Mutxamel';
  }

  String _etiquetaFase(FasePartido? fase) {
    return switch (fase) {
      FasePartido.primeraParte => _t.livePhaseFirstHalf,
      FasePartido.descanso => _t.livePhaseHalftime,
      FasePartido.segundaParte => _t.livePhaseSecondHalf,
      FasePartido.finalPartido => _t.livePhaseFinished,
      _ => _t.livePhaseNotStarted,
    };
  }

  Widget _construirMarcador() {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _textoMarcador(),
                maxLines: 1,
                style: TextStyle(
                  color: _colors.onPrimaryContainer,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _colors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _etiquetaFase(_estado?.fase),
                style: TextStyle(
                  color: _colors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGoleadores() {
    final goleadores = _estado?.goleadores ?? const [];

    // Goles (a favor y en contra) con su minuto delante, que se pueden pulsar para
    // corregir el minuto. Si el estado no trae los eventos de los goles (backend
    // antiguo), la lista de siempre.
    final goles = (_estado?.eventos ?? const <EventoEnVivo>[])
        .where((e) => e.tipo == 'GOL_FAVOR' || e.tipo == 'GOL_CONTRA')
        .toList();

    final golesFavor = goles.where((e) => e.tipo == 'GOL_FAVOR').length;
    final usarEventos = goles.isNotEmpty && golesFavor == goleadores.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t.liveScorers,
          style: TextStyle(
            color: _colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        if (goleadores.isEmpty && goles.isEmpty)
          Text(
            _t.liveNoScorersYet,
            style: TextStyle(color: _colors.onSurfaceVariant),
          )
        else if (usarEventos)
          for (final gol in goles)
            InkWell(
              key: ValueKey('gol-${gol.id}'),
              onTap: _enviando ? null : () => _corregirMinuto(gol),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _textoGol(gol),
                  style: TextStyle(color: _colors.onSurface, fontSize: 15),
                ),
              ),
            )
        else
          for (final autor in goleadores)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '⚽ ${_nombreAutor(autor)}',
                style: TextStyle(color: _colors.onSurface, fontSize: 15),
              ),
            ),
      ],
    );
  }

  /// "⚽ 23' Pérez" (a favor) o "🥅 31' Gol en contra"; sin minuto, sin esa parte.
  String _textoGol(EventoEnVivo gol) {
    final minuto = gol.minuto == null ? '' : "${gol.minuto}' ";

    return gol.tipo == 'GOL_FAVOR'
        ? '⚽ $minuto${_nombreAutor(gol.autor ?? '')}'.trimRight()
        : '🥅 $minuto${_t.liveGoalAgainstRow}';
  }

  String _nombreAutor(String autor) =>
      autor == EstadoPartidoEnVivo.propiaPuerta ? _t.liveOwnGoalShort : autor;

  Widget _construirBoton({
    required IconData icono,
    required String titulo,
    required VoidCallback? onPressed,
    bool habilitado = true,
    bool necesitaEstado = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed:
            _enviando || !habilitado || (necesitaEstado && _estado == null)
            ? null
            : onPressed,
        icon: Icon(icono),
        label: Text(titulo, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _construirBotonConfirmacion({
    required IconData icono,
    required String titulo,
    required String mensajeConfirmacion,
    required bool habilitado,
    required Future<EstadoPartidoEnVivo> Function(int partidoId) accion,
  }) {
    return _construirBoton(
      icono: icono,
      titulo: titulo,
      habilitado: habilitado,
      onPressed: () => _confirmarYEnviar(titulo, mensajeConfirmacion, accion),
    );
  }

  Widget _construirBarraDeshacer() {
    final estado = _estado;
    final restante = _restante;
    final evento = estado?.eventoDeshacible;

    if (estado == null || restante == null || evento == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: _colors.surfaceContainerHigh,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _t.liveUndoLast(_etiquetaEvento(evento)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _colors.onSurface, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _enviando ? null : () => _deshacer(evento),
                icon: const Icon(Icons.undo),
                label: Text(_t.liveUndoButton(_formatear(restante))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _etiquetaEvento(EventoEnVivo evento) {
    return switch (evento.tipo) {
      'INICIO' => _t.liveEventKickoff,
      'GOL_FAVOR' => _t.liveGoalForButton,
      'GOL_CONTRA' => _t.liveEventGoalAgainst,
      'DESCANSO' => _t.liveEventHalftime,
      'SEGUNDA_PARTE' => _t.liveEventSecondHalf,
      'FINAL' => _t.liveEventFulltime,
      _ => _t.liveEventAlert,
    };
  }

  // ------------------------------------------------------------------
  // Acciones
  // ------------------------------------------------------------------

  Future<void> _confirmarYEnviar(
    String titulo,
    String mensajeConfirmacion,
    Future<EstadoPartidoEnVivo> Function(int partidoId) accion,
  ) async {
    final confirmado = await _mostrarConfirmacion(titulo, mensajeConfirmacion);

    if (confirmado != true) return;

    await _ejecutarEvento(accion, _t.liveNotificationSentMessage(titulo));
  }

  /// Gol en contra: la confirmación de siempre con el campo "Minuto" prerrellenado con
  /// el minuto actual del partido (editable; vacío = que lo calcule el servidor).
  Future<void> _confirmarGolContra() async {
    final titulo = _t.liveEventGoalAgainst;

    final respuesta = await showDialog<({int? minuto})>(
      context: context,
      builder: (context) => _DialogoMinuto(
        titulo: titulo,
        mensaje: _t.liveConfirmGoalAgainst,
        minutoInicial: _estado?.minutoActual,
        textoConfirmar: _t.send,
      ),
    );

    if (respuesta == null) return;

    await _ejecutarEvento(
      (id) => _service.enviarGolContra(id, minuto: respuesta.minuto),
      _t.liveNotificationSentMessage(titulo),
    );
  }

  /// Pulsar un gol de la lista: diálogo para corregir su minuto (sin nuevo aviso).
  Future<void> _corregirMinuto(EventoEnVivo evento) async {
    final respuesta = await showDialog<({int? minuto})>(
      context: context,
      builder: (context) => _DialogoMinuto(
        titulo: _t.liveMinuteEditTitle,
        minutoInicial: evento.minuto,
        textoConfirmar: _t.liveMinuteSave,
        obligatorio: true,
      ),
    );

    final minuto = respuesta?.minuto;

    if (minuto == null) return;

    await _ejecutarEvento(
      (id) => _service.corregirMinuto(id, evento.id, minuto),
      _t.liveMinuteSaved,
    );
  }

  Future<bool?> _mostrarConfirmacion(
    String titulo,
    String mensaje, {
    String? textoConfirmar,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(textoConfirmar ?? _t.send),
          ),
        ],
      ),
    );
  }

  /// Registra un evento del partido elegido y pinta el estado resultante. Si
  /// falla, vuelve a leer el estado: el servidor puede haber rechazado el
  /// evento por el orden o por otro retransmisor.
  Future<void> _ejecutarEvento(
    Future<EstadoPartidoEnVivo> Function(int partidoId) accion,
    String mensajeExito,
  ) async {
    final partido = _partido;

    if (partido == null) return;

    setState(() => _enviando = true);

    try {
      final estado = await accion(partido.id);

      if (!mounted) return;

      _aplicarEstado(estado);
      _mostrarMensaje(mensajeExito);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(_t.liveSendError(e.toString()));

      await _refrescar();
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _deshacer(EventoEnVivo evento) async {
    // Deshacer el final revierte el resultado guardado: pide confirmación.
    if (evento.tipo == 'FINAL') {
      final confirmado = await _mostrarConfirmacion(
        _t.liveUndoFulltimeTitle,
        _t.liveUndoFulltimeMessage,
        textoConfirmar: _t.liveUndoConfirm,
      );

      if (confirmado != true) return;
    }

    await _ejecutarEvento(
      (partidoId) => _service.deshacer(partidoId, evento.id),
      _t.liveUndoneMessage,
    );
  }

  /// Hoja inferior con los convocados (dorsal + nombre), "Otro…" y "Propia puerta".
  Future<void> _abrirSelectorAutor() async {
    final partido = _partido;

    if (partido == null || _cargandoConvocados) return;

    setState(() => _cargandoConvocados = true);

    List<ConvocadoEnVivo> convocados = const [];

    try {
      convocados = await _service.obtenerConvocados(partido.id);
    } catch (e) {
      if (!mounted) return;

      // Se puede seguir con "Otro" o "Propia puerta".
      _mostrarMensaje(_t.liveSendError(e.toString()));
    }

    if (!mounted) return;

    setState(() => _cargandoConvocados = false);

    final autor = await showModalBottomSheet<_AutorGol>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SelectorAutorGol(
        convocados: convocados,
        titulo: _t.liveGoalAuthorTitle,
        otro: _t.liveGoalOther,
        propiaPuerta: _t.liveGoalOwnGoal,
        sinJugadores: _t.liveNoPlayersToPick,
        alElegirOtro: _pedirAutorLibre,
        minutoInicial: _estado?.minutoActual,
        etiquetaMinuto: _t.liveMinuteLabel,
        errorMinuto: _t.liveMinuteInvalid,
      ),
    );

    if (autor == null || !mounted) return;

    await _ejecutarEvento(
      (id) => _service.enviarGolFavor(
        id,
        jugadorId: autor.jugadorId,
        autorTexto: autor.texto,
        minuto: autor.minuto,
      ),
      _t.liveGoalSentMessage,
    );
  }

  /// "Otro…": texto libre de hasta 60 caracteres.
  Future<_AutorGol?> _pedirAutorLibre() async {
    final texto = await showDialog<String>(
      context: context,
      builder: (context) => const _DialogoAutorLibre(),
    );

    return texto == null ? null : _AutorGol.texto(texto);
  }

  Future<void> _abrirDialogoAlineacion() async {
    final onceController = TextEditingController();
    final suplentesController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.liveLineupButton),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: onceController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _t.liveStartingLineupLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: suplentesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _t.liveSubstitutesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.send),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    if (onceController.text.trim().isEmpty ||
        suplentesController.text.trim().isEmpty) {
      _mostrarMensaje(_t.liveFillLineupError);
      return;
    }

    setState(() => _enviando = true);

    try {
      await _service.enviarAlineacion(
        onceInicial: onceController.text.trim(),
        suplentes: suplentesController.text.trim(),
      );

      if (!mounted) return;

      _mostrarMensaje(_t.liveLineupSentMessage);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(_t.liveSendError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    // Cada aviso sustituye al anterior (no se encolan: con retransmisión rápida
    // el mensaje llegaría tarde).
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _t.liveLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarPartidos,
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja inferior para elegir quién ha marcado, con el campo "Minuto" (prerrellenado con
/// el minuto actual del partido; vacío = que lo calcule el servidor).
class _SelectorAutorGol extends StatefulWidget {
  final List<ConvocadoEnVivo> convocados;
  final String titulo;
  final String otro;
  final String propiaPuerta;
  final String sinJugadores;
  final Future<_AutorGol?> Function() alElegirOtro;
  final int? minutoInicial;
  final String etiquetaMinuto;
  final String errorMinuto;

  const _SelectorAutorGol({
    required this.convocados,
    required this.titulo,
    required this.otro,
    required this.propiaPuerta,
    required this.sinJugadores,
    required this.alElegirOtro,
    required this.minutoInicial,
    required this.etiquetaMinuto,
    required this.errorMinuto,
  });

  @override
  State<_SelectorAutorGol> createState() => _SelectorAutorGolState();
}

class _SelectorAutorGolState extends State<_SelectorAutorGol> {
  late final TextEditingController _minuto = TextEditingController(
    text: widget.minutoInicial?.toString() ?? '',
  );

  bool _minutoInvalido = false;

  @override
  void dispose() {
    _minuto.dispose();
    super.dispose();
  }

  /// El minuto escrito; si no es válido se marca el campo y se devuelve null.
  ({int? minuto})? _minutoElegido() {
    final lectura = _leerMinuto(_minuto.text);

    setState(() => _minutoInvalido = !lectura.valido);

    return lectura.valido ? (minuto: lectura.minuto) : null;
  }

  void _elegir(_AutorGol autor) {
    final elegido = _minutoElegido();

    if (elegido == null) return;

    Navigator.pop(context, autor.conMinuto(elegido.minuto));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.titulo,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const ValueKey('campo-minuto'),
                controller: _minuto,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                decoration: InputDecoration(
                  labelText: widget.etiquetaMinuto,
                  errorText: _minutoInvalido ? widget.errorMinuto : null,
                  counterText: '',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (widget.convocados.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  widget.sinJugadores,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            for (final jugador in widget.convocados)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    jugador.dorsal?.toString() ?? '-',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(jugador.nombre),
                onTap: () => _elegir(_AutorGol.jugador(jugador.jugadorId)),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(widget.otro),
              onTap: () async {
                if (_minutoElegido() == null) return;

                final autor = await widget.alElegirOtro();

                if (autor != null && mounted) {
                  _elegir(autor);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer_outlined),
              title: Text(widget.propiaPuerta),
              onTap: () =>
                  _elegir(const _AutorGol.texto(EstadoPartidoEnVivo.propiaPuerta)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo con el campo "Minuto": para confirmar un gol en contra (con [mensaje]) o
/// para corregir el minuto de un gol ([obligatorio]). Devuelve `(minuto: n)`, con n
/// null si se deja vacío (lo calcula el servidor), o null si se cancela.
class _DialogoMinuto extends StatefulWidget {
  final String titulo;
  final String? mensaje;
  final int? minutoInicial;
  final String textoConfirmar;
  final bool obligatorio;

  const _DialogoMinuto({
    required this.titulo,
    this.mensaje,
    required this.minutoInicial,
    required this.textoConfirmar,
    this.obligatorio = false,
  });

  @override
  State<_DialogoMinuto> createState() => _DialogoMinutoState();
}

class _DialogoMinutoState extends State<_DialogoMinuto> {
  late final TextEditingController _controlador = TextEditingController(
    text: widget.minutoInicial?.toString() ?? '',
  );

  bool _invalido = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final lectura = _leerMinuto(_controlador.text);

    if (!lectura.valido || (widget.obligatorio && lectura.minuto == null)) {
      setState(() => _invalido = true);
      return;
    }

    Navigator.pop(context, (minuto: lectura.minuto));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mensaje != null) ...[
            Text(widget.mensaje!),
            const SizedBox(height: 14),
          ],
          TextField(
            key: const ValueKey('campo-minuto'),
            controller: _controlador,
            autofocus: widget.mensaje == null,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            decoration: InputDecoration(
              labelText: t.liveMinuteLabel,
              errorText: _invalido ? t.liveMinuteInvalid : null,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(onPressed: _confirmar, child: Text(widget.textoConfirmar)),
      ],
    );
  }
}

/// Diálogo de "Otro…": el controlador es suyo, así que se libera cuando el
/// diálogo ya ha terminado de cerrarse.
class _DialogoAutorLibre extends StatefulWidget {
  const _DialogoAutorLibre();

  @override
  State<_DialogoAutorLibre> createState() => _DialogoAutorLibreState();
}

class _DialogoAutorLibreState extends State<_DialogoAutorLibre> {
  final TextEditingController _controlador = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.liveGoalOther),
      content: TextField(
        controller: _controlador,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(
          labelText: t.liveGoalOtherLabel,
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            final valor = _controlador.text.trim();

            if (valor.isEmpty) {
              setState(() => _error = t.liveEnterGoalAuthorError);
              return;
            }

            Navigator.pop(context, valor);
          },
          child: Text(t.send),
        ),
      ],
    );
  }
}
