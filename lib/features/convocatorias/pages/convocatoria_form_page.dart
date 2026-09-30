import 'package:flutter/material.dart';

import '../../../core/utils/fecha_visualizacion.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/models/perfil_app.dart';
import '../../matches/models/match_model.dart';
import '../../matches/services/match_service.dart';
import '../../teams/models/player_model.dart';
import '../../teams/services/team_services.dart';
import '../model/convocatoria_model.dart';
import '../services/convocatoria_service.dart';

class ConvocatoriaFormPage extends StatefulWidget {
  final PerfilEquipo equipo;
  final ConvocatoriaModel? convocatoria;

  const ConvocatoriaFormPage({
    super.key,
    required this.equipo,
    this.convocatoria,
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
  final TeamService _teamService = TeamService();
  final MatchService _matchService = MatchService();
  final ConvocatoriaService _convocatoriaService = ConvocatoriaService();

  final TextEditingController _lugarController = TextEditingController();

  late Future<_DatosFormulario> _futureDatos;

  /// Partido elegido para la convocatoria. La convocatoria SIEMPRE se
  /// crea/edita a partir de un partido ya existente: rival/campo/fecha/
  /// hora del partido ya NO se pueden escribir a mano, se muestran de
  /// solo lectura una vez elegido el partido (se leen en vivo del
  /// partido, nunca se duplican en la convocatoria).
  MatchModel? _partidoSeleccionado;

  TimeOfDay _horaConvocatoria = const TimeOfDay(hour: 17, minute: 0);

  final Set<int> _jugadoresSeleccionados = {};

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  bool get _esEdicion => widget.convocatoria != null;

  @override
  void initState() {
    super.initState();

    _futureDatos = _cargarDatos();
  }

  Future<_DatosFormulario> _cargarDatos() async {
    final resultados = await Future.wait([
      _teamService.obtenerJugadores(widget.equipo.id),
      _matchService.obtenerPartidosSinConvocatoria(
        widget.equipo.id,
        incluirPartidoId: widget.convocatoria?.partidoId,
      ),
    ]);

    return _DatosFormulario(
      resultados[0] as List<PlayerModel>,
      resultados[1] as List<MatchModel>,
    );
  }

  void _cargarConvocatoria(List<MatchModel> partidos) {
    final convocatoria = widget.convocatoria!;

    _lugarController.text = convocatoria.lugarConvocatoria;

    _horaConvocatoria = _parsearHora(convocatoria.horaConvocatoria);

    _jugadoresSeleccionados.addAll(
      convocatoria.jugadores.map((jugador) => jugador.jugadorId),
    );

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
      diaFormateado: convocatoria.fechaPartido,
    );

    _partidoSeleccionado = partido;
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
    if (_esEdicion) return;

    setState(() {
      if (_jugadoresSeleccionados.contains(jugadorId)) {
        _jugadoresSeleccionados.remove(jugadorId);
      } else {
        _jugadoresSeleccionados.add(jugadorId);
      }
    });
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
          ],
        ),
      ),
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
        });
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
          _construirFilaInfo(Icons.stadium_outlined, _t.fieldLabelCampo, partido.campo),
          const SizedBox(height: 6),
          _construirFilaInfo(
            Icons.calendar_today_outlined,
            _t.matchDateLabel,
            _formatearFechaPartido(partido),
          ),
          const SizedBox(height: 6),
          _construirFilaInfo(Icons.access_time, _t.matchTimeLabel, partido.hora),
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
          _esEdicion
              ? _t.notModifiable
              : _t.selectedCountLabel(_jugadoresSeleccionados.length),
          style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _construirJugador(PlayerModel jugador) {
    final seleccionado = _jugadoresSeleccionados.contains(jugador.id);
    final bloqueado = _esEdicion;

    final nombre = '${jugador.nombre} ${jugador.apellidos}'.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: bloqueado
          ? _colors.surfaceContainerHighest
          : (seleccionado ? _colors.primaryContainer : _colors.surface),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: seleccionado
              ? (bloqueado ? _colors.onSurfaceVariant : _colors.primary)
              : _colors.onSurfaceVariant,
          width: seleccionado ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: bloqueado ? null : () => _alternarJugador(jugador.id),
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
                child: Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _colors.onSurface,
                  ),
                ),
              ),
              Icon(
                seleccionado
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: seleccionado
                    ? _colors.primary
                    : _colors.onSurfaceVariant,
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

    if (!_esEdicion && _jugadoresSeleccionados.isEmpty) {
      _mostrarMensaje(_t.selectAtLeastOnePlayerError);
      return;
    }

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
        );
      } else {
        await _convocatoriaService.crear(
          partidoId: partido.id!,
          horaConvocatoria: horaConvocatoria,
          lugarConvocatoria: _lugarController.text.trim(),
          jugadoresIds: _jugadoresSeleccionados.toList(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? _t.callupUpdatedSuccess
                : _t.callupCreatedSuccess,
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

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
