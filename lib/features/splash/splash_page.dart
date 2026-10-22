import 'dart:async';

import 'package:flutter/material.dart';
import '../../routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/version/control_version.dart';
import '../../core/notifications/services/local_notification_service.dart';
import '../../core/notifications/services/push_notification_service.dart';
import '../../l10n/gen/app_localizations.dart';

class SplashPage extends StatefulWidget {
  /// Lo que dura el splash antes de pasar a home.
  final Duration duracion;

  /// Solo para tests: sustituye a la inicialización real de las notificaciones
  /// (Firebase, permisos, plugin local).
  final Future<void> Function()? inicializarNotificaciones;

  /// Solo para tests: sustituye a la consulta de la versión mínima (red y plugin
  /// de la versión instalada).
  final Future<EstadoVersion?> Function()? comprobarVersion;

  const SplashPage({
    super.key,
    this.duracion = const Duration(seconds: 3),
    this.inicializarNotificaciones,
    this.comprobarVersion,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // Permisos/red de notificaciones corren en paralelo, sin bloquear el primer frame.
    // Un fallo al inicializar las notificaciones se anota aquí mismo (no se
    // queda como error sin capturar) y no impide pasar a home.
    final notificacionesListas = _inicializarNotificaciones().then<void>(
      (_) {},
      onError: (Object e) {
        debugPrint('ERROR AL INICIALIZAR LAS NOTIFICACIONES: $e');
      },
    );

    // La versión mínima se consulta en paralelo, sin retrasar el splash: si la
    // app está obsoleta, la pantalla de actualización sustituye a todo lo demás
    // aunque la respuesta llegue después de pasar a home. Sin red, la app sigue.
    (widget.comprobarVersion ?? ControlVersion.comprobar)().then<void>(
      (_) {},
      onError: (Object e) {
        debugPrint('ERROR AL COMPROBAR LA VERSIÓN DE LA APP: $e');
      },
    );

    Timer(widget.duracion, () async {
      if (!mounted) return;

      // Ya bloqueada por una versión obsoleta: no se pasa a home.
      if (ControlVersion.bloqueada) return;

      Navigator.pushReplacementNamed(context, AppRoutes.public);

      ControlVersion.splashTerminado();

      // El aviso de convocatoria con el que se arrancó la app se abre ahora,
      // ya sobre home: antes, el pushReplacement de arriba lo habría tapado.
      await notificacionesListas;

      await PushNotificationService.procesarAvisoPendiente();

      // Hay una versión recomendada (no obligatoria): se avisa una vez al día.
      await ControlVersion.avisarSiProcede();
    });
  }

  Future<void> _inicializarNotificaciones() async {
    final sustituta = widget.inicializarNotificaciones;

    if (sustituta != null) {
      await sustituta();
      return;
    }

    await LocalNotificationService.inicializar();

    await PushNotificationService.inicializar();

    await PushNotificationService.procesarNotificacionInicial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azul,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/escudo.png',
                      width: 180,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).splashTagline,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 45),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.dorado,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // PATROCINADORES
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: _SponsorLogo(
                      assetPath: 'assets/images/patrocinador_ud.png',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SponsorLogo(
                      assetPath: 'assets/images/patrocinador_frutas.png',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SponsorLogo(
                      assetPath: 'assets/images/patrocinador_ayto.png',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorLogo extends StatelessWidget {
  final String assetPath;

  const _SponsorLogo({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65,
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}
