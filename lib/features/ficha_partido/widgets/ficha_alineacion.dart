import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/ficha_partido_model.dart';
import 'campo_futbol.dart';
import 'ficha_comunes.dart';

/// Pestaña Alineación: el campo dibujado con cada titular en su fila y columna (foto o avatar, dorsal y nombre
/// en directo, con el icono de cambio y de tarjeta si los tuvo) y debajo la lista de suplentes. Sin formación no hay
/// posiciones y los titulares salen en lista.
class FichaAlineacion extends StatelessWidget {
  final AlineacionFicha alineacion;

  const FichaAlineacion({super.key, required this.alineacion});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    if (alineacion.vacia) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.groups_outlined, size: 48, color: colors.outline),
          const SizedBox(height: 12),
          Text(
            t.fichaNoLineup,
            key: const ValueKey('ficha-sin-alineacion'),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        if (alineacion.tienePosiciones)
          CampoFutbol(
            formacion: alineacion.formacion,
            jugadores: [
              for (final titular in alineacion.titulares)
                PosicionEnCampo(
                  fila: titular.fila!,
                  columna: titular.columna!,
                  child: _TitularEnCampo(titular: titular),
                ),
            ],
          )
        else
          for (final titular in alineacion.titulares)
            _FilaJugador(
              dorsal: titular.dorsal,
              nombre: titular.nombre,
              foto: titular.fotoBase64,
              tarjetas: titular.tarjetas,
              extra: titular.sustituido
                  ? _MarcaCambio(
                      entra: false,
                      minuto: titular.minutoSustitucion,
                    )
                  : null,
            ),
        if (alineacion.suplentes.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            t.fichaSubstitutes,
            key: const ValueKey('ficha-suplentes'),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (final suplente in alineacion.suplentes)
            _FilaJugador(
              dorsal: suplente.dorsal,
              nombre: suplente.nombre,
              foto: suplente.fotoBase64,
              tarjetas: suplente.tarjetas,
              extra: suplente.entro
                  ? _MarcaCambio(entra: true, minuto: suplente.minutoEntrada)
                  : null,
            ),
        ],
      ],
    );
  }
}

/// Icono de cambio con el minuto: flecha verde si entra, roja si sale.
class _MarcaCambio extends StatelessWidget {
  final bool entra;
  final int? minuto;

  const _MarcaCambio({required this.entra, this.minuto});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: entra ? t.fichaSubIn : t.fichaSubOut,
      child: Row(
        key: ValueKey(entra ? 'marca-entra' : 'marca-sale'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entra ? Icons.arrow_circle_up : Icons.arrow_circle_down,
            size: 18,
            color: entra ? const Color(0xFF2E9E4F) : const Color(0xFFD62828),
          ),
          if (minuto != null)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                "$minuto'",
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaJugador extends StatelessWidget {
  final int? dorsal;
  final String nombre;
  final String? foto;
  final List<TarjetaFicha> tarjetas;
  final Widget? extra;

  const _FilaJugador({
    required this.dorsal,
    required this.nombre,
    required this.foto,
    required this.tarjetas,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      key: ValueKey('jugador-$nombre'),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          FotoJugador(fotoBase64: foto, radio: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              dorsal?.toString() ?? '-',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nombre,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurface, fontSize: 15),
            ),
          ),
          // Con doble amarilla, la primera amarilla ya va dentro del grupo (2 amarillas + roja).
          for (final tarjeta in tarjetas.where(
            (t) => t.dobleAmarilla || !tarjetas.any((o) => o.dobleAmarilla),
          ))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: tarjeta.dobleAmarilla
                  ? const TarjetasDobleAmarilla(alto: 14)
                  : TarjetaIcono(roja: tarjeta.esRoja, alto: 14),
            ),
          if (extra != null)
            Padding(padding: const EdgeInsets.only(left: 8), child: extra),
        ],
      ),
    );
  }
}

/// Un titular dentro del campo.
class _TitularEnCampo extends StatelessWidget {
  final TitularFicha titular;

  const _TitularEnCampo({required this.titular});

  @override
  Widget build(BuildContext context) {
    // La tarjeta más grave: roja si la hubo.
    final tarjeta = titular.tarjetas.isEmpty
        ? null
        : titular.tarjetas.firstWhere(
            (t) => t.dobleAmarilla || t.esRoja,
            orElse: () => titular.tarjetas.last,
          );

    return Column(
      key: ValueKey('titular-${titular.nombre}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              FotoJugador(fotoBase64: titular.fotoBase64, radio: 20),
              Positioned(
                bottom: 0,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3D5C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    titular.dorsal?.toString() ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (titular.sustituido)
                const Positioned(
                  top: -2,
                  left: 0,
                  child: _InsigniaCambio(),
                ),
              if (tarjeta != null)
                Positioned(
                  top: -2,
                  right: 2,
                  child: tarjeta.dobleAmarilla
                      ? const TarjetasDobleAmarilla(alto: 14)
                      : TarjetaIcono(roja: tarjeta.esRoja, alto: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titular.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(blurRadius: 3, color: Colors.black87)],
          ),
        ),
      ],
    );
  }
}

class _InsigniaCambio extends StatelessWidget {
  const _InsigniaCambio();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('insignia-cambio'),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_circle_down,
        size: 16,
        color: Color(0xFFD62828),
      ),
    );
  }
}
