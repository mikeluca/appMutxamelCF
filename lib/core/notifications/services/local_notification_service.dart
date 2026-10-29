import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/navigation/app_navigator.dart';
import '../utils/convocatoria_notificacion.dart';

/// Firma de [LocalNotificationService.mostrarComunicacion].
typedef MostrarNotificacionLocal =
    Future<void> Function({
      required int comunicacionId,
      required String titulo,
      required String mensaje,
      int cantidadNoLeidas,
      bool esPrivada,
      int? autorId,
      Map<String, dynamic> datos,
    });

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

    // iOS: los permisos ya los pide firebase_messaging, así que aquí no.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

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
    procesarPayload(response.payload);
  }

  /// Navega según el payload de una notificación local tocada.
  @visibleForTesting
  static void procesarPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    const prefijoPrivada = 'PRIVADA:';
    const prefijoComunicacion = 'COMUNICACION:';

    // Aviso de una convocatoria: el calendario o la edición de la convocatoria.
    final destino = destinoDePayload(payload);

    if (destino != null) {
      AppNavigator.abrirDestinoConvocatoria(destino);
      return;
    }

    if (payload.startsWith(prefijoPrivada)) {
      final autorId = int.tryParse(payload.substring(prefijoPrivada.length));

      if (autorId != null && autorId > 0) {
        AppNavigator.abrirChatPrivado(autorId);
      }

      return;
    }

    if (!payload.startsWith(prefijoComunicacion)) {
      return;
    }

    final idTexto = payload.substring(prefijoComunicacion.length);

    final comunicacionId = int.tryParse(idTexto);

    if (comunicacionId == null || comunicacionId <= 0) {
      return;
    }

    AppNavigator.abrirComunicacion(comunicacionId);
  }

  /// Lo que lleva la notificación local para saber, al tocarla, a dónde ir.
  ///
  /// Es null si el aviso es de un tipo con destino propio (REPORTE, PASAR_LISTA) y el
  /// usuario no tiene permiso para él: su referenciaId no es el de una comunicación
  /// "normal" y no debe acabar abriendo COMUNICACION:id.
  @visibleForTesting
  static String? payloadDeAviso({
    required int comunicacionId,
    required String titulo,
    bool esPrivada = false,
    int? autorId,
    Map<String, dynamic> datos = const {},
  }) {
    final tipo = datos['tipo']?.toString();

    final destino = destinoDeAvisoConvocatoria(
      tipo: tipo,
      titulo: titulo,
      datos: datos,
    );

    if (destino != null) {
      return payloadDeDestino(destino);
    }

    if (tipo == tipoPushReporte || tipo == tipoPushPasarLista) {
      return null;
    }

    return esPrivada && autorId != null && autorId > 0
        ? 'PRIVADA:$autorId'
        : 'COMUNICACION:$comunicacionId';
  }

  /// Espacios de ids distintos para los avisos que no son una comunicación: el
  /// referenciaId de un REPORTE es el de un reporte y el de PASAR_LISTA va ligado a
  /// su propio aviso, y no deben pisar (ni ser pisados por) la notificación de una
  /// comunicación con el mismo número.
  static const int _baseReporte = 1000000000;
  static const int _basePasarLista = 1100000000;
  static const int _baseContinuidad = 1200000000;
  static const int _tamanoEspacio = 100000000;

  @visibleForTesting
  static int idDeNotificacion(int referenciaId, Map<String, dynamic> datos) {
    return switch (datos['tipo']?.toString()) {
      tipoPushReporte => _baseReporte + referenciaId % _tamanoEspacio,
      tipoPushPasarLista => _basePasarLista + referenciaId % _tamanoEspacio,
      tipoPushContinuidad ||
      tipoPushContinuidadRespuesta => _baseContinuidad + referenciaId % _tamanoEspacio,
      _ => referenciaId,
    };
  }

  static Future<void> mostrarComunicacion({
    required int comunicacionId,
    required String titulo,
    required String mensaje,
    int cantidadNoLeidas = 1,
    bool esPrivada = false,
    int? autorId,
    Map<String, dynamic> datos = const {},
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

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: cantidadNoLeidas,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final payload = payloadDeAviso(
      comunicacionId: comunicacionId,
      titulo: titulo,
      esPrivada: esPrivada,
      autorId: autorId,
      datos: datos,
    );

    await _plugin.show(
      id: idDeNotificacion(comunicacionId, datos),
      title: titulo,
      body: mensaje,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
