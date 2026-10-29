import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/reparto_model.dart';
import '../services/reparto_service.dart';

/// Los jugadores cuyo dorsal coincide con el de otro de los [seleccionados] o con
/// el de alguien que ya está en [equipo]. El dorsal repetido solo avisa: el
/// servidor asigna igualmente.
Set<int> dorsalesRepetidos(
  Map<int, int?> seleccionados,
  EquipoRepartoModel? equipo,
) {
  final repetidos = <int>{};
  final yaEnElEquipo = {
    for (final j in equipo?.jugadores ?? <JugadorRepartoModel>[])
      if (j.dorsal != null) j.dorsal!,
  };

  final cuentas = <int, int>{};
  for (final dorsal in seleccionados.values) {
    if (dorsal != null) cuentas[dorsal] = (cuentas[dorsal] ?? 0) + 1;
  }

  seleccionados.forEach((jugadorId, dorsal) {
    if (dorsal != null &&
        ((cuentas[dorsal] ?? 0) > 1 || yaEnElEquipo.contains(dorsal))) {
      repetidos.add(jugadorId);
    }
  });

  return repetidos;
}

/// El texto de un fallo del reparto: un 409 (sin temporada activa o siguiente) tiene
/// texto propio; el resto, como el de cualquier acción del servidor.
String mensajeDeReparto(AppLocalizations t, Object? error) {
  if (error is ApiException && error.statusCode == 409) {
    return t.rosterNoSeason;
  }

  return mensajeDeAccion(t, error);
}

/// Reparto de equipos (COORDINADOR y ADMIN_APP): pasa a los jugadores de la
/// pretemporada y a los de prueba a un equipo definitivo de su categoría.
class RepartoPage extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real.
  final RepartoService? servicio;

  const RepartoPage({super.key, this.servicio});

  @override
  State<RepartoPage> createState() => _RepartoPageState();
}

class _RepartoPageState extends State<RepartoPage> {
  late final RepartoService _servicio = widget.servicio ?? RepartoService();

  List<String> _categorias = [];
  String? _categoria;
  RepartoCategoriaModel? _reparto;

  bool _cargando = true;
  bool _trabajando = false;
  Object? _error;

  /// Jugadores marcados para asignar y el texto del dorsal de cada uno.
  final Set<int> _seleccionados = {};
  final Map<int, TextEditingController> _dorsales = {};
  int? _equipoDestinoId;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    for (final c in _dorsales.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await _servicio.obtenerCategorias();

      if (!mounted) return;

      _categorias = categorias;
      _categoria = categorias.isEmpty ? null : categorias.first;

      if (_categoria == null) {
        setState(() {
          _cargando = false;
          _error = null;
        });
        return;
      }

      await _cargarReparto();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = e;
      });
    }
  }

  Future<void> _cargarReparto() async {
    final categoria = _categoria;

    if (categoria == null) return;

    try {
      final reparto = await _servicio.obtenerReparto(categoria);

      if (!mounted || categoria != _categoria) return;

      for (final c in _dorsales.values) {
        c.dispose();
      }
      _dorsales.clear();

      for (final j in reparto.porAsignar) {
        _dorsales[j.jugadorId] = TextEditingController(
          text: j.dorsal?.toString() ?? '',
        );
      }

      setState(() {
        _reparto = reparto;
        _seleccionados.clear();
        _equipoDestinoId = reparto.equipos.any((e) => e.equipoId == _equipoDestinoId)
            ? _equipoDestinoId
            : null;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = e;
      });
    }
  }

  void _mostrar(String texto) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Map<int, int?> _dorsalesSeleccionados() {
    return {
      for (final id in _seleccionados)
        id: int.tryParse(_dorsales[id]?.text.trim() ?? ''),
    };
  }

  EquipoRepartoModel? get _equipoDestino => _reparto?.equipos
      .where((e) => e.equipoId == _equipoDestinoId)
      .firstOrNull;

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final t = _t;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: Text(t.cancel),
          ),
          TextButton(
            key: const ValueKey('reparto-confirmar'),
            onPressed: () => Navigator.pop(contexto, true),
            child: Text(t.rosterConfirm),
          ),
        ],
      ),
    );

    return resultado == true;
  }

  Future<void> _asignar({bool confirmarPruebas = false}) async {
    final t = _t;
    final equipo = _equipoDestino;

    if (_seleccionados.isEmpty) {
      _mostrar(t.rosterSelectPlayers);
      return;
    }

    if (equipo == null) {
      _mostrar(t.rosterChooseTeam);
      return;
    }

    final dorsales = _dorsalesSeleccionados();

    for (final entrada in _dorsales.entries) {
      final texto = entrada.value.text.trim();
      final valor = int.tryParse(texto);

      if (_seleccionados.contains(entrada.key) &&
          texto.isNotEmpty &&
          (valor == null || valor < 0 || valor > 99)) {
        _mostrar(t.rosterDorsalInvalid);
        return;
      }
    }

    setState(() => _trabajando = true);

    try {
      final resultado = await _servicio.asignar(
        equipoId: equipo.equipoId,
        jugadores: [
          for (final e in dorsales.entries) AsignacionJugador(e.key, e.value),
        ],
        confirmarPruebas: confirmarPruebas,
      );

      if (!mounted) return;

      _mostrar(t.rosterAssigned(resultado.asignados));

      // El diálogo de avisos no debe dejar el indicador de carga girando detrás.
      setState(() => _trabajando = false);

      if (resultado.avisos.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (contexto) => AlertDialog(
            title: Text(t.rosterWarningsTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final aviso in resultado.avisos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(aviso),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(contexto),
                child: Text(t.close),
              ),
            ],
          ),
        );
      }

      await _cargarReparto();
    } on PruebasSinConfirmarException catch (e) {
      if (!mounted) return;

      setState(() => _trabajando = false);

      final seguir = await _confirmar(
        t.rosterTrialDialogTitle,
        t.rosterTrialDialogBody(e.pruebas.join(', ')),
      );

      if (seguir && mounted) {
        await _asignar(confirmarPruebas: true);
      }
    } catch (e) {
      if (!mounted) return;

      _mostrar(mensajeDeReparto(t, e));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _devolver(JugadorRepartoModel jugador) async {
    final t = _t;

    final seguir = await _confirmar(
      t.rosterReturnTooltip,
      t.rosterReturnConfirm(jugador.nombre),
    );

    if (!seguir || !mounted) return;

    setState(() => _trabajando = true);

    try {
      final resultado = await _servicio.devolver([jugador.jugadorId]);

      if (!mounted) return;

      _mostrar(t.rosterReturned(resultado.devueltos));
      await _cargarReparto();
    } catch (e) {
      if (!mounted) return;

      _mostrar(mensajeDeReparto(t, e));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _crearEquipo() async {
    final t = _t;
    final categoria = _categoria;

    if (categoria == null) return;

    final seguir = await _confirmar(
      t.rosterNewTeam,
      t.rosterNewTeamConfirm(categoria),
    );

    if (!seguir || !mounted) return;

    setState(() => _trabajando = true);

    try {
      final equipo = await _servicio.crearEquipo(categoria);

      if (!mounted) return;

      _mostrar(t.rosterTeamCreated(equipo.nombre));
      await _cargarReparto();
    } catch (e) {
      if (!mounted) return;

      _mostrar(mensajeDeReparto(t, e));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.rosterTitle)),
      body: _contenido(),
    );
  }

  Widget _contenido() {
    final t = _t;

    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.azul),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensajeDeReparto(t, _error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _cargando = true;
                    _error = null;
                  });
                  _categoria == null ? _cargarCategorias() : _cargarReparto();
                },
                icon: const Icon(Icons.refresh),
                label: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_categorias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.rosterNoCategories, textAlign: TextAlign.center),
        ),
      );
    }

    final reparto = _reparto;

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargarReparto,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(t.rosterCategory, style: _estiloEtiqueta()),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: const ValueKey('reparto-categoria'),
            initialValue: _categoria,
            items: [
              for (final c in _categorias)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: _trabajando
                ? null
                : (c) {
                    setState(() {
                      _categoria = c;
                      _reparto = null;
                      _cargando = true;
                    });
                    _cargarReparto();
                  },
          ),
          const SizedBox(height: 20),
          if (reparto != null) ..._seccionPorAsignar(reparto),
          const SizedBox(height: 24),
          if (reparto != null) ..._seccionEquipos(reparto),
        ],
      ),
    );
  }

  TextStyle _estiloEtiqueta() => TextStyle(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 13,
  );

  TextStyle _estiloTitulo() => TextStyle(
    color: Theme.of(context).colorScheme.onSurface,
    fontSize: 19,
    fontWeight: FontWeight.bold,
  );

  List<Widget> _seccionPorAsignar(RepartoCategoriaModel reparto) {
    final t = _t;
    final repetidos = _equipoDestino == null
        ? <int>{}
        : dorsalesRepetidos(_dorsalesSeleccionados(), _equipoDestino);

    return [
      Text(t.rosterToAssign(reparto.porAsignar.length), style: _estiloTitulo()),
      if (reparto.pretemporada != null) ...[
        const SizedBox(height: 4),
        Text(
          t.rosterPreseasonTeam(reparto.pretemporada!.nombre),
          style: _estiloEtiqueta(),
        ),
      ],
      const SizedBox(height: 8),
      if (reparto.porAsignar.isEmpty)
        Text(t.rosterNothingToAssign)
      else ...[
        for (final jugador in reparto.porAsignar)
          _filaPorAsignar(jugador, repetidos.contains(jugador.jugadorId)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: const ValueKey('reparto-equipo-destino'),
          initialValue: _equipoDestinoId,
          hint: Text(t.rosterChooseTeam),
          decoration: InputDecoration(labelText: t.rosterTargetTeam),
          items: [
            for (final e in reparto.equipos)
              DropdownMenuItem(value: e.equipoId, child: Text(e.nombre)),
          ],
          onChanged: _trabajando
              ? null
              : (id) => setState(() => _equipoDestinoId = id),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('reparto-asignar'),
          onPressed: _trabajando ? null : _asignar,
          icon: _trabajando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.group_add_outlined),
          label: Text(t.rosterAssignButton(_seleccionados.length)),
        ),
      ],
    ];
  }

  Widget _filaPorAsignar(JugadorRepartoModel jugador, bool repetido) {
    final t = _t;
    final marcado = _seleccionados.contains(jugador.jugadorId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        key: ValueKey('reparto-jugador-${jugador.jugadorId}'),
        children: [
          Checkbox(
            value: marcado,
            onChanged: _trabajando
                ? null
                : (v) => setState(() {
                    v == true
                        ? _seleccionados.add(jugador.jugadorId)
                        : _seleccionados.remove(jugador.jugadorId);
                  }),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(jugador.nombre),
                if (jugador.esPrueba)
                  Chip(
                    label: Text(t.rosterTrialBadge),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 84,
            child: TextField(
              key: ValueKey('reparto-dorsal-${jugador.jugadorId}'),
              controller: _dorsales[jugador.jugadorId],
              keyboardType: TextInputType.number,
              enabled: !_trabajando,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: t.fieldDorsal,
                isDense: true,
                errorText: marcado && repetido ? t.rosterDorsalRepeated : null,
                errorMaxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _seccionEquipos(RepartoCategoriaModel reparto) {
    final t = _t;

    return [
      Row(
        children: [
          Expanded(child: Text(t.rosterTeamsTitle, style: _estiloTitulo())),
          OutlinedButton.icon(
            key: const ValueKey('reparto-nuevo-equipo'),
            onPressed: _trabajando ? null : _crearEquipo,
            icon: const Icon(Icons.add),
            label: Text(t.rosterNewTeam),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (reparto.equipos.isEmpty)
        Text(t.rosterNoTeams)
      else
        for (final equipo in reparto.equipos) _tarjetaEquipo(equipo),
    ];
  }

  Widget _tarjetaEquipo(EquipoRepartoModel equipo) {
    final t = _t;

    return Card(
      key: ValueKey('reparto-equipo-${equipo.equipoId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    equipo.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(equipo.activo ? t.rosterActive : t.rosterInactive),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (equipo.jugadores.isEmpty)
              Text(t.rosterTeamEmpty, style: _estiloEtiqueta())
            else
              for (final jugador in equipo.jugadores)
                Row(
                  key: ValueKey('reparto-miembro-${jugador.jugadorId}'),
                  children: [
                    Expanded(child: Text(jugador.nombre)),
                    if (jugador.dorsal != null) Text('#${jugador.dorsal}'),
                    IconButton(
                      tooltip: t.rosterReturnTooltip,
                      icon: const Icon(Icons.undo),
                      onPressed: _trabajando ? null : () => _devolver(jugador),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
