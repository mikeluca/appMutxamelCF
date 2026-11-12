import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/ficha_partido_model.dart';
import 'ficha_comunes.dart';

/// Cabecera fija de la ficha: fondo oscuro con degradado del color del club, los dos escudos (el del Mutxamel y
/// uno genérico para el rival) según local/visitante, la fecha, el marcador, el estado y la competición.
class FichaCabecera extends StatelessWidget {
  final CabeceraFicha cabecera;

  const FichaCabecera({super.key, required this.cabecera});

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
                  nombre: cabecera.equipoLocal,
                  mutxamel: local,
                  clave: 'ficha-equipo-local',
                ),
              ),
              SizedBox(width: 120, child: _Centro(cabecera: cabecera, fecha: _fecha(), t: t)),
              Expanded(
                child: _Equipo(
                  nombre: cabecera.equipoVisitante,
                  mutxamel: !local,
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

  const _Equipo({
    required this.nombre,
    required this.mutxamel,
    required this.clave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(clave),
      children: [
        EscudoEquipo(mutxamel: mutxamel, tamano: 56),
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

class _Centro extends StatelessWidget {
  final CabeceraFicha cabecera;
  final String fecha;
  final AppLocalizations t;

  const _Centro({
    required this.cabecera,
    required this.fecha,
    required this.t,
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
          child: Text(
            sinMarcador
                ? '-'
                : '${cabecera.golesLocal} - ${cabecera.golesVisitante}',
            key: const ValueKey('ficha-marcador'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _Estado(cabecera: cabecera, t: t),
      ],
    );
  }
}

class _Estado extends StatelessWidget {
  final CabeceraFicha cabecera;
  final AppLocalizations t;

  const _Estado({required this.cabecera, required this.t});

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    final contenido = switch (cabecera.estado) {
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
