import '../../../core/config/app_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../auth/models/login_response.dart';
import '../models/solicitud_familia_model.dart';

/// Las solicitudes de acceso de las familias (contrato: docs/api-app-solicitudes-familia.md del backend).
///
/// Las rutas públicas (registro, verificar, reenviar) van sin sesión; el resto, con ella. En estas respuestas el
/// backend nunca dice si un jugador existe: las coincidencias solo salen en las rutas de revisión.
class SolicitudFamiliaService {
  const SolicitudFamiliaService();

  // ---- sin sesión --------------------------------------------------------------------------------------------------

  /// Crea la cuenta sin roles y manda el código por email. Lanza [ApiException] con 400 (mensaje claro) o 429.
  Future<EstadoRegistroFamilia> registrar(
    SolicitudFamiliaNueva solicitud,
  ) async {
    final idioma = await AppPreferences.obtenerIdioma();

    try {
      final data = await ApiClient.post(
        '/public/solicitudes-familia',
        body: solicitud.toJson(idioma: idioma),
      );

      return switch ((data as Map<String, dynamic>)['estado']) {
        'CUENTA_EXISTENTE' => EstadoRegistroFamilia.cuentaExistente,
        'INVITACION_PENDIENTE' => EstadoRegistroFamilia.invitacionPendiente,
        _ => EstadoRegistroFamilia.codigoEnviado,
      };
    } on ApiException catch (e) {
      final datos = e.datos;

      // La cuenta se creó pero el email no salió: se sigue a la pantalla del código para reenviarlo.
      if (e.statusCode == 503 &&
          datos is Map<String, dynamic> &&
          datos['estado'] == 'ENVIO_FALLIDO') {
        return EstadoRegistroFamilia.envioFallido;
      }

      rethrow;
    }
  }

  /// Confirma el email con el código y fija la contraseña. La respuesta es un login válido (sin roles).
  Future<LoginResponse> verificar({
    required String email,
    required String codigo,
    required String password,
  }) async {
    final idioma = await AppPreferences.obtenerIdioma();

    final data = await ApiClient.post(
      '/public/solicitudes-familia/verificar',
      body: {
        'email': email.trim().toLowerCase(),
        'codigo': codigo.trim(),
        'password': password,
        'idioma': idioma,
      },
    );

    await AppPreferences.guardarUltimoIdiomaEnviado(idioma);

    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Un código nuevo. Responde siempre 204 (no revela nada); 429 si se supera el límite.
  Future<void> reenviarCodigo(String email) async {
    await ApiClient.post(
      '/public/solicitudes-familia/reenviar-codigo',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  // ---- con sesión --------------------------------------------------------------------------------------------------

  /// Pide el acceso a otro jugador estando ya dentro (sin crear cuenta ni verificar email).
  Future<SolicitudFamiliaMia> solicitarConSesion(
    SolicitudFamiliaNueva solicitud,
  ) async {
    final data = await ApiClient.post(
      '/app/solicitudes-familia',
      body: solicitud.toJson(idioma: await AppPreferences.obtenerIdioma()),
      autenticado: true,
    );

    return SolicitudFamiliaMia.fromJson(data as Map<String, dynamic>);
  }

  /// Las solicitudes propias que no han caducado, la más reciente primero.
  Future<List<SolicitudFamiliaMia>> mias() async {
    final data = await ApiClient.get(
      '/app/solicitudes-familia/mias',
      autenticado: true,
    );

    return [
      for (final s in (data as List<dynamic>? ?? const []))
        SolicitudFamiliaMia.fromJson(s as Map<String, dynamic>),
    ];
  }

  // ---- revisión ----------------------------------------------------------------------------------------------------

  Future<List<SolicitudRevision>> pendientes() async {
    final data = await ApiClient.get(
      '/app/solicitudes-familia/pendientes',
      autenticado: true,
    );

    return [
      for (final s in (data as List<dynamic>? ?? const []))
        SolicitudRevision.fromJson(s as Map<String, dynamic>),
    ];
  }

  Future<int> contarPendientes() async {
    final data = await ApiClient.get(
      '/app/solicitudes-familia/pendientes/contador',
      autenticado: true,
    );

    return ((data as Map<String, dynamic>)['total'] as num?)?.toInt() ?? 0;
  }

  /// Jugadores activos por nombre entre los que puede ver quien revisa (mínimo 3 letras).
  Future<List<CoincidenciaJugador>> buscarJugadores(String texto) async {
    final data = await ApiClient.get(
      '/app/solicitudes-familia/jugadores?q=${Uri.encodeQueryComponent(texto.trim())}',
      autenticado: true,
    );

    return [
      for (final c in (data as List<dynamic>? ?? const []))
        CoincidenciaJugador.fromJson(c as Map<String, dynamic>),
    ];
  }

  Future<void> aprobarHijo(int hijoId, int jugadorId) async {
    await ApiClient.post(
      '/app/solicitudes-familia/hijos/$hijoId/aprobar',
      body: {'jugadorId': jugadorId},
      autenticado: true,
    );
  }

  Future<void> rechazarHijo(int hijoId, {String? motivo}) async {
    final limpio = motivo?.trim() ?? '';

    await ApiClient.post(
      '/app/solicitudes-familia/hijos/$hijoId/rechazar',
      body: {if (limpio.isNotEmpty) 'motivo': limpio},
      autenticado: true,
    );
  }
}
