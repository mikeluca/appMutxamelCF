import 'package:flutter/material.dart';
import '../../entrenamientos/pages/entrenamientos_page.dart';
import '../../convocatorias/pages/convocatorias_page.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../teams/pages/jugadores_equipo_page.dart';
import '../models/perfil_app.dart';

class EquipoGestionPage extends StatelessWidget {
  final PerfilEquipo equipo;

  const EquipoGestionPage({super.key, required this.equipo});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: equipo.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Gestión del equipo',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _construirOpcion(
            context,
            icono: Icons.fact_check_outlined,
            titulo: 'Entrenamientos',
            descripcion: 'Crear y consultar entrenamientos y asistencia',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EntrenamientosPage(equipo: equipo),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _construirOpcion(
            context,
            icono: Icons.sports_soccer_outlined,
            titulo: 'Convocatorias',
            descripcion: 'Crear y consultar convocatorias de partidos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConvocatoriasPage(equipo: equipo),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _construirOpcion(
            context,
            icono: Icons.groups_outlined,
            titulo: 'Jugadores',
            descripcion: 'Consultar los jugadores del equipo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JugadoresEquipoPage(equipo: equipo),
                ),
              );
            },
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
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: colors.onPrimaryContainer, size: 26),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
