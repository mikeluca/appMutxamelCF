import 'dart:async';

import 'package:flutter/material.dart';
import '../../routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/notifications/services/local_notification_service.dart';
import '../../core/notifications/services/push_notification_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // Permisos/red de notificaciones corren en paralelo, sin bloquear el primer frame.
    _inicializarNotificaciones();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, AppRoutes.public);
    });
  }

  Future<void> _inicializarNotificaciones() async {
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
                    const Text(
                      'La app oficial del club',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
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
