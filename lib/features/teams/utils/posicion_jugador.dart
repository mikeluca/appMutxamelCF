import '../../../l10n/gen/app_localizations.dart';

/// Las posiciones de la lista cerrada del backend (los códigos de la API), en el orden del selector.
const List<String> posicionesJugador = [
  'PORTERO',
  'DEFENSA',
  'CENTROCAMPISTA',
  'EXTREMO',
  'DELANTERO',
];

/// El nombre de una posición de la lista en el idioma de la app, o null si [codigo] no es de la lista.
String? nombrePosicion(AppLocalizations t, String? codigo) {
  return switch (codigo) {
    'PORTERO' => t.positionPORTERO,
    'DEFENSA' => t.positionDEFENSA,
    'CENTROCAMPISTA' => t.positionCENTROCAMPISTA,
    'EXTREMO' => t.positionEXTREMO,
    'DELANTERO' => t.positionDELANTERO,
    _ => null,
  };
}

/// La posición a mostrar: el código traducido y, si no viene (backend antiguo o un valor fuera de la lista), el texto
/// guardado tal cual. Null si no hay nada que mostrar.
String? textoPosicion(AppLocalizations t, {String? codigo, String? texto}) {
  final traducida = nombrePosicion(t, codigo);

  if (traducida != null) return traducida;

  final limpio = texto?.trim();

  return limpio == null || limpio.isEmpty ? null : limpio;
}
