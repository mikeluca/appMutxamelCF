import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routing/app_routes.dart';
import '../services/auth_manager.dart';

class ClubPage extends StatelessWidget {
  const ClubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthManager.usuarioActual;

    final tieneJugadores =
        usuario?.tieneRol('FAMILIAR') == true ||
        usuario?.tieneRol('JUGADOR') == true ||
        usuario?.tieneRol('COORDINADOR') == true ||
        usuario?.tieneRol('ADMIN_APP') == true;

    final tieneEquipos =
        usuario?.tieneRol('ENTRENADOR') == true ||
        usuario?.tieneRol('COORDINADOR') == true ||
        usuario?.tieneRol('ADMIN_APP') == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Área Club'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _construirCabecera(context, usuario),

          const SizedBox(height: 28),

          Text(
            'Club',
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
              titulo: 'Mis jugadores',
              descripcion: 'Jugadores vinculados a tu cuenta',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.players);
              },
            ),

          if (tieneJugadores) const SizedBox(height: 12),

          if (tieneEquipos)
            _construirOpcion(
              context,
              icono: Icons.groups_outlined,
              titulo: 'Mis equipos',
              descripcion: 'Equipos vinculados a tu actividad en el club',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.myTeams);
              },
            ),

          if (tieneEquipos) const SizedBox(height: 12),

          _construirOpcion(
            context,
            icono: Icons.calendar_month_outlined,
            titulo: 'Mis partidos',
            descripcion: 'Próximos partidos y resultados',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.myMatches);
            },
          ),

          const SizedBox(height: 12),

          _construirOpcion(
            context,
            icono: Icons.notifications_none,
            titulo: 'Comunicaciones',
            descripcion: 'Avisos y comunicaciones del club',
            onTap: () {
              // Lo implementaremos posteriormente.
            },
          ),

          const SizedBox(height: 30),

          Text(
            'Mi cuenta',
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
            titulo: 'Mi perfil',
            descripcion: 'Tus datos personales y configuración',
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
            label: const Text('Cerrar sesión'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _construirCabecera(BuildContext context, dynamic usuario) {
    final nombre = usuario?.email ?? 'Miembro del club';

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
                const Text(
                  'Área Club',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
