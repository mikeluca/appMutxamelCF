import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../features/auth/services/notificacion_service.dart';

import 'dispositivo_app_service.dart';
import 'local_notification_service.dart';

import '../../../core/navigation/app_navigator.dart';

class PushNotificationService {
  // FL-04: se registraba 'ANDROID' también en iOS.
  static String get _plataformaActual => Platform.isIOS ? 'IOS' : 'ANDROID';
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static RemoteMessage? _notificacionInicial;

  // Topics de FCM para notificaciones "anónimas" (sin sesión
  // iniciada, sin cuenta): la suscripción es 100% cliente, vía el
  // propio SDK de Firebase, sin llamar a la API. Los nombres deben
  // coincidir exactamente con lo que publica el backend.
  static const String topicNoticias = 'noticias';
  static const String topicResultados = 'resultados';

  // FL-05: tipos de "tipo" que puede enviar el backend en el canal
  // personal (ver FcmPushServiceImpl/PartidoEnVivoServiceImpl). Solo
  // 'COMUNICACION' abre una notificación local o hace deep-link al
  // tocarla; 'RESULTADO' se apoya en la notificación de sistema que
  // FCM muestra por su cuenta con el título/cuerpo del payload. Se
  // nombran aquí para no repetir el string mágico y para poder
  // distinguir un tipo no reconocido de uno simplemente no manejado.
  static const String _tipoComunicacion = 'COMUNICACION';
  static const String _tipoResultado = 'RESULTADO';

  static Future<void> suscribirATopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  static Future<void> desuscribirDeTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  /// Se llama al iniciar sesión: quien tiene cuenta recibe los
  /// avisos de resultados por el canal personal existente (ver
  /// PartidoEnVivoServiceImpl.difundirATodos en el backend), así que
  /// hay que desuscribirlo de los topics anónimos para que no le
  /// lleguen duplicados.
  static Future<void> desuscribirDeTopicsAnonimos() async {
    try {
      await desuscribirDeTopic(topicNoticias);
      await desuscribirDeTopic(topicResultados);
    } catch (e) {
      debugPrint('ERROR AL DESUSCRIBIR DE TOPICS ANÓNIMOS: $e');
    }
  }

  static Future<void> inicializar() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Permiso de notificaciones: '
      '${settings.authorizationStatus}',
    );

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (e) {
      debugPrint('NO SE PUDO OBTENER EL TOKEN FCM: $e');
    }

    if (token != null && token.isNotEmpty) {
      try {
        await DispositivoAppService.registrar(
          tokenFcm: token,
          plataforma: _plataformaActual,
        );

        debugPrint('DISPOSITIVO FCM REGISTRADO CORRECTAMENTE');
      } catch (e) {
        debugPrint('ERROR AL REGISTRAR EL DISPOSITIVO FCM: $e');
      }
    }

    _messaging.onTokenRefresh.listen((nuevoToken) async {
      debugPrint('TOKEN FCM ACTUALIZADO');

      try {
        await DispositivoAppService.registrar(
          tokenFcm: nuevoToken,
          plataforma: _plataformaActual,
        );

        debugPrint('NUEVO TOKEN FCM REGISTRADO CORRECTAMENTE');
      } catch (e) {
        debugPrint('ERROR AL REGISTRAR EL NUEVO TOKEN FCM: $e');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final tipo = message.data['tipo'];
      final referenciaIdString = message.data['referenciaId'];

      if (tipo != _tipoComunicacion) {
        if (tipo != _tipoResultado) {
          debugPrint('Push con tipo no reconocido en foreground: $tipo');
        }
        return;
      }

      final referenciaId = int.tryParse(referenciaIdString?.toString() ?? '');

      if (referenciaId == null || referenciaId <= 0) {
        return;
      }

      final titulo = message.notification?.title ?? 'Comunicación del club';

      final mensaje = message.notification?.body ?? '';

      final esPrivada = message.data['esPrivada'] == 'true';
      final autorId = int.tryParse(message.data['autorId']?.toString() ?? '');

      final cantidadNoLeidas = await NotificacionService.contarNoLeidas();

      await LocalNotificationService.mostrarComunicacion(
        comunicacionId: referenciaId,
        titulo: titulo,
        mensaje: mensaje,
        cantidadNoLeidas: cantidadNoLeidas,
        esPrivada: esPrivada,
        autorId: autorId,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _procesarNotificacion(message);
    });

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _notificacionInicial = initialMessage;
    }
  }

  static Future<void> registrarDispositivoActual() async {
    try {
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      await DispositivoAppService.registrar(
        tokenFcm: token,
        plataforma: _plataformaActual,
      );

      debugPrint('DISPOSITIVO FCM REGISTRADO CORRECTAMENTE');
    } catch (e) {
      // En iOS sin APNs (cuenta gratuita, simulador, o token aún no
      // disponible) getToken lanza apns-token-not-set: no debe
      // impedir el login.
      debugPrint('ERROR AL REGISTRAR EL DISPOSITIVO FCM: $e');
    }
  }

  /// Borra solo el token FCM de este dispositivo, sin avisar al backend.
  /// Se usa tras eliminar la cuenta: el backend ya ha borrado el
  /// dispositivo y el token de sesión ya no es válido.
  static Future<void> borrarTokenFcmLocal() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('ERROR AL BORRAR EL TOKEN FCM LOCAL: $e');
    }
  }

  /// SEC-07: se llama al cerrar sesión, antes de borrar el token de
  /// sesión guardado, para que un móvil compartido (varios hijos, tablet
  /// del club) deje de recibir las notificaciones push del usuario que
  /// acaba de salir.
  static Future<void> desregistrarDispositivoActual() async {
    try {
      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        // N-01: timeout propio además del de ApiClient, para que un
        // servidor caído/lento no deje el logout colgado indefinidamente.
        await DispositivoAppService.desactivar(
          token,
        ).timeout(const Duration(seconds: 5));
      }

      await _messaging.deleteToken();

      debugPrint('DISPOSITIVO FCM DESREGISTRADO CORRECTAMENTE');
    } catch (e) {
      debugPrint('ERROR AL DESREGISTRAR EL DISPOSITIVO FCM: $e');
    }
  }

  static Future<void> _procesarNotificacion(RemoteMessage message) async {
    final tipo = message.data['tipo'];

    if (tipo != _tipoComunicacion) {
      if (tipo != _tipoResultado) {
        debugPrint('Push con tipo no reconocido al abrir: $tipo');
      }
      return;
    }

    final esPrivada = message.data['esPrivada'] == 'true';

    if (esPrivada) {
      final autorId = int.tryParse(message.data['autorId']?.toString() ?? '');

      if (autorId == null || autorId <= 0) {
        return;
      }

      await AppNavigator.abrirChatPrivado(autorId);
      return;
    }

    final referenciaIdString = message.data['referenciaId'];

    final referenciaId = int.tryParse(referenciaIdString?.toString() ?? '');

    if (referenciaId == null || referenciaId <= 0) {
      return;
    }

    await AppNavigator.abrirComunicacion(referenciaId);
  }

  static Future<void> procesarNotificacionInicial() async {
    final message = _notificacionInicial;

    if (message == null) {
      return;
    }

    _notificacionInicial = null;

    await _procesarNotificacion(message);
  }
}
