import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/continuidad_model.dart';
import '../services/continuidad_service.dart';
import '../widgets/continuidad_card.dart';

/// Pantalla de continuidad de la familia: a donde lleva el push CONTINUIDAD.
/// Lista las tarjetas "¿Seguirá X en la temporada Y?" de sus jugadores.
class ContinuidadPage extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real.
  final ContinuidadService? servicio;

  const ContinuidadPage({super.key, this.servicio});

  @override
  State<ContinuidadPage> createState() => _ContinuidadPageState();
}

class _ContinuidadPageState extends State<ContinuidadPage> {
  late final ContinuidadService _servicio =
      widget.servicio ?? ContinuidadService();

  List<ContinuidadJugadorModel> _jugadores = [];
  final Set<int> _guardando = {};
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await _servicio.listar();

      if (!mounted) return;

      setState(() {
        _jugadores = lista;
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
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.continuityTitle)),
      body: _contenido(t),
    );
  }

  Widget _contenido(AppLocalizations t) {
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
              Text(mensajeDeError(t, _error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _cargando = true;
                    _error = null;
                  });
                  _cargar();
                },
                icon: const Icon(Icons.refresh),
                label: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargar,
      child: _jugadores.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 80),
                Text(
                  t.continuityNothingToConfirm,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                for (final jugador in _jugadores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ContinuidadCard(
                      jugador: jugador,
                      guardando: _guardando.contains(jugador.jugadorId),
                      onResponder: (r) => _responder(jugador, r),
                    ),
                  ),
              ],
            ),
    );
  }
}
