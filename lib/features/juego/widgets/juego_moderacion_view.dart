import 'package:material_ui/material_ui.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/juego_modelos.dart';
import '../services/juego_service.dart';

/// "Juego Mutxigol" dentro de Moderación (solo ADMIN_APP): busca perfiles por alias, cambia un alias, oculta o muestra
/// del ranking y borra puntuaciones (una o todas), siempre con confirmación. Aquí sí salen el nombre y el email de la
/// cuenta (el ranking público solo lleva el alias). El servidor rechaza con 403 a quien no sea ADMIN_APP.
class JuegoModeracionView extends StatefulWidget {
  const JuegoModeracionView({super.key, this.servicio = const JuegoService()});

  final JuegoService servicio;

  @override
  State<JuegoModeracionView> createState() => _JuegoModeracionViewState();
}

class _JuegoModeracionViewState extends State<JuegoModeracionView> {
  final TextEditingController _busqueda = TextEditingController();

  late Future<List<PerfilJuegoAdmin>> _perfiles;

  bool _ejecutando = false;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    _perfiles = widget.servicio.listarPerfiles();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _buscar() {
    setState(() {
      _perfiles = widget.servicio.listarPerfiles(alias: _busqueda.text);
    });
  }

  Future<bool> _confirmar(String mensaje) async {
    final t = _t;

    final si = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirmar-juego'),
            onPressed: () => Navigator.pop(dialogo, true),
            child: Text(t.moderationConfirm),
          ),
        ],
      ),
    );

    return si == true;
  }

  /// Ejecuta una acción de moderación y avisa del resultado (el motivo del servidor si lo explica; 403, sin permiso).
  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (_ejecutando) return false;

    setState(() => _ejecutando = true);

    var correcta = false;

    try {
      await accion();

      correcta = true;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_t.gameModDone)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensajeDeAccion(_t, e))));
      }
    }

    if (mounted) setState(() => _ejecutando = false);

    return correcta;
  }

  Future<void> _cambiarAlias(PerfilJuegoAdmin perfil) async {
    final t = _t;
    final controlador = TextEditingController(text: perfil.alias ?? '');
    String? error;

    final nuevo = await showDialog<String>(
      context: context,
      builder: (dialogo) => StatefulBuilder(
        builder: (context, setDialogo) => AlertDialog(
          title: Text(t.gameModChangeAlias),
          content: TextField(
            key: const ValueKey('campo-nuevo-alias'),
            controller: controlador,
            maxLength: 15,
            decoration: InputDecoration(
              labelText: t.gameModNewAlias,
              border: const OutlineInputBorder(),
              errorText: error,
              errorMaxLines: 3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogo),
              child: Text(t.cancel),
            ),
            FilledButton(
              key: const ValueKey('guardar-nuevo-alias'),
              onPressed: () async {
                final alias = controlador.text.trim();

                if (alias.isEmpty) return;

                try {
                  await widget.servicio.cambiarAlias(perfil.usuarioId, alias);

                  if (dialogo.mounted) Navigator.pop(dialogo, alias);
                } catch (e) {
                  // 400 (no vale) y 409 (en uso) traen el motivo; se queda abierto para corregirlo.
                  setDialogo(() => error = mensajeDeAccion(t, e));
                }
              },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );

    if (nuevo != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.gameModDone)));
      _buscar();
    }
  }

  Future<void> _ocultar(PerfilJuegoAdmin perfil) async {
    final t = _t;
    final nombre = perfil.alias ?? perfil.email;

    final confirmado = await _confirmar(
      perfil.oculto
          ? t.gameModConfirmShow(nombre)
          : t.gameModConfirmHide(nombre),
    );

    if (!confirmado) return;

    final bien = await _ejecutar(
      () => widget.servicio.ocultar(perfil.usuarioId, oculto: !perfil.oculto),
    );

    if (bien && mounted) _buscar();
  }

  Future<void> _verPuntuaciones(PerfilJuegoAdmin perfil) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PuntuacionesDelPerfil(
        perfil: perfil,
        servicio: widget.servicio,
        confirmar: _confirmar,
        ejecutar: _ejecutar,
      ),
    );

    if (mounted) _buscar();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            key: const ValueKey('buscar-alias'),
            controller: _busqueda,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            decoration: InputDecoration(
              labelText: t.gameModSearch,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                key: const ValueKey('boton-buscar-alias'),
                icon: const Icon(Icons.search),
                onPressed: _buscar,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PerfilJuegoAdmin>>(
            future: _perfiles,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mensajeDeError(t, snapshot.error),
                          key: const ValueKey('error-juego-moderacion'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _buscar,
                          child: Text(t.retry),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final perfiles = snapshot.data ?? const [];

              if (perfiles.isEmpty) {
                return Center(child: Text(t.gameModNoProfiles));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: perfiles.length,
                itemBuilder: (context, i) => _tarjeta(perfiles[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(PerfilJuegoAdmin p) {
    final t = _t;

    return Card(
      key: ValueKey('perfil-juego-${p.usuarioId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.alias ?? '—',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (p.oculto)
                  Chip(
                    key: ValueKey('oculto-${p.usuarioId}'),
                    label: Text(t.gameModHiddenChip),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Text('${p.nombre} · ${p.email}'),
            Text(
              t.gameModMarks(p.mejorPenaltis, p.mejorToques, p.mejorAtrapa),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: ValueKey('cambiar-alias-${p.usuarioId}'),
                  onPressed: _ejecutando ? null : () => _cambiarAlias(p),
                  child: Text(t.gameModChangeAlias),
                ),
                TextButton(
                  key: ValueKey('ocultar-${p.usuarioId}'),
                  onPressed: _ejecutando ? null : () => _ocultar(p),
                  child: Text(p.oculto ? t.gameModShow : t.gameModHide),
                ),
                TextButton(
                  key: ValueKey('puntuaciones-${p.usuarioId}'),
                  onPressed: _ejecutando ? null : () => _verPuntuaciones(p),
                  child: Text(t.gameModScores),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Las últimas partidas de un perfil, con borrar una o todas.
class _PuntuacionesDelPerfil extends StatefulWidget {
  const _PuntuacionesDelPerfil({
    required this.perfil,
    required this.servicio,
    required this.confirmar,
    required this.ejecutar,
  });

  final PerfilJuegoAdmin perfil;
  final JuegoService servicio;
  final Future<bool> Function(String mensaje) confirmar;
  final Future<bool> Function(Future<void> Function() accion) ejecutar;

  @override
  State<_PuntuacionesDelPerfil> createState() => _PuntuacionesDelPerfilState();
}

class _PuntuacionesDelPerfilState extends State<_PuntuacionesDelPerfil> {
  late Future<List<PuntuacionAdmin>> _puntuaciones;

  @override
  void initState() {
    super.initState();

    _puntuaciones = widget.servicio.puntuacionesDe(widget.perfil.usuarioId);
  }

  void _recargar() {
    setState(() {
      _puntuaciones = widget.servicio.puntuacionesDe(widget.perfil.usuarioId);
    });
  }

  String _nombreDelJuego(AppLocalizations t, Juego? juego) => switch (juego) {
    Juego.penaltis => t.gamePenaltiesShort,
    Juego.toques => t.gameTouchesShort,
    Juego.atrapa => t.gameCatchShort,
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final alias = widget.perfil.alias ?? widget.perfil.email;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${t.gameModScores} · $alias',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: TextButton(
                key: const ValueKey('borrar-todas'),
                onPressed: () async {
                  if (!await widget.confirmar(
                    t.gameModConfirmDeleteAll(alias),
                  )) {
                    return;
                  }

                  final bien = await widget.ejecutar(
                    () => widget.servicio.borrarTodas(widget.perfil.usuarioId),
                  );

                  if (bien) _recargar();
                },
                child: Text(t.gameModDeleteAll),
              ),
            ),
            Flexible(
              child: FutureBuilder<List<PuntuacionAdmin>>(
                future: _puntuaciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(mensajeDeError(t, snapshot.error)),
                    );
                  }

                  final lista = snapshot.data ?? const [];

                  if (lista.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(t.gameModNoScores),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in lista)
                        ListTile(
                          key: ValueKey('puntuacion-${p.id}'),
                          title: Text(
                            '${_nombreDelJuego(t, p.juego)} · ${p.puntos}',
                          ),
                          subtitle: Text(
                            p.fecha == null
                                ? ''
                                : MaterialLocalizations.of(
                                    context,
                                  ).formatShortDate(p.fecha!),
                          ),
                          trailing: IconButton(
                            key: ValueKey('borrar-puntuacion-${p.id}'),
                            tooltip: t.gameModDelete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (!await widget.confirmar(
                                t.gameModConfirmDeleteScore,
                              )) {
                                return;
                              }

                              final bien = await widget.ejecutar(
                                () => widget.servicio.borrarPuntuacion(p.id),
                              );

                              if (bien) _recargar();
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
