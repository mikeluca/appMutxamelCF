/// Un partido que el usuario sigue: su id y el día en que se juega (para darlo de baja pasado el tiempo).
class PartidoSeguido {
  final int id;
  final DateTime fecha;

  const PartidoSeguido(this.id, this.fecha);
}

/// Resultado de pulsar "Seguir este partido".
enum ResultadoSeguir {
  /// Ya está dado de alta en el topic del partido.
  seguido,

  /// El usuario no ha dado permiso de notificaciones: no se marca como seguido.
  permisoDenegado,
}

/// "Seguir este partido": los avisos de un solo partido sin activar todos los de resultados.
///
/// El backend publica cada aviso del directo con partido también en el topic `partido_{id}_{idioma}` (docs/
/// api-app-retransmision.md). Seguir = alta en el topic del idioma de la app; dejar de seguir = baja. Los partidos
/// seguidos (id y día) se guardan en el dispositivo para moverlos si cambia el idioma y darlos de baja cuando
/// terminan o pasan más de [diasMaximos] días.
///
/// Solo se ofrece a quien NO recibe ya los avisos de resultados (sin cuenta: el interruptor anónimo apagado; con
/// cuenta: su preferencia de resultados apagada). Así nadie recibe el mismo aviso dos veces: quien tiene los
/// resultados activos los recibe por su cuenta o por `resultados_xx`, y quien sigue un partido solo por su topic.
///
/// No toca Firebase ni el disco: recibe las funciones, para poder probarlo.
class SeguirPartidoService {
  SeguirPartidoService({
    required this.suscribir,
    required this.desuscribir,
    required this.obtenerIdioma,
    required this.leer,
    required this.guardar,
    this.pedirPermiso,
    this.recibeResultados,
    DateTime Function()? ahora,
  }) : _ahora = ahora ?? DateTime.now;

  final Future<void> Function(String topic) suscribir;
  final Future<void> Function(String topic) desuscribir;
  final Future<String> Function() obtenerIdioma;
  final Future<Map<int, DateTime>> Function() leer;
  final Future<void> Function(Map<int, DateTime> seguidos) guardar;

  /// Pide el permiso de notificaciones; true si se tiene. Sin función se da por concedido.
  final Future<bool> Function()? pedirPermiso;

  /// true si este dispositivo ya recibe los avisos de resultados; null si no se puede saber.
  final Future<bool?> Function()? recibeResultados;

  final DateTime Function() _ahora;

  /// Pasados estos días desde el partido se da de baja aunque no se haya cargado su ficha final.
  static const int diasMaximos = 2;

  /// "partido_30_es".
  static String topicDe(int partidoId, String idioma) =>
      'partido_${partidoId}_$idioma';

  Future<bool> sigue(int partidoId) async =>
      (await leer()).containsKey(partidoId);

  /// true si el dispositivo recibe ya los avisos de resultados (no hace falta seguir), false si no, null si no se
  /// sabe (entonces no se ofrece nada).
  Future<bool?> recibeAvisosDeResultados() async =>
      recibeResultados == null ? false : await recibeResultados!();

  /// Alta en el topic del partido en el idioma de la app. Pide el permiso de notificaciones si hace falta; si se
  /// deniega, no se marca como seguido. [fecha] es el día del partido (si no se sabe, hoy).
  Future<ResultadoSeguir> seguir(int partidoId, DateTime? fecha) async {
    if (pedirPermiso != null && !await pedirPermiso!()) {
      return ResultadoSeguir.permisoDenegado;
    }

    final idioma = await obtenerIdioma();

    await suscribir(topicDe(partidoId, idioma));

    final seguidos = await leer();
    seguidos[partidoId] = _soloDia(fecha ?? _ahora());
    await guardar(seguidos);

    return ResultadoSeguir.seguido;
  }

  /// Baja del topic del partido (en el idioma de la app y, por si acaso, en los otros dos) y lo olvida.
  Future<void> dejarDeSeguir(int partidoId) async {
    final seguidos = await leer();

    if (!seguidos.containsKey(partidoId)) return;

    await _bajaDeTopics(partidoId);

    seguidos.remove(partidoId);
    await guardar(seguidos);
  }

  /// El usuario cambia de idioma: de cada partido seguido, baja del topic del idioma anterior y alta en el del nuevo.
  Future<void> alCambiarIdioma(String anterior, String nuevo) async {
    if (anterior == nuevo) return;

    for (final id in (await leer()).keys) {
      await desuscribir(topicDe(id, anterior));
      await suscribir(topicDe(id, nuevo));
    }
  }

  /// Baja de los partidos seguidos con más de [diasMaximos] días. Se llama al arrancar la app.
  Future<void> bajaAutomatica() async {
    final seguidos = await leer();
    final hoy = _soloDia(_ahora());
    final caducados = [
      for (final e in seguidos.entries)
        if (hoy.difference(e.value).inDays > diasMaximos) e.key,
    ];

    for (final id in caducados) {
      await _bajaDeTopics(id);
      seguidos.remove(id);
    }

    if (caducados.isNotEmpty) await guardar(seguidos);
  }

  /// Se llama al cargar la ficha de un partido FINALIZADO o CANCELADO: ya no hay nada que avisar.
  Future<void> bajaSiTermino(int partidoId) => dejarDeSeguir(partidoId);

  /// Baja de todos los partidos seguidos: el dispositivo ya recibe los avisos de resultados, así que seguirlos
  /// duplicaría los avisos.
  Future<void> bajaDeTodos() async {
    final seguidos = await leer();

    if (seguidos.isEmpty) return;

    for (final id in seguidos.keys) {
      await _bajaDeTopics(id);
    }

    await guardar({});
  }

  /// Al arrancar: baja de los caducados y, si el dispositivo ya recibe los resultados (los activó después de
  /// seguir algún partido), de todos.
  Future<void> alArrancar() async {
    await bajaAutomatica();

    if (await recibeAvisosDeResultados() == true) {
      await bajaDeTodos();
    }
  }

  Future<void> _bajaDeTopics(int partidoId) async {
    final idioma = await obtenerIdioma();

    await desuscribir(topicDe(partidoId, idioma));

    for (final otro in const ['es', 'ca', 'en']) {
      if (otro != idioma) await desuscribir(topicDe(partidoId, otro));
    }
  }

  static DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);
}
