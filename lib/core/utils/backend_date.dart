/// Antes de N-06 (2.ª auditoría), el backend serializaba los campos
/// java.time (LocalDate/LocalDateTime) como un array JSON
/// `[year, month, day, ...]` en vez de una cadena ISO-8601. Desde que se
/// desactivó `write-dates-as-timestamps`, llegan como texto ISO-8601
/// (igual que los campos java.util.Date, que ya llegaban así). Esta
/// función entiende ambos formatos para no tener que repetir el parseo
/// en cada modelo, ni depender de que todos los endpoints se hayan
/// desplegado ya con el cambio.
DateTime? parseFechaBackend(dynamic value) {
  if (value == null) return null;

  if (value is List) {
    if (value.isEmpty) return null;

    final partes = value.map((e) => (e as num).toInt()).toList();

    return DateTime(
      partes[0],
      partes.length > 1 ? partes[1] : 1,
      partes.length > 2 ? partes[2] : 1,
      partes.length > 3 ? partes[3] : 0,
      partes.length > 4 ? partes[4] : 0,
      partes.length > 5 ? partes[5] : 0,
    );
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

/// Igual que [parseFechaBackend], pero para cuando el valor ya ha
/// pasado por un `.toString()` en el modelo (p.ej.
/// `json['fecha']?.toString()`), como hacen EntrenamientoModel.fecha y
/// ConvocatoriaModel.fechaPartido: si el valor original era el array
/// JSON antiguo `[year, month, day]`, `.toString()` ya lo convirtió en
/// el texto "[year, month, day]" (formato de List.toString() de Dart),
/// que no es una fecha ISO parseable directamente y hay que reconocer
/// aparte.
DateTime? parseFechaTextoBackend(String? texto) {
  if (texto == null || texto.isEmpty) return null;

  final directa = DateTime.tryParse(texto);

  if (directa != null) return directa;

  final match = RegExp(r'\[(\d+),\s*(\d+),\s*(\d+)').firstMatch(texto);

  if (match == null) return null;

  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}
