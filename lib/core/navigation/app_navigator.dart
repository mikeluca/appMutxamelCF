import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../network/api_client.dart';
import '../notifications/utils/convocatoria_notificacion.dart';
import '../../features/auth/models/perfil_app.dart';
import '../../features/calendario/pages/calendario_page.dart';
import '../../features/convocatorias/model/convocatoria_model.dart';
import '../../features/convocatorias/pages/convocatoria_form_page.dart';
import '../../features/convocatorias/services/convocatoria_service.dart';
import '../../features/entrenamientos/model/entrenamiento_model.dart';
import '../../features/entrenamientos/pages/entrenamiento_form_page.dart';
import '../../features/entrenamientos/services/entrenamiento_service.dart';
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

  @visibleForTesting
  static ConvocatoriaService Function()? fabricaConvocatoriaService;

  @visibleForTesting
  static Widget Function(EntrenamientoModel entrenamiento)?
  constructorAsistencia;

  @visibleForTesting
  static EntrenamientoService Function()? fabricaEntrenamientoService;

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
      case PasarLista(:final entrenamientoId):
        await abrirAsistenciaEntrenamiento(entrenamientoId);
    }
  }

  /// La asistencia del entrenamiento [entrenamientoId], para pasar lista. Sin
  /// permiso (403) o con el entrenamiento ya borrado (404) no se abre nada.
  static Future<void> abrirAsistenciaEntrenamiento(
    int entrenamientoId, {
    EntrenamientoService? servicio,
  }) async {
    final navigatorState = navigator;

    if (navigatorState == null) {
      return;
    }

    try {
      final entrenamiento =
          await (servicio ??
                  fabricaEntrenamientoService?.call() ??
                  EntrenamientoService())
              .obtenerPorId(entrenamientoId);

      if (!navigatorState.mounted) {
        return;
      }

      await navigatorState.push(
        MaterialPageRoute(
          builder: (_) =>
              (constructorAsistencia ??
              (e) => EntrenamientoFormPage(
                equipo: PerfilEquipo(id: e.equipoId, nombre: e.equipo),
                entrenamiento: e,
              ))(entrenamiento),
        ),
      );
    } catch (e) {
      debugPrint('No se pudo abrir el entrenamiento $entrenamientoId: $e');

      final contexto = navigatorState.context;

      if (!contexto.mounted) {
        return;
      }

      final t = AppLocalizations.of(contexto);

      final noDisponible =
          e is ApiException && (e.statusCode == 403 || e.statusCode == 404);

      ScaffoldMessenger.maybeOf(contexto)?.showSnackBar(
        SnackBar(
          content: Text(noDisponible ? t.trainingNotFound : t.connectionError),
        ),
      );
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
      final convocatoria =
          await (servicio ??
                  fabricaConvocatoriaService?.call() ??
                  ConvocatoriaService())
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

      final contexto = navigatorState.context;

      if (!contexto.mounted) {
        return;
      }

      final t = AppLocalizations.of(contexto);

      // Solo "ya no existe" (404) o "ya no se puede gestionar" (403) significan
      // que la convocatoria no está disponible; cualquier otro fallo (red,
      // servidor caído...) es un problema de conexión, reintentable.
      final noDisponible =
          e is ApiException && (e.statusCode == 403 || e.statusCode == 404);

      ScaffoldMessenger.maybeOf(contexto)?.showSnackBar(
        SnackBar(
          content: Text(noDisponible ? t.callupUnavailable : t.connectionError),
        ),
      );
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
