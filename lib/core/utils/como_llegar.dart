import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';

/// Lo que se puede cambiar en los tests: la plataforma y la apertura de la URL.
class ComoLlegar {
  ComoLlegar._();

  @visibleForTesting
  static bool Function() esIos = () => Platform.isIOS;

  @visibleForTesting
  static Future<bool> Function(Uri url) abrirUrl = (url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

/// El texto que se busca en el mapa: si [lugar] no contiene ya "Mutxamel" ni una
/// coma (una dirección completa), se añade ", Alicante" para afinar la búsqueda.
String consultaComoLlegar(String lugar) {
  final texto = lugar.trim();

  if (texto.toLowerCase().contains('mutxamel') || texto.contains(',')) {
    return texto;
  }

  return '$texto, Alicante';
}

/// La URL que abre el mapa del sistema: Apple Maps en iOS y Google Maps en
/// Android.
Uri urlComoLlegar(String lugar, {required bool esIos}) {
  final consulta = Uri.encodeComponent(consultaComoLlegar(lugar));

  return Uri.parse(
    esIos
        ? 'https://maps.apple.com/?q=$consulta'
        : 'https://www.google.com/maps/search/?api=1&query=$consulta',
  );
}

/// Abre el mapa buscando [lugar]; si no se puede abrir, avisa con un SnackBar.
Future<void> abrirComoLlegar(BuildContext context, String lugar) async {
  final mensajero = ScaffoldMessenger.maybeOf(context);
  final mensaje = AppLocalizations.of(context).directionsOpenError;

  var abierto = false;

  try {
    abierto = await ComoLlegar.abrirUrl(
      urlComoLlegar(lugar, esIos: ComoLlegar.esIos()),
    );
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
