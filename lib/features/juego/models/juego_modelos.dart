/// Los cuatro minijuegos de Mutxigol, en el orden del menú y del ranking. [codigo] es el que entiende el backend.
enum Juego {
  atrapa('ATRAPA'),
  cabezazos('CABEZAZOS'),
  parejas('PAREJAS');

  const Juego(this.codigo);

  final String codigo;

  /// En Parejas la marca es el TIEMPO (menos es mejor); en los demás, los PUNTOS (más es mejor).
  bool get esDeTiempo => this == Juego.parejas;

  static Juego? desdeCodigo(String? codigo) {
    for (final juego in Juego.values) {
      if (juego.codigo == codigo?.toUpperCase()) return juego;
    }

    return null;
  }
}

/// El periodo del ranking.
enum PeriodoRanking {
  semana('SEMANA'),
  historico('HISTORICO');

  const PeriodoRanking(this.codigo);

  final String codigo;
}

/// La equipación de Mutxigol; [carpeta] es la de assets/images/mutxigol/.
enum Equipacion {
  azul('AZUL', 'azul'),
  rosa('ROSA', 'rosa');

  const Equipacion(this.codigo, this.carpeta);

  final String codigo;
  final String carpeta;

  static Equipacion desdeCodigo(String? codigo) =>
      codigo?.toUpperCase() == 'ROSA' ? Equipacion.rosa : Equipacion.azul;

  /// La otra equipación del club (los defensas de Cabezazos la llevan).
  Equipacion get opuesta => this == Equipacion.azul ? Equipacion.rosa : Equipacion.azul;
}

/// Las poses de Mutxigol (un .webp por equipación). [salto] es de perfil, mirando a
/// la derecha.
enum PoseMutxigol {
  parado('mutxigol_parado'),
  atrapando('mutxigol_atrapando'),
  celebrando('mutxigol_celebrando'),
  triste('mutxigol_triste'),
  cara('mutxigol_cara'),
  salto('mutxigol_salto');

  const PoseMutxigol(this.fichero);

  final String fichero;
}

/// Las rutas de las imágenes del juego.
class ImagenesMutxigol {
  ImagenesMutxigol._();

  static const String _base = 'assets/images/mutxigol';

  static const String balon = '$_base/balon.webp';

  /// El escudo del club (Atrapa lo deja caer como vida extra; Parejas lo pone en el reverso de las cartas).
  static const String escudoClub = 'assets/images/escudo.png';

  static String pose(Equipacion equipacion, PoseMutxigol pose) =>
      '$_base/${equipacion.carpeta}/${pose.fichero}.webp';
}

/// Lo que mide la marca según el backend (campo `marca`: PUNTOS o TIEMPO). Sin el campo, lo habitual del juego.
bool marcaEsTiempo(Object? marca, {required bool porDefecto}) =>
    marca == null ? porDefecto : '$marca'.toUpperCase() == 'TIEMPO';

/// Una marca: puntos, tiempo de la partida (ms), cuándo se hicieron y la posición que ocupa en el ranking (null si el
/// perfil está oculto).
class MarcaJuego {
  final int puntos;
  final int tiempoMs;
  final DateTime? fecha;
  final int? posicion;

  const MarcaJuego({
    required this.puntos,
    this.tiempoMs = 0,
    this.fecha,
    this.posicion,
  });

  factory MarcaJuego.fromJson(Map<String, dynamic> json) => MarcaJuego(
    puntos: (json['puntos'] as num).toInt(),
    tiempoMs: (json['tiempoMs'] as num?)?.toInt() ?? 0,
    fecha: DateTime.tryParse('${json['fecha'] ?? ''}'),
    posicion: (json['posicion'] as num?)?.toInt(),
  );
}

/// Las mejores marcas de un juego: de esta semana y de siempre (null si aún no hay). [esTiempo] dice si la marca es el
/// tiempo (Parejas: menos es mejor) o los puntos.
class MarcasDeJuego {
  final bool esTiempo;
  final MarcaJuego? semana;
  final MarcaJuego? historico;

  const MarcasDeJuego({this.esTiempo = false, this.semana, this.historico});

  /// El valor de una marca: ms si es tiempo, puntos si no (0 si no hay).
  static int valor(MarcaJuego? marca, {required bool esTiempo}) =>
      marca == null ? 0 : (esTiempo ? marca.tiempoMs : marca.puntos);

  MarcaJuego? dePeriodo(PeriodoRanking periodo) =>
      periodo == PeriodoRanking.semana ? semana : historico;
}

/// El perfil del juego de la cuenta (GET /api/app/juego/perfil).
class PerfilJuego {
  final String? alias;
  final Equipacion equipacion;
  final bool oculto;
  final Map<Juego, MarcasDeJuego> juegos;

  const PerfilJuego({
    this.alias,
    this.equipacion = Equipacion.azul,
    this.oculto = false,
    this.juegos = const {},
  });

  bool get tieneAlias => alias != null && alias!.trim().isNotEmpty;

  MarcasDeJuego marcas(Juego juego) =>
      juegos[juego] ?? MarcasDeJuego(esTiempo: juego.esDeTiempo);

  /// El récord histórico en ese juego (0 si no hay): los puntos o, en Parejas, el mejor tiempo en ms.
  int record(Juego juego) {
    final m = marcas(juego);

    return MarcasDeJuego.valor(m.historico, esTiempo: m.esTiempo);
  }

  factory PerfilJuego.fromJson(Map<String, dynamic> json) {
    final juegos = <Juego, MarcasDeJuego>{};
    final crudos = json['juegos'];

    if (crudos is Map) {
      for (final entrada in crudos.entries) {
        final juego = Juego.desdeCodigo('${entrada.key}');
        final valor = entrada.value;

        if (juego == null || valor is! Map) continue;

        MarcaJuego? marca(String clave) => valor[clave] is Map
            ? MarcaJuego.fromJson(Map<String, dynamic>.from(valor[clave]))
            : null;

        juegos[juego] = MarcasDeJuego(
          esTiempo: marcaEsTiempo(valor['marca'], porDefecto: juego.esDeTiempo),
          semana: marca('semana'),
          historico: marca('historico'),
        );
      }
    }

    return PerfilJuego(
      alias: json['alias'] as String?,
      equipacion: Equipacion.desdeCodigo(json['equipacion'] as String?),
      oculto: json['oculto'] == true,
      juegos: juegos,
    );
  }
}

/// Una fila del ranking público. [esTiempo] (campo `marca` del backend) dice si lo que cuenta es el tiempo.
class FilaRanking {
  final int posicion;
  final String alias;
  final int puntos;
  final int tiempoMs;
  final bool esTiempo;
  final DateTime? fecha;

  const FilaRanking({
    required this.posicion,
    required this.alias,
    required this.puntos,
    this.tiempoMs = 0,
    this.esTiempo = false,
    this.fecha,
  });

  /// Lo que se enseña: ms si es tiempo, puntos si no.
  int get valor => esTiempo ? tiempoMs : puntos;

  factory FilaRanking.fromJson(
    Map<String, dynamic> json, {
    bool tiempoPorDefecto = false,
  }) => FilaRanking(
    posicion: (json['posicion'] as num).toInt(),
    alias: '${json['alias']}',
    puntos: (json['puntos'] as num).toInt(),
    tiempoMs: (json['tiempoMs'] as num?)?.toInt() ?? 0,
    esTiempo: marcaEsTiempo(json['marca'], porDefecto: tiempoPorDefecto),
    fecha: DateTime.tryParse('${json['fecha'] ?? ''}'),
  );
}

/// Un club con escudo para las cartas de Parejas (GET /public/juego/escudos). [escudoUrl] es la ruta relativa que da el
/// backend.
class EscudoJuego {
  final int id;
  final String nombre;
  final String? escudoUrl;

  const EscudoJuego({required this.id, required this.nombre, this.escudoUrl});

  factory EscudoJuego.fromJson(Map<String, dynamic> json) => EscudoJuego(
    id: (json['id'] as num).toInt(),
    nombre: '${json['nombre'] ?? ''}',
    escudoUrl: json['escudoUrl'] as String?,
  );
}

/// Lo que devuelve guardar una puntuación (POST /api/app/juego/puntuacion).
class ResultadoPuntuacion {
  final bool esTiempo;
  final bool recordSemana;
  final bool recordHistorico;
  final int? posicionSemana;
  final int? posicionHistorico;

  const ResultadoPuntuacion({
    this.esTiempo = false,
    this.recordSemana = false,
    this.recordHistorico = false,
    this.posicionSemana,
    this.posicionHistorico,
  });

  bool get esRecord => recordSemana || recordHistorico;

  factory ResultadoPuntuacion.fromJson(Map<String, dynamic> json) =>
      ResultadoPuntuacion(
        esTiempo: marcaEsTiempo(json['marca'], porDefecto: false),
        recordSemana: json['recordSemana'] == true,
        recordHistorico: json['recordHistorico'] == true,
        posicionSemana: (json['posicionSemana'] as num?)?.toInt(),
        posicionHistorico: (json['posicionHistorico'] as num?)?.toInt(),
      );
}

/// Un perfil para moderar (solo ADMIN_APP): con la cuenta (nombre y email).
class PerfilJuegoAdmin {
  final int usuarioId;
  final String? alias;
  final Equipacion equipacion;
  final bool oculto;
  final String nombre;
  final String email;
  final int partidas;
  final int mejorAtrapa;
  final int mejorCabezazos;

  /// El menor tiempo en Parejas, en ms (0 si no ha jugado).
  final int mejorParejasMs;

  const PerfilJuegoAdmin({
    required this.usuarioId,
    this.alias,
    this.equipacion = Equipacion.azul,
    this.oculto = false,
    this.nombre = '',
    this.email = '',
    this.partidas = 0,
    this.mejorAtrapa = 0,
    this.mejorCabezazos = 0,
    this.mejorParejasMs = 0,
  });

  factory PerfilJuegoAdmin.fromJson(Map<String, dynamic> json) =>
      PerfilJuegoAdmin(
        usuarioId: (json['usuarioId'] as num).toInt(),
        alias: json['alias'] as String?,
        equipacion: Equipacion.desdeCodigo(json['equipacion'] as String?),
        oculto: json['oculto'] == true,
        nombre: '${json['nombre'] ?? ''}',
        email: '${json['email'] ?? ''}',
        partidas: (json['partidas'] as num?)?.toInt() ?? 0,
        mejorAtrapa: (json['mejorAtrapa'] as num?)?.toInt() ?? 0,
        mejorCabezazos: (json['mejorCabezazos'] as num?)?.toInt() ?? 0,
        mejorParejasMs: (json['mejorParejasMs'] as num?)?.toInt() ?? 0,
      );
}

/// Una partida guardada (para borrarla en la moderación).
class PuntuacionAdmin {
  final int id;
  final Juego? juego;
  final int puntos;
  final int duracionMs;
  final DateTime? fecha;

  const PuntuacionAdmin({
    required this.id,
    this.juego,
    required this.puntos,
    this.duracionMs = 0,
    this.fecha,
  });

  factory PuntuacionAdmin.fromJson(Map<String, dynamic> json) =>
      PuntuacionAdmin(
        id: (json['id'] as num).toInt(),
        juego: Juego.desdeCodigo(json['juego'] as String?),
        puntos: (json['puntos'] as num).toInt(),
        duracionMs: (json['duracionMs'] as num?)?.toInt() ?? 0,
        fecha: DateTime.tryParse('${json['fecha'] ?? ''}'),
      );
}
