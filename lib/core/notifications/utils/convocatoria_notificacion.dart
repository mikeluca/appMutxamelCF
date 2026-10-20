import '../../../features/auth/services/auth_manager.dart';

/// Valor de data["tipo"] con el que el backend marca el push de una
/// convocatoria nueva o modificada (ConvocatoriaServiceImpl). La app navega
/// según este tipo, no según el título.
const String tipoPushConvocatoria = 'CONVOCATORIA';

/// Valor de data["tipo"] del push que avisa al entrenador de que un convocado
/// ha justificado su ausencia: lleva a editar esa convocatoria.
const String tipoPushConvocatoriaEditar = 'CONVOCATORIA_EDITAR';

/// Valor de data["tipo"] del push que recuerda al entrenador pasar lista: lleva
/// a la asistencia de ese entrenamiento ("entrenamientoId").
const String tipoPushPasarLista = 'PASAR_LISTA';

/// Valor de data["tipo"] del push que avisa a ADMIN_APP de un mensaje reportado:
/// lleva a la pantalla de Moderación ("reporteId" y "referenciaId" son el id del
/// reporte, no de una comunicación).
const String tipoPushReporte = 'REPORTE';

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
      tipo == tipoPushConvocatoriaEditar ||
      tipo == tipoPushPasarLista ||
      tipo == tipoPushReporte ||
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
  if (tipo == tipoPushReporte) {
    // Solo un administrador puede abrir la cola de moderación.
    return AuthManager.usuarioActual?.tieneRol('ADMIN_APP') == true
        ? const AbrirModeracion()
        : null;
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
      tipo == tipoPushConvocatoria || titulo?.trim() == tituloNuevaConvocatoria;

  if (!esConvocatoria) {
    return null;
  }

  final usuario = AuthManager.usuarioActual;

  final veSuCalendario =
      usuario?.tieneRol('JUGADOR') == true ||
      usuario?.tieneRol('FAMILIAR') == true;

  return veSuCalendario
      ? AbrirCalendario(diaDeFechaPartido(datos['fechaPartido']?.toString()))
      : null;
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
    EditarConvocatoria(:final convocatoriaId) =>
      'CONVOCATORIA_EDITAR:$convocatoriaId',
    PasarLista(:final entrenamientoId) => 'PASAR_LISTA:$entrenamientoId',
    AbrirModeracion() => 'REPORTE',
  };
}

/// Lo contrario de [payloadDeDestino]; null si el payload no es de una
/// convocatoria.
DestinoConvocatoria? destinoDePayload(String payload) {
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
