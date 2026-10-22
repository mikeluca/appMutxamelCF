import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nombre_rol.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../admin/services/admin_service.dart';
import '../models/club_menu.dart';
import '../services/auth_manager.dart';
import '../services/comunicacion_service.dart';

class ClubPage extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real del contador de moderación.
  final AdminService? adminService;

  const ClubPage({super.key, this.adminService});

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  int _comunicacionesNoLeidas = 0;
  int _reportesPendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargarContadorComunicaciones();

    if (AuthManager.usuarioActual?.tieneRol('ADMIN_APP') == true) {
      _cargarContadorModeracion();
    }
  }

  Future<void> _cargarContadorModeracion() async {
    try {
      final cantidad = await (widget.adminService ?? AdminService())
          .contarReportesPendientes();

      if (!mounted) return;

      setState(() {
        _reportesPendientes = cantidad;
      });
    } catch (_) {
      // Si falla el contador, la opción sigue funcionando sin él.
    }
  }

  Future<void> _abrirModeracion() async {
    await Navigator.pushNamed(context, AppRoutes.moderation);

    if (!mounted) return;

    await _cargarContadorModeracion();
  }

  Future<void> _cargarContadorComunicaciones() async {
    try {
      final cantidad = await ComunicacionService.contarComunicacionesNoLeidas();

      if (!mounted) return;

      setState(() {
        _comunicacionesNoLeidas = cantidad;
      });
    } catch (_) {
      // Si falla el contador, no impedimos
      // que funcione el Área Club.
    }
  }

  Future<void> _abrirComunicaciones() async {
    await Navigator.pushNamed(context, AppRoutes.communication);

    if (!mounted) return;

    await _cargarContadorComunicaciones();
  }

  /// La pantalla de Cuotas (AppRoutes.cuotas / CuotasPage) sigue intacta
  /// para retomarla más adelante: de momento solo se deja de navegar a
  /// ella y se informa de que estará operativa próximamente.
  void _mostrarCuotasProximamente(BuildContext context) {
    final t = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.clubPageFees),
        content: Text(t.clubPageFeesComingSoonMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthManager.usuarioActual;
    final t = AppLocalizations.of(context);
    final secciones = construirSeccionesClub(usuario);

    return Scaffold(
      appBar: AppBar(title: Text(t.homeAreaClub), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _construirCabecera(context, usuario),

          for (final seccion in secciones) ..._construirSeccion(context, seccion),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _tituloSeccion(AppLocalizations t, SeccionClubId id) {
    switch (id) {
      case SeccionClubId.club:
        return t.clubPageSectionClub;
      case SeccionClubId.jugador:
        return t.clubSectionPlayer;
      case SeccionClubId.familia:
        return t.clubSectionFamily;
      case SeccionClubId.entrenador:
        return t.clubSectionCoach;
      case SeccionClubId.coordinacion:
        return t.clubSectionCoordination;
      case SeccionClubId.administracion:
        return t.clubSectionAdministration;
      case SeccionClubId.retransmision:
        return t.clubSectionBroadcast;
      case SeccionClubId.cuenta:
        return t.clubPageSectionAccount;
    }
  }

  List<Widget> _construirSeccion(BuildContext context, SeccionClub seccion) {
    final t = AppLocalizations.of(context);

    return [
      const SizedBox(height: 30),

      Text(
        _tituloSeccion(t, seccion.id),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      for (var i = 0; i < seccion.opciones.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        _construirOpcionClub(context, seccion.opciones[i]),
      ],
    ];
  }

  void _navegar(OpcionClub opcion) {
    Navigator.pushNamed(context, rutaDeOpcionClub(opcion)!);
  }

  Widget _construirOpcionClub(BuildContext context, OpcionClub opcion) {
    final t = AppLocalizations.of(context);
    final usuario = AuthManager.usuarioActual;
    final esGestionGlobal =
        usuario?.tieneRol('COORDINADOR') == true ||
        usuario?.tieneRol('ADMIN_APP') == true;

    switch (opcion) {
      case OpcionClub.comunicaciones:
        return _construirOpcionComunicaciones(context);
      case OpcionClub.calendario:
        return _construirOpcion(
          context,
          icono: Icons.event_note_outlined,
          titulo: t.clubPageCalendar,
          descripcion: t.clubPageCalendarDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.partidos:
        return _construirOpcion(
          context,
          icono: Icons.calendar_month_outlined,
          titulo: esGestionGlobal ? t.allMatchesTitle : t.clubPageMyMatches,
          descripcion: t.clubPageMyMatchesDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.clasificaciones:
        return _construirOpcion(
          context,
          icono: Icons.leaderboard_outlined,
          titulo: esGestionGlobal
              ? t.allStandingsTitle
              : t.clubPageMyStandings,
          descripcion: esGestionGlobal
              ? t.clubPageAllStandingsDesc
              : t.clubPageMyStandingsDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.miFicha:
        return _construirOpcion(
          context,
          icono: Icons.badge_outlined,
          titulo: t.clubPageMyCard,
          descripcion: t.clubPageMyCardDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.misJugadores:
        return _construirOpcion(
          context,
          icono: Icons.sports_soccer,
          titulo: t.clubPageMyPlayers,
          descripcion: t.clubPageMyPlayersDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.cuotas:
        return _construirOpcion(
          context,
          icono: Icons.payments_outlined,
          titulo: t.clubPageFees,
          descripcion: t.clubPageFeesComingSoonDesc,
          onTap: () => _mostrarCuotasProximamente(context),
        );
      case OpcionClub.misEquipos:
      case OpcionClub.todosLosEquipos:
        return _construirOpcion(
          context,
          icono: Icons.groups_outlined,
          titulo: opcion == OpcionClub.todosLosEquipos
              ? t.allTeamsTitle
              : t.clubPageMyTeams,
          descripcion: t.clubPageMyTeamsDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.finDeSemana:
        return _construirOpcion(
          context,
          icono: Icons.dashboard_outlined,
          titulo: t.clubPageWeekend,
          descripcion: t.clubPageWeekendDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.seguimientoJugadores:
        return _construirOpcion(
          context,
          icono: Icons.report_problem_outlined,
          titulo: t.clubPagePlayerTracking,
          descripcion: t.clubPagePlayerTrackingDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.moderacion:
        return _construirOpcion(
          context,
          icono: Icons.shield_outlined,
          titulo: t.clubPageModeration,
          descripcion: t.clubPageModerationDesc,
          contador: _reportesPendientes,
          onTap: _abrirModeracion,
        );
      case OpcionClub.cuentasPendientes:
        return _construirOpcion(
          context,
          icono: Icons.mark_email_unread_outlined,
          titulo: t.clubPagePendingAccounts,
          descripcion: t.clubPagePendingAccountsDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.estadoApp:
        return _construirOpcion(
          context,
          icono: Icons.insights_outlined,
          titulo: t.clubPageAppStatus,
          descripcion: t.clubPageAppStatusDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.partidoEnDirecto:
        return _construirOpcion(
          context,
          icono: Icons.campaign_outlined,
          titulo: t.clubPageLiveMatch,
          descripcion: t.clubPageLiveMatchDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.miPerfil:
        return _construirOpcion(
          context,
          icono: Icons.person_outline,
          titulo: t.clubPageMyProfile,
          descripcion: t.clubPageMyProfileDesc,
          onTap: () => _navegar(opcion),
        );
      case OpcionClub.cerrarSesion:
        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: OutlinedButton.icon(
            onPressed: () async {
              await AuthManager.cerrarSesion();

              if (!context.mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.public,
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: Text(t.clubPageLogout),
          ),
        );
    }
  }

  Widget _construirOpcionComunicaciones(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _abrirComunicaciones,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.azul.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: Theme.of(context).colorScheme.primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).clubPageCommunications,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).clubPageCommunicationsDesc,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              if (_comunicacionesNoLeidas > 0) ...[
                const SizedBox(width: 8),
                _construirBurbuja(context, _comunicacionesNoLeidas),
                const SizedBox(width: 8),
              ],

              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBurbuja(BuildContext context, int cantidad) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: AppColors.dorado,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        cantidad > 99 ? '99+' : '$cantidad',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _construirCabecera(BuildContext context, dynamic usuario) {
    final nombre = (usuario?.nombre as String?)?.trim().isNotEmpty == true
        ? usuario.nombre as String
        : usuario?.email ?? AppLocalizations.of(context).clubPageDefaultMember;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppColors.blancoCalido,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 34,
              color: AppColors.azulOscuro,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).homeAreaClub,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 4),

                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                if (usuario != null && usuario.roles.isNotEmpty) ...[
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final rol in usuario.roles)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            nombreDeRol(AppLocalizations.of(context), rol),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirOpcion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
    int contador = 0,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.azul.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  color: Theme.of(context).colorScheme.primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      descripcion,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              if (contador > 0) ...[
                const SizedBox(width: 8),
                _construirBurbuja(context, contador),
                const SizedBox(width: 8),
              ],

              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
