import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/ficha_partido_model.dart';
import 'ficha_comunes.dart';

/// Pestaña Detalle: los eventos con lo último arriba. Minuto e icono en el centro; los hechos del Mutxamel a su lado
/// (izquierda si juega de local, derecha si es visitante) y el gol del rival al otro; el descanso y el final, como
/// separadores a lo ancho con su marcador.
class FichaDetalle extends StatelessWidget {
  final FichaPartido ficha;

  const FichaDetalle({super.key, required this.ficha});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    // Siempre desplazable, para que el "tirar para refrescar" funcione también con la lista vacía.
    if (ficha.eventos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.sports_soccer_outlined, size: 48, color: colors.outline),
          const SizedBox(height: 12),
          Text(
            t.fichaNotBroadcast,
            key: const ValueKey('ficha-sin-eventos'),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
          ),
        ],
      );
    }

    final local = ficha.cabecera.mutxamelEsLocal;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ficha.eventos.length,
      itemBuilder: (context, indice) {
        final evento = ficha.eventos[indice];

        return evento.esSeparador
            ? _Separador(
                clave: 'evento-$indice',
                evento: evento,
                local: local,
              )
            : _FilaEvento(
                clave: 'evento-$indice',
                evento: evento,
                mutxamelEsLocal: local,
              );
      },
    );
  }
}

/// El marcador de un evento en el orden en que se pinta (local - visitante).
String _marcadorDe(EventoFicha evento, bool mutxamelEsLocal) {
  final favor = evento.golesFavor;
  final contra = evento.golesContra;

  return mutxamelEsLocal
      ? marcadorTexto(favor, contra)
      : marcadorTexto(contra, favor);
}

class _Separador extends StatelessWidget {
  final String clave;
  final EventoFicha evento;
  final bool local;

  const _Separador({
    required this.clave,
    required this.evento,
    required this.local,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final titulo = evento.tipo == EventoFicha.descanso
        ? t.fichaHalftimeSeparator
        : t.fichaFinalSeparator;

    return Container(
      key: ValueKey(clave),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: colors.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$titulo ${_marcadorDe(evento, local)}',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaEvento extends StatelessWidget {
  final String clave;
  final EventoFicha evento;
  final bool mutxamelEsLocal;

  const _FilaEvento({
    required this.clave,
    required this.evento,
    required this.mutxamelEsLocal,
  });

  @override
  Widget build(BuildContext context) {
    // Los nuestros del lado del Mutxamel; el gol del rival, en el otro.
    final enIzquierda = evento.esNuestro == mutxamelEsLocal;
    final contenido = _contenido(context);

    return Padding(
      key: ValueKey(clave),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: enIzquierda
                ? Align(alignment: Alignment.centerRight, child: contenido)
                : const SizedBox.shrink(),
          ),
          _Centro(evento: evento),
          Expanded(
            child: enIzquierda
                ? const SizedBox.shrink()
                : Align(alignment: Alignment.centerLeft, child: contenido),
          ),
        ],
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final texto = TextStyle(color: colors.onSurface, fontSize: 14);

    switch (evento.tipo) {
      case EventoFicha.golFavor:
      case EventoFicha.golContra:
        final nombre = evento.tipo == EventoFicha.golContra
            ? t.fichaGoalAgainst
            : (evento.jugador ?? t.fichaGoal);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                nombre,
                overflow: TextOverflow.ellipsis,
                style: texto.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              key: const ValueKey('marcador-gol'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _marcadorDe(evento, mutxamelEsLocal),
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );

      case EventoFicha.cambio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: t.fichaSubIn,
              child: Text(
                evento.jugadorEntra ?? '',
                key: const ValueKey('cambio-entra'),
                style: texto.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Semantics(
              label: t.fichaSubOut,
              child: Text(
                evento.jugador ?? '',
                key: const ValueKey('cambio-sale'),
                style: texto.copyWith(color: colors.outline),
              ),
            ),
          ],
        );

      default:
        // Tarjetas.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(evento.jugador ?? '', style: texto),
            if (evento.dobleAmarilla)
              Text(
                t.fichaSecondYellow,
                style: TextStyle(color: colors.outline, fontSize: 12),
              ),
          ],
        );
    }
  }
}

class _Centro extends StatelessWidget {
  final EventoFicha evento;

  const _Centro({required this.evento});

  Widget _icono(BuildContext context) {
    final t = AppLocalizations.of(context);

    switch (evento.tipo) {
      case EventoFicha.golFavor:
      case EventoFicha.golContra:
        return Semantics(
          label: t.fichaGoal,
          child: const Icon(
            Icons.sports_soccer,
            key: ValueKey('icono-gol'),
            size: 22,
          ),
        );
      case EventoFicha.cambio:
        return const Column(
          key: ValueKey('icono-cambio'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward, size: 15, color: Color(0xFF2E9E4F)),
            Icon(Icons.arrow_downward, size: 15, color: Color(0xFFD62828)),
          ],
        );
      case EventoFicha.tarjetaRoja:
        return Semantics(
          label: evento.dobleAmarilla ? t.fichaSecondYellow : t.fichaRedCard,
          child: const TarjetaIcono(roja: true),
        );
      default:
        return Semantics(
          label: t.fichaYellowCard,
          child: const TarjetaIcono(roja: false),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 78,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              evento.minuto == null ? '' : "${evento.minuto}'",
              key: const ValueKey('minuto-evento'),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 24, child: Center(child: _icono(context))),
        ],
      ),
    );
  }
}
