import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../envio_puntuacion.dart';
import '../models/juego_modelos.dart';

/// La pantalla del fin de partida: Mutxigol celebrando (récord personal) o triste, los puntos, el récord y lo que ha
/// pasado con el envío de la puntuación (guardada, sin sesión, sin alias, enviando o con error).
class FinDePartida extends StatelessWidget {
  const FinDePartida({
    super.key,
    required this.equipacion,
    required this.puntos,
    required this.recordAnterior,
    required this.envio,
    required this.onOtraVez,
    required this.onRanking,
    required this.onElegirAlias,
    this.onSalir,
  });

  final Equipacion equipacion;
  final int puntos;

  /// El mejor resultado anterior (0 si no había): para saber si es récord mientras no hay respuesta del servidor.
  final int recordAnterior;

  final EnvioPuntuacion envio;
  final VoidCallback onOtraVez;
  final VoidCallback onRanking;
  final VoidCallback onElegirAlias;
  final VoidCallback? onSalir;

  /// Récord personal: lo que dice el servidor y, hasta que conteste (o sin sesión), la comparación con lo conocido.
  bool get esRecord => envio.resultado != null
      ? envio.resultado!.esRecord
      : puntos > 0 && puntos > recordAnterior;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;
    final record = esRecord;

    return Card(
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              child: Image.asset(
                ImagenesMutxigol.pose(
                  equipacion,
                  record ? PoseMutxigol.celebrando : PoseMutxigol.triste,
                ),
                key: ValueKey(record ? 'fin-celebrando' : 'fin-triste'),
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              record ? t.gameNewRecord : t.gameOverTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.gameFinalScore(puntos),
              key: const ValueKey('fin-puntos'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colores.primary,
              ),
            ),
            if (recordAnterior > 0 && !record)
              Text(
                t.gameYourRecord(recordAnterior),
                key: const ValueKey('fin-record'),
              ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: envio,
              builder: (context, _) => _estadoEnvio(context, t),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('otra-vez'),
                  onPressed: onOtraVez,
                  child: Text(t.gamePlayAgain),
                ),
                OutlinedButton(
                  key: const ValueKey('ver-ranking'),
                  onPressed: onRanking,
                  child: Text(t.gameRankingButton),
                ),
                if (onSalir != null)
                  TextButton(
                    key: const ValueKey('salir-fin'),
                    onPressed: onSalir,
                    child: Text(t.gameExit),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoEnvio(BuildContext context, AppLocalizations t) {
    switch (envio.estado) {
      case EstadoEnvio.noAplica:
        return const SizedBox.shrink();

      case EstadoEnvio.sinSesion:
        return Text(
          t.gameLoginBanner,
          key: const ValueKey('aviso-sin-sesion'),
          textAlign: TextAlign.center,
        );

      case EstadoEnvio.sinAlias:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.gameAliasToSave,
              key: const ValueKey('aviso-sin-alias'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const ValueKey('elegir-alias'),
              onPressed: onElegirAlias,
              child: Text(t.gameChooseAliasAction),
            ),
          ],
        );

      case EstadoEnvio.enviando:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(t.gameSaving, key: const ValueKey('guardando'))),
          ],
        );

      case EstadoEnvio.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              envio.mensajeError ?? t.gameSendError,
              key: const ValueKey('error-envio'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('reintentar-envio'),
              onPressed: envio.reintentar,
              child: Text(t.retry),
            ),
          ],
        );

      case EstadoEnvio.enviado:
        final r = envio.resultado!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r.recordSemana)
              Text(
                t.gameRecordWeek,
                key: const ValueKey('record-semana'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (r.recordHistorico)
              Text(
                t.gameRecordAllTime,
                key: const ValueKey('record-historico'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (r.posicionSemana != null)
              Text(
                t.gamePositionWeek(r.posicionSemana!),
                key: const ValueKey('posicion-semana'),
              ),
            if (r.posicionHistorico != null)
              Text(
                t.gamePositionAllTime(r.posicionHistorico!),
                key: const ValueKey('posicion-historico'),
              ),
          ],
        );
    }
  }
}
