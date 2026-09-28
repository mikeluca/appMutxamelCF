/// El backend serializa los campos java.time (LocalDate/LocalDateTime)
/// como un array JSON `[year, month, day, ...]` en vez de una cadena
/// ISO-8601 (a diferencia de los campos java.util.Date, que sí llegan
/// como texto/epoch). Esta función entiende ambos formatos para no
/// tener que repetir el parseo en cada modelo.
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
