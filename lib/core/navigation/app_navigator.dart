import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../network/api_client.dart';
import '../version/control_version.dart';
import '../notifications/utils/convocatoria_notificacion.dart';
import '../../features/auth/models/perfil_app.dart';
import '../../features/admin/pages/moderacion_page.dart';
import '../../features/calendario/pages/calendario_page.dart';
import '../../features/convocatorias/model/convocatoria_model.dart';
import '../../features/auth/services/perfil_service.dart';
import '../../features/convocatorias/pages/convocatoria_familia_page.dart';
import '../../features/convocatorias/pages/convocatoria_form_page.dart';
import '../../features/convocatorias/services/convocatoria_partido_service.dart';
import '../../features/convocatorias/services/convocatoria_service.dart';
import '../../features/entrenamientos/model/entrenamiento_model.dart';
import '../../features/entrenamientos/pages/entrenamiento_form_page.dart';
import '../../features/entrenamientos/services/entrenamiento_service.dart';
import '../../features/matches/models/match_model.dart';
import '../../features/matches/pages/resultado_partido_form_page.dart';
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

  @visibleForTesting
  static Widget Function()? constructorModeracion;

  static Future<void> abrirComunicacion(int comunicacionId) async {
    final navigatorState = navigator;

    if (navigatorState == null || ControlVersion.bloqueada) {
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
    if (ControlVersion.bloqueada) {
      return;
    }

    switch (destino) {
      case AbrirCalendario(:final dia):
        await abrirCalendario(dia);
      case AbrirDetalleConvocatoria(:final partidoId, :final dia):
        await abrirDetalleConvocatoria(partidoId, dia);
      case AbrirFormularioConvocatoria(:final partidoId, :final equipoId, :final equipo):
        await abrirFormularioConvocatoria(partidoId, equipoId, equipo);
      case AbrirFormularioResultado():
        await abrirFormularioResultado(destino);
      case EditarConvocatoria(:final convocatoriaId):
        await abrirEdicionConvocatoria(convocatoriaId);
      case PasarLista(:final entrenamientoId):
        await abrirAsistenciaEntrenamiento(entrenamientoId);
      case AbrirModeracion():
        await abrirModeracion();
    }
  }

  /// Solo para tests: sustituyen al servicio, al perfil y a la pantalla reales.
  @visibleForTesting
  static ConvocatoriaPartidoService Function()? fabricaConvocatoriaPartidoService;

  @visibleForTesting
  static Future<PerfilApp> Function()? cargarPerfilParaAviso;

  @visibleForTesting
  static Widget Function(int partidoId, PerfilJugador jugador)?
  constructorConvocatoriaFamilia;

  /// El aviso de una convocatoria de un partido para JUGADOR/FAMILIAR: si el
  /// usuario tiene un solo jugador en esa convocatoria se abre la pantalla
  /// "Convocatoria" de ese jugador; con varios (o ninguno, o si algo falla), el
  /// calendario en el día del partido, como siempre.
  static Future<void> abrirDetalleConvocatoria(
    int partidoId, [
    DateTime? dia,
  ]) async {
    final navigatorState = navigator;

    if (navigatorState == null || ControlVersion.bloqueada) {
      return;
    }

    PerfilJugador? unico;

    // Mientras se piden el perfil y las convocatorias, un indicador de carga encima.
    final carga = PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black26,
      pageBuilder: (_, _, _) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    unawaited(navigatorState.push(carga));

    try {
      final perfil =
          await (cargarPerfilParaAviso ?? PerfilService.obtenerPerfil)();

      final servicio =
          fabricaConvocatoriaPartidoService?.call() ??
          ConvocatoriaPartidoService();

      final convocados = <PerfilJugador>[];

      for (final jugador in perfil.jugadores) {
        try {
          final convocatoria = await servicio.obtener(
            partidoId: partidoId,
            jugadorId: jugador.id,
          );

          if (convocatoria.convocado) {
            convocados.add(jugador);
          }
        } catch (_) {
          // Un jugador de otro equipo (403) o sin convocatoria (404) no cuenta.
        }
      }

      if (convocados.length == 1) {
        unico = convocados.first;
      }
    } catch (e) {
      debugPrint('No se pudo resolver la convocatoria del partido $partidoId: $e');
    } finally {
      if (carga.isActive && navigatorState.mounted) {
        navigatorState.removeRoute(carga);
      }
    }

    if (ControlVersion.bloqueada) {
      return;
    }

    if (unico == null || !navigatorState.mounted) {
      await abrirCalendario(dia);
      return;
    }

    final jugador = unico;

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) =>
            (constructorConvocatoriaFamilia ??
            (id, j) => ConvocatoriaFamiliaPage(
              partidoId: id,
              jugadorId: j.id,
              jugadorNombre: j.nombre,
              jugadorApellidos: j.apellidos,
            ))(partidoId, jugador),
      ),
    );
  }

  /// Solo para tests: sustituyen a los formularios reales.
  @visibleForTesting
  static Widget Function(int partidoId, PerfilEquipo equipo)?
  constructorFormularioConvocatoria;

  @visibleForTesting
  static Widget Function(MatchModel partido)? constructorFormularioResultado;

  /// Aviso "publica la convocatoria" de coordinación: el formulario de convocatoria con
  /// ese partido preseleccionado.
  static Future<void> abrirFormularioConvocatoria(
    int partidoId,
    int equipoId,
    String equipo,
  ) async {
    final navigatorState = navigator;

    if (navigatorState == null || ControlVersion.bloqueada) {
      return;
    }

    final perfilEquipo = PerfilEquipo(id: equipoId, nombre: equipo);

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) =>
            (constructorFormularioConvocatoria ??
            (id, e) => ConvocatoriaFormPage(equipo: e, partidoIdInicial: id))(
              partidoId,
              perfilEquipo,
            ),
      ),
    );
  }

  /// Aviso "falta el resultado" de coordinación: el formulario de resultado del partido.
  static Future<void> abrirFormularioResultado(
    AbrirFormularioResultado destino,
  ) async {
    final navigatorState = navigator;

    if (navigatorState == null || ControlVersion.bloqueada) {
      return;
    }

    final partido = MatchModel(
      id: destino.partidoId,
      equipoId: destino.equipoId,
      categoria: '',
      equipo: destino.equipo,
      rival: destino.rival,
      dia: destino.dia,
      hora: destino.hora,
      local: destino.local,
    );

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) =>
            (constructorFormularioResultado ??
            (p) => ResultadoPartidoFormPage(partido: p))(partido),
      ),
    );
  }

  /// La cola de moderación (ADMIN_APP).
  static Future<void> abrirModeracion() async {
    final navigatorState = navigator;

    if (navigatorState == null || ControlVersion.bloqueada) {
      return;
    }

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) =>
            (constructorModeracion ?? () => const ModeracionPage())(),
      ),
    );
  }

  /// La asistencia del entrenamiento [entrenamientoId], para pasar lista. Sin
  /// permiso (403) o con el entrenamiento ya borrado (404) no se abre nada.
  static Future<void> abrirAsistenciaEntrenamiento(
    int entrenamientoId, {
    EntrenamientoService? servicio,
  }) async {
    final navigatorState = navigator;

    if (navigatorState == null || ControlVersion.bloqueada) {
      return;
    }

    try {
      final entrenamiento =
          await (servicio ??
                  fabricaEntrenamientoService?.call() ??
                  EntrenamientoService())
              .obtenerPorId(entrenamientoId);

      if (!navigatorState.mounted || ControlVersion.bloqueada) {
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

    if (navigatorState == null || ControlVersion.bloqueada) {
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

    if (navigatorState == null || ControlVersion.bloqueada) {
      return;
    }

    try {
      final convocatoria =
          await (servicio ??
                  fabricaConvocatoriaService?.call() ??
                  ConvocatoriaService())
              .obtenerPorId(convocatoriaId);

      if (!navigatorState.mounted || ControlVersion.bloqueada) {
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

    if (navigatorState == null || ControlVersion.bloqueada) {
      return;
    }

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) => ChatPrivadoPage(contraparteId: contraparteId),
      ),
    );
  }
}
