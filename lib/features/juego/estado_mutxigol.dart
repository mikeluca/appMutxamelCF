import 'package:flutter/foundation.dart';

import 'models/juego_modelos.dart';

/// Lo que el juego recuerda MIENTRAS LA APP ESTÁ ABIERTA (nada se guarda en el móvil): la equipación elegida (con
/// sesión se guarda además en el perfil del juego, en el backend) y, sin sesión, los récords de esta sesión.
class EstadoMutxigol {
  EstadoMutxigol._();

  /// La equipación con la que se ve a Mutxigol en toda la app (la barra, el menú y los juegos).
  static final ValueNotifier<Equipacion> equipacion = ValueNotifier(
    Equipacion.azul,
  );

  static final Map<Juego, int> _recordsDeLaSesion = {};

  /// El mejor resultado de esta sesión de la app en ese juego (0 si no hay).
  static int recordDeLaSesion(Juego juego) => _recordsDeLaSesion[juego] ?? 0;

  static void anotarPuntuacion(Juego juego, int puntos) {
    if (puntos > recordDeLaSesion(juego)) _recordsDeLaSesion[juego] = puntos;
  }

  /// Solo para tests: vuelve al estado de recién abierta la app.
  @visibleForTesting
  static void reiniciar() {
    equipacion.value = Equipacion.azul;
    _recordsDeLaSesion.clear();
  }
}
