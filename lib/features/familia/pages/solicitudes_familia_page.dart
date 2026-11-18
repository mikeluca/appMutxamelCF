import 'package:material_ui/material_ui.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../core/widget/hoja_con_teclado.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/solicitud_familia_model.dart';
import '../services/solicitud_familia_service.dart';
import '../widgets/formulario_familia.dart';

/// "Solicitudes de familia": las familias que piden acceso a sus hijos, para coordinación y administradores (todas) y
/// para los entrenadores (solo las de sus equipos; lo filtra el backend). Por cada hijo se ve lo que escribió la
/// familia y las coincidencias del backend: se elige una con un toque (o se busca otro jugador entre los que puede ver
/// quien revisa) y se aprueba, o se rechaza con un motivo opcional tras confirmarlo.
class SolicitudesFamiliaPage extends StatefulWidget {
  final SolicitudFamiliaService servicio;

  const SolicitudesFamiliaPage({
    super.key,
    this.servicio = const SolicitudFamiliaService(),
  });

  @override
  State<SolicitudesFamiliaPage> createState() => _SolicitudesFamiliaPageState();
}

class _SolicitudesFamiliaPageState extends State<SolicitudesFamiliaPage> {
  List<SolicitudRevision>? _solicitudes;
  bool _error = false;

  /// El jugador elegido para cada hijo (id del hijo -> jugador).
  final Map<int, CoincidenciaJugador> _elegidos = {};

  /// Los jugadores añadidos con "Buscar otro jugador" para cada hijo, además de las coincidencias.
  final Map<int, List<CoincidenciaJugador>> _buscados = {};

  /// Los hijos que se están aprobando o rechazando (su botón queda en espera).
  final Set<int> _enCurso = {};

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await widget.servicio.pendientes();

      if (!mounted) return;

      setState(() {
        _solicitudes = lista;
        _error = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _solicitudes ??= const [];
          _error = true;
        });
      }
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _aprobar(HijoRevision hijo) async {
    final jugador = _elegidos[hijo.id];

    if (jugador == null) return;

    setState(() => _enCurso.add(hijo.id));

    try {
      await widget.servicio.aprobarHijo(hijo.id, jugador.jugadorId);

      if (!mounted) return;

      _avisar(_t.familyApprovedSnack);
      _elegidos.remove(hijo.id);

      await _cargar();
    } catch (e) {
      if (mounted) _avisar(mensajeDeAccion(_t, e));
    } finally {
      if (mounted) setState(() => _enCurso.remove(hijo.id));
    }
  }

  Future<void> _rechazar(SolicitudRevision solicitud, HijoRevision hijo) async {
    // null = cancelar; si no, el motivo escrito (puede ser vacío: es opcional).
    final decision = await showDialog<({String motivo})>(
      context: context,
      builder: (_) => _DialogoRechazo(nombreFamiliar: solicitud.nombreCompleto),
    );

    if (decision == null || !mounted) return;

    final motivo = decision.motivo;

    setState(() => _enCurso.add(hijo.id));

    try {
      await widget.servicio.rechazarHijo(hijo.id, motivo: motivo);

      if (!mounted) return;

      _avisar(_t.familyRejectedSnack);
      _elegidos.remove(hijo.id);

      await _cargar();
    } catch (e) {
      if (mounted) _avisar(mensajeDeAccion(_t, e));
    } finally {
      if (mounted) setState(() => _enCurso.remove(hijo.id));
    }
  }

  Future<void> _buscarOtro(HijoRevision hijo) async {
    final elegido = await showModalBottomSheet<CoincidenciaJugador>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BuscadorJugadores(servicio: widget.servicio),
    );

    if (elegido == null || !mounted) return;

    setState(() {
      final lista = _buscados.putIfAbsent(hijo.id, () => []);

      if (!lista.any((c) => c.jugadorId == elegido.jugadorId) &&
          !hijo.coincidencias.any((c) => c.jugadorId == elegido.jugadorId)) {
        lista.add(elegido);
      }

      _elegidos[hijo.id] = elegido;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final solicitudes = _solicitudes;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.familyRequestsTitle)),
      body: solicitudes == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        t.connectionError,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (solicitudes.isEmpty && !_error)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          t.familyRequestsEmpty,
                          key: const ValueKey('familia-sin-pendientes'),
                        ),
                      ),
                    ),
                  for (final s in solicitudes) _construirSolicitud(context, s),
                ],
              ),
            ),
    );
  }

  Widget _construirSolicitud(BuildContext context, SolicitudRevision s) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;

    final fecha = s.fechaSolicitud == null
        ? null
        : MaterialLocalizations.of(context).formatShortDate(s.fechaSolicitud!);

    return Card(
      key: ValueKey('familia-revision-${s.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.nombreCompleto,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 2),
            Text(
              textoParentescoDeCodigo(t, s.parentesco),
              style: TextStyle(color: colores.primary),
            ),
            const SizedBox(height: 6),
            Text(s.email),
            if ((s.telefono ?? '').isNotEmpty) Text(s.telefono!),
            if (fecha != null)
              Text(
                fecha,
                style: TextStyle(color: colores.onSurfaceVariant, fontSize: 13),
              ),
            const Divider(height: 28),
            for (final h in s.hijos) ...[
              _construirHijo(context, s, h),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirHijo(
    BuildContext context,
    SolicitudRevision s,
    HijoRevision h,
  ) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;
    final enCurso = _enCurso.contains(h.id);
    final elegido = _elegidos[h.id];

    final opciones = [...h.coincidencias, ...?_buscados[h.id]];

    return Container(
      key: ValueKey('familia-revision-hijo-${h.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colores.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.familyWrittenByFamily,
            style: TextStyle(color: colores.onSurfaceVariant, fontSize: 12),
          ),
          Text(
            [h.nombreCompleto, if (h.equipo.isNotEmpty) h.equipo].join(' · '),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          if (!h.pendiente) ...[
            const SizedBox(height: 6),
            Text(
              h.estado == estadoHijoAprobado
                  ? t.familyChildApproved
                  : t.familyChildRejected,
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              t.familyMatchesTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (opciones.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  t.familyNoMatches,
                  key: ValueKey('familia-sin-coincidencias-${h.id}'),
                  style: TextStyle(color: colores.onSurfaceVariant),
                ),
              ),
            for (final c in opciones) _construirCoincidencia(context, h, c),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  key: ValueKey('familia-buscar-otro-${h.id}'),
                  onPressed: enCurso ? null : () => _buscarOtro(h),
                  icon: const Icon(Icons.search),
                  label: Text(t.familySearchOther),
                ),
              ],
            ),
            if (elegido == null)
              Text(
                t.familyChooseMatch,
                style: TextStyle(color: colores.onSurfaceVariant, fontSize: 12),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: ValueKey('familia-aprobar-${h.id}'),
                    onPressed: (elegido == null || enCurso)
                        ? null
                        : () => _aprobar(h),
                    child: Text(t.familyApprove),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('familia-rechazar-${h.id}'),
                    onPressed: enCurso ? null : () => _rechazar(s, h),
                    child: Text(t.familyReject),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirCoincidencia(
    BuildContext context,
    HijoRevision h,
    CoincidenciaJugador c,
  ) {
    final t = AppLocalizations.of(context);
    final seleccionada = _elegidos[h.id]?.jugadorId == c.jugadorId;
    final colores = Theme.of(context).colorScheme;

    final detalle = [
      if (c.equipo.isNotEmpty) c.equipo,
      if (c.dorsal != null) t.familyJerseyNumber(c.dorsal!),
    ].join(' · ');

    return Card(
      key: ValueKey('familia-coincidencia-${h.id}-${c.jugadorId}'),
      margin: const EdgeInsets.only(top: 6),
      color: seleccionada ? colores.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _elegidos[h.id] = c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  seleccionada
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: colores.primary,
                ),
              ),
              const SizedBox(width: 10),
              // Todo va en una columna que se ajusta al ancho: con letra grande en un iPhone pequeño no desborda.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (detalle.isNotEmpty)
                      Text(
                        detalle,
                        style: TextStyle(
                          color: colores.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    if (c.coincideEquipo)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: Text(t.familySameTeam),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La hoja de "Buscar otro jugador": el campo de búsqueda y los resultados (solo los que puede ver quien revisa).
class _BuscadorJugadores extends StatefulWidget {
  final SolicitudFamiliaService servicio;

  const _BuscadorJugadores({required this.servicio});

  @override
  State<_BuscadorJugadores> createState() => _BuscadorJugadoresState();
}

class _BuscadorJugadoresState extends State<_BuscadorJugadores> {
  final _controlador = TextEditingController();
  List<CoincidenciaJugador> _resultados = const [];
  bool _buscado = false;
  bool _buscando = false;
  int _secuencia = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _buscar(String texto) async {
    final consulta = texto.trim();
    final mia = ++_secuencia;

    if (consulta.length < 3) {
      setState(() {
        _resultados = const [];
        _buscado = false;
      });
      return;
    }

    setState(() => _buscando = true);

    try {
      final lista = await widget.servicio.buscarJugadores(consulta);

      // Una búsqueda más nueva ya ha salido: esta se descarta.
      if (!mounted || mia != _secuencia) return;

      setState(() {
        _resultados = lista;
        _buscado = true;
      });
    } catch (_) {
      if (mounted && mia == _secuencia) {
        setState(() {
          _resultados = const [];
          _buscado = true;
        });
      }
    } finally {
      if (mounted && mia == _secuencia) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return HojaConTeclado(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            key: const ValueKey('familia-buscador'),
            controller: _controlador,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _buscar,
            decoration: InputDecoration(
              hintText: t.familySearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _buscando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (_buscado && _resultados.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.familySearchNoResults,
              key: const ValueKey('familia-sin-resultados'),
              textAlign: TextAlign.center,
            ),
          ),
        for (final c in _resultados)
          ListTile(
            key: ValueKey('familia-resultado-${c.jugadorId}'),
            title: Text(c.nombre),
            subtitle: c.equipo.isEmpty ? null : Text(c.equipo),
            onTap: () => Navigator.pop(context, c),
          ),
      ],
    );
  }
}

/// La confirmación de rechazar un hijo, con el motivo opcional. Tiene su propio controlador para liberarlo cuando el
/// diálogo ya se ha cerrado del todo (no mientras anima su salida).
class _DialogoRechazo extends StatefulWidget {
  final String nombreFamiliar;

  const _DialogoRechazo({required this.nombreFamiliar});

  @override
  State<_DialogoRechazo> createState() => _DialogoRechazoState();
}

class _DialogoRechazoState extends State<_DialogoRechazo> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.familyRejectTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.familyRejectBody(widget.nombreFamiliar)),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('familia-motivo'),
              controller: _motivo,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: t.familyRejectReasonHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey('familia-confirmar-rechazo'),
          onPressed: () => Navigator.pop(context, (motivo: _motivo.text)),
          child: Text(t.familyReject),
        ),
      ],
    );
  }
}
