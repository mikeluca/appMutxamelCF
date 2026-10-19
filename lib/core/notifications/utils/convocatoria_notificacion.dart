import '../../../features/auth/services/auth_manager.dart';

/// Título que pone el backend a la comunicación privada de una convocatoria
/// nueva o modificada (ConvocatoriaServiceImpl.generarNotificaciones). Es lo
/// único que la distingue de cualquier otro mensaje del entrenador.
const String tituloNuevaConvocatoria = 'Nueva convocatoria';

/// true si tocar esta notificación debe abrir "Mis convocatorias": es el aviso
/// de una convocatoria y el usuario es JUGADOR o FAMILIAR (los únicos que la
/// responden). Para el resto se mantiene el comportamiento de siempre.
bool abreMisConvocatorias(String? titulo) {
  if (titulo?.trim() != tituloNuevaConvocatoria) {
    return false;
  }

  final usuario = AuthManager.usuarioActual;

  return usuario?.tieneRol('JUGADOR') == true ||
      usuario?.tieneRol('FAMILIAR') == true;
}
