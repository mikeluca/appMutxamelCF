import '../../network/api_client.dart';
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

    final request = DispositivoAppRequest(
      tokenFcm: tokenFcm,
      plataforma: plataforma,
    );

    await ApiClient.post(
      '/app/dispositivos',
      autenticado: true,
      body: request.toJson(),
    );
  }
}
