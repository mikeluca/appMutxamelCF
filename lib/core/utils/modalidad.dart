/// Criterio único para saber si un equipo registra estadísticas individuales
/// de jugador (goles, asistencias, tarjetas): solo el fútbol 11.
///
/// Orden: la clave `admiteEstadisticas` si viene; si no, `modalidad == 'F11'`
/// (null o vacía → false) cuando viene la clave `modalidad`; y sin ninguna de
/// las dos (backend antiguo) → true.
bool leerAdmiteEstadisticas(Map<String, dynamic> json) {
  final admite = json['admiteEstadisticas'];

  if (admite is bool) {
    return admite;
  }

  if (json.containsKey('modalidad')) {
    return json['modalidad'] == 'F11';
  }

  return true;
}
