import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import '../../../features/auth/services/notificacion_service.dart';
import '../../../features/auth/services/auth_session.dart';
import '../../config/app_preferences.dart';
import 'permiso_notificaciones.dart';
import 'topics_anonimos.dart';
import '../../../features/directo/services/seguir_partido_service.dart';
import '../../../features/directo/widgets/partido_visible.dart';
import '../../../features/auth/services/preferencias_notificacion_service.dart';

import 'dispositivo_app_service.dart';
import 'local_notification_service.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../features/auth/services/auth_manager.dart';
import '../utils/convocatoria_notificacion.dart';
import '../../version/control_version.dart';
import '../../../features/ficha_partido/pages/ficha_partido_page.dart';

class PushNotificationService {
  // FL-04: se registraba 'ANDROID' también en iOS.
  static String get _plataformaActual => Platform.isIOS ? 'IOS' : 'ANDROID';
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static RemoteMessage? _notificacionInicial;

  // Topics de FCM para notificaciones "anónimas" (sin sesión
  // iniciada, sin cuenta): la suscripción es 100% cliente, vía el
  // propio SDK de Firebase, sin llamar a la API. Los nombres deben
  // coincidir exactamente con lo que publica el backend: un topic por idioma
  // (noticias_es|ca|en, resultados_es|ca|en); ver TopicsAnonimos.
  static const String topicNoticias = TopicsAnonimos.baseNoticias;
  static const String topicResultados = TopicsAnonimos.baseResultados;

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

  /// El partido al que lleva un aviso del directo (data "tipo" RESULTADO con "partidoId"), o null si no lo lleva
  /// (avisos antiguos o de versiones anteriores del backend, y los de otros tipos).
  @visibleForTesting
  static int? partidoDeAviso(Map<String, dynamic> datos) {
    if (datos['tipo'] != _tipoResultado) {
      return null;
    }

    final id = int.tryParse(datos['partidoId']?.toString() ?? '');

    return id != null && id > 0 ? id : null;
  }

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
      tipo == tipoPushContinuidadRespuesta ||
      tipo == tipoPushImagenesRedes ||
      esTipoPushInvitacion(tipo);

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

  /// "Seguir este partido": altas y bajas en `partido_{id}_{idioma}` y los partidos seguidos (en AppPreferences).
  /// Los tests lo sustituyen por uno con funciones falsas.
  static SeguirPartidoService seguirPartidos = SeguirPartidoService(
    suscribir: suscribirATopic,
    desuscribir: desuscribirDeTopic,
    obtenerIdioma: AppPreferences.obtenerIdioma,
    leer: AppPreferences.obtenerPartidosSeguidos,
    guardar: AppPreferences.guardarPartidosSeguidos,
    pedirPermiso: PermisoNotificaciones.estaConcedido,
    recibeResultados: recibeAvisosDeResultados,
  );

  /// true si este dispositivo ya recibe los avisos de resultados: sin cuenta, su interruptor anónimo; con cuenta, su
  /// preferencia de avisos de resultados (con las notificaciones activadas). null si no se puede saber (error de red).
  static Future<bool?> recibeAvisosDeResultados() async {
    try {
      final token = await AuthSession.obtenerToken();

      if (token == null || token.isEmpty) {
        return await AppPreferences.obtenerNotifResultados();
      }

      final preferencias =
          await PreferenciasNotificacionService.obtenerPreferencias();

      return preferencias.notificacionesActivadas &&
          preferencias.resultadosActivados;
    } catch (e) {
      debugPrint('NO SE PUDO SABER SI RECIBE LOS RESULTADOS: $e');
      return null;
    }
  }

  /// Al arrancar: baja de los partidos seguidos caducados (más de 2 días) y, si el dispositivo ya recibe los
  /// resultados, de todos (evita avisos duplicados). Nunca lanza.
  static Future<void> sincronizarPartidosSeguidos() async {
    try {
      await seguirPartidos.alArrancar();
    } catch (e) {
      debugPrint('ERROR AL SINCRONIZAR LOS PARTIDOS SEGUIDOS: $e');
    }
  }

  /// Solo para tests: sustituye a las altas y bajas reales de Firebase.
  @visibleForTesting
  static TopicsAnonimos topicsAnonimos = TopicsAnonimos(
    suscribir: suscribirATopic,
    desuscribir: desuscribirDeTopic,
  );

  /// Interruptor "Noticias" de quien no tiene sesión: alta en el topic de su
  /// idioma (y baja de los antiguos y de los otros idiomas) o baja de todos.
  static Future<void> activarNoticiasAnonimas(bool activo) async {
    if (activo) {
      await topicsAnonimos.activar(
        TopicsAnonimos.baseNoticias,
        await AppPreferences.obtenerIdioma(),
      );
    } else {
      await topicsAnonimos.desactivar(TopicsAnonimos.baseNoticias);
    }
  }

  /// Interruptor "Resultados" de quien no tiene sesión (ver
  /// [activarNoticiasAnonimas]).
  static Future<void> activarResultadosAnonimos(bool activo) async {
    if (activo) {
      await topicsAnonimos.activar(
        TopicsAnonimos.baseResultados,
        await AppPreferences.obtenerIdioma(),
      );

      // Ya recibe los avisos de todos los partidos: seguir alguno duplicaría los avisos.
      await sinSeguirPartidos();
    } else {
      await topicsAnonimos.desactivar(TopicsAnonimos.baseResultados);
    }
  }

  /// Baja de todos los partidos seguidos (porque pasa a recibir todos los resultados). Nunca lanza.
  static Future<void> sinSeguirPartidos() async {
    try {
      await seguirPartidos.bajaDeTodos();
    } catch (e) {
      debugPrint('ERROR AL DEJAR DE SEGUIR LOS PARTIDOS: $e');
    }
  }

  /// Al cambiar el idioma en Ajustes: de los topics anónimos que tenga
  /// activos, baja del idioma anterior y alta en el nuevo. Nunca lanza.
  static Future<void> alCambiarIdioma(String anterior, String nuevo) async {
    try {
      await topicsAnonimos.cambiarIdioma(
        anterior: anterior,
        nuevo: nuevo,
        noticias: await AppPreferences.obtenerNotifNoticias(),
        resultados: await AppPreferences.obtenerNotifResultados(),
      );

      await seguirPartidos.alCambiarIdioma(anterior, nuevo);

      await AppPreferences.guardarIdiomaTopics(nuevo);
    } catch (e) {
      debugPrint('ERROR AL CAMBIAR LOS TOPICS DE IDIOMA: $e');
    }
  }

  /// Al arrancar: si los topics anónimos no están ajustados al idioma de la
  /// app (instalación anterior a los topics por idioma, o idioma cambiado por
  /// otra vía), los deja en el topic de su idioma y sin los antiguos. Con
  /// sesión iniciada no hace nada: ya se dio de baja de todos al entrar. No
  /// repite el trabajo en cada arranque y nunca lanza.
  static Future<void> sincronizarTopicsAnonimos() async {
    try {
      final idioma = await AppPreferences.obtenerIdioma();

      final idiomaAnterior = await AppPreferences.obtenerIdiomaTopics();

      // El idioma cambió sin pasar por Ajustes: los partidos seguidos también se mueven.
      if (idiomaAnterior != null && idiomaAnterior != idioma) {
        await seguirPartidos.alCambiarIdioma(idiomaAnterior, idioma);
      }

      if (idiomaAnterior == idioma) {
        return;
      }

      final token = await AuthSession.obtenerToken();

      if (token == null || token.isEmpty) {
        await topicsAnonimos.sincronizar(
          idioma: idioma,
          noticias: await AppPreferences.obtenerNotifNoticias(),
          resultados: await AppPreferences.obtenerNotifResultados(),
        );
      }

      await AppPreferences.guardarIdiomaTopics(idioma);
    } catch (e) {
      // Se reintenta en el siguiente arranque.
      debugPrint('ERROR AL SINCRONIZAR LOS TOPICS ANÓNIMOS: $e');
    }
  }

  /// Se llama al iniciar sesión: quien tiene cuenta recibe los
  /// avisos de resultados por el canal personal existente (ver
  /// PartidoEnVivoServiceImpl.difundirATodos en el backend), así que
  /// hay que desuscribirlo de los topics anónimos para que no le
  /// lleguen duplicados.
  static Future<void> desuscribirDeTopicsAnonimos() async {
    try {
      await topicsAnonimos.desuscribirDeTodos();
    } catch (e) {
      debugPrint('ERROR AL DESUSCRIBIR DE TOPICS ANÓNIMOS: $e');
    }
  }

  static Future<void> inicializar() async {
    // El permiso NO se pide aqui: lo pide PermisoNotificaciones, siempre tras la pantalla propia (bienvenida, iniciar sesion
    // o seguir un partido). Al concederlo se registra el dispositivo.
    PermisoNotificaciones.alConceder = registrarDispositivoActual;

    debugPrint(
      'Permiso de notificaciones: '
      '${(await _messaging.getNotificationSettings()).authorizationStatus}',
    );

    String? token;
    try {
      // ignore: deprecated_member_use
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

    // ignore: deprecated_member_use
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

  // NOTA: getToken/onTokenRefresh/deleteToken están marcados como obsoletos en firebase_messaging 17, pero sus
  // sustitutos (register/onRegistered/unregister/onUnregistered) entregan el Firebase Installation ID (FID), no el
  // token FCM que guarda y usa el backend (DISPOSITIVOS_APP.TOKEN_FCM, envío por token y topics). Migrar sin que el
  // backend acepte FID dejaría a todos sin avisos personales, así que se mantiene la API actual (avisos silenciados
  // con ignore) hasta que el backend lo soporte.
  static Future<void> registrarDispositivoActual() async {
    try {
      // ignore: deprecated_member_use
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
      // ignore: deprecated_member_use
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
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        // N-01: timeout propio además del de ApiClient, para que un
        // servidor caído/lento no deje el logout colgado indefinidamente.
        await DispositivoAppService.desactivar(
          token,
        ).timeout(const Duration(seconds: 5));
      }

      // ignore: deprecated_member_use
      await _messaging.deleteToken();

      debugPrint('DISPOSITIVO FCM DESREGISTRADO CORRECTAMENTE');
    } catch (e) {
      debugPrint('ERROR AL DESREGISTRAR EL DISPOSITIVO FCM: $e');
    }
  }

  static final StreamController<void> _avisosDeResultados =
      StreamController<void>.broadcast();

  /// Un evento por cada push del partido en directo recibido con la app abierta (el de la cuenta,
  /// con tipo RESULTADO, o el de un topic anónimo, que no trae datos): la portada se refresca con él.
  static Stream<void> get avisosDeResultados => _avisosDeResultados.stream;

  /// Push recibido con la app abierta: se enseña como notificación local, que
  /// al tocarla navega igual que el push de fondo.
  @visibleForTesting
  static Future<void> mostrarEnPrimerPlano(RemoteMessage message) async {
    final tipo = message.data['tipo'];
    final referenciaIdString = message.data['referenciaId'];

    if (tipo == _tipoResultado || tipo == null) {
      _avisosDeResultados.add(null);
    }

    // El aviso del directo con partido se enseña como notificación local que, al tocarla, abre su ficha.
    final partidoId = partidoDeAviso(message.data);

    if (partidoId != null) {
      // Con la ficha de ese partido a la vista no se avisa: ya se está recargando sola.
      if (FichaPartidoPage.estaVisible(partidoId) ||
          PartidoVisible.estaVisible(partidoId)) {
        return;
      }

      await mostrarNotificacionLocal(
        comunicacionId: partidoId,
        titulo: message.notification?.title ?? '',
        mensaje: message.notification?.body ?? '',
        datos: message.data,
      );
      return;
    }

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

    // El aviso del directo abre la ficha de su partido; sin partido, como siempre (abre la app en el inicio).
    final partidoId = partidoDeAviso(message.data);

    if (partidoId != null) {
      await AppNavigator.abrirFichaPartido(partidoId);
      return;
    }

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

    // La ficha pública no necesita sesión, pero igual que la convocatoria espera a que el splash dé paso a home.
    if (partidoDeAviso(message.data) != null) {
      _avisoPendiente = message;
      return;
    }

    // El aviso de una convocatoria necesita la sesión (su destino depende del
    // rol) y que el splash ya haya dado paso a home: se guarda y lo abre
    // procesarAvisoPendiente() después. El resto se abre al momento.
    if (esAvisoDeConvocatoria(
      tipo: message.data['tipo']?.toString(),
      titulo: message.notification?.title,
      accion: message.data['accion']?.toString(),
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

    // La ficha del partido es pública: se abre también sin sesión.
    if (partidoDeAviso(message.data) != null) {
      await procesarNotificacion(message);
      return;
    }

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
