import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/services/auth_session.dart';
import '../config/app_preferences.dart';

/// Lo que se usa de Firebase Crashlytics. Los tests lo sustituyen por uno falso.
abstract class PasarelaInformes {
  Future<void> activarRecogida(bool activada);

  Future<void> registrarErrorDeFlutter(FlutterErrorDetails detalles);

  Future<void> registrarError(Object error, StackTrace pila);

  Future<void> poner(String clave, String valor);
}

class _PasarelaCrashlytics implements PasarelaInformes {
  FirebaseCrashlytics get _c => FirebaseCrashlytics.instance;

  @override
  Future<void> activarRecogida(bool activada) =>
      _c.setCrashlyticsCollectionEnabled(activada);

  @override
  Future<void> registrarErrorDeFlutter(FlutterErrorDetails detalles) =>
      _c.recordFlutterFatalError(detalles);

  @override
  Future<void> registrarError(Object error, StackTrace pila) =>
      _c.recordError(error, pila, fatal: true);

  @override
  Future<void> poner(String clave, String valor) =>
      _c.setCustomKey(clave, valor);
}

/// Informes de errores con Firebase Crashlytics.
///
/// - En debug no se envía nada (la recogida se desactiva).
/// - El interruptor "Enviar informes de errores" de Ajustes (activado por defecto, en [AppPreferences]) la activa y
///   desactiva; se aplica al arrancar.
/// - Nunca se envían datos personales: no se usa ningún identificador de usuario y las únicas claves son la versión de la
///   aplicación, el idioma y si hay sesión (sí/no).
class InformesErrores {
  InformesErrores._();

  /// Las únicas claves que se envían (los tests comprueban que no hay otras).
  static const String claveVersion = 'app_version';
  static const String claveIdioma = 'idioma';
  static const String claveSesion = 'sesion';

  @visibleForTesting
  static PasarelaInformes pasarela = _PasarelaCrashlytics();

  /// true en debug: sin envío. Los tests lo cambian.
  @visibleForTesting
  static bool Function() esDebug = () => kDebugMode;

  @visibleForTesting
  static Future<String> Function() leerVersion = () async {
    final info = await PackageInfo.fromPlatform();

    return '${info.version}+${info.buildNumber}';
  };

  @visibleForTesting
  static Future<bool> Function() haySesion = () async {
    final token = await AuthSession.obtenerToken();

    return token != null && token.isNotEmpty;
  };

  /// Si la recogida está activada ahora (para los tests y Ajustes).
  static bool recogidaActivada = false;

  /// Al arrancar: aplica la preferencia, engancha los manejadores de errores y deja las claves. Nunca lanza.
  static Future<void> iniciar() async {
    try {
      await aplicar(await AppPreferences.obtenerInformesErrores());

      FlutterError.onError = (detalles) {
        // Se sigue enseñando en la consola en debug, como siempre.
        FlutterError.presentError(detalles);

        if (recogidaActivada) {
          pasarela.registrarErrorDeFlutter(detalles);
        }
      };

      PlatformDispatcher.instance.onError = (error, pila) {
        if (recogidaActivada) {
          pasarela.registrarError(error, pila);
        }

        return true;
      };

      await actualizarClaves();
    } catch (e) {
      debugPrint('NO SE PUDO INICIAR LOS INFORMES DE ERRORES: $e');
    }
  }

  /// Activa o desactiva la recogida según la preferencia [activado]; en debug nunca se activa.
  static Future<void> aplicar(bool activado) async {
    recogidaActivada = activado && !esDebug();

    await pasarela.activarRecogida(recogidaActivada);
  }

  /// El interruptor de Ajustes: guarda la preferencia y la aplica.
  static Future<void> cambiarPreferencia(bool activado) async {
    await AppPreferences.guardarInformesErrores(activado);

    await aplicar(activado);
  }

  /// Versión, idioma y si hay sesión (sí/no): nada más.
  static Future<void> actualizarClaves() async {
    try {
      await pasarela.poner(claveVersion, await leerVersion());
      await pasarela.poner(claveIdioma, await AppPreferences.obtenerIdioma());
      await pasarela.poner(claveSesion, await haySesion() ? 'si' : 'no');
    } catch (e) {
      debugPrint('NO SE PUDIERON PONER LAS CLAVES DE LOS INFORMES: $e');
    }
  }
}
