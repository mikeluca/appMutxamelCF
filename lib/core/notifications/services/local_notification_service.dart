import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/navigation/app_navigator.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'comunicaciones',
    'Comunicaciones',
    description: 'Notificaciones y comunicaciones del club',
    importance: Importance.max,
    playSound: true,
    showBadge: true,
  );

  static Future<void> inicializar() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);

    await androidPlugin?.requestNotificationsPermission();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    const prefijo = 'COMUNICACION:';

    if (!payload.startsWith(prefijo)) {
      return;
    }

    final idTexto = payload.substring(prefijo.length);

    final comunicacionId = int.tryParse(idTexto);

    if (comunicacionId == null || comunicacionId <= 0) {
      return;
    }

    AppNavigator.abrirComunicacion(comunicacionId);
  }

  static Future<void> mostrarComunicacion({
    required int comunicacionId,
    required String titulo,
    required String mensaje,
    int cantidadNoLeidas = 1,
  }) async {
    if (comunicacionId <= 0) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableLights: true,
      enableVibration: true,
      number: cantidadNoLeidas,
      channelShowBadge: true,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: comunicacionId,
      title: titulo,
      body: mensaje,
      notificationDetails: notificationDetails,
      payload: 'COMUNICACION:$comunicacionId',
    );
  }
}
