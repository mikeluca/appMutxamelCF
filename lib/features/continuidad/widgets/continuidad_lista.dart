import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/continuidad_model.dart';
import '../services/continuidad_service.dart';
import 'continuidad_card.dart';

/// Las tarjetas de continuidad del usuario. No pinta nada (ni siquiera un
/// hueco) mientras carga, si falla o si no hay nada que confirmar.
class ContinuidadLista extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real.
  final ContinuidadService? servicio;

  /// Hueco que se deja bajo cada tarjeta.
  final double separacion;

  const ContinuidadLista({super.key, this.servicio, this.separacion = 16});

  @override
  State<ContinuidadLista> createState() => ContinuidadListaState();
}

class ContinuidadListaState extends State<ContinuidadLista> {
  late final ContinuidadService _servicio =
      widget.servicio ?? ContinuidadService();

  List<ContinuidadJugadorModel> _jugadores = [];
  final Set<int> _guardando = {};

  @override
  void initState() {
    super.initState();
    recargar();
  }

  /// Vuelve a pedir la lista (p. ej. al hacer pull-to-refresh de la pantalla).
  Future<void> recargar() async {
    try {
      final lista = await _servicio.listar();

      if (!mounted) return;

      setState(() => _jugadores = lista);
    } catch (_) {
      // Es un añadido a la pantalla: si falla, la pantalla sigue sin él.
      if (!mounted) return;

      setState(() => _jugadores = []);
    }
  }

  Future<void> _responder(ContinuidadJugadorModel jugador, String r) async {
    final t = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.maybeOf(context);

    setState(() => _guardando.add(jugador.jugadorId));

    try {
      final nuevo = await _servicio.responder(jugador.jugadorId, r);

      if (!mounted) return;

      setState(() {
        _jugadores = [
          for (final j in _jugadores) j.jugadorId == nuevo.jugadorId ? nuevo : j,
        ];
      });

      mensajes?.showSnackBar(SnackBar(content: Text(t.continuitySaved)));
    } catch (e) {
      mensajes?.showSnackBar(SnackBar(content: Text(mensajeDeAccion(t, e))));
    } finally {
      if (mounted) {
        setState(() => _guardando.remove(jugador.jugadorId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_jugadores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final jugador in _jugadores)
          Padding(
            padding: EdgeInsets.only(bottom: widget.separacion),
            child: ContinuidadCard(
              jugador: jugador,
              guardando: _guardando.contains(jugador.jugadorId),
              onResponder: (r) => _responder(jugador, r),
            ),
          ),
      ],
    );
  }
}
