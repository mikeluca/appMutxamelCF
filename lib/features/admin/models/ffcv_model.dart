/// Lo que devuelve el backend al subir los datos de la FFCV (solo ADMIN_APP). Ver docs/api-app-admin-ffcv.md del
/// backend. Las vistas previas guardan el JSON tal cual llegó: al confirmar los partidos se manda de vuelta igual.
library;

DateTime? _fecha(Object? valor) {
  if (valor is! String || valor.length < 10) return null;

  return DateTime.tryParse(valor.substring(0, 10));
}

int? _entero(Object? valor) => (valor as num?)?.toInt();

List<T> _lista<T>(Object? json, T Function(Map<String, dynamic>) crear) =>
    (json as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(crear)
        .toList();

List<String> _textos(Object? json) =>
    (json as List<dynamic>? ?? const []).map((e) => e.toString()).toList();

// ---------------------------------------------------------------------------
// Partidos (LstPartidos.csv)
// ---------------------------------------------------------------------------

/// Qué pasaría con una fila del archivo al confirmar.
enum EstadoFilaFfcv {
  nuevo('NUEVO'),
  actualizado('ACTUALIZADO'),
  sinCambios('SIN_CAMBIOS'),
  sinEquipo('SIN_EQUIPO'),
  conflictoManual('CONFLICTO_MANUAL');

  final String codigo;

  const EstadoFilaFfcv(this.codigo);

  static EstadoFilaFfcv desdeTexto(String? texto) => EstadoFilaFfcv.values
      .firstWhere((e) => e.codigo == texto, orElse: () => EstadoFilaFfcv.nuevo);
}

class FilaFfcvModel {
  final DateTime? fecha;
  final String competicion;
  final String? letra;
  final bool local;
  final String rival;
  final String? campo;
  final String? hora;
  final int? jornada;
  final EstadoFilaFfcv estado;
  final int? equipoId;
  final String? equipoNombre;
  final List<String> cambios;

  const FilaFfcvModel({
    this.fecha,
    this.competicion = '',
    this.letra,
    this.local = true,
    this.rival = '',
    this.campo,
    this.hora,
    this.jornada,
    required this.estado,
    this.equipoId,
    this.equipoNombre,
    this.cambios = const [],
  });

  /// El grupo de la FFCV: las filas con la misma competición y letra comparten el equipo que se les asigne.
  String get claveGrupo => '$competicion|${letra ?? ''}';

  /// El nombre con el que se enseña el equipo: el del club o, si no se conoce, la competición y la letra.
  String get equipoVisible {
    final nombre = equipoNombre ?? '';

    if (nombre.isNotEmpty) return nombre;

    return letra == null || letra!.isEmpty
        ? competicion
        : '$competicion "$letra"';
  }

  factory FilaFfcvModel.fromJson(Map<String, dynamic> json) {
    return FilaFfcvModel(
      fecha: _fecha(json['fecha']),
      competicion: json['competicion']?.toString() ?? '',
      letra: json['letra']?.toString(),
      local: json['local'] as bool? ?? true,
      rival: json['rival']?.toString() ?? '',
      campo: json['campo']?.toString(),
      hora: json['hora']?.toString(),
      jornada: _entero(json['jornada']),
      estado: EstadoFilaFfcv.desdeTexto(json['estado']?.toString()),
      equipoId: _entero(json['equipoId']),
      equipoNombre: json['equipoNombre']?.toString(),
      cambios: _textos(json['cambios']),
    );
  }
}

/// Un partido que estaba guardado y ya no aparece en la FFCV (¿aplazado?). No se toca automáticamente.
class DesaparecidoFfcvModel {
  final String equipoNombre;
  final DateTime? fecha;
  final String rival;
  final String? hora;
  final bool tieneConvocatoria;

  const DesaparecidoFfcvModel({
    this.equipoNombre = '',
    this.fecha,
    this.rival = '',
    this.hora,
    this.tieneConvocatoria = false,
  });

  factory DesaparecidoFfcvModel.fromJson(Map<String, dynamic> json) {
    return DesaparecidoFfcvModel(
      equipoNombre: json['equipoNombre']?.toString() ?? '',
      fecha: _fecha(json['fecha']),
      rival: json['rival']?.toString() ?? '',
      hora: json['hora']?.toString(),
      tieneConvocatoria: json['tieneConvocatoria'] as bool? ?? false,
    );
  }
}

class ErrorLineaFfcvModel {
  final int linea;
  final String mensaje;

  const ErrorLineaFfcvModel({this.linea = 0, this.mensaje = ''});

  factory ErrorLineaFfcvModel.fromJson(Map<String, dynamic> json) {
    return ErrorLineaFfcvModel(
      linea: _entero(json['linea']) ?? 0,
      mensaje: json['mensaje']?.toString() ?? '',
    );
  }
}

/// POST /app/admin/ffcv/partidos/previsualizar.
class PrevisualizacionPartidosModel {
  final DateTime? desde;
  final DateTime? hasta;
  final List<FilaFfcvModel> filas;
  final List<String> descansan;
  final List<DesaparecidoFfcvModel> desaparecidos;
  final List<ErrorLineaFfcvModel> errores;

  /// El JSON recibido, para devolverlo tal cual al confirmar.
  final Map<String, dynamic> json;

  const PrevisualizacionPartidosModel({
    this.desde,
    this.hasta,
    this.filas = const [],
    this.descansan = const [],
    this.desaparecidos = const [],
    this.errores = const [],
    this.json = const {},
  });

  int cuantas(EstadoFilaFfcv estado) =>
      filas.where((f) => f.estado == estado).length;

  /// Las filas que, tras confirmar, dejan un partido creado o cambiado (las de SIN_EQUIPO solo si se les asigna uno).
  int partidosAImportar({Set<String> gruposAsignados = const {}}) =>
      cuantas(EstadoFilaFfcv.nuevo) +
      cuantas(EstadoFilaFfcv.actualizado) +
      filas
          .where(
            (f) =>
                f.estado == EstadoFilaFfcv.sinEquipo &&
                gruposAsignados.contains(f.claveGrupo),
          )
          .length;

  /// Las competiciones (con letra) de las filas sin equipo: lo que hay que asignar a un equipo del club.
  List<FilaFfcvModel> get gruposSinEquipo {
    final vistos = <String>{};

    return filas
        .where(
          (f) =>
              f.estado == EstadoFilaFfcv.sinEquipo && vistos.add(f.claveGrupo),
        )
        .toList();
  }

  factory PrevisualizacionPartidosModel.fromJson(Map<String, dynamic> json) {
    return PrevisualizacionPartidosModel(
      desde: _fecha(json['desde']),
      hasta: _fecha(json['hasta']),
      filas: _lista(json['filas'], FilaFfcvModel.fromJson),
      descansan: (json['descansan'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((d) => d['equipoNombre']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
      desaparecidos: _lista(
        json['desaparecidos'],
        DesaparecidoFfcvModel.fromJson,
      ),
      errores: _lista(json['errores'], ErrorLineaFfcvModel.fromJson),
      json: json,
    );
  }
}

/// POST /app/admin/ffcv/partidos/confirmar.
class ResultadoPartidosModel {
  final int creados;
  final int actualizados;
  final int sinCambios;
  final int conflictosManuales;
  final int sinEquipo;
  final int descansosCreados;
  final int descansosEliminados;
  final List<String> avisos;

  const ResultadoPartidosModel({
    this.creados = 0,
    this.actualizados = 0,
    this.sinCambios = 0,
    this.conflictosManuales = 0,
    this.sinEquipo = 0,
    this.descansosCreados = 0,
    this.descansosEliminados = 0,
    this.avisos = const [],
  });

  factory ResultadoPartidosModel.fromJson(Map<String, dynamic> json) {
    return ResultadoPartidosModel(
      creados: _entero(json['creados']) ?? 0,
      actualizados: _entero(json['actualizados']) ?? 0,
      sinCambios: _entero(json['sinCambios']) ?? 0,
      conflictosManuales: _entero(json['conflictosManuales']) ?? 0,
      sinEquipo: _entero(json['sinEquipo']) ?? 0,
      descansosCreados: _entero(json['descansosCreados']) ?? 0,
      descansosEliminados: _entero(json['descansosEliminados']) ?? 0,
      avisos: _textos(json['avisos']),
    );
  }
}

// ---------------------------------------------------------------------------
// Clasificaciones (ListadoClasificaciones.xlsx)
// ---------------------------------------------------------------------------

/// La clasificación de un grupo del archivo y qué cambiaría en un equipo del club.
class EquipoClasificacionPreviaModel {
  final int? equipoId;
  final String equipoNombre;
  final bool encontrado;
  final String? motivo;
  final String competicion;
  final int? jornada;
  final int? jornadaGuardada;
  final int? posicion;
  final int? puntos;
  final int? pj;

  /// El archivo es de una jornada anterior a la guardada (¿archivo antiguo?).
  final bool antiguo;
  final bool importable;
  final bool marcadoPorDefecto;
  final bool cambia;
  final List<String> cambios;

  const EquipoClasificacionPreviaModel({
    this.equipoId,
    this.equipoNombre = '',
    this.encontrado = true,
    this.motivo,
    this.competicion = '',
    this.jornada,
    this.jornadaGuardada,
    this.posicion,
    this.puntos,
    this.pj,
    this.antiguo = false,
    this.importable = true,
    this.marcadoPorDefecto = true,
    this.cambia = true,
    this.cambios = const [],
  });

  factory EquipoClasificacionPreviaModel.fromJson(Map<String, dynamic> json) {
    return EquipoClasificacionPreviaModel(
      equipoId: _entero(json['equipoId']),
      equipoNombre: json['equipoNombre']?.toString() ?? '',
      encontrado: json['encontrado'] as bool? ?? true,
      motivo: json['motivo']?.toString(),
      competicion: json['competicion']?.toString() ?? '',
      jornada: _entero(json['jornada']),
      jornadaGuardada: _entero(json['jornadaGuardada']),
      posicion: _entero(json['posicion']),
      puntos: _entero(json['puntos']),
      pj: _entero(json['pj']),
      antiguo: json['antiguo'] as bool? ?? false,
      importable: json['importable'] as bool? ?? true,
      marcadoPorDefecto: json['marcadoPorDefecto'] as bool? ?? true,
      cambia: json['cambia'] as bool? ?? true,
      cambios: _textos(json['cambios']),
    );
  }
}

/// Filas del Mutxamel en el archivo que ninguna relación de Equipos FFCV reconoce (no se importan).
class ClasificacionSinMapeoModel {
  final String competicion;
  final String? letra;
  final String equipo;

  const ClasificacionSinMapeoModel({
    this.competicion = '',
    this.letra,
    this.equipo = '',
  });

  factory ClasificacionSinMapeoModel.fromJson(Map<String, dynamic> json) {
    return ClasificacionSinMapeoModel(
      competicion: json['competicion']?.toString() ?? '',
      letra: json['letra']?.toString(),
      equipo: json['equipo']?.toString() ?? '',
    );
  }
}

/// POST /app/admin/ffcv/clasificaciones/previsualizar.
class PrevisualizacionClasificacionesModel {
  final int filasLeidas;
  final int competiciones;
  final List<EquipoClasificacionPreviaModel> equipos;
  final List<ClasificacionSinMapeoModel> sinMapeo;
  final List<ErrorLineaFfcvModel> errores;

  const PrevisualizacionClasificacionesModel({
    this.filasLeidas = 0,
    this.competiciones = 0,
    this.equipos = const [],
    this.sinMapeo = const [],
    this.errores = const [],
  });

  factory PrevisualizacionClasificacionesModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PrevisualizacionClasificacionesModel(
      filasLeidas: _entero(json['filasLeidas']) ?? 0,
      competiciones: _entero(json['competiciones']) ?? 0,
      equipos: _lista(json['equipos'], EquipoClasificacionPreviaModel.fromJson),
      sinMapeo: _lista(json['sinMapeo'], ClasificacionSinMapeoModel.fromJson),
      errores: _lista(json['errores'], ErrorLineaFfcvModel.fromJson),
    );
  }
}

/// POST /app/admin/ffcv/clasificaciones/confirmar.
class ResultadoClasificacionesModel {
  final int importados;
  final int filas;
  final List<String> equipos;
  final List<String> avisos;

  const ResultadoClasificacionesModel({
    this.importados = 0,
    this.filas = 0,
    this.equipos = const [],
    this.avisos = const [],
  });

  factory ResultadoClasificacionesModel.fromJson(Map<String, dynamic> json) {
    return ResultadoClasificacionesModel(
      importados: _entero(json['importados']) ?? 0,
      filas: _entero(json['filas']) ?? 0,
      equipos: _textos(json['equipos']),
      avisos: _textos(json['avisos']),
    );
  }
}
