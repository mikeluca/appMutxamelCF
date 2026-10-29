import '../../../features/auth/services/auth_manager.dart';

/// Valor de data["tipo"] con el que el backend marca el push de una
/// convocatoria nueva o modificada (ConvocatoriaServiceImpl). La app navega
/// según este tipo, no según el título.
const String tipoPushConvocatoria = 'CONVOCATORIA';

/// Valor de data["tipo"] del push que avisa de que el entrenador ha anulado una
/// convocatoria (ya no existe, así que no lleva convocatoriaId): lleva al
/// calendario, en el día del partido.
const String tipoPushConvocatoriaAnulada = 'CONVOCATORIA_ANULADA';

/// Valor de data["tipo"] del push que avisa al entrenador de que un convocado
/// ha justificado su ausencia: lleva a editar esa convocatoria.
const String tipoPushConvocatoriaEditar = 'CONVOCATORIA_EDITAR';

/// Valor de data["tipo"] del push con el que coordinación recuerda al entrenador publicar la
/// convocatoria de un partido: lleva al formulario de convocatoria con ese partido
/// preseleccionado ("partidoId", "equipoId" y "equipo" vienen en el aviso).
const String tipoPushConvocatoriaPendiente = 'CONVOCATORIA_PENDIENTE';

/// Valor de data["tipo"] del push con el que coordinación recuerda al entrenador meter el
/// resultado de un partido: lleva al formulario de resultado de ese partido.
const String tipoPushResultadoPendiente = 'RESULTADO_PENDIENTE';

/// Valor de data["tipo"] del push que recuerda al entrenador pasar lista: lleva
/// a la asistencia de ese entrenamiento ("entrenamientoId").
const String tipoPushPasarLista = 'PASAR_LISTA';

/// Valor de data["tipo"] del push que avisa a ADMIN_APP de un mensaje reportado:
/// lleva a la pantalla de Moderación ("reporteId" y "referenciaId" son el id del
/// reporte, no de una comunicación).
const String tipoPushReporte = 'REPORTE';

/// Valor de data["tipo"] del push a las familias que pregunta si un jugador seguirá la temporada
/// siguiente (data["pantalla"] == "CONTINUIDAD"): lleva a la pantalla de continuidad.
const String tipoPushContinuidad = 'CONTINUIDAD';

/// Valor de data["tipo"] del push a los coordinadores cuando una familia responde NO_SIGUE o DUDA
/// (data["pantalla"] == "CONTINUIDAD_COORDINADOR"). La revisión se hace en el panel web, así que la app
/// solo abre la bandeja de notificaciones.
const String tipoPushContinuidadRespuesta = 'CONTINUIDAD_RESPUESTA';

/// Título que pone el backend a la comunicación privada de una convocatoria
/// nueva o modificada. Solo sirve de reserva para los pushes y avisos enviados
/// antes de que existiera el tipo (y para la lista de notificaciones, cuyas
/// filas no guardan el data del push).
const String tituloNuevaConvocatoria = 'Nueva convocatoria';

/// true si el aviso tiene un destino propio (una convocatoria de cualquier
/// tipo o pasar lista) y por tanto, al abrir la app en frío, espera a que haya
/// sesión y home: por su data["tipo"] o, como reserva para los pushes antiguos
/// de convocatoria, por el título.
bool esAvisoDeConvocatoria({String? tipo, String? titulo}) {
  return tipo == tipoPushConvocatoria ||
      tipo == tipoPushConvocatoriaAnulada ||
      tipo == tipoPushConvocatoriaPendiente ||
      tipo == tipoPushResultadoPendiente ||
      tipo == tipoPushConvocatoriaEditar ||
      tipo == tipoPushPasarLista ||
      tipo == tipoPushReporte ||
      tipo == tipoPushContinuidad ||
      tipo == tipoPushContinuidadRespuesta ||
      titulo?.trim() == tituloNuevaConvocatoria;
}

/// A dónde lleva tocar el aviso de una convocatoria.
sealed class DestinoConvocatoria {
  const DestinoConvocatoria();
}

/// JUGADOR/FAMILIAR: el calendario, en el día del partido ([dia]; null si el
/// aviso no lo trae, y entonces se abre en hoy).
class AbrirCalendario extends DestinoConvocatoria {
  final DateTime? dia;

  const AbrirCalendario([this.dia]);

  @override
  bool operator ==(Object other) =>
      other is AbrirCalendario && other.dia == dia;

  @override
  int get hashCode => dia.hashCode;
}

/// JUGADOR/FAMILIAR: la pantalla "Convocatoria" del partido [partidoId] cuando el
/// usuario tiene un solo jugador en esa convocatoria; con varios (o ninguno),
/// el calendario en [dia]. Quien lo abre decide cuál de los dos según el perfil.
class AbrirDetalleConvocatoria extends DestinoConvocatoria {
  final int partidoId;
  final DateTime? dia;

  const AbrirDetalleConvocatoria(this.partidoId, [this.dia]);

  @override
  bool operator ==(Object other) =>
      other is AbrirDetalleConvocatoria &&
      other.partidoId == partidoId &&
      other.dia == dia;

  @override
  int get hashCode => Object.hash(partidoId, dia);
}

/// Entrenador: el formulario de convocatoria con el partido [partidoId] (del equipo
/// [equipoId], de nombre [equipo]) preseleccionado.
class AbrirFormularioConvocatoria extends DestinoConvocatoria {
  final int partidoId;
  final int equipoId;
  final String equipo;

  const AbrirFormularioConvocatoria({
    required this.partidoId,
    required this.equipoId,
    required this.equipo,
  });

  @override
  bool operator ==(Object other) =>
      other is AbrirFormularioConvocatoria &&
      other.partidoId == partidoId &&
      other.equipoId == equipoId &&
      other.equipo == equipo;

  @override
  int get hashCode => Object.hash(partidoId, equipoId, equipo);
}

/// Entrenador: el formulario de resultado del partido [partidoId], con los datos del
/// partido que traía el aviso.
class AbrirFormularioResultado extends DestinoConvocatoria {
  final int partidoId;
  final int equipoId;
  final String equipo;
  final String rival;
  final DateTime? dia;
  final String? hora;
  final bool local;

  const AbrirFormularioResultado({
    required this.partidoId,
    required this.equipoId,
    required this.equipo,
    required this.rival,
    this.dia,
    this.hora,
    this.local = true,
  });

  @override
  bool operator ==(Object other) =>
      other is AbrirFormularioResultado &&
      other.partidoId == partidoId &&
      other.equipoId == equipoId &&
      other.equipo == equipo &&
      other.rival == rival &&
      other.dia == dia &&
      other.hora == hora &&
      other.local == local;

  @override
  int get hashCode =>
      Object.hash(partidoId, equipoId, equipo, rival, dia, hora, local);
}

/// Entrenador: la edición de esa convocatoria.
class EditarConvocatoria extends DestinoConvocatoria {
  final int convocatoriaId;

  const EditarConvocatoria(this.convocatoriaId);

  @override
  bool operator ==(Object other) =>
      other is EditarConvocatoria && other.convocatoriaId == convocatoriaId;

  @override
  int get hashCode => convocatoriaId.hashCode;
}

/// Entrenador: la asistencia de ese entrenamiento, para pasar lista.
class PasarLista extends DestinoConvocatoria {
  final int entrenamientoId;

  const PasarLista(this.entrenamientoId);

  @override
  bool operator ==(Object other) =>
      other is PasarLista && other.entrenamientoId == entrenamientoId;

  @override
  int get hashCode => entrenamientoId.hashCode;
}

/// ADMIN_APP: la pantalla de Moderación.
class AbrirModeracion extends DestinoConvocatoria {
  const AbrirModeracion();

  @override
  bool operator ==(Object other) => other is AbrirModeracion;

  @override
  int get hashCode => 'AbrirModeracion'.hashCode;
}

/// FAMILIA: la pantalla de continuidad ("¿Seguirá X en la temporada Y?").
class AbrirContinuidad extends DestinoConvocatoria {
  const AbrirContinuidad();

  @override
  bool operator ==(Object other) => other is AbrirContinuidad;

  @override
  int get hashCode => 'AbrirContinuidad'.hashCode;
}

/// COORDINADOR: la bandeja de notificaciones (no hay pantalla propia: la revisión de continuidad
/// se hace en el panel web).
class AbrirBandeja extends DestinoConvocatoria {
  const AbrirBandeja();

  @override
  bool operator ==(Object other) => other is AbrirBandeja;

  @override
  int get hashCode => 'AbrirBandeja'.hashCode;
}

/// El destino del aviso de una convocatoria o de pasar lista, o null si no lo
/// es (se mantiene el comportamiento de siempre).
///
/// - [tipo] "PASAR_LISTA" con un "entrenamientoId" válido: la asistencia de
///   ese entrenamiento.
/// - [tipo] "CONVOCATORIA_EDITAR" con un "convocatoriaId" válido: editar esa
///   convocatoria.
/// - [tipo] "CONVOCATORIA" o, como reserva para los pushes antiguos (que
///   llevan el tipo "COMUNICACION"), el [titulo] "Nueva convocatoria": el
///   calendario, solo para JUGADOR y FAMILIAR (los demás roles no ven sus
///   propios partidos ahí). El día sale de "fechaPartido" (yyyy-MM-dd).
DestinoConvocatoria? destinoDeAvisoConvocatoria({
  String? tipo,
  String? titulo,
  Map<String, dynamic> datos = const {},
}) {
  if (tipo == tipoPushContinuidad) {
    return const AbrirContinuidad();
  }

  if (tipo == tipoPushContinuidadRespuesta) {
    return const AbrirBandeja();
  }

  if (tipo == tipoPushReporte) {
    // Solo un administrador puede abrir la cola de moderación.
    return AuthManager.usuarioActual?.tieneRol('ADMIN_APP') == true
        ? const AbrirModeracion()
        : null;
  }

  if (tipo == tipoPushConvocatoriaPendiente ||
      tipo == tipoPushResultadoPendiente) {
    final partidoId = int.tryParse(datos['partidoId']?.toString() ?? '');
    final equipoId = int.tryParse(datos['equipoId']?.toString() ?? '');

    // Sin el partido o su equipo no hay formulario que abrir: el aviso se abre como
    // una comunicación más.
    if (partidoId == null ||
        partidoId <= 0 ||
        equipoId == null ||
        equipoId <= 0) {
      return null;
    }

    final equipo = datos['equipo']?.toString() ?? '';

    if (tipo == tipoPushConvocatoriaPendiente) {
      return AbrirFormularioConvocatoria(
        partidoId: partidoId,
        equipoId: equipoId,
        equipo: equipo,
      );
    }

    return AbrirFormularioResultado(
      partidoId: partidoId,
      equipoId: equipoId,
      equipo: equipo,
      rival: datos['rival']?.toString() ?? '',
      dia: diaDeFechaPartido(datos['fecha']?.toString()),
      hora: datos['hora']?.toString(),
      local: datos['local']?.toString() != 'false',
    );
  }

  if (tipo == tipoPushPasarLista) {
    final id = int.tryParse(datos['entrenamientoId']?.toString() ?? '');

    return id != null && id > 0 ? PasarLista(id) : null;
  }

  if (tipo == tipoPushConvocatoriaEditar) {
    final id = int.tryParse(datos['convocatoriaId']?.toString() ?? '');

    return id != null && id > 0 ? EditarConvocatoria(id) : null;
  }

  final esConvocatoria =
      tipo == tipoPushConvocatoria ||
      tipo == tipoPushConvocatoriaAnulada ||
      titulo?.trim() == tituloNuevaConvocatoria;

  if (!esConvocatoria) {
    return null;
  }

  final usuario = AuthManager.usuarioActual;

  final veSuCalendario =
      usuario?.tieneRol('JUGADOR') == true ||
      usuario?.tieneRol('FAMILIAR') == true;

  if (!veSuCalendario) {
    return null;
  }

  final dia = diaDeFechaPartido(datos['fechaPartido']?.toString());

  // Con el partido en el aviso se intenta abrir la pantalla "Convocatoria" (una
  // convocatoria anulada ya no tiene detalle: solo el calendario).
  final partidoId = int.tryParse(datos['partidoId']?.toString() ?? '');

  if (tipo == tipoPushConvocatoria && partidoId != null && partidoId > 0) {
    return AbrirDetalleConvocatoria(partidoId, dia);
  }

  return AbrirCalendario(dia);
}

/// "2026-10-24" (o con hora) -> ese día a las 00:00; null si no se puede leer.
DateTime? diaDeFechaPartido(String? texto) {
  final fecha = DateTime.tryParse(texto ?? '');

  return fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
}

/// Texto de la notificación local para abrir [destino] al tocarla.
String payloadDeDestino(DestinoConvocatoria destino) {
  return switch (destino) {
    AbrirCalendario(:final dia) =>
      dia == null
          ? 'CALENDARIO'
          : 'CALENDARIO:${dia.year.toString().padLeft(4, '0')}-'
                '${dia.month.toString().padLeft(2, '0')}-'
                '${dia.day.toString().padLeft(2, '0')}',
    AbrirDetalleConvocatoria(:final partidoId, :final dia) =>
      'CONVOCATORIA_PARTIDO:$partidoId:${dia == null ? '' : _diaTexto(dia)}',
    AbrirFormularioConvocatoria(
      :final partidoId,
      :final equipoId,
      :final equipo,
    ) =>
      'CONVOCATORIA_PENDIENTE:${_campos([partidoId, equipoId, equipo])}',
    AbrirFormularioResultado(
      :final partidoId,
      :final equipoId,
      :final equipo,
      :final rival,
      :final dia,
      :final hora,
      :final local,
    ) =>
      'RESULTADO_PENDIENTE:${_campos([partidoId, equipoId, equipo, rival, dia == null ? '' : _diaTexto(dia), hora ?? '', local])}',
    EditarConvocatoria(:final convocatoriaId) =>
      'CONVOCATORIA_EDITAR:$convocatoriaId',
    PasarLista(:final entrenamientoId) => 'PASAR_LISTA:$entrenamientoId',
    AbrirModeracion() => 'REPORTE',
    AbrirContinuidad() => 'CONTINUIDAD',
    AbrirBandeja() => 'CONTINUIDAD_RESPUESTA',
  };
}

/// Los campos de un payload, cada uno codificado y separados por "|".
String _campos(List<Object> valores) =>
    valores.map((v) => Uri.encodeComponent('$v')).join('|');

List<String> _leerCampos(String texto) =>
    texto.split('|').map(Uri.decodeComponent).toList();

String _diaTexto(DateTime dia) {
  return '${dia.year.toString().padLeft(4, '0')}-'
      '${dia.month.toString().padLeft(2, '0')}-'
      '${dia.day.toString().padLeft(2, '0')}';
}

/// Lo contrario de [payloadDeDestino]; null si el payload no es de una
/// convocatoria.
DestinoConvocatoria? destinoDePayload(String payload) {
  if (payload.startsWith('CONVOCATORIA_PENDIENTE:')) {
    final campos = _leerCampos(
      payload.substring('CONVOCATORIA_PENDIENTE:'.length),
    );
    final partidoId = int.tryParse(campos.elementAtOrNull(0) ?? '');
    final equipoId = int.tryParse(campos.elementAtOrNull(1) ?? '');

    if (partidoId == null || partidoId <= 0 || equipoId == null) {
      return null;
    }

    return AbrirFormularioConvocatoria(
      partidoId: partidoId,
      equipoId: equipoId,
      equipo: campos.elementAtOrNull(2) ?? '',
    );
  }

  if (payload.startsWith('RESULTADO_PENDIENTE:')) {
    final campos = _leerCampos(
      payload.substring('RESULTADO_PENDIENTE:'.length),
    );
    final partidoId = int.tryParse(campos.elementAtOrNull(0) ?? '');
    final equipoId = int.tryParse(campos.elementAtOrNull(1) ?? '');

    if (partidoId == null || partidoId <= 0 || equipoId == null) {
      return null;
    }

    final hora = campos.elementAtOrNull(5) ?? '';

    return AbrirFormularioResultado(
      partidoId: partidoId,
      equipoId: equipoId,
      equipo: campos.elementAtOrNull(2) ?? '',
      rival: campos.elementAtOrNull(3) ?? '',
      dia: diaDeFechaPartido(campos.elementAtOrNull(4)),
      hora: hora.isEmpty ? null : hora,
      local: campos.elementAtOrNull(6) != 'false',
    );
  }

  if (payload.startsWith('CONVOCATORIA_PARTIDO:')) {
    final partes = payload.substring('CONVOCATORIA_PARTIDO:'.length).split(':');
    final partidoId = int.tryParse(partes.first);

    if (partidoId == null || partidoId <= 0) {
      return null;
    }

    return AbrirDetalleConvocatoria(
      partidoId,
      partes.length > 1 ? diaDeFechaPartido(partes[1]) : null,
    );
  }

  if (payload == 'CALENDARIO') {
    return const AbrirCalendario();
  }

  if (payload.startsWith('CALENDARIO:')) {
    return AbrirCalendario(
      diaDeFechaPartido(payload.substring('CALENDARIO:'.length)),
    );
  }

  if (payload == 'REPORTE') {
    return const AbrirModeracion();
  }

  if (payload == 'CONTINUIDAD') {
    return const AbrirContinuidad();
  }

  if (payload == 'CONTINUIDAD_RESPUESTA') {
    return const AbrirBandeja();
  }

  if (payload.startsWith('PASAR_LISTA:')) {
    final id = int.tryParse(payload.substring('PASAR_LISTA:'.length));

    return id != null && id > 0 ? PasarLista(id) : null;
  }

  if (payload.startsWith('CONVOCATORIA_EDITAR:')) {
    final id = int.tryParse(payload.substring('CONVOCATORIA_EDITAR:'.length));

    return id != null && id > 0 ? EditarConvocatoria(id) : null;
  }

  return null;
}
