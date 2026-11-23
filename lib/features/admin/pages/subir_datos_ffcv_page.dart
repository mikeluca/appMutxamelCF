import 'package:material_ui/material_ui.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/selector_ficheros.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../teams/models/team_model.dart';
import '../../teams/services/team_services.dart';
import '../models/ffcv_model.dart';
import '../services/ffcv_service.dart';

/// Subir los datos de la FFCV desde el móvil (solo ADMIN_APP), con el mismo flujo que el panel web y dos apartados:
/// Partidos (LstPartidos.csv) y Clasificaciones (ListadoClasificaciones.xlsx). En cada uno: elegir el fichero,
/// previsualizar lo que haría el servidor y confirmar la importación. No se guarda nada en el móvil: el fichero solo
/// está en memoria hasta subirlo.
class SubirDatosFfcvPage extends StatelessWidget {
  final FfcvService? servicio;
  final SelectorFicheros? selector;

  /// Solo para tests: la lista de equipos del club (para asignar las filas sin equipo).
  final Future<List<TeamModel>> Function()? equipos;

  const SubirDatosFfcvPage({
    super.key,
    this.servicio,
    this.selector,
    this.equipos,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ffcv = servicio ?? FfcvService();
    final elegir = selector ?? const SelectorFicherosSistema();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: ClubAppBarTitle(titulo: t.clubPageFfcvUpload),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                key: const ValueKey('pestana-partidos'),
                text: t.ffcvTabMatches,
              ),
              Tab(
                key: const ValueKey('pestana-clasificaciones'),
                text: t.ffcvTabStandings,
              ),
              Tab(
                key: const ValueKey('pestana-veteranos'),
                text: t.ffcvTabVeterans,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PestanaPartidos(
              servicio: ffcv,
              selector: elegir,
              equipos: equipos ?? TeamService().obtenerEquipos,
            ),
            _PestanaClasificaciones(servicio: ffcv, selector: elegir),
            _PestanaVeteranos(servicio: ffcv, selector: elegir),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Piezas comunes
// ---------------------------------------------------------------------------

/// El paso 1 de los dos apartados: la explicación de arriba, "Elegir fichero" y, ya elegido, su nombre.
class _ElegirFichero extends StatelessWidget {
  final String ayuda;
  final FicheroElegido? fichero;
  final bool ocupado;
  final VoidCallback alElegir;
  final VoidCallback? alPrevisualizar;

  const _ElegirFichero({
    required this.ayuda,
    required this.fichero,
    required this.ocupado,
    required this.alElegir,
    required this.alPrevisualizar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ayuda,
          key: const ValueKey('ffcv-ayuda'),
          style: TextStyle(color: colores.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const ValueKey('ffcv-elegir'),
          onPressed: ocupado ? null : alElegir,
          icon: const Icon(Icons.folder_open_outlined),
          label: Text(fichero == null ? t.ffcvChooseFile : t.ffcvChangeFile),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              fichero == null
                  ? Icons.insert_drive_file_outlined
                  : Icons.description_outlined,
              size: 20,
              color: colores.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fichero?.nombre ?? t.ffcvNoFile,
                key: const ValueKey('ffcv-nombre-fichero'),
                style: TextStyle(
                  fontWeight: fichero == null
                      ? FontWeight.normal
                      : FontWeight.w600,
                  color: fichero == null
                      ? colores.onSurfaceVariant
                      : colores.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('ffcv-previsualizar'),
          onPressed: ocupado ? null : alPrevisualizar,
          icon: const Icon(Icons.visibility_outlined),
          label: Text(t.ffcvPreview),
        ),
      ],
    );
  }
}

/// El indicador mientras se sube y se procesa, con el texto de qué se está haciendo.
class _Trabajando extends StatelessWidget {
  final String texto;

  const _Trabajando({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('ffcv-trabajando'),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Un error o un aviso destacado: con borde y fondo del color y un icono, legible en claro y en oscuro.
class _Destacado extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String? titulo;
  final List<String> lineas;

  const _Destacado({
    super.key,
    required this.color,
    required this.icono,
    this.titulo,
    required this.lineas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null)
                  Text(
                    titulo!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                for (final linea in lineas) Text(linea),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const Color _rojo = Color(0xFFDC2626);
const Color _naranja = Color(0xFFD97706);
const Color _verde = Color(0xFF16A34A);

String _fechaCorta(DateTime? fecha) {
  if (fecha == null) return '';

  String dos(int n) => n.toString().padLeft(2, '0');

  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}

Future<bool> _confirmar(
  BuildContext context, {
  required String titulo,
  required String cuerpo,
  required String boton,
}) async {
  final t = AppLocalizations.of(context);

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titulo),
      content: Text(cuerpo),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey('ffcv-confirmar-dialogo'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(boton),
        ),
      ],
    ),
  );

  return confirmado == true;
}

// ---------------------------------------------------------------------------
// Partidos
// ---------------------------------------------------------------------------

class _PestanaPartidos extends StatefulWidget {
  final FfcvService servicio;
  final SelectorFicheros selector;
  final Future<List<TeamModel>> Function() equipos;

  const _PestanaPartidos({
    required this.servicio,
    required this.selector,
    required this.equipos,
  });

  @override
  State<_PestanaPartidos> createState() => _PestanaPartidosState();
}

class _PestanaPartidosState extends State<_PestanaPartidos>
    with AutomaticKeepAliveClientMixin {
  FicheroElegido? _fichero;
  PrevisualizacionPartidosModel? _previa;
  ResultadoPartidosModel? _resultado;
  String? _trabajando;
  String? _error;

  List<TeamModel> _equipos = const [];

  /// El equipo elegido para cada grupo (competición + letra) de las filas sin equipo.
  final Map<String, int> _asignados = {};

  @override
  bool get wantKeepAlive => true;

  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _elegir() async {
    try {
      final elegido = await widget.selector.elegir(extensiones: const ['csv']);

      if (elegido == null || !mounted) return;

      setState(() {
        _fichero = elegido;
        _previa = null;
        _resultado = null;
        _error = null;
        _asignados.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = mensajeDeAdmin(_t, e));
    }
  }

  Future<void> _previsualizar() async {
    final fichero = _fichero;

    if (fichero == null) {
      await _elegir();

      return;
    }

    setState(() {
      _trabajando = _t.ffcvUploading;
      _error = null;
      _previa = null;
      _resultado = null;
      _asignados.clear();
    });

    try {
      final previa = await widget.servicio.previsualizarPartidos(
        bytes: fichero.bytes,
        nombreArchivo: fichero.nombre,
      );

      // Para asignar las filas sin equipo hace falta la lista de equipos del club.
      var equipos = _equipos;

      if (previa.gruposSinEquipo.isNotEmpty && equipos.isEmpty) {
        equipos = await widget.equipos();
      }

      if (!mounted) return;

      setState(() {
        _previa = previa;
        _equipos = equipos;
        _trabajando = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _trabajando = null;
        _error = mensajeDeAdmin(_t, e);
      });
    }
  }

  List<({String competicion, String? letra, int equipoId})> _asignaciones(
    PrevisualizacionPartidosModel previa,
  ) {
    return [
      for (final grupo in previa.gruposSinEquipo)
        if (_asignados[grupo.claveGrupo] != null)
          (
            competicion: grupo.competicion,
            letra: grupo.letra,
            equipoId: _asignados[grupo.claveGrupo]!,
          ),
    ];
  }

  Future<void> _confirmarImportacion() async {
    final previa = _previa;

    if (previa == null) return;

    final asignados = _asignados.keys.toSet();
    final total = previa.partidosAImportar(gruposAsignados: asignados);
    final nuevos = previa.cuantas(EstadoFilaFfcv.nuevo);
    final actualizados = previa.cuantas(EstadoFilaFfcv.actualizado);

    final ok = await _confirmar(
      context,
      titulo: _t.ffcvConfirm,
      cuerpo: _t.ffcvConfirmMatchesBody(total, nuevos, actualizados),
      boton: _t.ffcvConfirm,
    );

    if (!ok || !mounted) return;

    setState(() {
      _trabajando = _t.ffcvSaving;
      _error = null;
    });

    try {
      final resultado = await widget.servicio.confirmarPartidos(
        previa,
        asignaciones: _asignaciones(previa),
      );

      if (!mounted) return;

      setState(() {
        _resultado = resultado;
        _previa = null;
        _fichero = null;
        _trabajando = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _trabajando = null;
        _error = mensajeDeAdmin(_t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final ocupado = _trabajando != null;
    final previa = _previa;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ElegirFichero(
          ayuda: _t.ffcvMatchesHelp,
          fichero: _fichero,
          ocupado: ocupado,
          alElegir: _elegir,
          alPrevisualizar: _fichero == null ? null : _previsualizar,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          _Destacado(
            key: const ValueKey('ffcv-error'),
            color: _rojo,
            icono: Icons.error_outline,
            lineas: [_error!],
          ),
        if (_trabajando != null) _Trabajando(texto: _trabajando!),
        if (previa != null && !ocupado) ..._construirPrevia(previa),
        if (_resultado != null && !ocupado) _construirResultado(_resultado!),
      ],
    );
  }

  List<Widget> _construirPrevia(PrevisualizacionPartidosModel previa) {
    final colores = Theme.of(context).colorScheme;

    final partes = [
      if (previa.cuantas(EstadoFilaFfcv.nuevo) > 0)
        _t.ffcvCountNew(previa.cuantas(EstadoFilaFfcv.nuevo)),
      if (previa.cuantas(EstadoFilaFfcv.actualizado) > 0)
        _t.ffcvCountUpdated(previa.cuantas(EstadoFilaFfcv.actualizado)),
      if (previa.cuantas(EstadoFilaFfcv.sinCambios) > 0)
        _t.ffcvCountUnchanged(previa.cuantas(EstadoFilaFfcv.sinCambios)),
      if (previa.cuantas(EstadoFilaFfcv.sinEquipo) > 0)
        _t.ffcvCountNoTeam(previa.cuantas(EstadoFilaFfcv.sinEquipo)),
      if (previa.cuantas(EstadoFilaFfcv.conflictoManual) > 0)
        _t.ffcvCountConflict(previa.cuantas(EstadoFilaFfcv.conflictoManual)),
    ];

    return [
      Text(
        previa.filas.isEmpty
            ? _t.ffcvNoMatchesFound
            : _t.ffcvWeekendSummary(
                _fechaCorta(previa.desde),
                _fechaCorta(previa.hasta),
                partes.join(', '),
              ),
        key: const ValueKey('ffcv-resumen'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),

      // Los errores y los avisos, destacados arriba.
      if (previa.errores.isNotEmpty) ...[
        _Destacado(
          key: const ValueKey('ffcv-errores'),
          color: _rojo,
          icono: Icons.error_outline,
          titulo: _t.ffcvErrorsTitle,
          lineas: [
            for (final e in previa.errores)
              e.linea > 0 ? _t.ffcvErrorLine(e.linea, e.mensaje) : e.mensaje,
          ],
        ),
        const SizedBox(height: 10),
      ],
      if (previa.desaparecidos.isNotEmpty) ...[
        _Destacado(
          key: const ValueKey('ffcv-desaparecidos'),
          color: _naranja,
          icono: Icons.warning_amber_rounded,
          titulo: '${_t.ffcvVanished}\n${_t.ffcvVanishedNote}',
          lineas: [
            for (final d in previa.desaparecidos)
              [
                d.equipoNombre,
                _fechaCorta(d.fecha),
                d.rival,
                if (d.hora != null && d.hora!.isNotEmpty) '(${d.hora})',
                if (d.tieneConvocatoria) '— ${_t.ffcvHasCallup}',
              ].where((p) => p.isNotEmpty).join(' · '),
          ],
        ),
        const SizedBox(height: 10),
      ],

      // Las filas sin equipo: hay que elegir un equipo del club para cada grupo.
      for (final grupo in previa.gruposSinEquipo) ...[
        DropdownButtonFormField<int>(
          key: ValueKey('asignar-${grupo.claveGrupo}'),
          isExpanded: true,
          initialValue: _asignados[grupo.claveGrupo],
          decoration: InputDecoration(
            labelText: _t.ffcvAssignTeamFor(grupo.equipoVisible),
            border: const OutlineInputBorder(),
          ),
          hint: Text(_t.ffcvChooseTeam),
          items: [
            for (final equipo in _equipos)
              DropdownMenuItem<int>(
                value: equipo.id,
                child: Text(equipo.nombre, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (valor) => setState(() {
            if (valor == null) {
              _asignados.remove(grupo.claveGrupo);
            } else {
              _asignados[grupo.claveGrupo] = valor;
            }
          }),
        ),
        const SizedBox(height: 10),
      ],

      for (final fila in previa.filas) _construirFila(fila, colores),

      if (previa.descansan.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(_t.ffcvRests, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final equipo in previa.descansan)
              Chip(label: Text(equipo), visualDensity: VisualDensity.compact),
          ],
        ),
      ],

      if (previa.filas.isNotEmpty) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('ffcv-confirmar'),
          onPressed: _confirmarImportacion,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(_t.ffcvConfirm),
        ),
      ],
    ];
  }

  Widget _construirFila(FilaFfcvModel fila, ColorScheme colores) {
    final (etiqueta, color) = switch (fila.estado) {
      EstadoFilaFfcv.nuevo => (_t.ffcvStatusNew, _verde),
      EstadoFilaFfcv.actualizado => (_t.ffcvStatusUpdated, colores.primary),
      EstadoFilaFfcv.sinCambios => (
        _t.ffcvStatusUnchanged,
        colores.onSurfaceVariant,
      ),
      EstadoFilaFfcv.sinEquipo => (_t.ffcvStatusNoTeam, _naranja),
      EstadoFilaFfcv.conflictoManual => (_t.ffcvStatusConflict, _rojo),
    };

    final donde = [
      if (fila.campo != null && fila.campo!.isNotEmpty) fila.campo!,
      if (fila.hora != null && fila.hora!.isNotEmpty) fila.hora!,
      if (fila.jornada != null) 'J${fila.jornada}',
    ].join(' · ');

    return Card(
      key: ValueKey(
        'fila-ffcv-${fila.competicion}-${fila.rival}-${fila.fecha}',
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  _fechaCorta(fila.fecha),
                  style: TextStyle(color: colores.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fila.equipoVisible,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              fila.local
                  ? _t.ffcvHomeVs(fila.rival)
                  : _t.ffcvAwayVs(fila.rival),
            ),
            if (donde.isNotEmpty)
              Text(donde, style: TextStyle(color: colores.onSurfaceVariant)),
            if (fila.cambios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(fila.cambios.join(' · ')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirResultado(ResultadoPartidosModel r) {
    return Column(
      key: const ValueKey('ffcv-resultado'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Destacado(
          color: _verde,
          icono: Icons.check_circle_outline,
          lineas: [
            _t.ffcvResultMatches(
              r.creados,
              r.actualizados,
              r.sinCambios,
              r.conflictosManuales,
              r.sinEquipo,
              r.descansosCreados,
              r.descansosEliminados,
            ),
          ],
        ),
        if (r.avisos.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Destacado(
            key: const ValueKey('ffcv-avisos'),
            color: _naranja,
            icono: Icons.warning_amber_rounded,
            titulo: _t.ffcvWarnings,
            lineas: r.avisos,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Clasificaciones
// ---------------------------------------------------------------------------

class _PestanaClasificaciones extends StatefulWidget {
  final FfcvService servicio;
  final SelectorFicheros selector;

  const _PestanaClasificaciones({
    required this.servicio,
    required this.selector,
  });

  @override
  State<_PestanaClasificaciones> createState() =>
      _PestanaClasificacionesState();
}

class _PestanaClasificacionesState extends State<_PestanaClasificaciones>
    with AutomaticKeepAliveClientMixin {
  FicheroElegido? _fichero;
  PrevisualizacionClasificacionesModel? _previa;
  ResultadoClasificacionesModel? _resultado;
  String? _trabajando;
  String? _error;

  /// Los equipos marcados para importar.
  final Set<int> _marcados = {};

  @override
  bool get wantKeepAlive => true;

  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _elegir() async {
    try {
      final elegido = await widget.selector.elegir(extensiones: const ['xlsx']);

      if (elegido == null || !mounted) return;

      setState(() {
        _fichero = elegido;
        _previa = null;
        _resultado = null;
        _error = null;
        _marcados.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = mensajeDeAdmin(_t, e));
    }
  }

  Future<void> _previsualizar() async {
    final fichero = _fichero;

    if (fichero == null) {
      await _elegir();

      return;
    }

    setState(() {
      _trabajando = _t.ffcvUploading;
      _error = null;
      _previa = null;
      _resultado = null;
      _marcados.clear();
    });

    try {
      final previa = await widget.servicio.previsualizarClasificaciones(
        bytes: fichero.bytes,
        nombreArchivo: fichero.nombre,
      );

      if (!mounted) return;

      setState(() {
        _previa = previa;
        _trabajando = null;
        // Como en el panel: marcados los que el servidor propone (los antiguos vienen desmarcados).
        _marcados.addAll([
          for (final e in previa.equipos)
            if (e.equipoId != null && e.importable && e.marcadoPorDefecto)
              e.equipoId!,
        ]);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _trabajando = null;
        _error = mensajeDeAdmin(_t, e);
      });
    }
  }

  Future<void> _confirmarImportacion() async {
    if (_marcados.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.ffcvNothingSelected)));

      return;
    }

    final ok = await _confirmar(
      context,
      titulo: _t.ffcvConfirm,
      cuerpo: _t.ffcvConfirmStandingsBody(_marcados.length),
      boton: _t.ffcvConfirm,
    );

    if (!ok || !mounted) return;

    setState(() {
      _trabajando = _t.ffcvSaving;
      _error = null;
    });

    try {
      final resultado = await widget.servicio.confirmarClasificaciones(
        _marcados.toList(),
      );

      if (!mounted) return;

      setState(() {
        _resultado = resultado;
        _previa = null;
        _fichero = null;
        _marcados.clear();
        _trabajando = null;
      });
    } catch (e) {
      if (!mounted) return;

      // La vista previa se conserva (salvo que haya caducado: entonces el mensaje lo dice).
      setState(() {
        _trabajando = null;
        _error = mensajeDeAdmin(_t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final ocupado = _trabajando != null;
    final previa = _previa;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ElegirFichero(
          ayuda: _t.ffcvStandingsHelp,
          fichero: _fichero,
          ocupado: ocupado,
          alElegir: _elegir,
          alPrevisualizar: _fichero == null ? null : _previsualizar,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          _Destacado(
            key: const ValueKey('ffcv-error'),
            color: _rojo,
            icono: Icons.error_outline,
            lineas: [_error!],
          ),
        if (_trabajando != null) _Trabajando(texto: _trabajando!),
        if (previa != null && !ocupado) ..._construirPrevia(previa),
        if (_resultado != null && !ocupado) _construirResultado(_resultado!),
      ],
    );
  }

  List<Widget> _construirPrevia(PrevisualizacionClasificacionesModel previa) {
    final colores = Theme.of(context).colorScheme;

    return [
      Text(
        _t.ffcvStandingsSummary(previa.filasLeidas, previa.competiciones),
        key: const ValueKey('ffcv-resumen'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      if (previa.errores.isNotEmpty) ...[
        _Destacado(
          key: const ValueKey('ffcv-errores'),
          color: _rojo,
          icono: Icons.error_outline,
          titulo: _t.ffcvErrorsTitle,
          lineas: [
            for (final e in previa.errores)
              e.linea > 0 ? _t.ffcvErrorLine(e.linea, e.mensaje) : e.mensaje,
          ],
        ),
        const SizedBox(height: 10),
      ],
      if (previa.sinMapeo.isNotEmpty) ...[
        _Destacado(
          key: const ValueKey('ffcv-sin-mapeo'),
          color: _naranja,
          icono: Icons.warning_amber_rounded,
          titulo: _t.ffcvUnmappedTitle,
          lineas: [
            _t.ffcvUnmappedBody,
            for (final s in previa.sinMapeo)
              [
                s.competicion,
                if (s.letra != null && s.letra!.isNotEmpty) '"${s.letra}"',
                '(${s.equipo})',
              ].join(' '),
          ],
        ),
        const SizedBox(height: 10),
      ],
      if (previa.equipos.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _t.ffcvNoTeamsRelated,
            style: TextStyle(color: colores.onSurfaceVariant),
          ),
        ),
      for (final equipo in previa.equipos) _construirEquipo(equipo, colores),
      if (previa.equipos.isNotEmpty) ...[
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('ffcv-confirmar'),
          onPressed: _confirmarImportacion,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(_t.ffcvConfirm),
        ),
      ],
    ];
  }

  Widget _construirEquipo(
    EquipoClasificacionPreviaModel equipo,
    ColorScheme colores,
  ) {
    String dato(int? n) => n?.toString() ?? '–';

    final id = equipo.equipoId;
    final marcado = id != null && _marcados.contains(id);

    return Card(
      key: ValueKey('clasificacion-${equipo.equipoNombre}'),
      margin: const EdgeInsets.only(bottom: 8),
      shape: equipo.antiguo
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _naranja, width: 1.5),
            )
          : null,
      child: CheckboxListTile(
        value: marcado,
        onChanged: (!equipo.importable || id == null)
            ? null
            : (valor) => setState(() {
                if (valor == true) {
                  _marcados.add(id);
                } else {
                  _marcados.remove(id);
                }
              }),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          equipo.equipoNombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${equipo.encontrado ? _t.ffcvFound : _t.ffcvNotFound}'
              '${equipo.competicion.isEmpty ? '' : ' · ${equipo.competicion}'}',
              style: TextStyle(color: colores.onSurfaceVariant),
            ),
            if (equipo.encontrado)
              Text(
                _t.ffcvStandingsLine(
                  dato(equipo.jornada),
                  dato(equipo.posicion),
                  dato(equipo.puntos),
                  dato(equipo.pj),
                ),
              ),
            if (equipo.antiguo)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _t.ffcvOldFileWarning(
                    dato(equipo.jornada),
                    dato(equipo.jornadaGuardada),
                  ),
                  key: const ValueKey('ffcv-aviso-antiguo'),
                  style: const TextStyle(
                    color: _naranja,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!equipo.encontrado && (equipo.motivo ?? '').isNotEmpty)
              Text(equipo.motivo!),
            if (equipo.encontrado && equipo.cambia)
              for (final cambio in equipo.cambios) Text('• $cambio'),
            if (equipo.encontrado && !equipo.cambia)
              Text(
                _t.ffcvStatusUnchanged,
                style: TextStyle(color: colores.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirResultado(ResultadoClasificacionesModel r) {
    return Column(
      key: const ValueKey('ffcv-resultado'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Destacado(
          color: _verde,
          icono: Icons.check_circle_outline,
          lineas: [
            _t.ffcvResultStandings(r.importados, r.filas),
            ...r.equipos.map((e) => '• $e'),
          ],
        ),
        if (r.avisos.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Destacado(
            key: const ValueKey('ffcv-avisos'),
            color: _naranja,
            icono: Icons.warning_amber_rounded,
            titulo: _t.ffcvWarnings,
            lineas: r.avisos,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Clasificación de veteranos (LVCA)
// ---------------------------------------------------------------------------

class _PestanaVeteranos extends StatefulWidget {
  final FfcvService servicio;
  final SelectorFicheros selector;

  const _PestanaVeteranos({required this.servicio, required this.selector});

  @override
  State<_PestanaVeteranos> createState() => _PestanaVeteranosState();
}

class _PestanaVeteranosState extends State<_PestanaVeteranos>
    with AutomaticKeepAliveClientMixin {
  FicheroElegido? _fichero;
  PrevisualizacionVeteranosModel? _previa;
  ResultadoVeteranosModel? _resultado;
  String? _trabajando;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _elegir() async {
    try {
      final elegido = await widget.selector.elegir(
        extensiones: const ['html', 'htm'],
      );

      if (elegido == null || !mounted) return;

      setState(() {
        _fichero = elegido;
        _previa = null;
        _resultado = null;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = mensajeDeAdmin(_t, e));
    }
  }

  Future<void> _previsualizar() async {
    final fichero = _fichero;

    if (fichero == null) {
      await _elegir();

      return;
    }

    setState(() {
      _trabajando = _t.ffcvUploading;
      _error = null;
      _previa = null;
      _resultado = null;
    });

    try {
      final previa = await widget.servicio.previsualizarVeteranos(
        bytes: fichero.bytes,
        nombreArchivo: fichero.nombre,
      );

      if (!mounted) return;

      setState(() {
        _previa = previa;
        _trabajando = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _trabajando = null;
        _error = mensajeDeAdmin(_t, e);
      });
    }
  }

  Future<void> _confirmarImportacion() async {
    final previa = _previa;

    if (previa == null) return;

    final ok = await _confirmar(
      context,
      titulo: _t.ffcvConfirm,
      cuerpo: _t.ffcvConfirmVeteransBody(previa.competiciones.length),
      boton: _t.ffcvConfirm,
    );

    if (!ok || !mounted) return;

    setState(() {
      _trabajando = _t.ffcvSaving;
      _error = null;
    });

    try {
      final resultado = await widget.servicio.confirmarVeteranos();

      if (!mounted) return;

      setState(() {
        _resultado = resultado;
        _previa = null;
        _fichero = null;
        _trabajando = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _trabajando = null;
        _error = mensajeDeAdmin(_t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final ocupado = _trabajando != null;
    final previa = _previa;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ElegirFichero(
          ayuda: _t.ffcvVeteransHelp,
          fichero: _fichero,
          ocupado: ocupado,
          alElegir: _elegir,
          alPrevisualizar: _fichero == null ? null : _previsualizar,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          _Destacado(
            key: const ValueKey('ffcv-error'),
            color: _rojo,
            icono: Icons.error_outline,
            lineas: [_error!],
          ),
        if (_trabajando != null) _Trabajando(texto: _trabajando!),
        if (previa != null && !ocupado) ..._construirPrevia(previa),
        if (_resultado != null && !ocupado) _construirResultado(_resultado!),
      ],
    );
  }

  List<Widget> _construirPrevia(PrevisualizacionVeteranosModel previa) {
    return [
      Text(
        _t.ffcvVeteransSummary(previa.competiciones.length),
        key: const ValueKey('ffcv-resumen'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      for (final c in previa.competiciones) _construirCompeticion(c),
      if (previa.clubesACrear.isNotEmpty) ...[
        _Destacado(
          key: const ValueKey('ffcv-clubes-nuevos'),
          color: _naranja,
          icono: Icons.shield_outlined,
          titulo: '${_t.ffcvVeteransNewClubs}\n${_t.ffcvVeteransNewClubsBody}',
          lineas: previa.clubesACrear,
        ),
        const SizedBox(height: 12),
      ],
      FilledButton.icon(
        key: const ValueKey('ffcv-confirmar'),
        onPressed: _confirmarImportacion,
        icon: const Icon(Icons.check_circle_outline),
        label: Text(_t.ffcvConfirm),
      ),
    ];
  }

  Widget _construirCompeticion(CompeticionVeteranosModel c) {
    final colores = Theme.of(context).colorScheme;

    Widget celda(String texto, double ancho, TextStyle estilo) => SizedBox(
      width: ancho,
      child: Text(texto, textAlign: TextAlign.center, style: estilo),
    );

    return Card(
      key: ValueKey('competicion-veteranos-${c.nombre}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.nombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _t.ffcvVeteransRound(c.jornada),
              style: TextStyle(fontSize: 12, color: colores.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final f in c.tabla)
              Container(
                key: ValueKey('fila-veteranos-${c.nombre}-${f.posicion}'),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                decoration: BoxDecoration(
                  color: f.esNuestro
                      ? colores.primary.withValues(alpha: 0.16)
                      : null,
                  border: f.esNuestro
                      ? Border(
                          left: BorderSide(color: colores.primary, width: 3),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    celda(
                      '${f.posicion}',
                      28,
                      const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        f.equipo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: f.esNuestro
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    celda('${f.pj}', 28, const TextStyle()),
                    celda(
                      '${f.puntos}',
                      34,
                      const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirResultado(ResultadoVeteranosModel r) {
    return Column(
      key: const ValueKey('ffcv-resultado'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Destacado(
          color: _verde,
          icono: Icons.check_circle_outline,
          lineas: [
            _t.ffcvResultVeterans(r.competiciones, r.filas),
            ...r.nombres.map((n) => '• $n'),
          ],
        ),
        if (r.clubesCreados.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Destacado(
            key: const ValueKey('ffcv-clubes-creados'),
            color: _naranja,
            icono: Icons.shield_outlined,
            lineas: [_t.ffcvCreatedClubs(r.clubesCreados.join(', '))],
          ),
        ],
      ],
    );
  }
}
