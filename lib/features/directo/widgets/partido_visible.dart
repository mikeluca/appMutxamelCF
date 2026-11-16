/// Los partidos cuyo marcador está ahora mismo a la vista (ficha o tarjeta de la portada, con la app en primer plano
/// y sin otra pantalla encima). Con el partido a la vista el aviso del directo no sale también como notificación
/// local: la pantalla ya se está recargando y celebra el gol por su cuenta.
class PartidoVisible {
  PartidoVisible._();

  static final Map<Object, int> _porDueno = {};

  /// Marca (o desmarca, con [partidoId] null) lo que enseña [dueno].
  static void actualizar(Object dueno, int? partidoId) {
    if (partidoId == null) {
      _porDueno.remove(dueno);
    } else {
      _porDueno[dueno] = partidoId;
    }
  }

  static bool estaVisible(int partidoId) => _porDueno.containsValue(partidoId);

  /// Solo para tests.
  static void reiniciar() => _porDueno.clear();
}
