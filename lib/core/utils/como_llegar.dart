import 'dart:io' show Platform;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoActionSheet, CupertinoActionSheetAction, showCupertinoModalPopup;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../config/app_preferences.dart';

/// Lo que se puede cambiar en los tests: la plataforma y la apertura de la URL.
class ComoLlegar {
  ComoLlegar._();

  @visibleForTesting
  static bool Function() esIos = () => Platform.isIOS;

  @visibleForTesting
  static Future<bool> Function(Uri url) abrirUrl = (url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

/// El texto que se busca en el mapa: exactamente [lugar] (el campo o el lugar de
/// citación que viene del backend), sin añadir ninguna ciudad.
String consultaComoLlegar(String lugar) => lugar.trim();

/// La aplicación de mapas a la que se envía la búsqueda.
enum MapaComoLlegar { google, apple }

final RegExp _identificadorCampo = RegExp(
  r'\bF-?(?:5|7|8|11)\b|\bCampo\s*-?\s*[123]\b',
  caseSensitive: false,
);

/// El texto para Apple Maps: sin los identificadores de campo ("F-11", "F8",
/// "Campo 2"...) que su buscador toma por un número de portal. Si al limpiar no
/// queda nada, el texto original.
String consultaAppleMaps(String lugar) {
  final original = consultaComoLlegar(lugar);
  final limpia = original
      .replaceAll(_identificadorCampo, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return limpia.isEmpty ? original : limpia;
}

/// La URL de la búsqueda en [mapa]. Google Maps recibe siempre el texto
/// completo; Apple Maps, el texto limpio ([consultaAppleMaps]).
Uri urlComoLlegar(String lugar, {required MapaComoLlegar mapa}) {
  switch (mapa) {
    case MapaComoLlegar.google:
      final consulta = Uri.encodeComponent(consultaComoLlegar(lugar));

      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$consulta',
      );
    case MapaComoLlegar.apple:
      final consulta = Uri.encodeComponent(consultaAppleMaps(lugar));

      return Uri.parse('https://maps.apple.com/?q=$consulta');
  }
}

/// Lee la última opción elegida (google por defecto) sin fallar si no hay
/// almacenamiento.
Future<MapaComoLlegar> _mapaPreferido() async {
  try {
    final guardado = await AppPreferences.obtenerMapaPreferido();

    return guardado == 'apple' ? MapaComoLlegar.apple : MapaComoLlegar.google;
  } catch (_) {
    return MapaComoLlegar.google;
  }
}

/// Hoja de acciones de iOS: devuelve el mapa elegido o null si se cancela. La
/// última opción elegida va primera.
Future<MapaComoLlegar?> _elegirMapa(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final preferido = await _mapaPreferido();

  if (!context.mounted) {
    return null;
  }

  final orden = [
    preferido,
    if (preferido == MapaComoLlegar.google)
      MapaComoLlegar.apple
    else
      MapaComoLlegar.google,
  ];

  return showCupertinoModalPopup<MapaComoLlegar>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      actions: [
        for (final mapa in orden)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(mapa),
            child: Text(
              mapa == MapaComoLlegar.google
                  ? l10n.directionsGoogleMaps
                  : l10n.directionsAppleMaps,
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(l10n.cancel),
      ),
    ),
  );
}

/// Abre el mapa buscando [lugar]; si no se puede abrir, avisa con un SnackBar.
/// En iOS pregunta antes con qué aplicación (Google Maps o Apple Maps).
Future<void> abrirComoLlegar(BuildContext context, String lugar) async {
  final mensajero = ScaffoldMessenger.maybeOf(context);
  final mensaje = AppLocalizations.of(context).directionsOpenError;

  var mapa = MapaComoLlegar.google;

  if (ComoLlegar.esIos()) {
    final elegido = await _elegirMapa(context);

    if (elegido == null) {
      return;
    }

    mapa = elegido;

    try {
      await AppPreferences.guardarMapaPreferido(mapa.name);
    } catch (e) {
      debugPrint('NO SE PUDO GUARDAR EL MAPA PREFERIDO: $e');
    }
  }

  var abierto = false;

  try {
    abierto = await ComoLlegar.abrirUrl(urlComoLlegar(lugar, mapa: mapa));
  } catch (e) {
    debugPrint('NO SE PUDO ABRIR EL MAPA: $e');
  }

  if (!abierto) {
    mensajero?.showSnackBar(SnackBar(content: Text(mensaje)));
  }
}

/// Botón "Cómo llegar" (icono de direcciones) para el campo de un partido o el
/// lugar de una citación. No se pinta si el texto está vacío.
class BotonComoLlegar extends StatelessWidget {
  final String? lugar;

  const BotonComoLlegar({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    final texto = lugar?.trim() ?? '';

    if (texto.isEmpty) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: AppLocalizations.of(context).directionsButton,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.directions),
      color: Theme.of(context).colorScheme.primary,
      onPressed: () => abrirComoLlegar(context, texto),
    );
  }
}
