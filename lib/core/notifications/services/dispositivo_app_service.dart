import '../../network/api_client.dart';
import '../../version/control_version.dart';
import '../../../features/auth/services/auth_session.dart';
import '../models/dispositivo_app_request.dart';

class DispositivoAppService {
  DispositivoAppService._();

  static Future<void> registrar({
    required String tokenFcm,
    required String plataforma,
  }) async {
    final tokenSesion = await AuthSession.obtenerToken();

    // No hay sesión iniciada.
    if (tokenSesion == null || tokenSesion.isEmpty) {
      return;
    }

    // El backend guarda la versión instalada con cada registro o renovación
    // del token.
    final request = DispositivoAppRequest(
      tokenFcm: tokenFcm,
      plataforma: plataforma,
      versionApp: await ControlVersion.versionInstalada(),
    );

    await ApiClient.post(
      '/app/dispositivos',
      autenticado: true,
      body: request.toJson(),
    );
  }

  /// SEC-07: desregistra el token FCM de este dispositivo. Debe llamarse
  /// antes de borrar la sesión (el endpoint requiere Bearer token).
  static Future<void> desactivar(String tokenFcm) async {
    final tokenSesion = await AuthSession.obtenerToken();

    if (tokenSesion == null || tokenSesion.isEmpty) {
      return;
    }

    final tokenCodificado = Uri.encodeQueryComponent(tokenFcm);

    await ApiClient.delete(
      '/app/dispositivos?tokenFcm=$tokenCodificado',
      autenticado: true,
    );
  }
}
