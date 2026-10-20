import 'package:flutter/material.dart';

import '../notifications/utils/convocatoria_notificacion.dart';
import '../../features/auth/models/perfil_app.dart';
import '../../features/calendario/pages/calendario_page.dart';
import '../../features/convocatorias/model/convocatoria_model.dart';
import '../../features/convocatorias/pages/convocatoria_form_page.dart';
import '../../features/convocatorias/services/convocatoria_service.dart';
import '../../../features/auth/pages/chat_privado_page.dart';
import '../../../features/auth/pages/comunicacion_detail_page.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Solo para tests: sustituyen a las pantallas reales (que piden datos a la
  /// red al abrirse).
  @visibleForTesting
  static Widget Function(DateTime? dia)? constructorCalendario;

  @visibleForTesting
  static Widget Function(ConvocatoriaModel convocatoria)? constructorEdicion;

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

  /// Tocar el aviso de una convocatoria: el calendario en el día del partido
  /// (JUGADOR/FAMILIAR) o la edición de esa convocatoria (entrenador).
  static Future<void> abrirDestinoConvocatoria(
    DestinoConvocatoria destino,
  ) async {
    switch (destino) {
      case AbrirCalendario(:final dia):
        await abrirCalendario(dia);
      case EditarConvocatoria(:final convocatoriaId):
        await abrirEdicionConvocatoria(convocatoriaId);
    }
  }

  /// El calendario, con [dia] seleccionado (hoy si es null).
  static Future<void> abrirCalendario([DateTime? dia]) async {
    final navigatorState = navigator;

    if (navigatorState == null) {
      return;
    }

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) =>
            (constructorCalendario ?? (d) => CalendarioPage(diaInicial: d))(
              dia,
            ),
      ),
    );
  }

  /// La edición de la convocatoria [convocatoriaId]. Sin permiso (403) o con
  /// la convocatoria ya borrada no se abre nada.
  static Future<void> abrirEdicionConvocatoria(
    int convocatoriaId, {
    ConvocatoriaService? servicio,
  }) async {
    final navigatorState = navigator;

    if (navigatorState == null) {
      return;
    }

    try {
      final convocatoria = await (servicio ?? ConvocatoriaService())
          .obtenerPorId(convocatoriaId);

      if (!navigatorState.mounted) {
        return;
      }

      await navigatorState.push(
        MaterialPageRoute(
          builder: (_) =>
              (constructorEdicion ??
              (c) => ConvocatoriaFormPage(
                equipo: PerfilEquipo(id: c.equipoId, nombre: c.equipo),
                convocatoria: c,
              ))(convocatoria),
        ),
      );
    } catch (e) {
      debugPrint('No se pudo abrir la convocatoria $convocatoriaId: $e');
    }
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
