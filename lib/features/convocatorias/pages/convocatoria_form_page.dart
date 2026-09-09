import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../auth/models/perfil_app.dart';
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

class _ConvocatoriaFormPageState extends State<ConvocatoriaFormPage> {
  final TeamService _teamService = TeamService();
  final ConvocatoriaService _convocatoriaService = ConvocatoriaService();

  final TextEditingController _rivalController = TextEditingController();

  final TextEditingController _campoController = TextEditingController();

  final TextEditingController _lugarController = TextEditingController();

  late Future<List<PlayerModel>> _futureJugadores;

  DateTime _fechaPartido = DateTime.now();

  TimeOfDay _horaPartido = const TimeOfDay(hour: 18, minute: 0);

  TimeOfDay _horaConvocatoria = const TimeOfDay(hour: 17, minute: 0);

  final Set<int> _jugadoresSeleccionados = {};

  ColorScheme get _colors => Theme.of(context).colorScheme;

  bool get _esEdicion => widget.convocatoria != null;

  @override
  void initState() {
    super.initState();

    _futureJugadores = _teamService.obtenerJugadores(widget.equipo.id);

    if (_esEdicion) {
      _cargarConvocatoria();
    }
  }

  void _cargarConvocatoria() {
    final convocatoria = widget.convocatoria!;

    _rivalController.text = convocatoria.rival;
    _campoController.text = convocatoria.campo;
    _lugarController.text = convocatoria.lugarConvocatoria;

    final match = RegExp(
      r'\[(\d+),\s*(\d+),\s*(\d+)\]',
    ).firstMatch(convocatoria.fechaPartido);

    if (match != null) {
      _fechaPartido = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }

    _horaPartido = _parsearHora(convocatoria.horaPartido);

    _horaConvocatoria = _parsearHora(convocatoria.horaConvocatoria);

    _jugadoresSeleccionados.addAll(
      convocatoria.jugadores.map((jugador) => jugador.jugadorId),
    );
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
    _rivalController.dispose();
    _campoController.dispose();
    _lugarController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaPartido,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) return;

    setState(() {
      _fechaPartido = fecha;
    });
  }

  Future<void> _seleccionarHoraPartido() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaPartido,
    );

    if (hora == null) return;

    setState(() {
      _horaPartido = hora;
    });
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
          titulo: _esEdicion ? 'Editar convocatoria' : 'Nueva convocatoria',
        ),
      ),
      body: FutureBuilder<List<PlayerModel>>(
        future: _futureJugadores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _construirError(snapshot.error);
          }

          final jugadores = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    _construirDatosPartido(),
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

  Widget _construirDatosPartido() {
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
            TextField(
              controller: _rivalController,
              decoration: const InputDecoration(
                labelText: 'Rival',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _campoController,
              decoration: const InputDecoration(
                labelText: 'Campo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.stadium_outlined),
              ),
            ),
            const SizedBox(height: 14),
            _construirSelectorFecha(),
            const SizedBox(height: 14),
            _construirSelectorHora(
              titulo: 'Hora del partido',
              hora: _horaPartido,
              onTap: _seleccionarHoraPartido,
            ),
            const SizedBox(height: 14),
            _construirSelectorHora(
              titulo: 'Hora de convocatoria',
              hora: _horaConvocatoria,
              onTap: _seleccionarHoraConvocatoria,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _lugarController,
              decoration: const InputDecoration(
                labelText: 'Lugar de convocatoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirSelectorFecha() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _seleccionarFecha,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha del partido',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          _formatearFechaVisible(_fechaPartido),
          style: const TextStyle(fontSize: 16),
        ),
      ),
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
            'Jugadores convocados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
        ),
        Text(
          _esEdicion
              ? 'No modificables'
              : '${_jugadoresSeleccionados.length} seleccionados',
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
              _esEdicion ? 'Guardar cambios' : 'Guardar convocatoria',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_rivalController.text.trim().isEmpty) {
      _mostrarMensaje('Introduce el rival.');
      return;
    }

    if (_campoController.text.trim().isEmpty) {
      _mostrarMensaje('Introduce el campo.');
      return;
    }

    if (_lugarController.text.trim().isEmpty) {
      _mostrarMensaje('Introduce el lugar de convocatoria.');
      return;
    }

    if (_jugadoresSeleccionados.isEmpty) {
      _mostrarMensaje('Selecciona al menos un jugador.');
      return;
    }

    try {
      final fechaPartido =
          '${_fechaPartido.year}-'
          '${_fechaPartido.month.toString().padLeft(2, '0')}-'
          '${_fechaPartido.day.toString().padLeft(2, '0')}';

      final horaPartido =
          '${_horaPartido.hour.toString().padLeft(2, '0')}:'
          '${_horaPartido.minute.toString().padLeft(2, '0')}';

      final horaConvocatoria =
          '${_horaConvocatoria.hour.toString().padLeft(2, '0')}:'
          '${_horaConvocatoria.minute.toString().padLeft(2, '0')}';

      if (_esEdicion) {
        await _convocatoriaService.actualizar(
          convocatoriaId: widget.convocatoria!.id,
          equipoId: widget.equipo.id,
          rival: _rivalController.text.trim(),
          campo: _campoController.text.trim(),
          fechaPartido: fechaPartido,
          horaPartido: horaPartido,
          horaConvocatoria: horaConvocatoria,
          lugarConvocatoria: _lugarController.text.trim(),
        );
      } else {
        await _convocatoriaService.crear(
          equipoId: widget.equipo.id,
          rival: _rivalController.text.trim(),
          campo: _campoController.text.trim(),
          fechaPartido: fechaPartido,
          horaPartido: horaPartido,
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
                ? 'Convocatoria actualizada correctamente.'
                : 'Convocatoria creada correctamente.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        _esEdicion
            ? 'No se ha podido actualizar la convocatoria: $e'
            : 'No se ha podido crear la convocatoria: $e',
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
          'No hay jugadores disponibles para este equipo.',
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
              'No se han podido cargar los jugadores.',
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

  String _formatearFechaVisible(DateTime fecha) {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year.toString();

    return '$day/$month/$year';
  }
}
