import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/ficha_partido_model.dart';
import 'ficha_comunes.dart';

/// Pestaña Últ. partidos: los últimos partidos con resultado, cada uno con el escudo local, la píldora del
/// resultado (verde ganado, gris empatado, rojo perdido) y el escudo visitante, con el Mutxamel en casa o fuera según
/// se jugó. Tocar una fila abre la ficha de ese partido.
class FichaForma extends StatelessWidget {
  final List<FormaFicha> forma;
  final void Function(int partidoId) alTocar;

  const FichaForma({super.key, required this.forma, required this.alTocar});

  static const Color verde = Color(0xFF2E9E4F);
  static const Color gris = Color(0xFF8A8F98);
  static const Color rojo = Color(0xFFD62828);

  static Color colorDe(String resultado) {
    return switch (resultado) {
      'G' => verde,
      'P' => rojo,
      _ => gris,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    if (forma.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          Text(
            t.fichaFormEmpty,
            key: const ValueKey('ficha-sin-forma'),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: forma.length,
      itemBuilder: (context, indice) {
        final partido = forma[indice];

        return _FilaForma(
          partido: partido,
          alTocar: () => alTocar(partido.partidoId),
        );
      },
    );
  }
}

class _FilaForma extends StatelessWidget {
  final FormaFicha partido;
  final VoidCallback alTocar;

  const _FilaForma({required this.partido, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fecha = partido.dia == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(partido.dia!);

    return Card(
      key: ValueKey('forma-${partido.partidoId}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _Escudo(mutxamel: partido.local),
                    ),
                  ),
                  Container(
                    key: ValueKey('forma-resultado-${partido.partidoId}'),
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: FichaForma.colorDe(partido.resultado),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${partido.golesLocal} - ${partido.golesVisitante}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Escudo(mutxamel: !partido.local),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [fecha, partido.rival].where((p) => p.isNotEmpty).join(' · '),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Escudo pequeño sobre fondo claro: el del club o el genérico del rival (en gris).
class _Escudo extends StatelessWidget {
  final bool mutxamel;

  const _Escudo({required this.mutxamel});

  @override
  Widget build(BuildContext context) {
    if (mutxamel) {
      return const EscudoEquipo(mutxamel: true, tamano: 36);
    }

    return Icon(
      Icons.shield_outlined,
      key: const ValueKey('escudo-rival'),
      size: 34,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
