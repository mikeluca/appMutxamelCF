import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import '../../../features/auth/services/notificacion_service.dart';

import 'dispositivo_app_service.dart';
import 'local_notification_service.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../features/auth/services/auth_manager.dart';
import '../utils/convocatoria_notificacion.dart';
import '../../version/control_version.dart';

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

  // El aviso de cambio de temporada (y las noticias) llegan como NOTICIA: sin pantalla propia, la
  // notificación de sistema abre la app en el inicio. No es un tipo desconocido.
  static const String _tipoNoticia = 'NOTICIA';

  // Los tipos de push que nacen de una comunicación: la normal y las de una
  // convocatoria (CONVOCATORIA abre el calendario; CONVOCATORIA_EDITAR, la
  // edición de esa convocatoria).
  static bool _esTipoDeComunicacion(Object? tipo) =>
      tipo == _tipoComunicacion ||
      tipo == tipoPushConvocatoria ||
      tipo == tipoPushConvocatoriaAnulada ||
      tipo == tipoPushConvocatoriaPendiente ||
      tipo == tipoPushResultadoPendiente ||
      tipo == tipoPushConvocatoriaEditar ||
      tipo == tipoPushPasarLista ||
      tipo == tipoPushReporte ||
      tipo == tipoPushContinuidad ||
      tipo == tipoPushContinuidadRespuesta;

  /// Solo para tests: sustituyen a las llamadas a la red, a las notificaciones
  /// locales y a la restauración de la sesión.
  @visibleForTesting
  static Future<int> Function() contarNoLeidas =
      NotificacionService.contarNoLeidas;

  @visibleForTesting
  static MostrarNotificacionLocal mostrarNotificacionLocal =
      LocalNotificationService.mostrarComunicacion;

  @visibleForTesting
  static Future<bool> Function() restaurarSesion = AuthManager.restaurarSesion;

  /// Aviso de una convocatoria con el que se abrió la app en frío. Se guarda
  /// hasta que haya sesión y home: abrirlo antes lo taparía el splash.
  static RemoteMessage? _avisoPendiente;

  @visibleForTesting
  static void simularMensajeInicial(RemoteMessage? mensaje) {
    _notificacionInicial = mensaje;
    _avisoPendiente = null;
  }

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

    FirebaseMessaging.onMessage.listen(mostrarEnPrimerPlano);

    FirebaseMessaging.onMessageOpenedApp.listen(procesarNotificacion);

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

  /// Push recibido con la app abierta: se enseña como notificación local, que
  /// al tocarla navega igual que el push de fondo.
  @visibleForTesting
  static Future<void> mostrarEnPrimerPlano(RemoteMessage message) async {
    final tipo = message.data['tipo'];
    final referenciaIdString = message.data['referenciaId'];

    if (!_esTipoDeComunicacion(tipo)) {
      if (tipo != _tipoResultado && tipo != _tipoNoticia) {
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

    final cantidadNoLeidas = await contarNoLeidas();

    await mostrarNotificacionLocal(
      comunicacionId: referenciaId,
      titulo: titulo,
      mensaje: mensaje,
      cantidadNoLeidas: cantidadNoLeidas,
      esPrivada: esPrivada,
      autorId: autorId,
      datos: message.data,
    );
  }

  /// Push tocado con la app en segundo plano (o ya iniciada): navega a donde
  /// corresponda.
  @visibleForTesting
  static Future<void> procesarNotificacion(RemoteMessage message) async {
    final tipo = message.data['tipo'];

    if (!_esTipoDeComunicacion(tipo)) {
      if (tipo != _tipoResultado && tipo != _tipoNoticia) {
        debugPrint('Push con tipo no reconocido al abrir: $tipo');
      }
      return;
    }

    // El aviso de una convocatoria lleva a JUGADOR/FAMILIAR al calendario, en
    // el día del partido (data["tipo"] == "CONVOCATORIA"; para los pushes
    // antiguos, su título), y al entrenador a editarla ("CONVOCATORIA_EDITAR").
    final destino = destinoDeAvisoConvocatoria(
      tipo: tipo?.toString(),
      titulo: message.notification?.title,
      datos: message.data,
    );

    if (destino != null) {
      await AppNavigator.abrirDestinoConvocatoria(destino);
      return;
    }

    // Su referenciaId es el de un reporte, no el de una comunicación: sin destino
    // (no es administrador) no se abre nada.
    if (tipo == tipoPushReporte) {
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

    // El aviso de una convocatoria necesita la sesión (su destino depende del
    // rol) y que el splash ya haya dado paso a home: se guarda y lo abre
    // procesarAvisoPendiente() después. El resto se abre al momento.
    if (esAvisoDeConvocatoria(
      tipo: message.data['tipo']?.toString(),
      titulo: message.notification?.title,
    )) {
      _avisoPendiente = message;
      return;
    }

    await procesarNotificacion(message);
  }

  /// Abre el aviso de convocatoria con el que se arrancó la app, si lo hubo:
  /// restaura la sesión y navega encima de home. Se llama cuando el splash ya
  /// ha navegado a home.
  static Future<void> procesarAvisoPendiente() async {
    final message = _avisoPendiente;

    if (message == null) {
      return;
    }

    _avisoPendiente = null;

    // Con la versión obsoleta no se navega: la pantalla de actualización no se tapa.
    if (ControlVersion.bloqueada) {
      return;
    }

    // Espera a que home se haya pintado: el destino se abre encima de ella.
    await WidgetsBinding.instance.endOfFrame;

    var sesionValida = false;

    try {
      sesionValida = await restaurarSesion();
    } catch (e) {
      debugPrint('NO SE PUDO RESTAURAR LA SESIÓN PARA EL AVISO: $e');
    }

    // Sin una sesión válida el aviso se descarta: no se navega y la app se
    // queda en su pantalla normal (o en el login al abrir el área del club).
    if (!sesionValida) {
      return;
    }

    await procesarNotificacion(message);
  }
}
