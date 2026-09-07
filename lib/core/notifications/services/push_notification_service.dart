import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../features/auth/services/notificacion_service.dart';

import 'dispositivo_app_service.dart';
import 'local_notification_service.dart';

import '../../../core/navigation/app_navigator.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static RemoteMessage? _notificacionInicial;

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

    final token = await _messaging.getToken();

    debugPrint('TOKEN FCM: $token');

    if (token != null && token.isNotEmpty) {
      try {
        await DispositivoAppService.registrar(
          tokenFcm: token,
          plataforma: 'ANDROID',
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
          plataforma: 'ANDROID',
        );

        debugPrint('NUEVO TOKEN FCM REGISTRADO CORRECTAMENTE');
      } catch (e) {
        debugPrint('ERROR AL REGISTRAR EL NUEVO TOKEN FCM: $e');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final tipo = message.data['tipo'];
      final referenciaIdString = message.data['referenciaId'];

      if (tipo != 'COMUNICACION') {
        return;
      }

      final referenciaId = int.tryParse(referenciaIdString?.toString() ?? '');

      if (referenciaId == null || referenciaId <= 0) {
        return;
      }

      final titulo = message.notification?.title ?? 'Comunicación del club';

      final mensaje = message.notification?.body ?? '';

      final cantidadNoLeidas = await NotificacionService.contarNoLeidas();

      await LocalNotificationService.mostrarComunicacion(
        comunicacionId: referenciaId,
        titulo: titulo,
        mensaje: mensaje,
        cantidadNoLeidas: cantidadNoLeidas,
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
    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await DispositivoAppService.registrar(
        tokenFcm: token,
        plataforma: 'ANDROID',
      );

      debugPrint('DISPOSITIVO FCM REGISTRADO CORRECTAMENTE');
    } catch (e) {
      debugPrint('ERROR AL REGISTRAR EL DISPOSITIVO FCM: $e');
    }
  }

  static Future<void> _procesarNotificacion(RemoteMessage message) async {
    final tipo = message.data['tipo'];

    final referenciaIdString = message.data['referenciaId'];

    if (tipo != 'COMUNICACION') {
      return;
    }

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
