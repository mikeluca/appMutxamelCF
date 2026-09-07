import 'package:flutter/material.dart';

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
}
