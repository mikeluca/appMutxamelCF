import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';

/// Construye la imagen de red del escudo; los tests la sustituyen para no ir a la red.
typedef ConstructorEscudoRed =
    Widget Function(String url, double tamano, Widget generico);

/// El escudo de un equipo rival, en un solo sitio para toda la app:
///
/// * [esPropio] (el rival es un equipo de nuestro club): nuestro escudo, el asset del club;
/// * con [url] (la ruta que da el backend, relativa a la URL base del servidor, o una URL completa): el escudo de la
///   red, con caché en disco (`cached_network_image`) y sin fundidos, de modo que la misma URL es la misma imagen
///   guardada y al recargar cada 30 s no parpadea. Mientras carga y si falla, el escudo genérico;
/// * sin URL: el escudo genérico.
///
/// El escudo se ve entero (`BoxFit.contain`) en un cuadrado de [tamano], el mismo que el del Mutxamel.
class EscudoRival extends StatelessWidget {
  final String? url;
  final bool esPropio;
  final double tamano;

  /// El color del genérico (según el fondo: claro sobre la cabecera oscura, gris en las listas...).
  final Color? colorGenerico;

  /// true: mientras carga (y si falla) no se pinta la silueta genérica sino un hueco vacío (las cartas de Parejas solo
  /// enseñan el escudo ya cargado).
  final bool sinGenerico;

  const EscudoRival({
    super.key,
    this.url,
    this.esPropio = false,
    this.tamano = 56,
    this.colorGenerico,
    this.sinGenerico = false,
  });

  /// Solo para tests: la imagen de red.
  @visibleForTesting
  static ConstructorEscudoRed? constructorDeRed;

  /// Solo para tests: cómo se precarga un escudo (true si se ha cargado).
  @visibleForTesting
  static Future<bool> Function(BuildContext contexto, String url)?
  precargadorDeRed;

  /// Descarga el escudo y lo deja en la caché de imágenes con el mismo proveedor que usa el widget, de modo que luego
  /// sale al instante. false si no se ha podido cargar.
  static Future<bool> precargar(BuildContext contexto, String? ruta) async {
    final completa = urlCompleta(ruta);

    if (completa == null) return false;

    final falso = precargadorDeRed;

    if (falso != null) return falso(contexto, completa);

    var bien = true;

    try {
      await precacheImage(
        CachedNetworkImageProvider(completa),
        contexto,
        onError: (_, _) => bien = false,
      );
    } catch (_) {
      return false;
    }

    return bien;
  }

  /// La URL completa: la ruta relativa del backend ("/api/public/escudos-rivales/7?v=3") sobre la URL base del
  /// servidor. Null si no hay ruta.
  static String? urlCompleta(String? ruta) {
    final limpia = ruta?.trim();

    if (limpia == null || limpia.isEmpty) return null;

    if (limpia.startsWith('http://') || limpia.startsWith('https://')) {
      return limpia;
    }

    return '${AppConfig.mediaBaseUrl}${limpia.startsWith('/') ? '' : '/'}$limpia';
  }

  Widget _generico(BuildContext context) => SizedBox(
    width: tamano,
    height: tamano,
    child: Icon(
      Icons.shield_outlined,
      key: const ValueKey('escudo-rival'),
      size: tamano * 0.9,
      color: colorGenerico ?? Theme.of(context).colorScheme.primary,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (esPropio) {
      return Image.asset(
        'assets/images/escudo.png',
        key: const ValueKey('escudo-mutxamel'),
        width: tamano,
        height: tamano,
        fit: BoxFit.contain,
      );
    }

    final completa = urlCompleta(url);

    if (completa == null) {
      return sinGenerico
          ? SizedBox(width: tamano, height: tamano)
          : _generico(context);
    }

    final generico = sinGenerico
        ? SizedBox(width: tamano, height: tamano)
        : _generico(context);
    final construir = constructorDeRed;

    if (construir != null) return construir(completa, tamano, generico);

    return SizedBox(
      width: tamano,
      height: tamano,
      child: CachedNetworkImage(
        key: ValueKey('escudo-rival-red-$completa'),
        imageUrl: completa,
        width: tamano,
        height: tamano,
        fit: BoxFit.contain,
        // Sin fundidos: con la imagen ya en caché aparece al instante y el refresco no parpadea.
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, _) => generico,
        errorWidget: (_, _, _) => generico,
      ),
    );
  }
}
