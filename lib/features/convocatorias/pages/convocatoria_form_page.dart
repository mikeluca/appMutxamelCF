import 'package:flutter/material.dart';

import '../../../core/utils/backend_date.dart';
import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../invitados/models/invitacion_model.dart';
import '../../invitados/pages/elegir_invitados_page.dart';
import '../../invitados/services/invitados_service.dart';
import '../../invitados/widgets/invitado_widgets.dart';
import '../../invitados/widgets/invitados_seccion.dart';
import '../../matches/models/match_model.dart';
import '../../matches/services/justificacion_partido_service.dart';
import '../../matches/services/match_service.dart';
import '../../teams/models/player_model.dart';
import '../../teams/services/team_services.dart';
import '../model/convocatoria_model.dart';
import '../model/equipacion_model.dart';
import '../services/convocatoria_service.dart';
import '../services/equipacion_service.dart';
import '../widgets/equipaje_widgets.dart';

class ConvocatoriaFormPage extends StatefulWidget {
  final PerfilEquipo equipo;
  final ConvocatoriaModel? convocatoria;

  /// Partido que se deja elegido al crear una convocatoria nueva (si sigue sin
  /// convocatoria).
  final int? partidoIdInicial;

  /// Solo para tests: sustituyen a los servicios reales.
  final TeamService? teamService;
  final MatchService? matchService;
  final ConvocatoriaService? convocatoriaService;
  final JustificacionPartidoService? justificacionService;
  final InvitadosService? invitadosService;
  final EquipacionService? equipacionService;

  const ConvocatoriaFormPage({
    super.key,
    required this.equipo,
    this.convocatoria,
    this.partidoIdInicial,
    this.teamService,
    this.matchService,
    this.convocatoriaService,
    this.justificacionService,
    this.invitadosService,
    this.equipacionService,
  });

  @override
  State<ConvocatoriaFormPage> createState() => _ConvocatoriaFormPageState();
}

/// Datos necesarios para pintar el formulario: los jugadores del equipo y
/// los partidos que se pueden elegir para la convocatoria. Se cargan
/// juntos con Future.wait para poder mostrar un único loader.
class _DatosFormulario {
  final List<PlayerModel> jugadores;
  final List<MatchModel> partidos;

  _DatosFormulario(this.jugadores, this.partidos);
}

class _ConvocatoriaFormPageState extends State<ConvocatoriaFormPage> {
  late final TeamService _teamService = widget.teamService ?? TeamService();
  late final MatchService _matchService = widget.matchService ?? MatchService();
  late final ConvocatoriaService _convocatoriaService =
      widget.convocatoriaService ?? ConvocatoriaService();
  late final JustificacionPartidoService _justificacionService =
      widget.justificacionService ?? JustificacionPartidoService();
  late final EquipacionService _equipacionService =
      widget.equipacionService ?? EquipacionService();

  final TextEditingController _lugarController = TextEditingController();

  late Future<_DatosFormulario> _futureDatos;

  /// Partido elegido para la convocatoria. La convocatoria SIEMPRE se
  /// crea/edita a partir de un partido ya existente: rival/campo/fecha/
  /// hora del partido ya NO se pueden escribir a mano, se muestran de
  /// solo lectura una vez elegido el partido (se leen en vivo del
  /// partido, nunca se duplican en la convocatoria).
  MatchModel? _partidoSeleccionado;

  bool _partidoInicialAplicado = false;

  TimeOfDay _horaConvocatoria = const TimeOfDay(hour: 17, minute: 0);

  final Set<int> _jugadoresSeleccionados = {};

  /// Jugadores de otros equipos de la convocatoria, incluidos los que coordinación ha
  /// rechazado (se muestran con su estado; al guardar no se envían, así que quedan
  /// quitados).
  List<InvitadoElegido> _invitados = [];

  /// Los equipajes activos del club. Vacío si el club no ha dado de alta ninguno (o si no
  /// se han podido cargar: el formulario sigue funcionando y conserva el equipaje que
  /// tuviera la convocatoria).
  List<EquipacionModel> _equipajes = [];

  /// Equipaje elegido, con el que van vestidos al partido; null = sin indicar.
  int? _equipacionId;

  /// "Llevar también en la mochila" y el equipaje elegido para ella.
  bool _usarMochila = false;
  int? _mochilaId;

  /// Nombre de cada jugador del equipo, para nombrarlo en el diálogo de un 409.
  final Map<int, String> _nombresJugadores = {};

  /// Jugadores que han justificado su ausencia al partido elegido (id -> motivo).
  /// No se pueden añadir a la convocatoria; uno que ya estaba convocado sí se
  /// puede quitar.
  Map<int, String> _ausencias = {};

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  bool get _esEdicion => widget.convocatoria != null;

  @override
  void initState() {
    super.initState();

    _futureDatos = _cargarDatos();
  }

  /// Pide al servidor quién ha justificado su ausencia a [partidoId]. Si falla
  /// (o el partido cambió mientras tanto), el formulario sigue sin ese aviso:
  /// el servidor rechaza igualmente al guardar a un jugador justificado.
  Future<void> _cargarAusencias(int? partidoId) async {
    if (partidoId == null) {
      return;
    }

    Map<int, String> ausencias;

    try {
      final lista = await _justificacionService.obtener(partidoId);

      ausencias = {for (final a in lista) a.jugadorId: a.motivo};
    } catch (_) {
      ausencias = {};
    }

    if (!mounted || _partidoSeleccionado?.id != partidoId) return;

    setState(() {
      _ausencias = ausencias;

      // Al cambiar de partido, quien está justificado en el nuevo y todavía no
      // estaba convocado deja de estar marcado.
      _jugadoresSeleccionados.removeWhere(
        (id) => ausencias.containsKey(id) && _convocado(id) == null,
      );
    });
  }

  /// Los equipajes del club. Si no se pueden cargar el formulario sigue sin la sección
  /// de equipaje (y conserva el que tuviera la convocatoria): no es un motivo para
  /// impedir convocar.
  Future<List<EquipacionModel>> _cargarEquipajes() async {
    try {
      return await _equipacionService.obtenerActivas();
    } catch (_) {
      return [];
    }
  }

  Future<_DatosFormulario> _cargarDatos() async {
    final resultados = await Future.wait([
      _teamService.obtenerJugadores(widget.equipo.id),
      _matchService.obtenerPartidosSinConvocatoria(
        widget.equipo.id,
        incluirPartidoId:
            widget.convocatoria?.partidoId ?? widget.partidoIdInicial,
      ),
      _cargarEquipajes(),
    ]);

    _equipajes = resultados[2] as List<EquipacionModel>;

    final jugadores = resultados[0] as List<PlayerModel>;

    for (final jugador in jugadores) {
      _nombresJugadores[jugador.id] = '${jugador.nombre} ${jugador.apellidos}'
          .trim();
    }

    return _DatosFormulario(jugadores, resultados[1] as List<MatchModel>);
  }

  void _cargarConvocatoria(List<MatchModel> partidos) {
    final convocatoria = widget.convocatoria!;

    _lugarController.text = convocatoria.lugarConvocatoria;

    _horaConvocatoria = _parsearHora(convocatoria.horaConvocatoria);

    // Solo los del propio equipo: los invitados de otros equipos van aparte.
    _jugadoresSeleccionados.addAll(
      convocatoria.propios.map((jugador) => jugador.jugadorId),
    );

    _invitados = convocatoria.invitadosParaFormulario;

    _equipacionId = convocatoria.equipacion?.id;
    _mochilaId = convocatoria.equipacionMochila?.id;
    _usarMochila = _equipacionId != null && _mochilaId != null;

    MatchModel? partido;

    for (final candidato in partidos) {
      if (candidato.id == convocatoria.partidoId) {
        partido = candidato;
        break;
      }
    }

    // El endpoint de partidos-sin-convocatoria siempre incluye, aparte,
    // el partido ya vinculado (incluirPartidoId), así que en condiciones
    // normales `partido` no debería ser null. Por robustez, si no
    // apareciera se construye uno mínimo con los datos ya conocidos
    // (leídos en vivo por el backend en la respuesta de la convocatoria).
    partido ??= MatchModel(
      id: convocatoria.partidoId,
      equipoId: convocatoria.equipoId,
      categoria: '',
      equipo: convocatoria.equipo,
      rival: convocatoria.rival,
      campo: convocatoria.campo,
      hora: convocatoria.horaPartido,
      dia: parseFechaTextoBackend(convocatoria.fechaPartido),
      diaFormateado: convocatoria.fechaPartido,
    );

    _partidoSeleccionado = partido;

    _cargarAusencias(partido.id);
  }

  /// Una sola vez: deja elegido el partido con el que se abrió el formulario
  /// (desde el panel de coordinación), si sigue sin convocatoria.
  void _aplicarPartidoInicial(List<MatchModel> partidos) {
    _partidoInicialAplicado = true;

    final id = widget.partidoIdInicial;

    if (id == null) return;

    for (final partido in partidos) {
      if (partido.id == id) {
        if (_admiteConvocatoria(partido)) {
          _partidoSeleccionado = partido;
          _cargarAusencias(partido.id);
          return;
        }

        break;
      }
    }

    // Aunque se pidió con incluirPartidoId, el partido no vino o ya no admite convocatoria
    // (cancelado, pasado o con convocatoria): no se selecciona.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.callupMatchUnavailable)));
    });
  }

  /// Un partido admite convocatoria si no está cancelado, no es anterior a hoy y todavía no
  /// tiene una (el servidor lo vuelve a comprobar al guardar).
  bool _admiteConvocatoria(MatchModel partido) {
    if (partido.cancelado || partido.tieneConvocatoria == true) return false;

    final dia = partido.dia;

    if (dia == null) return true;

    final ahora = DateTime.now();

    return !DateTime(
      dia.year,
      dia.month,
      dia.day,
    ).isBefore(DateTime(ahora.year, ahora.month, ahora.day));
  }

  /// Se calcula a partir de partido.dia (en vez de usar diaFormateado tal
  /// cual llega del backend) para poder anteponer el nombre del día y
  /// respetar el idioma activo; diaFormateado queda como respaldo para el
  /// MatchModel mínimo que se construye si el partido no aparece en la
  /// lista (ver arriba).
  String? _formatearFechaPartido(MatchModel partido) {
    return partido.dia != null
        ? formatearFechaConDiaSemana(partido.dia!, _t)
        : partido.diaFormateado;
  }

  TimeOfDay _parsearHora(String hora) {
    final partes = hora.split(':');

    if (partes.length < 2) {
      return const TimeOfDay(hour: 18, minute: 0);
    }

    return TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 18,
      minute: int.tryParse(partes[1]) ?? 0,
    );
  }

  @override
  void dispose() {
    _lugarController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHoraConvocatoria() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaConvocatoria,
    );

    if (hora == null) return;

    setState(() {
      _horaConvocatoria = hora;
    });
  }

  void _alternarJugador(int jugadorId) {
    // Uno con ausencia justificada no se puede marcar; si ya estaba marcado, sí
    // se puede quitar.
    if (_ausencias.containsKey(jugadorId) &&
        !_jugadoresSeleccionados.contains(jugadorId)) {
      return;
    }

    setState(() {
      if (_jugadoresSeleccionados.contains(jugadorId)) {
        _jugadoresSeleccionados.remove(jugadorId);
      } else {
        _jugadoresSeleccionados.add(jugadorId);
      }
    });
  }

  /// Los invitados que se envían al guardar: todos menos los rechazados.
  List<int> get _invitadosIds =>
      _invitados.where((i) => !i.rechazado).map((i) => i.jugadorId).toList();

  Future<void> _anadirInvitados() async {
    final partidoId = _partidoSeleccionado?.id;

    if (partidoId == null) return;

    final elegidos = await Navigator.push<List<InvitadoElegido>>(
      context,
      MaterialPageRoute(
        builder: (_) => ElegirInvitadosPage(
          partidoId: partidoId,
          seleccion: _invitados.where((i) => !i.rechazado).toList(),
          service: widget.invitadosService,
        ),
      ),
    );

    if (elegidos == null || !mounted) return;

    final idsElegidos = elegidos.map((i) => i.jugadorId).toSet();

    setState(() {
      // Los rechazados que no se han vuelto a elegir se quedan a la vista.
      _invitados = [
        ..._invitados.where(
          (i) => i.rechazado && !idsElegidos.contains(i.jugadorId),
        ),
        ...elegidos,
      ];
    });
  }

  void _quitarInvitado(InvitadoElegido invitado) {
    setState(
      () => _invitados.removeWhere((i) => i.jugadorId == invitado.jugadorId),
    );
  }

  /// El nombre del jugador del 409, de los jugadores del equipo o de los invitados.
  String _nombreDeJugador(int? jugadorId) {
    if (jugadorId == null) return '';

    return _nombresJugadores[jugadorId] ??
        _invitados.where((i) => i.jugadorId == jugadorId).firstOrNull?.nombre ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(
          titulo: _esEdicion ? _t.editCallupTitle : _t.newCallupTitle,
        ),
      ),
      body: FutureBuilder<_DatosFormulario>(
        future: _futureDatos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _construirError(snapshot.error);
          }

          final datos = snapshot.data!;
          final jugadores = datos.jugadores;
          final partidos = datos.partidos;

          if (_esEdicion && _partidoSeleccionado == null) {
            _cargarConvocatoria(partidos);
          } else if (!_esEdicion &&
              _partidoSeleccionado == null &&
              !_partidoInicialAplicado) {
            _aplicarPartidoInicial(partidos);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    _construirDatosPartido(partidos),
                    const SizedBox(height: 24),
                    _construirTituloJugadores(),
                    const SizedBox(height: 12),
                    if (jugadores.isEmpty)
                      _construirSinJugadores()
                    else
                      ...jugadores.map(_construirJugador),
                    const SizedBox(height: 24),
                    InvitadosSeccion(
                      invitados: _invitados,
                      hayPartido: _partidoSeleccionado?.id != null,
                      onAnadir: _anadirInvitados,
                      onQuitar: _quitarInvitado,
                    ),
                  ],
                ),
              ),
              _construirBotonGuardar(),
            ],
          );
        },
      ),
    );
  }

  Widget _construirDatosPartido(List<MatchModel> partidos) {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.equipo.nombre,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            if (partidos.isEmpty && _partidoSeleccionado == null)
              _construirSinPartidos()
            else
              _construirSelectorPartido(partidos),
            if (_partidoSeleccionado != null) ...[
              const SizedBox(height: 14),
              _construirDatosPartidoSeleccionado(_partidoSeleccionado!),
            ],
            const SizedBox(height: 14),
            _construirSelectorHora(
              titulo: _t.callupTimeLabel,
              hora: _horaConvocatoria,
              onTap: _seleccionarHoraConvocatoria,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _lugarController,
              decoration: InputDecoration(
                labelText: _t.callupPlaceLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 18),
            _construirEquipaje(),
          ],
        ),
      ),
    );
  }

  /// Los equipajes que se pueden elegir: los activos del club y, al editar, los que la
  /// convocatoria ya tiene aunque se hayan desactivado después (el servidor los admite).
  List<EquipacionModel> get _opcionesEquipaje {
    final opciones = [..._equipajes];

    for (final actual in [
      widget.convocatoria?.equipacion,
      widget.convocatoria?.equipacionMochila,
    ]) {
      if (actual != null && !opciones.any((o) => o.id == actual.id)) {
        opciones.add(actual);
      }
    }

    return opciones;
  }

  EquipacionModel? _equipajePorId(int? id) =>
      _opcionesEquipaje.where((e) => e.id == id).firstOrNull;

  void _elegirEquipaje(int? id) {
    setState(() {
      _equipacionId = id;

      // La mochila exige equipaje principal y distinto de él.
      if (id == null) {
        _usarMochila = false;
        _mochilaId = null;
      } else if (_mochilaId == id) {
        _mochilaId = null;
      }
    });
  }

  Widget _construirEquipaje() {
    if (_equipajes.isEmpty) {
      return Text(
        _t.callupKitEmpty,
        key: const ValueKey('equipaje-vacio'),
        style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
      );
    }

    final opciones = _opcionesEquipaje;
    final principal = _equipajePorId(_equipacionId);
    final detalle = principal == null
        ? null
        : detalleEquipacion(_t, principal);
    final hayPrincipal = principal != null;
    final mochila = _equipajePorId(_mochilaId);
    final detalleMochila = mochila == null
        ? null
        : detalleEquipacion(_t, mochila);

    return Column(
      key: const ValueKey('equipaje-seccion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t.callupKitSection,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(
          key: ValueKey('equipaje-selector-$_equipacionId'),
          initialValue: principal?.id,
          decoration: InputDecoration(
            labelText: _t.callupKitSelectorLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.checkroom_outlined),
          ),
          isExpanded: true,
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(_t.callupKitNone)),
            ...opciones.map(
              (e) => DropdownMenuItem<int?>(
                value: e.id,
                child: OpcionEquipaje(equipacion: e),
              ),
            ),
          ],
          onChanged: _elegirEquipaje,
        ),
        if (detalle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              detalle,
              key: const ValueKey('equipaje-detalle'),
              style: TextStyle(fontSize: 13, color: _colors.onSurfaceVariant),
            ),
          ),
        CheckboxListTile(
          key: const ValueKey('equipaje-mochila-casilla'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(_t.callupKitBackpackCheck),
          value: hayPrincipal && _usarMochila,
          onChanged: hayPrincipal
              ? (marcada) => setState(() {
                  _usarMochila = marcada ?? false;

                  if (!_usarMochila) _mochilaId = null;
                })
              : null,
        ),
        if (hayPrincipal && _usarMochila) ...[
          DropdownButtonFormField<int>(
            key: ValueKey('equipaje-mochila-selector-$_mochilaId-$_equipacionId'),
            initialValue: mochila?.id,
            decoration: InputDecoration(
              labelText: _t.callupKitBackpackLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.backpack_outlined),
            ),
            isExpanded: true,
            items: opciones
                .where((e) => e.id != _equipacionId)
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e.id,
                    child: OpcionEquipaje(equipacion: e),
                  ),
                )
                .toList(),
            onChanged: (id) => setState(() => _mochilaId = id),
          ),
          if (detalleMochila != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                detalleMochila,
                key: const ValueKey('equipaje-mochila-detalle'),
                style: TextStyle(fontSize: 13, color: _colors.onSurfaceVariant),
              ),
            ),
        ],
      ],
    );
  }

  Widget _construirSinPartidos() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _t.noMatchesAvailableForCallup,
        style: TextStyle(color: _colors.onSurfaceVariant),
      ),
    );
  }

  Widget _construirSelectorPartido(List<MatchModel> partidos) {
    final idSeleccionado = _partidoSeleccionado?.id;

    // Si el partido actualmente seleccionado no está en la lista (por
    // ejemplo, tras recargar), evita que el Dropdown reciba un value sin
    // item asociado.
    final hayValorValido =
        idSeleccionado != null &&
        partidos.any((partido) => partido.id == idSeleccionado);

    return DropdownButtonFormField<int>(
      initialValue: hayValorValido ? idSeleccionado : null,
      decoration: InputDecoration(
        labelText: _t.selectMatchLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.sports_soccer),
      ),
      hint: Text(_t.selectMatchHint),
      isExpanded: true,
      items: partidos
          .map(
            (partido) => DropdownMenuItem<int>(
              value: partido.id,
              child: Text(
                '${partido.rival}'
                '${_formatearFechaPartido(partido)?.isNotEmpty == true ? ' — ${_formatearFechaPartido(partido)}' : ''}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (id) {
        setState(() {
          _partidoSeleccionado = partidos.firstWhere(
            (partido) => partido.id == id,
          );
          _ausencias = {};
        });

        _cargarAusencias(id);
      },
    );
  }

  Widget _construirDatosPartidoSeleccionado(MatchModel partido) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirFilaInfo(
            Icons.stadium_outlined,
            _t.fieldLabelCampo,
            partido.campo,
          ),
          const SizedBox(height: 6),
          _construirFilaInfo(
            Icons.calendar_today_outlined,
            _t.matchDateLabel,
            _formatearFechaPartido(partido),
          ),
          const SizedBox(height: 6),
          _construirFilaInfo(
            Icons.access_time,
            _t.matchTimeLabel,
            partido.hora,
          ),
        ],
      ),
    );
  }

  Widget _construirFilaInfo(IconData icono, String titulo, String? valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: _colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$titulo: ${(valor == null || valor.isEmpty) ? '-' : valor}',
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _construirSelectorHora({
    required String titulo,
    required TimeOfDay hora,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: titulo,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(hora.format(context), style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _construirTituloJugadores() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _t.callupPlayersTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
        ),
        Text(
          _t.selectedCountLabel(_jugadoresSeleccionados.length),
          style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
        ),
      ],
    );
  }

  /// El convocado con ese id en la convocatoria que se está editando.
  ConvocatoriaJugadorModel? _convocado(int jugadorId) {
    return widget.convocatoria?.jugadores
        .where((j) => j.jugadorId == jugadorId)
        .firstOrNull;
  }

  Widget _construirJugador(PlayerModel jugador) {
    final seleccionado = _jugadoresSeleccionados.contains(jugador.id);
    final motivoAusencia = _ausencias[jugador.id];
    final ausente = motivoAusencia != null;

    // Con ausencia justificada no se puede marcar; si ya estaba convocado, sí
    // se puede quitar.
    final deshabilitado = ausente && !seleccionado;

    final nombre = '${jugador.nombre} ${jugador.apellidos}'.trim();

    return Card(
      key: ValueKey('jugador-convocatoria-${jugador.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      color: deshabilitado
          ? _colors.surfaceContainerHighest
          : (seleccionado ? _colors.primaryContainer : _colors.surface),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: ausente
              ? Colors.redAccent
              : (seleccionado ? _colors.primary : _colors.onSurfaceVariant),
          width: seleccionado || ausente ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: deshabilitado ? null : () => _alternarJugador(jugador.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _colors.surfaceContainerHighest,
                child: Text(
                  jugador.nombre.isNotEmpty
                      ? jugador.nombre[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: deshabilitado
                            ? _colors.onSurfaceVariant
                            : _colors.onSurface,
                      ),
                    ),
                    if (ausente) ...[
                      const SizedBox(height: 3),
                      Text(
                        _t.matchAbsenceBadge,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      if (motivoAusencia.trim().isNotEmpty)
                        Text(
                          _t.callupReasonShown(motivoAusencia),
                          style: TextStyle(
                            fontSize: 13,
                            color: _colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Icon(
                deshabilitado
                    ? Icons.block
                    : (seleccionado
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked),
                color: deshabilitado
                    ? _colors.onSurfaceVariant
                    : (seleccionado
                          ? _colors.primary
                          : _colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBotonGuardar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              _esEdicion ? _t.saveChangesButton : _t.saveCallupButton,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final partido = _partidoSeleccionado;

    if (partido == null || partido.id == null) {
      _mostrarMensaje(_t.selectMatchError);
      return;
    }

    if (_lugarController.text.trim().isEmpty) {
      _mostrarMensaje(_t.enterCallupPlaceError);
      return;
    }

    if (_jugadoresSeleccionados.isEmpty) {
      _mostrarMensaje(_t.selectAtLeastOnePlayerError);
      return;
    }

    // Con la casilla de la mochila marcada hay que elegir su equipaje.
    if (_equipacionId != null && _usarMochila && _mochilaId == null) {
      _mostrarMensaje(_t.callupKitBackpackMissing);
      return;
    }

    final equipacionId = _equipacionId;
    final mochilaId = equipacionId != null && _usarMochila ? _mochilaId : null;

    try {
      final horaConvocatoria =
          '${_horaConvocatoria.hour.toString().padLeft(2, '0')}:'
          '${_horaConvocatoria.minute.toString().padLeft(2, '0')}';

      if (_esEdicion) {
        await _convocatoriaService.actualizar(
          convocatoriaId: widget.convocatoria!.id,
          partidoId: partido.id!,
          horaConvocatoria: horaConvocatoria,
          lugarConvocatoria: _lugarController.text.trim(),
          jugadoresIds: _jugadoresSeleccionados.toList(),
          invitadosIds: _invitadosIds,
          equipacionId: equipacionId,
          equipacionMochilaId: mochilaId,
          indicarEquipaje: true,
        );
      } else {
        await _convocatoriaService.crear(
          partidoId: partido.id!,
          horaConvocatoria: horaConvocatoria,
          lugarConvocatoria: _lugarController.text.trim(),
          jugadoresIds: _jugadoresSeleccionados.toList(),
          invitadosIds: _invitadosIds,
          equipacionId: equipacionId,
          equipacionMochilaId: mochilaId,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion ? _t.callupUpdatedSuccess : _t.callupCreatedSuccess,
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      // Un jugador que ese día ya va invitado con otro equipo: se explica con su nombre
      // y el equipo, sin depender del texto del servidor.
      final conflicto = ConflictoInvitacion.desde(e);

      if (conflicto != null) {
        await mostrarConflictoInvitacion(
          context,
          conflicto,
          jugador: _nombreDeJugador(conflicto.jugadorId),
        );
        return;
      }

      _mostrarMensaje(
        _esEdicion
            ? _t.callupUpdateError(e.toString())
            : _t.callupCreateError(e.toString()),
      );
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Widget _construirSinJugadores() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _t.noPlayersAvailableForTeam,
          textAlign: TextAlign.center,
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _construirError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _t.playersLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
