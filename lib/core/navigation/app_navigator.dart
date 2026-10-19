import 'package:flutter/material.dart';

import '../../routing/app_routes.dart';
import '../../../features/auth/pages/chat_privado_page.dart';
import '../../../features/auth/pages/comunicacion_detail_page.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static Future<void> abrirComunicacion(int comunicacionId) async {
    final navigatorState = navigator;

    if (navigatorState == null) {
      return;
    }

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) => ComunicacionDetallePage(comunicacionId: comunicacionId),
      ),
    );
  }

  /// Abre "Mis convocatorias" (tocar el aviso de una convocatoria nueva).
  static Future<void> abrirMisConvocatorias() async {
    final navigatorState = navigator;

    if (navigatorState == null) {
      return;
    }

    await navigatorState.pushNamed(AppRoutes.myCallups);
  }

  static Future<void> abrirChatPrivado(int contraparteId) async {
    final navigatorState = navigator;

    if (navigatorState == null) {
      return;
    }

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) => ChatPrivadoPage(contraparteId: contraparteId),
      ),
    );
  }
}
