final RegExp _formatoMarcador = RegExp(r'^(\d+)\s*-\s*(\d+)$');

/// Marcador para mostrarlo con los equipos pintados como local | visitante.
///
/// El backend guarda SIEMPRE el resultado desde el punto de vista del
/// Mutxamel ("golesMutxamel-golesRival"). Si el Mutxamel es visitante hay
/// que darle la vuelta para que coincida con el orden en pantalla. Lo que se
/// guarda y se envía al backend no cambia.
///
/// Devuelve null si no hay resultado; si el texto no tiene la forma "X-Y"
/// (p. ej. " - " o "Aplazado") lo devuelve tal cual.
String? marcadorLocalVisitante(String? resultado, {required bool local}) {
  final texto = resultado?.trim();

  if (texto == null || texto.isEmpty) {
    return null;
  }

  if (local) {
    return texto;
  }

  final coincidencia = _formatoMarcador.firstMatch(texto);

  if (coincidencia == null) {
    return texto;
  }

  return '${coincidencia.group(2)}-${coincidencia.group(1)}';
}
