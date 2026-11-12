/// Formaciones admitidas por el backend (lista cerrada según la modalidad del equipo) y la posición en el campo de
/// cada titular según el orden de elección.
///
/// Una formación es "defensas-medios-delanteros" (con cualquier número de líneas) y el equipo lleva además un
/// portero: titulares = 1 + la suma de la formación. La posición sale del orden de elección: el 1.º es el portero;
/// después, las líneas de la formación de atrás adelante y, dentro de cada línea, de izquierda a derecha.
class Formaciones {
  Formaciones._();

  static const List<String> f11 = [
    '4-4-2',
    '4-3-3',
    '4-2-3-1',
    '4-5-1',
    '4-1-4-1',
    '3-5-2',
    '3-4-3',
    '5-3-2',
    '5-4-1',
  ];

  static const List<String> f8 = [
    '3-3-1',
    '3-2-2',
    '2-3-2',
    '2-4-1',
    '3-1-3',
    '4-2-1',
  ];

  static const List<String> f5 = ['2-2', '1-2-1', '2-1-1', '1-1-2', '3-1'];

  /// Las de la modalidad del equipo (F11 si no se conoce).
  static List<String> paraModalidad(String? modalidad) => switch (modalidad) {
    'F8' => f8,
    'F5' => f5,
    _ => f11,
  };

  /// Titulares que exige la formación: el portero más todos los de campo.
  static int titulares(String formacion) =>
      1 + _lineas(formacion).fold<int>(0, (suma, n) => suma + n);

  static List<int> _lineas(String formacion) =>
      formacion.split('-').map(int.parse).toList();

  /// Fila (1 = portero, luego las líneas de atrás adelante) y columna (de izquierda a derecha) del titular número
  /// [orden] (desde 1); null si [orden] no cabe en la formación.
  static ({int fila, int columna})? posicion(String formacion, int orden) {
    if (orden < 1) return null;

    if (orden == 1) return (fila: 1, columna: 1);

    var restantes = orden - 1;
    final lineas = _lineas(formacion);

    for (var i = 0; i < lineas.length; i++) {
      if (restantes <= lineas[i]) {
        return (fila: i + 2, columna: restantes);
      }

      restantes -= lineas[i];
    }

    return null;
  }

  /// Número de filas del campo para esa formación (el portero y una por línea).
  static int filas(String formacion) => 1 + _lineas(formacion).length;
}
