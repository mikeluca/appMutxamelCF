import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/utils/convocatoria_notificacion.dart';
import '../../../routing/app_routes.dart';
import '../services/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/navigation/app_navigator.dart';
import '../models/notificacion_model.dart';
import '../services/notificacion_service.dart';
import 'comunicacion_detail_page.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  List<NotificacionModel> _notificaciones = [];
  bool _cargando = true;
  bool _sinSesion = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    // Sin sesión no se llama al servidor: solo se enseña el estado propio.
    if (!await AuthSession.estaAutenticado()) {
      if (!mounted) return;

      setState(() {
        _sinSesion = true;
        _notificaciones = [];
        _cargando = false;
      });

      return;
    }

    try {
      final notificaciones = await NotificacionService.obtenerNotificaciones();

      if (!mounted) return;

      setState(() {
        _sinSesion = false;
        _notificaciones = notificaciones
            .where((notificacion) => !notificacion.leida)
            .toList();
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      // 401: la sesión ha caducado (ApiClient ya la ha limpiado). No es un
      // error: se enseña el mismo estado que sin sesión.
      setState(() {
        _sinSesion = e.statusCode == 401;
        _error = _sinSesion ? null : e.message;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _iniciarSesion() async {
    await Navigator.pushNamed(context, AppRoutes.login);

    if (!mounted) return;

    await _cargarNotificaciones();
  }

  Future<void> _abrirNotificacion(NotificacionModel notificacion) async {
    if (!notificacion.leida) {
      try {
        await NotificacionService.marcarComoLeida(notificacion.id);
      } catch (_) {
        // No impedimos abrir la notificación
        // aunque falle el marcado como leída.
      }
    }

    if (!mounted) return;

    // La fila de la lista no guarda el data del push: aquí solo se reconoce el
    // aviso de convocatoria por su título (abre el calendario en hoy).
    // Las de continuidad sí guardan su tipo: la pregunta a la familia abre su pantalla; la respuesta a
    // coordinación ya está en esta bandeja y se revisa en el panel web.
    final destino = notificacion.tipo == tipoPushContinuidad
        ? const AbrirContinuidad()
        : destinoDeAvisoConvocatoria(titulo: notificacion.titulo);

    if (destino != null) {
      await AppNavigator.abrirDestinoConvocatoria(destino);

      await _cargarNotificaciones();
    } else if (notificacion.tipo == 'COMUNICACION' &&
        notificacion.referenciaId != null &&
        notificacion.referenciaId! > 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComunicacionDetallePage(
            comunicacionId: notificacion.referenciaId!,
          ),
        ),
      );

      await _cargarNotificaciones();
    } else {
      await _cargarNotificaciones();
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    try {
      await NotificacionService.marcarTodasComoLeidas();

      await _cargarNotificaciones();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).markAllReadError,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
        ),
      );
    }
  }

  String _formatearFecha(BuildContext context, DateTime? fecha) {
    if (fecha == null) {
      return '';
    }

    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');

      return AppLocalizations.of(context).todayAt('$hora:$minuto');
    }

    if (diferencia.inDays == 1) {
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');

      return AppLocalizations.of(context).yesterdayAt('$hora:$minuto');
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final ano = fecha.year.toString();

    return '$dia/$mes/$ano';
  }

  IconData _iconoNotificacion(String tipo) {
    switch (tipo) {
      case 'COMUNICACION':
        return Icons.campaign_outlined;
      case tipoPushContinuidad:
      case tipoPushContinuidadRespuesta:
        return Icons.event_available_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: t.settingsSectionNotifications),
        actions: [
          if (_notificaciones.any((n) => !n.leida))
            IconButton(
              tooltip: t.markAllReadTooltip,
              icon: const Icon(Icons.done_all),
              onPressed: _marcarTodasComoLeidas,
            ),
        ],
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = AppLocalizations.of(context);

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sinSesion) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: AppColors.azulOscuro,
              ),
              const SizedBox(height: 16),
              Text(
                t.notificationsSignedOutMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _iniciarSesion,
                child: Text(t.loginButton),
              ),
              const SizedBox(height: 28),
              Text(
                t.notificationsPublicHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.settings),
                child: Text(t.notificationsOpenSettings),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                t.notificationsLoadError,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarNotificaciones,
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_notificaciones.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarNotificaciones,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 140),
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.azulOscuro,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                t.noNotifications,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notificaciones.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notificacion = _notificaciones[index];

          return _NotificacionCard(
            notificacion: notificacion,
            fecha: _formatearFecha(context, notificacion.fecha),
            icono: _iconoNotificacion(notificacion.tipo),
            onTap: () => _abrirNotificacion(notificacion),
          );
        },
      ),
    );
  }
}

class _NotificacionCard extends StatelessWidget {
  final NotificacionModel notificacion;
  final String fecha;
  final IconData icono;
  final VoidCallback onTap;

  const _NotificacionCard({
    required this.notificacion,
    required this.fecha,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final noLeida = !notificacion.leida;

    final colorTarjeta = noLeida
        ? colors.surface
        : Color.alphaBlend(
            colors.onSurface.withValues(alpha: 0.04),
            colors.surface,
          );

    return Material(
      color: colorTarjeta,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.azulOscuro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: noLeida
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (noLeida)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 8, top: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.azul,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notificacion.mensaje,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (fecha.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        fecha,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
