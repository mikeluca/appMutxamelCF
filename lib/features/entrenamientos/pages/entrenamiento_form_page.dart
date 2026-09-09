import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../auth/models/perfil_app.dart';
import '../../teams/models/player_model.dart';
import '../../teams/services/team_services.dart';
import '../services/entrenamiento_service.dart';
import '../model/entrenamiento_model.dart';

class EntrenamientoFormPage extends StatefulWidget {
  final PerfilEquipo equipo;
  final EntrenamientoModel? entrenamiento;

  const EntrenamientoFormPage({
    super.key,
    required this.equipo,
    this.entrenamiento,
  });

  @override
  State<EntrenamientoFormPage> createState() => _EntrenamientoFormPageState();
}

class _EntrenamientoFormPageState extends State<EntrenamientoFormPage> {
  final TeamService _teamService = TeamService();
  final EntrenamientoService _entrenamientoService = EntrenamientoService();

  late Future<List<PlayerModel>> _futureJugadores;

  DateTime _fecha = DateTime.now();

  final Map<int, String> _estados = {};

  bool _guardando = false;
  bool get _esEdicion => widget.entrenamiento != null;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();

    _futureJugadores = _teamService.obtenerJugadores(widget.equipo.id);

    if (_esEdicion) {
      _cargarDatosEntrenamiento();
    }
  }

  void _cargarDatosEntrenamiento() {
    final entrenamiento = widget.entrenamiento!;

    final fecha = entrenamiento.fecha;

    final match = RegExp(r'\[(\d+),\s*(\d+),\s*(\d+)\]').firstMatch(fecha);

    if (match != null) {
      _fecha = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }

    for (final asistencia in entrenamiento.asistencias) {
      _estados[asistencia.jugadorId] = asistencia.estado;
    }
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha.isAfter(hoy) ? hoy : _fecha,
      firstDate: DateTime(2020),
      lastDate: hoy,
    );

    if (fecha == null) return;

    setState(() {
      _fecha = fecha;
    });
  }

  void _inicializarEstados(List<PlayerModel> jugadores) {
    for (final jugador in jugadores) {
      _estados.putIfAbsent(jugador.id, () => 'PRESENTE');
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PRESENTE':
        return const Color.fromARGB(255, 64, 236, 70);
      case 'FALTA_JUSTIFICADA':
        return const Color.fromARGB(255, 255, 230, 7);
      case 'FALTA':
        return const Color.fromARGB(255, 248, 26, 26);
      case 'MAL_COMPORTAMIENTO':
        return const Color.fromARGB(255, 105, 104, 104);
      case 'RETRASO':
        return const Color.fromARGB(255, 115, 23, 190);
      default:
        return Colors.green;
    }
  }

  Future<void> _guardar(List<PlayerModel> jugadores) async {
    if (_guardando) return;

    if (jugadores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay jugadores para registrar el entrenamiento.'),
        ),
      );
      return;
    }

    _inicializarEstados(jugadores);

    final hoy = DateTime.now();

    final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);

    final fechaSeleccionada = DateTime(_fecha.year, _fecha.month, _fecha.day);

    if (fechaSeleccionada.isAfter(fechaHoy)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha del entrenamiento no puede ser posterior a hoy.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final fecha = _formatearFechaApi(_fecha);

      if (_esEdicion) {
        await _entrenamientoService.actualizar(
          entrenamientoId: widget.entrenamiento!.id,
          equipoId: widget.equipo.id,
          fecha: fecha,
          asistencias: _estados,
        );
      } else {
        await _entrenamientoService.crear(
          equipoId: widget.equipo.id,
          fecha: fecha,
          asistencias: _estados,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Entrenamiento actualizado correctamente.'
                : 'Entrenamiento guardado correctamente.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se ha podido guardar: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(
          titulo: _esEdicion ? 'Editar entrenamiento' : 'Nuevo entrenamiento',
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
                    _construirCabecera(),
                    const SizedBox(height: 24),
                    _construirTituloJugadores(),
                    const SizedBox(height: 12),
                    if (jugadores.isEmpty)
                      _construirSinJugadores()
                    else
                      ...jugadores.map((jugador) => _construirJugador(jugador)),
                  ],
                ),
              ),
              _construirBotonGuardar(jugadores),
            ],
          );
        },
      ),
    );
  }

  Widget _construirCabecera() {
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
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: _colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha del entrenamiento',
                            style: TextStyle(
                              fontSize: 13,
                              color: _colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatearFechaVisible(_fecha),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _colors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTituloJugadores() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Asistencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _colors.onSurface,
            ),
          ),
        ),
        Text(
          'Marca el estado de cada jugador',
          style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _construirJugador(PlayerModel jugador) {
    final estadoActual = _estados[jugador.id] ?? 'PRESENTE';
    final colorEstado = _colorEstado(estadoActual);

    final nombre = '${jugador.nombre} ${jugador.apellidos}'.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: colorEstado.withValues(alpha: 0.25),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorEstado.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _colors.primaryContainer,
                  child: Text(
                    jugador.nombre.isNotEmpty
                        ? jugador.nombre[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: _colors.onPrimaryContainer,
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
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: estadoActual,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'PRESENTE', child: Text('Presente')),
                DropdownMenuItem(value: 'FALTA', child: Text('Falta')),
                DropdownMenuItem(value: 'RETRASO', child: Text('Retraso')),
                DropdownMenuItem(
                  value: 'FALTA_JUSTIFICADA',
                  child: Text('Falta justificada'),
                ),
                DropdownMenuItem(
                  value: 'MAL_COMPORTAMIENTO',
                  child: Text('Mal comportamiento'),
                ),
              ],
              onChanged: _guardando
                  ? null
                  : (valor) {
                      if (valor == null) return;

                      setState(() {
                        _estados[jugador.id] = valor;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotonGuardar(List<PlayerModel> jugadores) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _guardando ? null : () => _guardar(jugadores),
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _guardando
                  ? 'Guardando...'
                  : (_esEdicion ? 'Guardar cambios' : 'Guardar entrenamiento'),
            ),
          ),
        ),
      ),
    );
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

  String _formatearFechaApi(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatearFechaVisible(DateTime fecha) {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year.toString();

    return '$day/$month/$year';
  }
}
