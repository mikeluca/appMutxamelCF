import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/models/ficha_partido_model.dart';
import '../../ficha_partido/widgets/ficha_comunes.dart';

/// Lo que lleva la imagen de compartir (y el texto que la acompaña): solo nombres de equipos, marcador, estado,
/// competición y fecha. Nunca fotos de jugadores ni ningún dato personal.
class DatosCompartir {
  final String local;
  final String visitante;
  final bool mutxamelEsLocal;

  /// "2 - 1", o "VS" antes del partido.
  final String marcador;

  /// "67'" en juego (con el reloj), "Descanso", "Final", "Cancelado" o, antes del partido, día y hora.
  final String estado;

  /// "Preferente Valenciana · Jornada 9".
  final String competicion;

  /// "08/11/2026".
  final String fecha;

  /// "Mutxamel CF 2-1 Rival · Final", el texto corto con el que se comparte la imagen.
  final String texto;

  const DatosCompartir({
    required this.local,
    required this.visitante,
    required this.mutxamelEsLocal,
    required this.marcador,
    required this.estado,
    required this.competicion,
    required this.fecha,
    required this.texto,
  });

  factory DatosCompartir.desdeCabecera(
    CabeceraFicha c,
    AppLocalizations t, {
    required DateTime ahora,
  }) {
    final fecha = c.dia == null ? '' : DateFormat('dd/MM/yyyy').format(c.dia!);
    final hora = c.hora?.trim() ?? '';
    final tieneMarcador = c.golesLocal != null && c.golesVisitante != null;
    final minutos = c.reloj?.tiempo(ahora)?.inMinutes;

    final estado = switch (c.estado) {
      EstadoFicha.enJuego =>
        c.reloj != null && !c.reloj!.enDescanso && minutos != null
            ? "$minutos'"
            : (c.reloj?.enDescanso ?? false)
            ? t.fichaStatusHalftime
            : t.fichaStatusLive,
      EstadoFicha.descanso => t.fichaStatusHalftime,
      EstadoFicha.finalizado => t.shareStatusFinal,
      EstadoFicha.cancelado => t.fichaStatusCancelled,
      EstadoFicha.proximo => [fecha, hora].where((s) => s.isNotEmpty).join(' · '),
    };

    final jugado =
        c.estado != EstadoFicha.proximo && c.estado != EstadoFicha.cancelado;
    final marcador = tieneMarcador && jugado
        ? '${c.golesLocal} - ${c.golesVisitante}'
        : t.matchVs;

    final texto = tieneMarcador && jugado
        // Los parámetros van en orden alfabético (el de gen-l10n): estado, local, marcador, visitante.
        ? t.shareTextScore(
            estado,
            c.equipoLocal,
            '${c.golesLocal}-${c.golesVisitante}',
            c.equipoVisitante,
          )
        : t.shareTextUpcoming(estado, c.equipoLocal, c.equipoVisitante);

    return DatosCompartir(
      local: c.equipoLocal,
      visitante: c.equipoVisitante,
      mutxamelEsLocal: c.mutxamelEsLocal,
      marcador: marcador,
      estado: estado,
      competicion: c.competicion,
      fecha: fecha,
      texto: texto,
    );
  }
}

/// La imagen cuadrada de 1080x1080 que se comparte: fondo con el degradado del club, el escudo del Mutxamel y uno
/// genérico para el rival según sean local o visitante, los nombres, el marcador grande, el estado, la competición
/// y la fecha, y al pie "Síguelo en la app del Mutxamel CF".
class TarjetaCompartir extends StatelessWidget {
  static const double lado = 1080;

  final DatosCompartir datos;

  const TarjetaCompartir({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    Widget equipo(String nombre, bool mutxamel) => Expanded(
      child: Column(
        children: [
          EscudoEquipo(mutxamel: mutxamel, tamano: 190),
          const SizedBox(height: 18),
          Text(
            nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );

    const base = TextStyle(decoration: TextDecoration.none);

    return SizedBox(
      key: const ValueKey('tarjeta-compartir'),
      width: lado,
      height: lado,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3D5C), Color(0xFF071F30)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 80, 64, 56),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  equipo(datos.local, datos.mutxamelEsLocal),
                  const SizedBox(width: 24),
                  equipo(datos.visitante, !datos.mutxamelEsLocal),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  datos.marcador,
                  key: const ValueKey('compartir-marcador'),
                  style: base.copyWith(
                    color: Colors.white,
                    fontSize: 200,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  datos.estado,
                  key: const ValueKey('compartir-estado'),
                  style: base.copyWith(
                    color: AppColors.dorado,
                    fontSize: 68,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                [
                  datos.competicion,
                  datos.fecha,
                ].where((s) => s.isNotEmpty).join(' · '),
                key: const ValueKey('compartir-competicion'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(color: Colors.white70, fontSize: 36),
              ),
              const SizedBox(height: 28),
              Text(
                t.shareImageFooter,
                key: const ValueKey('compartir-pie'),
                textAlign: TextAlign.center,
                style: base.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Envía la imagen y el texto al menú de compartir del sistema. Los tests lo sustituyen.
typedef EnviarACompartir = Future<void> Function(Uint8List png, String texto);

/// Genera la imagen del partido con un widget fuera de pantalla (RepaintBoundary → PNG) y la comparte.
class CompartirPartido {
  CompartirPartido._();

  @visibleForTesting
  static EnviarACompartir enviar = (png, texto) async {
    await SharePlus.instance.share(
      ShareParams(
        text: texto,
        files: [XFile.fromData(png, mimeType: 'image/png', name: 'partido.png')],
        fileNameOverrides: const ['partido.png'],
      ),
    );
  };

  /// Genera la imagen del partido y abre el menú de compartir. Lanza si no se puede (el llamador avisa al usuario).
  static Future<void> compartir(BuildContext context, DatosCompartir datos) async {
    final png = await generarPng(context, datos);

    await enviar(png, datos.texto);
  }

  /// La tarjeta de [datos] como PNG de 1080x1080. Se pinta en una capa fuera de la pantalla (a la izquierda del
  /// borde) con el tamaño de letra del sistema ignorado, para que siempre salga igual.
  static Future<Uint8List> generarPng(
    BuildContext context,
    DatosCompartir datos,
  ) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final clave = GlobalKey();

    // Con el escudo ya en la caché de imágenes entra en el primer fotograma.
    await precacheImage(const AssetImage('assets/images/escudo.png'), context);

    final entrada = OverlayEntry(
      builder: (contextoCapa) => Positioned(
        left: -TarjetaCompartir.lado * 2,
        top: 0,
        width: TarjetaCompartir.lado,
        height: TarjetaCompartir.lado,
        child: MediaQuery(
          data: MediaQuery.of(contextoCapa).copyWith(
            textScaler: TextScaler.noScaling,
            disableAnimations: true,
          ),
          child: RepaintBoundary(
            key: clave,
            child: TarjetaCompartir(datos: datos),
          ),
        ),
      ),
    );

    overlay.insert(entrada);

    try {
      await WidgetsBinding.instance.endOfFrame;

      final limite =
          clave.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (limite == null) {
        throw StateError('No se pudo pintar la imagen del partido');
      }

      final imagen = await limite.toImage(pixelRatio: 1);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);

      imagen.dispose();

      if (bytes == null) {
        throw StateError('No se pudo codificar la imagen del partido');
      }

      return bytes.buffer.asUint8List();
    } finally {
      entrada.remove();
      entrada.dispose();
    }
  }
}
