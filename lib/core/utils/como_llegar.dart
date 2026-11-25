import 'dart:io' show Platform;

import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoActionSheet,
        CupertinoActionSheetAction,
        showCupertinoModalPopup;
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

/// El campo de casa tal como se ve y se guarda (campo del partido, lugar de citación).
const String campoCasaTexto = 'Camp Nou Los Olmos Mutxamel';

/// El campo de casa tal como se envía a Google Maps y Apple Maps.
const String campoCasaMapas = 'Poliesportiu Municipal de Mutxamel';

/// El texto en minúsculas, sin acentos y con los espacios normalizados, para comparar lugares.
String normalizarLugar(String? texto) {
  const origen = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const destino = 'aaaaaeeeeiiiiooooouuuunc';

  var salida = (texto ?? '').toLowerCase();

  for (var i = 0; i < origen.length; i++) {
    salida = salida.replaceAll(origen[i], destino[i]);
  }

  return salida.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Si [a] y [b] son el mismo lugar sin contar mayúsculas, acentos ni espacios de más.
bool mismoLugar(String? a, String? b) =>
    normalizarLugar(a) == normalizarLugar(b);

/// Si el campo de un partido es Els Oms (el Camp Nou Los Olmos): la misma regla que el backend
/// (docs/api-app-como-llegar-local.md). true si está vacío o si, normalizado (minúsculas, sin acentos, sin puntos y con
/// los espacios simplificados), contiene la palabra completa "olmos" u "oms"; false en cualquier otro caso.
bool esCampoElsOms(String? campo) {
  if ((campo ?? '').trim().isEmpty) {
    return true;
  }

  final texto = normalizarLugar(campo!.replaceAll('.', ' '));

  return _palabrasElsOms.hasMatch(texto);
}

final RegExp _palabrasElsOms = RegExp(r'(?<![a-z0-9])(?:olmos|oms)(?![a-z0-9])');

/// Si el partido se juega en Els Oms: [enCasaElsOms] del backend si viene; si no (respuestas antiguas o en caché),
/// local y campo de Els Oms.
bool _seJuegaEnElsOms(String? campo, bool? local, bool? enCasaElsOms) =>
    enCasaElsOms ?? (local == true && esCampoElsOms(campo));

/// Lo que se envía al mapa para el campo de un partido: [campoCasaMapas] solo si es local y se juega en Els Oms
/// ([enCasaElsOms] del backend o, si no viene, [local] y [esCampoElsOms]); en cualquier otro caso (fuera, o en casa en
/// otro campo como el Hogar Provincial), el campo tal cual. No cambia lo que se muestra.
String destinoCampoPartido(String? campo, {bool? local, bool? enCasaElsOms}) {
  final texto = campo?.trim() ?? '';

  if (texto.isEmpty) {
    return '';
  }

  return _seJuegaEnElsOms(texto, local, enCasaElsOms) ? campoCasaMapas : texto;
}

/// Lo que se envía al mapa para el lugar de citación de una convocatoria: [campoCasaMapas] si el lugar es
/// [campoCasaTexto] o si el partido se juega en Els Oms y el lugar está vacío o es el campo del partido; si el partido
/// es en otro campo y el lugar está vacío, el campo del partido; en cualquier otro caso, el lugar tal cual.
String destinoLugarCitacion(
  String? lugar, {
  String? campo,
  bool? local,
  bool? enCasaElsOms,
}) {
  final texto = lugar?.trim() ?? '';

  if (mismoLugar(texto, campoCasaTexto)) {
    return campoCasaMapas;
  }

  if (texto.isEmpty || mismoLugar(texto, campo)) {
    return _seJuegaEnElsOms(campo, local, enCasaElsOms)
        ? campoCasaMapas
        : (campo?.trim() ?? texto);
  }

  return texto;
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
/// lugar de una citación. No se pinta si no hay nada que buscar.
///
/// [local] (true si el Mutxamel juega en casa) y [enCasaElsOms] (del backend; null si no lo manda) deciden si el destino
/// es [campoCasaMapas]: solo si se juega en Els Oms. Con [BotonComoLlegar.citacion] el texto es el lugar de citación y
/// [campo] el campo del partido.
class BotonComoLlegar extends StatelessWidget {
  final String? lugar;
  final bool? local;

  /// El `enCasaElsOms` del backend; null si no lo manda (se calcula con [local] y el campo).
  final bool? enCasaElsOms;
  final String? campo;
  final bool _esCitacion;

  const BotonComoLlegar({
    super.key,
    required this.lugar,
    this.local,
    this.enCasaElsOms,
  }) : campo = null,
       _esCitacion = false;

  const BotonComoLlegar.citacion({
    super.key,
    required this.lugar,
    this.campo,
    this.local,
    this.enCasaElsOms,
  }) : _esCitacion = true;

  @override
  Widget build(BuildContext context) {
    final destino = _esCitacion
        ? destinoLugarCitacion(
            lugar,
            campo: campo,
            local: local,
            enCasaElsOms: enCasaElsOms,
          )
        : destinoCampoPartido(
            lugar,
            local: local,
            enCasaElsOms: enCasaElsOms,
          );

    if (destino.isEmpty) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: AppLocalizations.of(context).directionsButton,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.directions),
      color: Theme.of(context).colorScheme.primary,
      onPressed: () => abrirComoLlegar(context, destino),
    );
  }
}
