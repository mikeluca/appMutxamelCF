/// Lógica de los topics de FCM de quien usa la app sin cuenta (resultados del
/// directo y noticias). El backend publica un topic por idioma
/// (`resultados_es|ca|en`, `noticias_es|ca|en`) y, para las versiones que no
/// se suscriben por idioma, los antiguos `resultados` y `noticias`, en
/// castellano. Esta versión solo está en el topic de su idioma, y en ningún
/// otro.
///
/// No toca Firebase: recibe las funciones de alta y baja, para poder
/// probarlo.
class TopicsAnonimos {
  TopicsAnonimos({required this.suscribir, required this.desuscribir});

  final Future<void> Function(String topic) suscribir;
  final Future<void> Function(String topic) desuscribir;

  static const String baseNoticias = 'noticias';
  static const String baseResultados = 'resultados';

  static const List<String> idiomas = ['es', 'ca', 'en'];

  /// "noticias_ca", "resultados_en"...
  static String topicDe(String base, String idioma) => '${base}_$idioma';

  /// Todos los topics de [base] que no son el del [idioma]: el antiguo sin
  /// idioma y los de los otros idiomas.
  static List<String> otrosTopics(String base, String idioma) => [
    base,
    for (final otro in idiomas)
      if (otro != idioma) topicDe(base, otro),
  ];

  /// Todos los topics de [base], el antiguo y los tres idiomas.
  static List<String> todosLosTopics(String base) => [
    base,
    for (final idioma in idiomas) topicDe(base, idioma),
  ];

  /// Activa [base] en [idioma]: alta en su topic y baja de los antiguos y de
  /// los de los otros idiomas.
  Future<void> activar(String base, String idioma) async {
    await suscribir(topicDe(base, idioma));
    await _bajas(otrosTopics(base, idioma));
  }

  /// Desactiva [base]: baja de todos sus topics.
  Future<void> desactivar(String base) => _bajas(todosLosTopics(base));

  /// El usuario cambia de idioma: de lo que tiene activo, baja del topic del
  /// idioma anterior y alta en el del nuevo.
  Future<void> cambiarIdioma({
    required String anterior,
    required String nuevo,
    required bool noticias,
    required bool resultados,
  }) async {
    if (anterior == nuevo) {
      return;
    }

    for (final base in [
      if (noticias) baseNoticias,
      if (resultados) baseResultados,
    ]) {
      await desuscribir(topicDe(base, anterior));
      await suscribir(topicDe(base, nuevo));
    }
  }

  /// Deja los topics activos en el idioma de la app, y sin los antiguos ni los
  /// de otros idiomas: para las instalaciones que se suscribieron con una
  /// versión anterior (a `noticias` / `resultados`) y para cuando el idioma
  /// cambió sin pasar por Ajustes.
  Future<void> sincronizar({
    required String idioma,
    required bool noticias,
    required bool resultados,
  }) async {
    if (noticias) {
      await activar(baseNoticias, idioma);
    }

    if (resultados) {
      await activar(baseResultados, idioma);
    }
  }

  /// Baja de los seis topics por idioma y de los dos antiguos: quien inicia
  /// sesión recibe los avisos por su cuenta y no debe recibirlos duplicados.
  Future<void> desuscribirDeTodos() async {
    await _bajas(todosLosTopics(baseNoticias));
    await _bajas(todosLosTopics(baseResultados));
  }

  Future<void> _bajas(List<String> topics) async {
    for (final topic in topics) {
      await desuscribir(topic);
    }
  }
}
