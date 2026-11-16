/// Fase con reloj del partido en directo (el backend manda `reloj` solo en estas tres; antes del inicio y tras el
/// final no hay objeto).
enum FaseReloj {
  primeraParte,
  descanso,
  segundaParte;

  static FaseReloj? desdeTexto(String? texto) {
    return switch (texto) {
      'PRIMERA_PARTE' => FaseReloj.primeraParte,
      'DESCANSO' => FaseReloj.descanso,
      'SEGUNDA_PARTE' => FaseReloj.segundaParte,
      _ => null,
    };
  }
}

/// Objeto `reloj` del backend (portada, ficha y estado de la retransmisión). Ver docs/api-app-retransmision.md
/// (sección 6) del backend.
///
/// El tiempo que se pinta es `minutoBase·60 s + (ahora del móvil + desfase − inicioParte)`, con
/// `desfase = ahoraServidor − hora del móvil al recibir la respuesta`: así no depende de que el reloj del móvil
/// vaya bien. Se calcula siempre desde los datos (no se acumula), de modo que un temporizador de 1 s solo necesita
/// repintar.
class RelojDirecto {
  final FaseReloj fase;

  /// Instante (epoch ms) del inicio de la parte en juego; null en el descanso.
  final int? inicioParteEpochMs;

  /// 0 en la primera parte; la duración de una parte en la segunda y en el descanso.
  final int minutoBase;

  /// Duración de cada parte según la modalidad del equipo.
  final int minutosParte;

  /// Hora del servidor (epoch ms) al construir la respuesta.
  final int ahoraServidorEpochMs;

  /// Hora del móvil al recibir la respuesta.
  final DateTime recibidoEn;

  const RelojDirecto({
    required this.fase,
    this.inicioParteEpochMs,
    this.minutoBase = 0,
    this.minutosParte = 45,
    required this.ahoraServidorEpochMs,
    required this.recibidoEn,
  });

  /// Null si no hay `reloj` (backend antiguo, antes del inicio o tras el final) o si no se entiende.
  static RelojDirecto? desdeJson(Object? json, {DateTime? recibidoEn}) {
    if (json is! Map<String, dynamic>) return null;

    final fase = FaseReloj.desdeTexto(json['fase'] as String?);
    final servidor = (json['ahoraServidorEpochMs'] as num?)?.toInt();
    final inicio = (json['inicioParteEpochMs'] as num?)?.toInt();

    if (fase == null || servidor == null) return null;

    // Sin inicio solo vale el descanso.
    if (fase != FaseReloj.descanso && inicio == null) return null;

    return RelojDirecto(
      fase: fase,
      inicioParteEpochMs: inicio,
      minutoBase: (json['minutoBase'] as num?)?.toInt() ?? 0,
      minutosParte: (json['minutosParte'] as num?)?.toInt() ?? 45,
      ahoraServidorEpochMs: servidor,
      recibidoEn: recibidoEn ?? DateTime.now(),
    );
  }

  bool get enDescanso => fase == FaseReloj.descanso;

  /// Cuánto va el reloj del servidor por delante del del móvil.
  Duration get desfase => Duration(
    milliseconds: ahoraServidorEpochMs - recibidoEn.millisecondsSinceEpoch,
  );

  /// El tiempo de partido en [ahora] (hora del móvil); null en el descanso. Nunca baja de `minutoBase`: con un
  /// desfase raro no se pinta un reloj hacia atrás. Pasada la duración de la parte sigue contando (47:13).
  Duration? tiempo(DateTime ahora) {
    final inicio = inicioParteEpochMs;

    if (enDescanso || inicio == null) return null;

    final ahoraServidor = ahora.millisecondsSinceEpoch + desfase.inMilliseconds;
    final transcurrido = ahoraServidor - inicio;

    return Duration(minutes: minutoBase) +
        Duration(milliseconds: transcurrido < 0 ? 0 : transcurrido);
  }

  /// "MM:ss" (con más de 99 minutos, tantos dígitos como haga falta); null en el descanso.
  String? texto(DateTime ahora) {
    final duracion = tiempo(ahora);

    if (duracion == null) return null;

    final minutos = duracion.inMinutes.toString().padLeft(2, '0');
    final segundos = (duracion.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutos:$segundos';
  }
}
