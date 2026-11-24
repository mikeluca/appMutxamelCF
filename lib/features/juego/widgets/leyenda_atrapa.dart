import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../logica/atrapa_logica.dart';
import 'dibujos_juego.dart';

/// La leyenda de Atrapa balones: cada objeto dibujado y lo que hace. Sale antes de la primera partida y desde el botón
/// "¿Cómo se juega?".
class LeyendaAtrapa extends StatelessWidget {
  const LeyendaAtrapa({super.key, required this.textoBoton, required this.onCerrar});

  /// Lo que dice el botón ("¡A jugar!" antes de la primera partida, "Entendido" desde el botón).
  final String textoBoton;
  final VoidCallback onCerrar;

  /// Lo que se enseña, en este orden.
  static const List<TipoCaida> objetos = [
    TipoCaida.balon,
    TipoCaida.balonEfecto,
    TipoCaida.balonDorado,
    TipoCaida.escudo,
    TipoCaida.balonPinchado,
    TipoCaida.tarjetaRoja,
    TipoCaida.tarjetaAmarilla,
    TipoCaida.bota,
    TipoCaida.silbato,
  ];

  /// Lo que dice cada uno.
  static String textoDe(AppLocalizations t, TipoCaida tipo) => switch (tipo) {
    TipoCaida.balon => t.gameLegendBall,
    TipoCaida.balonEfecto => t.gameLegendEffect,
    TipoCaida.balonDorado => t.gameLegendGolden,
    TipoCaida.escudo => t.gameLegendShield,
    TipoCaida.balonPinchado => t.gameLegendFlat,
    TipoCaida.tarjetaRoja => t.gameLegendRed,
    TipoCaida.tarjetaAmarilla => t.gameLegendYellow,
    TipoCaida.bota => t.gameLegendBoot,
    TipoCaida.silbato => t.gameLegendWhistle,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      key: const ValueKey('leyenda-atrapa'),
      margin: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.gameLegendTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final tipo in objetos)
                        Padding(
                          key: ValueKey('leyenda-${tipo.name}'),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              ObjetoDibujado(tipo: tipo, tamano: 38),
                              const SizedBox(width: 12),
                              Expanded(child: Text(textoDe(t, tipo))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('cerrar-leyenda'),
                onPressed: onCerrar,
                child: Text(textoBoton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// La leyenda en un diálogo (desde el botón "¿Cómo se juega?").
  static Future<void> mostrar(BuildContext context) {
    final t = AppLocalizations.of(context);

    return showDialog<void>(
      context: context,
      builder: (contexto) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: LeyendaAtrapa(
          textoBoton: t.gameLegendGotIt,
          onCerrar: () => Navigator.pop(contexto),
        ),
      ),
    );
  }
}
