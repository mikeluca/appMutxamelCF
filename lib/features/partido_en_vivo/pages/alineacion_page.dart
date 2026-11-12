import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/widgets/campo_futbol.dart';
import '../models/formaciones.dart';
import '../models/partido_en_vivo_models.dart';
import '../services/partido_en_vivo_service.dart';

/// Alineación del partido en tres pasos: la formación (opcional), el once inicial y los suplentes (opcional). Se
/// eligen jugadores de GET /convocados tocándolos en el orden en que se quieren publicar; con formación, ese orden
/// los coloca en el campo (portero, defensas de izquierda a derecha, medios y delanteros) y una vista previa del
/// campo se va llenando. El aviso se manda con sus nombres de retransmisión solo si la casilla "Enviar aviso" está
/// marcada (la primera vez lo está; si ya se envió una alineación, no). Se cierra con `true` si se envió.
class AlineacionPage extends StatefulWidget {
  final PartidoEnVivoService service;
  final PartidoEnVivoDisponible partido;

  /// true si el partido ya tiene una alineación enviada: reenviarla no avisa de nuevo salvo que se marque.
  final bool yaEnviada;

  const AlineacionPage({
    super.key,
    required this.service,
    required this.partido,
    this.yaEnviada = false,
  });

  @override
  State<AlineacionPage> createState() => _AlineacionPageState();
}

class _AlineacionPageState extends State<AlineacionPage> {
  static const int _pasoFormacion = 0;
  static const int _pasoOnce = 1;
  static const int _pasoSuplentes = 2;

  List<ConvocadoEnVivo>? _jugadores;
  bool _errorCarga = false;

  /// Ids elegidos, en el orden de elección (que es el de publicación y el de posición en el campo).
  final List<int> _titulares = [];
  final List<int> _suplentes = [];

  /// La formación elegida; null = sin formación.
  String? _formacion;

  int _paso = _pasoFormacion;
  bool _enviando = false;

  /// "Enviar aviso": marcada la primera vez, desmarcada si ya se envió una alineación.
  late bool _avisar = !widget.yaEnviada;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  /// Titulares que caben: con formación, justo los que pide; sin ella, los de la modalidad.
  int get _maximo => _formacion == null
      ? widget.partido.maximoTitulares
      : Formaciones.titulares(_formacion!);

  List<String> get _formaciones =>
      Formaciones.paraModalidad(widget.partido.modalidad);

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

  List<int> get _elegidosDelPaso =>
      _paso == _pasoOnce ? _titulares : _suplentes;

  void _elegirFormacion(String? formacion) {
    setState(() {
      _formacion = formacion;

      // Con otra formación caben otros titulares: los de más se quitan por el final.
      final maximo = _maximo;

      if (_titulares.length > maximo) {
        _titulares.removeRange(maximo, _titulares.length);
      }
    });
  }

  void _tocar(ConvocadoEnVivo jugador) {
    final lista = _elegidosDelPaso;

    if (lista.contains(jugador.jugadorId)) {
      // Quitarlo reordena: los siguientes suben un puesto.
      setState(() => lista.remove(jugador.jugadorId));
      return;
    }

    if (_paso == _pasoOnce && _titulares.length >= _maximo) {
      _mostrarMensaje(_t.liveLineupMaxReached(_maximo));
      return;
    }

    setState(() {
      lista.add(jugador.jugadorId);
      // Un titular nuevo no puede seguir en el banquillo.
      if (_paso == _pasoOnce) _suplentes.remove(jugador.jugadorId);
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

  String _nombres(List<int> ids) =>
      ids.map((id) => _jugador(id).nombreEnDirecto).join(', ');

  /// Con formación se exige el once exacto (el backend lo comprueba también).
  bool get _onceCompleto =>
      _titulares.isNotEmpty &&
      (_formacion == null || _titulares.length == _maximo);

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
        formacion: _formacion,
        avisar: _avisar,
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

    if (_paso == _pasoFormacion) {
      return Column(
        children: [
          Expanded(child: _construirPasoFormacion()),
          _construirPie(),
        ],
      );
    }

    return Column(
      children: [
        _construirCabecera(),
        if (_paso == _pasoOnce && _formacion != null) _construirVistaPreviaCampo(),
        Expanded(child: _construirLista()),
        _construirPie(),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Paso 0: formación
  // ------------------------------------------------------------------

  Widget _construirPasoFormacion() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Text(
          _t.liveFormationTitle,
          key: const ValueKey('titulo-paso'),
          style: TextStyle(
            color: _colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t.liveFormationHint,
          style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('formacion-ninguna'),
              label: Text(_t.liveFormationNone),
              selected: _formacion == null,
              onSelected: (_) => _elegirFormacion(null),
            ),
            for (final formacion in _formaciones)
              ChoiceChip(
                key: ValueKey('formacion-$formacion'),
                label: Text(formacion),
                selected: _formacion == formacion,
                onSelected: (_) => _elegirFormacion(formacion),
              ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Pasos 1 y 2
  // ------------------------------------------------------------------

  Widget _construirCabecera() {
    final origen = _origen;
    final esSuplentes = _paso == _pasoSuplentes;

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
                _formacion == null
                    ? _t.liveLineupIncompleteWarning(_titulares.length, _maximo)
                    : _t.liveLineupFormationNeeds(_maximo),
                key: const ValueKey('aviso-incompleto'),
                style: TextStyle(color: _colors.error, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  /// El campo que se va llenando según se eligen los titulares: cada uno en la posición que le toca por su orden.
  Widget _construirVistaPreviaCampo() {
    final formacion = _formacion!;
    final jugadores = <PosicionEnCampo>[];

    for (var i = 0; i < _titulares.length; i++) {
      final posicion = Formaciones.posicion(formacion, i + 1);

      if (posicion == null) continue;

      final jugador = _jugador(_titulares[i]);

      jugadores.add(
        PosicionEnCampo(
          fila: posicion.fila,
          columna: posicion.columna,
          child: _MarcadorPrevio(
            dorsal: jugador.dorsal,
            nombre: jugador.nombreEnDirecto,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 210,
        child: Center(
          child: CampoFutbol(
            key: const ValueKey('vista-previa-campo'),
            formacion: formacion,
            filas: Formaciones.filas(formacion),
            anchoJugador: 46,
            altoJugador: 40,
            jugadores: jugadores,
          ),
        ),
      ),
    );
  }

  Widget _construirLista() {
    // En el paso de suplentes ya no salen los titulares.
    final visibles = _jugadores!
        .where((j) => _paso == _pasoOnce || !_titulares.contains(j.jugadorId))
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
    final esSuplentes = _paso == _pasoSuplentes;

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
            if (esSuplentes && _origen == ConvocadoEnVivo.origenConvocatoria)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('anadir-resto'),
                  onPressed: _enviando ? null : _anadirElResto,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(_t.liveLineupAddRest),
                ),
              ),
            if (esSuplentes)
              // Un Material propio: el ListTile pinta sobre el Material mÃ¡s cercano y el pie tiene color.
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  key: const ValueKey('enviar-aviso'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _avisar,
                  onChanged: _enviando
                      ? null
                      : (valor) => setState(() => _avisar = valor ?? false),
                  title: Text(_t.liveLineupNotify),
                ),
              ),
            Row(
              children: [
                if (_paso != _pasoFormacion)
                  OutlinedButton(
                    onPressed: _enviando ? null : () => _irAlPaso(_paso - 1),
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
                else if (_paso == _pasoFormacion)
                  FilledButton(
                    key: const ValueKey('paso-formacion'),
                    onPressed: () => _irAlPaso(_pasoOnce),
                    child: Text(_t.liveLineupNext),
                  )
                else
                  FilledButton(
                    key: const ValueKey('paso-siguiente'),
                    // Sin formación se avisa del once incompleto, pero se puede continuar; con formación hace
                    // falta el once exacto.
                    onPressed: _onceCompleto
                        ? () => _irAlPaso(_pasoSuplentes)
                        : null,
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

/// Un titular en la vista previa del campo: círculo con el dorsal y el nombre debajo.
class _MarcadorPrevio extends StatelessWidget {
  final int? dorsal;
  final String nombre;

  const _MarcadorPrevio({required this.dorsal, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: const Color(0xFF0B3D5C),
          child: Text(
            dorsal?.toString() ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(blurRadius: 2, color: Colors.black87)],
          ),
        ),
      ],
    );
  }
}
