import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/hoja_con_teclado.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/player_model.dart';
import '../services/team_services.dart';
import '../utils/posicion_jugador.dart';

/// Abre la hoja para editar el dorsal y la posición de [jugador]. Devuelve el jugador actualizado, o null si se cierra sin
/// guardar.
Future<PlayerModel?> mostrarEditarJugador(
  BuildContext context, {
  required PlayerModel jugador,
  required TeamService servicio,
}) {
  return showModalBottomSheet<PlayerModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => EditarJugadorSheet(jugador: jugador, servicio: servicio),
  );
}

/// Hoja inferior: el nombre del jugador, el dorsal (1-99, o vacío) y la posición (lista cerrada o "Sin posición"). El
/// botón Guardar queda fijo abajo, visible con el teclado abierto.
class EditarJugadorSheet extends StatefulWidget {
  final PlayerModel jugador;
  final TeamService servicio;

  const EditarJugadorSheet({
    super.key,
    required this.jugador,
    required this.servicio,
  });

  @override
  State<EditarJugadorSheet> createState() => _EditarJugadorSheetState();
}

class _EditarJugadorSheetState extends State<EditarJugadorSheet> {
  /// Valores del selector que no son un código de la lista.
  static const String _ninguna = '';
  static const String _actual = '#actual';

  late final TextEditingController _dorsal = TextEditingController(
    text: widget.jugador.dorsal?.toString() ?? '',
  );

  late final String _posicionInicial = _seleccionInicial();
  late String _posicion = _posicionInicial;

  bool _guardando = false;
  String? _error;

  AppLocalizations get _t => AppLocalizations.of(context);

  /// El texto guardado cuando no es de la lista (posicionCodigo null y posicion con texto), o null.
  String? get _textoAntiguo {
    final j = widget.jugador;
    final texto = j.posicion?.trim();

    return j.posicionCodigo == null && texto != null && texto.isNotEmpty
        ? texto
        : null;
  }

  String _seleccionInicial() {
    final codigo = widget.jugador.posicionCodigo;

    if (codigo != null && posicionesJugador.contains(codigo)) return codigo;

    return _textoAntiguo != null ? _actual : _ninguna;
  }

  @override
  void dispose() {
    _dorsal.dispose();
    super.dispose();
  }

  /// Vacío es válido (sin dorsal); si no, un entero entre 1 y 99.
  ({bool valido, int? dorsal}) get _lecturaDorsal {
    final texto = _dorsal.text.trim();

    if (texto.isEmpty) return (valido: true, dorsal: null);

    final valor = int.tryParse(texto);

    if (valor == null || valor < 1 || valor > 99) {
      return (valido: false, dorsal: null);
    }

    return (valido: true, dorsal: valor);
  }

  bool get _hayCambios =>
      _lecturaDorsal.dorsal != widget.jugador.dorsal ||
      _posicion != _posicionInicial;

  bool get _puedeGuardar => !_guardando && _lecturaDorsal.valido && _hayCambios;

  Future<void> _guardar() async {
    if (!_puedeGuardar) return;

    final t = _t;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      // Con el texto antiguo seleccionado no hay código que enviar: la API solo admite los de la lista.
      final codigo = posicionesJugador.contains(_posicion) ? _posicion : null;

      final actualizado = await widget.servicio.actualizarDorsalPosicion(
        jugadorId: widget.jugador.id,
        dorsal: _lecturaDorsal.dorsal,
        posicionCodigo: codigo,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        widget.jugador.conDorsalYPosicion(
          dorsal: actualizado.dorsal,
          posicion: actualizado.posicion,
          posicionCodigo: actualizado.posicionCodigo,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
        // 409 (dorsal repetido) y demás 4xx traen el mensaje del servidor; 403, sin permiso; el resto, sin conexión.
        _error = e is ApiException ? mensajeDeAccion(t, e) : t.connectionError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final colors = Theme.of(context).colorScheme;
    final antiguo = _textoAntiguo;
    final dorsalInvalido = !_lecturaDorsal.valido;

    return HojaConTeclado(
      pie: FilledButton(
        key: const ValueKey('guardar-jugador'),
        onPressed: _puedeGuardar ? _guardar : null,
        child: _guardando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(t.save),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            widget.jugador.nombreCompleto,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            key: const ValueKey('campo-dorsal'),
            controller: _dorsal,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: t.fieldDorsal,
              border: const OutlineInputBorder(),
              counterText: '',
              errorText: dorsalInvalido ? t.playerDorsalInvalid : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DropdownButtonFormField<String>(
            key: const ValueKey('campo-posicion'),
            initialValue: _posicion,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.fieldPosition,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: _ninguna,
                child: Text(t.playerPositionNone),
              ),
              for (final codigo in posicionesJugador)
                DropdownMenuItem(
                  value: codigo,
                  child: Text(nombrePosicion(t, codigo)!),
                ),
              if (antiguo != null)
                DropdownMenuItem(
                  value: _actual,
                  child: Text(t.playerPositionCurrent(antiguo)),
                ),
            ],
            onChanged: _guardando
                ? null
                : (valor) => setState(() {
                    _posicion = valor ?? _ninguna;
                    _error = null;
                  }),
          ),
        ),
        if (_posicion == _actual)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              t.playerPositionLegacyHint,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        if (_error != null)
          Padding(
            key: const ValueKey('error-jugador'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          ),
      ],
    );
  }
}
