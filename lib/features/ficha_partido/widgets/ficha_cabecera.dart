import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/ficha_partido_model.dart';
import 'ficha_comunes.dart';
import 'reloj_en_directo.dart';
import '../../directo/widgets/cuenta_atras_texto.dart';
import '../../directo/widgets/marcador_que_late.dart';

/// Cabecera fija de la ficha: fondo oscuro con degradado del color del club, los dos escudos (el del Mutxamel y
/// uno genérico para el rival) según local/visitante, la fecha, el marcador, el estado y la competición.
class FichaCabecera extends StatelessWidget {
  final CabeceraFicha cabecera;

  /// Solo para tests: la hora del móvil y el temporizador del reloj.
  final DateTime Function()? ahora;
  final CrearTemporizador? crearTemporizador;

  const FichaCabecera({
    super.key,
    required this.cabecera,
    this.ahora,
    this.crearTemporizador,
  });

  /// "11/11/2026 • 21:00" (sin la hora, solo la fecha).
  String _fecha() {
    final dia = cabecera.dia;
    final hora = cabecera.hora?.trim();

    if (dia == null) return hora ?? '';

    final fecha = DateFormat('dd/MM/yyyy').format(dia);

    return hora == null || hora.isEmpty ? fecha : '$fecha • $hora';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final local = cabecera.mutxamelEsLocal;

    return Container(
      key: const ValueKey('ficha-cabecera'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B3D5C), Color(0xFF071F30)],
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Equipo(
                  nombre: cabecera.nombreLocal,
                  mutxamel: local || cabecera.rivalEsPropio,
                  url: local ? null : cabecera.escudoRivalUrl,
                  clave: 'ficha-equipo-local',
                ),
              ),
              SizedBox(
                width: 120,
                child: _Centro(
                  cabecera: cabecera,
                  fecha: _fecha(),
                  t: t,
                  ahora: ahora,
                  crearTemporizador: crearTemporizador,
                ),
              ),
              Expanded(
                child: _Equipo(
                  nombre: cabecera.nombreVisitante,
                  mutxamel: !local || cabecera.rivalEsPropio,
                  url: local ? cabecera.escudoRivalUrl : null,
                  clave: 'ficha-equipo-visitante',
                ),
              ),
            ],
          ),
          if (cabecera.competicion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              cabecera.competicion,
              key: const ValueKey('ficha-competicion'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _Equipo extends StatelessWidget {
  final String nombre;
  final bool mutxamel;
  final String clave;
  final String? url;

  const _Equipo({
    required this.nombre,
    required this.mutxamel,
    required this.clave,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(clave),
      children: [
        EscudoEquipo(mutxamel: mutxamel, tamano: 56, url: url),
        const SizedBox(height: 6),
        Text(
          nombre,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

const TextStyle _estiloMarcador = TextStyle(
  color: Colors.white,
  fontSize: 34,
  fontWeight: FontWeight.bold,
);

class _Centro extends StatelessWidget {
  final CabeceraFicha cabecera;
  final String fecha;
  final AppLocalizations t;
  final DateTime Function()? ahora;
  final CrearTemporizador? crearTemporizador;

  const _Centro({
    required this.cabecera,
    required this.fecha,
    required this.t,
    this.ahora,
    this.crearTemporizador,
  });

  @override
  Widget build(BuildContext context) {
    final sinMarcador =
        cabecera.golesLocal == null || cabecera.golesVisitante == null;

    return Column(
      children: [
        Text(
          fecha,
          key: const ValueKey('ficha-fecha'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: sinMarcador
              ? const Text(
                  '-',
                  key: ValueKey('ficha-marcador'),
                  style: _estiloMarcador,
                )
              : MarcadorQueLate(
                  key: const ValueKey('ficha-marcador'),
                  partidoId: cabecera.partidoId,
                  golesFavor: cabecera.golesFavor,
                  golesContra: cabecera.golesContra,
                  mutxamelEsLocal: cabecera.mutxamelEsLocal,
                  estilo: _estiloMarcador,
                ),
        ),
        const SizedBox(height: 4),
        _Estado(
          cabecera: cabecera,
          t: t,
          ahora: ahora,
          crearTemporizador: crearTemporizador,
        ),
      ],
    );
  }
}

class _Estado extends StatelessWidget {
  final CabeceraFicha cabecera;
  final AppLocalizations t;

  final DateTime Function()? ahora;
  final CrearTemporizador? crearTemporizador;

  const _Estado({
    required this.cabecera,
    required this.t,
    this.ahora,
    this.crearTemporizador,
  });

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    final contenido = switch (cabecera.estado) {
      // Con reloj, el tiempo de partido (MM:ss con el punto parpadeante) en lugar de "En directo".
      EstadoFicha.enJuego
          when cabecera.reloj != null && !cabecera.reloj!.enDescanso =>
        RelojEnDirecto(
          reloj: cabecera.reloj!,
          estilo: estilo,
          ahora: ahora,
          crearTemporizador: crearTemporizador,
        ),
      EstadoFicha.enJuego => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PuntoEnDirecto(),
          const SizedBox(width: 6),
          Text(t.fichaStatusLive, style: estilo),
        ],
      ),
      EstadoFicha.descanso => Text(t.fichaStatusHalftime, style: estilo),
      EstadoFicha.finalizado => Text(t.fichaStatusFinished, style: estilo),
      EstadoFicha.cancelado => Text(
        t.fichaStatusCancelled,
        style: estilo.copyWith(color: AppColors.dorado),
      ),
      // Con día y hora, la cuenta atrás ("Empieza en 3 h 15 min"); sin hora, como antes.
      EstadoFicha.proximo
          when CuentaAtrasTexto.aplica(cabecera.dia, cabecera.hora) =>
        CuentaAtrasTexto(
          dia: cabecera.dia,
          hora: cabecera.hora,
          estilo: estilo,
          ahora: ahora,
          crearTemporizador: crearTemporizador,
        ),
      EstadoFicha.proximo => Text(cabecera.hora?.trim() ?? '', style: estilo),
    };

    // Que quepa siempre en la columna central, también con letra grande.
    return FittedBox(
      key: const ValueKey('ficha-estado'),
      fit: BoxFit.scaleDown,
      child: contenido,
    );
  }
}

/// Punto rojo que parpadea mientras el partido está en directo.
class PuntoEnDirecto extends StatefulWidget {
  const PuntoEnDirecto({super.key});

  @override
  State<PuntoEnDirecto> createState() => _PuntoEnDirectoState();
}

class _PuntoEnDirectoState extends State<PuntoEnDirecto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: const ValueKey('punto-en-directo'),
      opacity: Tween<double>(begin: 0.25, end: 1).animate(_controlador),
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: Color(0xFFFF3B30),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
