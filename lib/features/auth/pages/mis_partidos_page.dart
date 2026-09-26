import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../matches/models/match_model.dart';
import '../../matches/services/match_service.dart';
import '../../matches/widgets/match_card.dart';
import '../models/perfil_app.dart';
import '../services/perfil_service.dart';

class MisPartidosPage extends StatefulWidget {
  const MisPartidosPage({super.key});

  @override
  State<MisPartidosPage> createState() => _MisPartidosPageState();
}

class _EquipoJugador {
  final String equipo;
  final String? jugador;
  final int? equipoId;
  final bool puedeGestionar;

  const _EquipoJugador({
    required this.equipo,
    this.jugador,
    this.equipoId,
    required this.puedeGestionar,
  });
}

class _MisPartidosPageState extends State<MisPartidosPage> {
  final MatchService _matchService = MatchService();

  PerfilApp? _perfil;
  List<MatchModel> _partidos = [];

  bool _cargando = true;
  String? _error;

  // Se incrementa en cada recarga para forzar que las secciones
  // del acordeón se reconstruyan desde cero (colapsadas).
  int _generacion = 0;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();

      // Se sigue usando para poder enumerar todos los equipos
      // existentes cuando el usuario tiene gestión global
      // (coordinador/administrador).
      final todosLosPartidos = await _matchService.obtenerResultados();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _partidos = todosLosPartidos;
        _cargando = false;
        _error = null;
        _generacion++;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esGestionGlobal =
        _perfil?.tieneRol('COORDINADOR') == true ||
        _perfil?.tieneRol('ADMIN_APP') == true;

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(
          titulo: esGestionGlobal ? _t.allMatchesTitle : _t.clubPageMyMatches,
        ),
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _construirError();
    }

    final equipos = _obtenerEquipos();

    if (equipos.isEmpty) {
      final esGestionGlobal =
          _perfil?.tieneRol('COORDINADOR') == true ||
          _perfil?.tieneRol('ADMIN_APP') == true;

      return RefreshIndicator(
        onRefresh: _cargarDatos,
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
            Center(
              child: Text(
                esGestionGlobal
                    ? _t.matchesNoMatchesAvailable
                    : _t.noTeamsAssociated,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: equipos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final equipoJugador = equipos[index];

          return _EquipoSeccion(
            // La clave incluye la generación para que, al recargar
            // (pull-to-refresh), las secciones se reconstruyan
            // colapsadas y sin datos en caché.
            key: ValueKey(
              '$_generacion-${equipoJugador.equipo}-'
              '${equipoJugador.jugador}-$index',
            ),
            matchService: _matchService,
            titulo: _tituloTexto(equipoJugador),
            equipoNombre: equipoJugador.equipo,
            equipoId: equipoJugador.equipoId,
            puedeGestionar: equipoJugador.puedeGestionar,
          );
        },
      ),
    );
  }

  List<_EquipoJugador> _obtenerEquipos() {
    final resultado = <_EquipoJugador>[];
    final equiposProcesados = <String>{};

    final perfil = _perfil;

    if (perfil == null) {
      return resultado;
    }

    final esGestionGlobal =
        perfil.tieneRol('COORDINADOR') || perfil.tieneRol('ADMIN_APP');

    if (esGestionGlobal) {
      // Coordinador y administrador ven todos los equipos que
      // aparecen en los partidos, y pueden gestionar cualquiera de
      // ellos (el backend ya lo permite vía
      // EquipoGestionDao.puedeGestionarEquipo). El id de equipo viene
      // directamente en cada partido; solo recurrimos a buscarlo en
      // perfil.equipos como último recurso si por lo que sea no
      // viniera informado.
      for (final partido in _partidos) {
        final equipo = partido.equipo.trim();

        if (equipo.isEmpty) {
          continue;
        }

        final clave = equipo.toUpperCase();

        if (equiposProcesados.add(clave)) {
          resultado.add(
            _EquipoJugador(
              equipo: equipo,
              equipoId: partido.equipoId ?? _buscarEquipoId(equipo),
              puedeGestionar: true,
            ),
          );
        }
      }

      return resultado;
    }

    // Para familiares/jugadores vinculados:
    // cada jugador mantiene su relación con su equipo.
    for (final jugador in perfil.jugadores) {
      final equipo = jugador.equipo;

      if (equipo == null || equipo.trim().isEmpty) {
        continue;
      }

      final clave = '${equipo.trim().toUpperCase()}|${jugador.id}';

      if (equiposProcesados.add(clave)) {
        final equipoId = _buscarEquipoId(equipo.trim());

        resultado.add(
          _EquipoJugador(
            equipo: equipo.trim(),
            jugador: jugador.nombreCompleto,
            equipoId: equipoId,
            // Solo puede gestionar este equipo si aparece entre
            // los equipos que entrena (perfil.equipos).
            puedeGestionar: equipoId != null,
          ),
        );
      }
    }

    // Equipos directos del perfil.
    // Se mantienen para entrenadores.
    for (final equipo in perfil.equipos) {
      if (equipo.nombre.trim().isEmpty) {
        continue;
      }

      final clave = equipo.nombre.trim().toUpperCase();

      if (equiposProcesados.add(clave)) {
        resultado.add(
          _EquipoJugador(
            equipo: equipo.nombre.trim(),
            equipoId: equipo.id,
            puedeGestionar: true,
          ),
        );
      }
    }

    return resultado;
  }

  /// Busca el id del equipo a partir de su nombre entre los equipos
  /// que gestiona el usuario (perfil.equipos). Devuelve null si el
  /// usuario no gestiona ese equipo o no se conoce su id.
  int? _buscarEquipoId(String equipoNombre) {
    final perfil = _perfil;

    if (perfil == null) {
      return null;
    }

    final clave = equipoNombre.trim().toUpperCase();

    for (final equipo in perfil.equipos) {
      if (equipo.nombre.trim().toUpperCase() == clave) {
        return equipo.id;
      }
    }

    return null;
  }

  String _tituloTexto(_EquipoJugador equipoJugador) {
    final tieneJugador =
        equipoJugador.jugador != null &&
        equipoJugador.jugador!.trim().isNotEmpty;

    return tieneJugador
        ? '${equipoJugador.equipo} - ${equipoJugador.jugador}'
        : equipoJugador.equipo;
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _t.matchesLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarDatos();
              },
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECCIÓN DE ACORDEÓN POR EQUIPO
// ============================================================

class _EquipoSeccion extends StatefulWidget {
  final MatchService matchService;
  final String titulo;
  final String equipoNombre;
  final int? equipoId;
  final bool puedeGestionar;

  const _EquipoSeccion({
    super.key,
    required this.matchService,
    required this.titulo,
    required this.equipoNombre,
    required this.equipoId,
    required this.puedeGestionar,
  });

  @override
  State<_EquipoSeccion> createState() => _EquipoSeccionState();
}

class _EquipoSeccionState extends State<_EquipoSeccion> {
  bool _cargando = false;
  bool _cargado = false;
  String? _error;
  List<MatchModel> _partidos = [];

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final equipoId = widget.equipoId;

      final partidos = equipoId != null
          ? await widget.matchService.obtenerUltimosPorEquipoId(equipoId)
          : await widget.matchService.obtenerUltimosPorEquipoNombre(
              widget.equipoNombre,
            );

      if (!mounted) return;

      setState(() {
        _partidos = partidos;
        _cargando = false;
        _cargado = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
        _cargado = true;
      });
    }
  }

  Future<void> _abrirFormulario({MatchModel? partidoExistente}) async {
    final equipoId = widget.equipoId;

    if (equipoId == null) return;

    // El diálogo devuelve 'guardado' (creación o edición), 'eliminado'
    // o null (si se canceló), para poder distinguir el mensaje a mostrar.
    final resultado = await showDialog<String>(
      context: context,
      builder: (_) => _PartidoFormDialog(
        matchService: widget.matchService,
        equipoId: equipoId,
        partidoExistente: partidoExistente,
      ),
    );

    if (!mounted || resultado == null) return;

    final mensaje = resultado == 'eliminado'
        ? _t.matchDeletedSuccess
        : (partidoExistente == null
              ? _t.matchCreatedSuccess
              : _t.matchUpdatedSuccess);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));

    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 5,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.dorado,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.titulo,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        onExpansionChanged: (expandido) {
          if (expandido && !_cargado && !_cargando) {
            _cargar();
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _construirContenidoSeccion(),
          ),
        ],
      ),
    );
  }

  Widget _construirContenidoSeccion() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Text(
            _t.teamMatchesLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: _colors.onSurface),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            label: Text(_t.retry),
          ),

          // Aunque la carga haya fallado, si el usuario gestiona este
          // equipo debe poder seguir creando un partido nuevo.
          if (widget.puedeGestionar && widget.equipoId != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: Text(_t.addMatchButton),
              ),
            ),
          ],
        ],
      );
    }

    if (!_cargado) {
      // Todavía no se ha expandido nunca esta sección.
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_partidos.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            color: _colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.event_busy, color: _colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t.teamNoMatchesAvailable,
                      style: TextStyle(color: _colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final partido in _partidos) ...[
            _construirTarjetaPartido(partido),
            const SizedBox(height: 12),
          ],

        if (widget.puedeGestionar && widget.equipoId != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: Text(_t.addMatchButton),
            ),
          ),
      ],
    );
  }

  Widget _construirTarjetaPartido(MatchModel partido) {
    if (!widget.puedeGestionar || partido.id == null) {
      return MatchCard(match: partido);
    }

    return Stack(
      children: [
        MatchCard(match: partido),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: _colors.surface,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: _t.editMatchTooltip,
              onPressed: () => _abrirFormulario(partidoExistente: partido),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DIÁLOGO DE CREACIÓN/EDICIÓN DE PARTIDO
// ============================================================

class _PartidoFormDialog extends StatefulWidget {
  final MatchService matchService;
  final int equipoId;
  final MatchModel? partidoExistente;

  const _PartidoFormDialog({
    required this.matchService,
    required this.equipoId,
    this.partidoExistente,
  });

  @override
  State<_PartidoFormDialog> createState() => _PartidoFormDialogState();
}

class _PartidoFormDialogState extends State<_PartidoFormDialog> {
  static const _tiposPartido = ['LIGA', 'AMISTOSO', 'COPA', 'TORNEO'];

  AppLocalizations get _t => AppLocalizations.of(context);

  String _etiquetaTipoPartido(String tipo) {
    switch (tipo) {
      case 'LIGA':
        return _t.matchTypeLiga;
      case 'AMISTOSO':
        return _t.matchTypeAmistoso;
      case 'COPA':
        return _t.matchTypeCopa;
      case 'TORNEO':
        return _t.matchTypeTorneo;
      default:
        return tipo;
    }
  }

  late final TextEditingController _rivalController;
  late final TextEditingController _horaController;
  late final TextEditingController _campoController;
  late final TextEditingController _resultadoController;

  DateTime? _dia;
  late String _tipo;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.partidoExistente != null;

  @override
  void initState() {
    super.initState();

    final partido = widget.partidoExistente;

    _rivalController = TextEditingController(text: partido?.rival ?? '');
    _horaController = TextEditingController(text: partido?.hora ?? '');
    _campoController = TextEditingController(text: partido?.campo ?? '');
    _resultadoController = TextEditingController(
      text: partido?.resultado ?? '',
    );
    _dia = partido?.dia;

    // 'LIGA' por defecto tanto al crear un partido nuevo como si el
    // partido existente no trae un tipo reconocido.
    final tipoExistente = partido?.tipo?.trim().toUpperCase();
    _tipo = _tiposPartido.contains(tipoExistente) ? tipoExistente! : 'LIGA';
  }

  @override
  void dispose() {
    _rivalController.dispose();
    _horaController.dispose();
    _campoController.dispose();
    _resultadoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _dia ?? ahora,
      firstDate: DateTime(ahora.year - 3),
      lastDate: DateTime(ahora.year + 3),
    );

    if (fecha == null) return;

    setState(() {
      _dia = fecha;
    });
  }

  String? _validarResultado(String texto) {
    final valor = texto.trim();

    if (valor.isEmpty) {
      return null;
    }

    final regex = RegExp(r'^\d+-\d+$');

    if (!regex.hasMatch(valor)) {
      return _t.resultFormatError;
    }

    return null;
  }

  Future<void> _guardar() async {
    final rival = _rivalController.text.trim();

    if (rival.isEmpty) {
      setState(() {
        _error = _t.rivalRequiredError;
      });
      return;
    }

    final resultadoTexto = _resultadoController.text.trim();
    final errorResultado = _validarResultado(resultadoTexto);

    if (errorResultado != null) {
      setState(() {
        _error = errorResultado;
      });
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final dia = _dia == null ? null : _formatearFechaApi(_dia!);
      final hora = _horaController.text.trim().isEmpty
          ? null
          : _horaController.text.trim();
      final campo = _campoController.text.trim().isEmpty
          ? null
          : _campoController.text.trim();
      final resultado = resultadoTexto.isEmpty ? null : resultadoTexto;

      if (_esEdicion) {
        await widget.matchService.actualizarPartido(
          partidoId: widget.partidoExistente!.id!,
          equipoId: widget.equipoId,
          rival: rival,
          dia: dia,
          hora: hora,
          campo: campo,
          resultado: resultado,
          tipo: _tipo,
        );
      } else {
        await widget.matchService.crearPartido(
          equipoId: widget.equipoId,
          rival: rival,
          dia: dia,
          hora: hora,
          campo: campo,
          resultado: resultado,
          tipo: _tipo,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, 'guardado');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _guardando = false;
      });
    }
  }

  Future<void> _eliminar() async {
    final partido = widget.partidoExistente;

    if (partido == null || partido.id == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.deleteMatchTitle),
        content: Text(_t.deleteMatchConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.delete),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await widget.matchService.eliminarPartido(partido.id!);

      if (!mounted) return;

      Navigator.pop(context, 'eliminado');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _guardando = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? _t.editMatchTitle : _t.newMatchTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _rivalController,
              enabled: !_guardando,
              decoration: InputDecoration(
                labelText: _t.rivalLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: InputDecoration(
                labelText: _t.matchTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: _tiposPartido
                  .map(
                    (tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(_etiquetaTipoPartido(tipo)),
                    ),
                  )
                  .toList(),
              onChanged: _guardando
                  ? null
                  : (valor) {
                      if (valor == null) return;

                      setState(() {
                        _tipo = valor;
                      });
                    },
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _guardando ? null : _seleccionarFecha,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _t.dateLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _dia == null
                      ? _t.noDateSelected
                      : _formatearFechaVisible(_dia!),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _horaController,
              enabled: !_guardando,
              decoration: InputDecoration(
                labelText: _t.hourLabelHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _campoController,
              enabled: !_guardando,
              decoration: InputDecoration(
                labelText: _t.fieldLabelCampo,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _resultadoController,
              enabled: !_guardando,
              decoration: InputDecoration(
                labelText: _t.resultLabelHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_esEdicion)
          TextButton(
            onPressed: _guardando ? null : _eliminar,
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(_t.delete),
          ),
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: Text(_t.cancel),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_t.save),
        ),
      ],
    );
  }
}
