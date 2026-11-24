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

  /// Si ya se ha enseñado la leyenda de Atrapa balones en esta sesión de la app (sale antes de la primera partida).
  static bool leyendaAtrapaVista = false;

  /// El mejor resultado de esta sesión de la app en ese juego (0 si no hay): puntos o, en Parejas, el menor tiempo en
  /// ms.
  static int recordDeLaSesion(Juego juego) => _recordsDeLaSesion[juego] ?? 0;

  /// Anota una partida: [valor] son los puntos o, en Parejas, el tiempo en ms (menos es mejor).
  static void anotarPuntuacion(Juego juego, int valor) {
    if (valor <= 0) return;

    final actual = recordDeLaSesion(juego);

    final mejora = juego.esDeTiempo ? (actual == 0 || valor < actual) : valor > actual;

    if (mejora) _recordsDeLaSesion[juego] = valor;
  }

  /// Solo para tests: vuelve al estado de recién abierta la app.
  @visibleForTesting
  static void reiniciar() {
    equipacion.value = Equipacion.azul;
    _recordsDeLaSesion.clear();
    leyendaAtrapaVista = false;
  }
}
