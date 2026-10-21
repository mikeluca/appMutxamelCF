import '../../l10n/gen/app_localizations.dart';
import '../network/api_client.dart';

/// El texto para un fallo de red o del servidor: un 403 es "No tienes permiso" (no
/// un problema de conexión); cualquier otra cosa, el error de conexión genérico.
String mensajeDeError(AppLocalizations t, Object? error) {
  if (error is ApiException && error.statusCode == 403) {
    return t.noPermission;
  }

  return t.connectionError;
}

/// Como [mensajeDeError], pero un 4xx distinto de 403 trae del servidor un mensaje
/// claro (reglas de negocio: ya resuelto, límite de reenvíos...) y se muestra tal cual.
String mensajeDeAccion(AppLocalizations t, Object? error) {
  if (error is ApiException) {
    final codigo = error.statusCode;

    if (codigo == 403) {
      return t.noPermission;
    }

    if (codigo != null &&
        codigo >= 400 &&
        codigo < 500 &&
        error.message.isNotEmpty) {
      return error.message;
    }
  }

  return t.connectionError;
}

/// Como [mensajeDeAccion], pero un 429 (demasiados intentos al recuperar la
/// contraseña) se traduce a una clave propia en vez del texto del servidor.
String mensajeDeRecuperacion(AppLocalizations t, Object? error) {
  if (error is ApiException && error.statusCode == 429) {
    return t.recoverTooManyAttempts;
  }

  return mensajeDeAccion(t, error);
}
