import '../../../features/auth/services/auth_manager.dart';

/// Valor de data["tipo"] con el que el backend marca el push de una
/// convocatoria nueva o modificada (ConvocatoriaServiceImpl). La app navega
/// según este tipo, no según el título.
const String tipoPushConvocatoria = 'CONVOCATORIA';

/// Título que pone el backend a la comunicación privada de una convocatoria
/// nueva o modificada. Solo sirve de reserva para los pushes y avisos enviados
/// antes de que existiera el tipo (y para la lista de notificaciones, cuyas
/// filas no guardan el data del push).
const String tituloNuevaConvocatoria = 'Nueva convocatoria';

/// true si tocar esta notificación debe abrir "Mis convocatorias": es el aviso
/// de una convocatoria y el usuario es JUGADOR o FAMILIAR (los únicos que la
/// responden). Para el resto se mantiene el comportamiento de siempre.
///
/// El aviso es de convocatoria si [tipo] es [tipoPushConvocatoria] o, como
/// reserva para los pushes antiguos (que llevan el tipo "COMUNICACION"), si el
/// [titulo] es [tituloNuevaConvocatoria].
bool abreMisConvocatorias({String? tipo, String? titulo}) {
  final esConvocatoria =
      tipo == tipoPushConvocatoria || titulo?.trim() == tituloNuevaConvocatoria;

  if (!esConvocatoria) {
    return false;
  }

  final usuario = AuthManager.usuarioActual;

  return usuario?.tieneRol('JUGADOR') == true ||
      usuario?.tieneRol('FAMILIAR') == true;
}
