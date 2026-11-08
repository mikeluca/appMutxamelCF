import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/partido_en_vivo_models.dart';
import '../services/partido_en_vivo_service.dart';

/// Alineación del partido en dos pasos: el once inicial y los suplentes (opcional). Se eligen
/// jugadores de GET /convocados tocándolos en el orden en que se quieren publicar; el aviso se
/// manda con sus nombres de retransmisión. Se cierra con `true` si la alineación se envió.
class AlineacionPage extends StatefulWidget {
  final PartidoEnVivoService service;
  final PartidoEnVivoDisponible partido;

  const AlineacionPage({
    super.key,
    required this.service,
    required this.partido,
  });

  @override
  State<AlineacionPage> createState() => _AlineacionPageState();
}

class _AlineacionPageState extends State<AlineacionPage> {
  List<ConvocadoEnVivo>? _jugadores;
  bool _errorCarga = false;

  /// Ids elegidos, en el orden de elección (que es el de publicación).
  final List<int> _titulares = [];
  final List<int> _suplentes = [];

  /// 0 = once inicial, 1 = suplentes.
  int _paso = 0;
  bool _enviando = false;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  int get _maximo => widget.partido.maximoTitulares;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _jugadores = null;
      _errorCarga = false;
    });

    try {
      final jugadores = await widget.service.obtenerConvocados(
        widget.partido.id,
      );

      if (!mounted) return;

      setState(() => _jugadores = jugadores);
    } catch (_) {
      if (!mounted) return;

      setState(() => _errorCarga = true);
    }
  }

  ConvocadoEnVivo _jugador(int id) =>
      _jugadores!.firstWhere((j) => j.jugadorId == id);

  /// Con CONVOCATORIA / PLANTILLA según de dónde sale la lista; null si el backend no lo dice.
  String? get _origen {
    final jugadores = _jugadores;

    if (jugadores == null || jugadores.isEmpty) return null;

    return jugadores.first.origen;
  }

  List<int> get _elegidosDelPaso => _paso == 0 ? _titulares : _suplentes;

  void _tocar(ConvocadoEnVivo jugador) {
    final lista = _elegidosDelPaso;

    if (lista.contains(jugador.jugadorId)) {
      // Quitarlo reordena: los siguientes suben un puesto.
      setState(() => lista.remove(jugador.jugadorId));
      return;
    }

    if (_paso == 0 && _titulares.length >= _maximo) {
      _mostrarMensaje(_t.liveLineupMaxReached(_maximo));
      return;
    }

    setState(() {
      lista.add(jugador.jugadorId);
      // Un titular nuevo no puede seguir en el banquillo.
      if (_paso == 0) _suplentes.remove(jugador.jugadorId);
    });
  }

  /// Los convocados que aún no están ni de titulares ni de suplentes, por dorsal.
  void _anadirElResto() {
    final restantes = _jugadores!
        .where(
          (j) =>
              !_titulares.contains(j.jugadorId) &&
              !_suplentes.contains(j.jugadorId),
        )
        .toList();

    restantes.sort((a, b) {
      final da = a.dorsal;
      final db = b.dorsal;

      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      return da.compareTo(db);
    });

    setState(() => _suplentes.addAll(restantes.map((j) => j.jugadorId)));
  }

  void _irAlPaso(int paso) {
    setState(() => _paso = paso);
  }

  String _nombres(List<int> ids) => ids.map((id) => _jugador(id).nombreEnDirecto).join(', ');

  Future<void> _enviar() async {
    if (_titulares.isEmpty) {
      _mostrarMensaje(_t.liveLineupNeedStarters);
      return;
    }

    setState(() => _enviando = true);

    try {
      await widget.service.enviarAlineacion(
        widget.partido.id,
        titulares: List.of(_titulares),
        suplentes: List.of(_suplentes),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      // Los 400 del servidor llegan en texto claro.
      _mostrarMensaje(_t.liveSendError(e.toString()));
      setState(() => _enviando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.liveLineupButton)),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_errorCarga) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t.liveLineupLoadError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: Text(_t.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_jugadores == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _construirCabecera(),
        Expanded(child: _construirLista()),
        _construirPie(),
      ],
    );
  }

  Widget _construirCabecera() {
    final origen = _origen;
    final esSuplentes = _paso == 1;

    final textoOrigen = switch (origen) {
      ConvocadoEnVivo.origenConvocatoria => _t.liveLineupOriginCallup,
      ConvocadoEnVivo.origenPlantilla => _t.liveLineupOriginSquad,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (textoOrigen != null)
            Row(
              children: [
                Icon(Icons.groups_outlined, size: 18, color: _colors.primary),
                const SizedBox(width: 6),
                Text(
                  textoOrigen,
                  key: const ValueKey('origen-jugadores'),
                  style: TextStyle(
                    color: _colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  esSuplentes
                      ? _t.liveSubstitutesLabel
                      : _t.liveStartingLineupLabel,
                  key: const ValueKey('titulo-paso'),
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!esSuplentes)
                Text(
                  '${_titulares.length}/$_maximo',
                  key: const ValueKey('contador-titulares'),
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            esSuplentes
                ? _t.liveLineupSubstitutesHint
                : _t.liveLineupStartingHint,
            style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
          ),
          if (!esSuplentes && _titulares.length < _maximo)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _t.liveLineupIncompleteWarning(_titulares.length, _maximo),
                key: const ValueKey('aviso-incompleto'),
                style: TextStyle(color: _colors.error, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirLista() {
    // En el paso de suplentes ya no salen los titulares.
    final visibles = _jugadores!
        .where((j) => _paso == 0 || !_titulares.contains(j.jugadorId))
        .toList();

    if (visibles.isEmpty) {
      return Center(child: Text(_t.liveLineupNoPlayers));
    }

    final elegidos = _elegidosDelPaso;

    return ListView.builder(
      itemCount: visibles.length,
      itemBuilder: (context, indice) {
        final jugador = visibles[indice];
        final orden = elegidos.indexOf(jugador.jugadorId);
        final elegido = orden >= 0;

        return ListTile(
          key: ValueKey('jugador-${jugador.jugadorId}'),
          selected: elegido,
          leading: CircleAvatar(
            backgroundColor: elegido
                ? _colors.primary
                : _colors.primaryContainer,
            child: Text(
              jugador.dorsal?.toString() ?? '-',
              style: TextStyle(
                color: elegido ? _colors.onPrimary : _colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(jugador.nombre),
          subtitle: jugador.tieneNombreRetransmision
              ? Text(jugador.nombreRetransmision!)
              : null,
          trailing: elegido
              ? CircleAvatar(
                  key: ValueKey('orden-${jugador.jugadorId}'),
                  radius: 14,
                  backgroundColor: _colors.secondary,
                  child: Text(
                    '${orden + 1}',
                    style: TextStyle(
                      color: _colors.onSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
              : null,
          onTap: _enviando ? null : () => _tocar(jugador),
        );
      },
    );
  }

  Widget _construirPie() {
    final esSuplentes = _paso == 1;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: _colors.surfaceContainerLow,
          border: Border(top: BorderSide(color: _colors.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (esSuplentes) ..._construirVistaPrevia(),
            if (esSuplentes &&
                _origen == ConvocadoEnVivo.origenConvocatoria)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('anadir-resto'),
                  onPressed: _enviando ? null : _anadirElResto,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(_t.liveLineupAddRest),
                ),
              ),
            Row(
              children: [
                if (esSuplentes)
                  OutlinedButton(
                    onPressed: _enviando ? null : () => _irAlPaso(0),
                    child: Text(_t.liveLineupBack),
                  ),
                const Spacer(),
                if (esSuplentes)
                  FilledButton.icon(
                    key: const ValueKey('enviar-alineacion'),
                    onPressed: _enviando || _titulares.isEmpty ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_t.send),
                  )
                else
                  FilledButton(
                    key: const ValueKey('paso-siguiente'),
                    // Con el once incompleto se avisa, pero se puede continuar.
                    onPressed: _titulares.isEmpty ? null : () => _irAlPaso(1),
                    child: Text(_t.liveLineupNext),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "Once inicial: A, B" y, si hay, "Suplentes: C, D": el texto del aviso.
  List<Widget> _construirVistaPrevia() {
    return [
      Text(
        _t.liveLineupPreviewTitle,
        style: TextStyle(
          color: _colors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${_t.liveStartingLineupLabel}: ${_nombres(_titulares)}',
        key: const ValueKey('vista-previa-once'),
      ),
      const SizedBox(height: 2),
      Text(
        _suplentes.isEmpty
            ? _t.liveLineupNoSubstitutes
            : '${_t.liveSubstitutesLabel}: ${_nombres(_suplentes)}',
        key: const ValueKey('vista-previa-suplentes'),
      ),
      const SizedBox(height: 4),
    ];
  }
}
