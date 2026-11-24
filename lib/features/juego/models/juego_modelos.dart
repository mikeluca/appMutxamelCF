/// Los tres minijuegos de Mutxigol. [codigo] es el que entiende el backend.
enum Juego {
  penaltis('PENALTIS'),
  toques('TOQUES'),
  atrapa('ATRAPA');

  const Juego(this.codigo);

  final String codigo;

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
}

/// Las poses de Mutxigol (un .webp por equipación).
enum PoseMutxigol {
  parado('mutxigol_parado'),
  portero('mutxigol_portero'),
  parada('mutxigol_parada'),
  chutando('mutxigol_chutando'),
  toques('mutxigol_toques'),
  atrapando('mutxigol_atrapando'),
  celebrando('mutxigol_celebrando'),
  triste('mutxigol_triste'),
  cara('mutxigol_cara');

  const PoseMutxigol(this.fichero);

  final String fichero;
}

/// Las rutas de las imágenes del juego.
class ImagenesMutxigol {
  ImagenesMutxigol._();

  static const String _base = 'assets/images/mutxigol';

  static const String balon = '$_base/balon.webp';

  static String pose(Equipacion equipacion, PoseMutxigol pose) =>
      '$_base/${equipacion.carpeta}/${pose.fichero}.webp';
}

/// Una marca: puntos, cuándo se hicieron y la posición que ocupa en el ranking (null si el perfil está oculto).
class MarcaJuego {
  final int puntos;
  final DateTime? fecha;
  final int? posicion;

  const MarcaJuego({required this.puntos, this.fecha, this.posicion});

  factory MarcaJuego.fromJson(Map<String, dynamic> json) => MarcaJuego(
    puntos: (json['puntos'] as num).toInt(),
    fecha: DateTime.tryParse('${json['fecha'] ?? ''}'),
    posicion: (json['posicion'] as num?)?.toInt(),
  );
}

/// Las mejores marcas de un juego: de esta semana y de siempre (null si aún no hay).
class MarcasDeJuego {
  final MarcaJuego? semana;
  final MarcaJuego? historico;

  const MarcasDeJuego({this.semana, this.historico});

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
      juegos[juego] ?? const MarcasDeJuego();

  /// El récord histórico en ese juego (0 si no hay).
  int record(Juego juego) => marcas(juego).historico?.puntos ?? 0;

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

/// Una fila del ranking público.
class FilaRanking {
  final int posicion;
  final String alias;
  final int puntos;
  final DateTime? fecha;

  const FilaRanking({
    required this.posicion,
    required this.alias,
    required this.puntos,
    this.fecha,
  });

  factory FilaRanking.fromJson(Map<String, dynamic> json) => FilaRanking(
    posicion: (json['posicion'] as num).toInt(),
    alias: '${json['alias']}',
    puntos: (json['puntos'] as num).toInt(),
    fecha: DateTime.tryParse('${json['fecha'] ?? ''}'),
  );
}

/// Lo que devuelve guardar una puntuación (POST /api/app/juego/puntuacion).
class ResultadoPuntuacion {
  final bool recordSemana;
  final bool recordHistorico;
  final int? posicionSemana;
  final int? posicionHistorico;

  const ResultadoPuntuacion({
    this.recordSemana = false,
    this.recordHistorico = false,
    this.posicionSemana,
    this.posicionHistorico,
  });

  bool get esRecord => recordSemana || recordHistorico;

  factory ResultadoPuntuacion.fromJson(Map<String, dynamic> json) =>
      ResultadoPuntuacion(
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
  final int mejorPenaltis;
  final int mejorToques;
  final int mejorAtrapa;

  const PerfilJuegoAdmin({
    required this.usuarioId,
    this.alias,
    this.equipacion = Equipacion.azul,
    this.oculto = false,
    this.nombre = '',
    this.email = '',
    this.partidas = 0,
    this.mejorPenaltis = 0,
    this.mejorToques = 0,
    this.mejorAtrapa = 0,
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
        mejorPenaltis: (json['mejorPenaltis'] as num?)?.toInt() ?? 0,
        mejorToques: (json['mejorToques'] as num?)?.toInt() ?? 0,
        mejorAtrapa: (json['mejorAtrapa'] as num?)?.toInt() ?? 0,
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
