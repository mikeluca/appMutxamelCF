import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../model/equipacion_model.dart';

/// Camiseta, pantalón y medias de [equipacion] en una línea ("Camiseta Blanca · Pantalón
/// Blanco · Medias Blancas"), o null si no tiene ninguno.
String? detalleEquipacion(AppLocalizations t, EquipacionModel equipacion) {
  final partes = [
    if (equipacion.camiseta != null) t.callupKitShirt(equipacion.camiseta!),
    if (equipacion.pantalon != null) t.callupKitShorts(equipacion.pantalon!),
    if (equipacion.medias != null) t.callupKitSocks(equipacion.medias!),
  ];

  return partes.isEmpty ? null : partes.join(' · ');
}

/// La muestra de color de un equipaje (un círculo). Sin colorHex válido, un icono de ropa.
class MuestraColorEquipaje extends StatelessWidget {
  final EquipacionModel equipacion;
  final double tamano;

  const MuestraColorEquipaje({
    super.key,
    required this.equipacion,
    this.tamano = 20,
  });

  @override
  Widget build(BuildContext context) {
    final color = equipacion.color;
    final borde = Theme.of(context).colorScheme.outline;

    if (color == null) {
      return Icon(Icons.checkroom_outlined, size: tamano, color: borde);
    }

    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borde),
      ),
    );
  }
}

/// El selector de un equipaje: la muestra de color y el nombre.
class OpcionEquipaje extends StatelessWidget {
  final EquipacionModel equipacion;

  const OpcionEquipaje({super.key, required this.equipacion});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MuestraColorEquipaje(equipacion: equipacion),
        const SizedBox(width: 10),
        Flexible(
          child: Text(equipacion.nombre, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// Una fila de equipaje: la muestra de color, [titulo] ("Equipaje: Segunda") y debajo el
/// detalle de camiseta, pantalón y medias.
class FilaEquipaje extends StatelessWidget {
  final String titulo;
  final EquipacionModel equipacion;

  const FilaEquipaje({
    super.key,
    required this.titulo,
    required this.equipacion,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detalle = detalleEquipacion(AppLocalizations.of(context), equipacion);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: MuestraColorEquipaje(equipacion: equipacion),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                if (detalle != null)
                  Text(
                    detalle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El equipaje de una convocatoria: "Equipaje: X" y, si hay, "En la mochila: Y". Sin
/// equipaje no pinta nada.
class BloqueEquipaje extends StatelessWidget {
  final EquipacionModel? equipacion;
  final EquipacionModel? mochila;

  const BloqueEquipaje({super.key, this.equipacion, this.mochila});

  @override
  Widget build(BuildContext context) {
    final principal = equipacion;
    final reserva = mochila;

    if (principal == null && reserva == null) {
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (principal != null)
          FilaEquipaje(
            key: const ValueKey('equipaje-principal'),
            titulo: t.callupKitLine(principal.nombre),
            equipacion: principal,
          ),
        if (reserva != null)
          FilaEquipaje(
            key: const ValueKey('equipaje-mochila'),
            titulo: t.callupKitBackpackLine(reserva.nombre),
            equipacion: reserva,
          ),
      ],
    );
  }
}

/// "🚿 Ducha recomendable después del partido": va siempre al final del detalle de la
/// convocatoria de un jugador, una familia o un invitado.
class DuchaRecomendable extends StatelessWidget {
  const DuchaRecomendable({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).callupShowerReminder,
        key: const ValueKey('ducha-recomendable'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
