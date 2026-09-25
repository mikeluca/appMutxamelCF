import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../services/auth_manager.dart';
import '../services/comunicacion_service.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key});

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  int _comunicacionesNoLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargarContadorComunicaciones();
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

  @override
  Widget build(BuildContext context) {
    final usuario = AuthManager.usuarioActual;

    final tieneJugadores = usuario?.tieneRol('FAMILIAR') == true;

    final tieneEquipos =
        usuario?.tieneRol('ENTRENADOR') == true ||
        usuario?.tieneRol('COORDINADOR') == true ||
        usuario?.tieneRol('ADMIN_APP') == true;

    final esRetransmision = usuario?.tieneRol('RETRANSMISION') == true;

    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.homeAreaClub), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _construirCabecera(context, usuario),

          const SizedBox(height: 28),

          Text(
            t.clubPageSectionClub,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (tieneJugadores)
            _construirOpcion(
              context,
              icono: Icons.sports_soccer,
              titulo: t.clubPageMyPlayers,
              descripcion: t.clubPageMyPlayersDesc,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.players);
              },
            ),

          if (tieneJugadores) const SizedBox(height: 12),

          if (tieneJugadores)
            _construirOpcion(
              context,
              icono: Icons.payments_outlined,
              titulo: t.clubPageFees,
              descripcion: t.clubPageFeesDesc,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.cuotas);
              },
            ),

          if (tieneJugadores) const SizedBox(height: 12),

          if (tieneEquipos)
            _construirOpcion(
              context,
              icono: Icons.groups_outlined,
              titulo: t.clubPageMyTeams,
              descripcion: t.clubPageMyTeamsDesc,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.myTeams);
              },
            ),

          if (tieneEquipos) const SizedBox(height: 12),

          _construirOpcion(
            context,
            icono: Icons.calendar_month_outlined,
            titulo: t.clubPageMyMatches,
            descripcion: t.clubPageMyMatchesDesc,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.myMatches);
            },
          ),

          const SizedBox(height: 12),

          if (esRetransmision)
            _construirOpcion(
              context,
              icono: Icons.campaign_outlined,
              titulo: t.clubPageLiveMatch,
              descripcion: t.clubPageLiveMatchDesc,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.liveMatch);
              },
            ),

          if (esRetransmision) const SizedBox(height: 12),

          _construirOpcionComunicaciones(context),

          const SizedBox(height: 30),

          Text(
            t.clubPageSectionAccount,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _construirOpcion(
            context,
            icono: Icons.person_outline,
            titulo: t.clubPageMyProfile,
            descripcion: t.clubPageMyProfileDesc,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),

          const SizedBox(height: 30),

          OutlinedButton.icon(
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

          const SizedBox(height: 20),
        ],
      ),
    );
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
    final nombre =
        usuario?.email ?? AppLocalizations.of(context).clubPageDefaultMember;

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
