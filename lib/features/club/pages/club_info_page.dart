import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/red_social.dart';

/// Ficha pública de contacto del club (dirección, teléfono, email y
/// redes sociales), equivalente a la página "Contacto" de la web y
/// a los iconos de redes sociales de su cabecera. Es contenido
/// público y estático: no requiere sesión iniciada ni backend.
///
/// No confundir con `ClubPage` (lib/features/auth/pages/club_page.dart),
/// que es el menú PRIVADO "Área Club" (requiere login).
class ClubInfoPage extends StatelessWidget {
  const ClubInfoPage({super.key});

  static const String _direccion = 'Calle los Olmos S/N, Mutxamel, Alicante';
  static const String _telefonoVisible = '+34 623 17 68 18';
  static const String _telefonoTel = '+34623176818';
  static const String _email = 'mutxamelcf.gestion@gmail.com';
  static const String _urlWeb = 'https://mutxamelcf.es';

  // Coordenadas de la sede del club (Calle los Olmos S/N, Mutxamel),
  // sacadas del iframe de Google Maps que ya usa contacto.html en la
  // web.
  static const String _mapaEstaticoUrl =
      'https://staticmap.openstreetmap.de/staticmap.php'
      '?center=38.407683,-0.445294&zoom=17&size=600x300'
      '&markers=38.407683,-0.445294,red-pushpin';

  Future<void> _abrirUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir el enlace')),
      );
    }
  }

  Future<void> _abrirMapa(BuildContext context) async {
    final query = Uri.encodeComponent(_direccion);

    await _abrirUrl(
      context,
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
  }

  Future<void> _llamar(BuildContext context) async {
    await _abrirUrl(context, 'tel:$_telefonoTel');
  }

  Future<void> _enviarEmail(BuildContext context) async {
    await _abrirUrl(context, 'mailto:$_email');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Club')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _construirCabecera(),

          const SizedBox(height: 24),

          _construirSeccion(
            context,
            titulo: 'Dónde estamos',
            icono: Icons.place_outlined,
            children: [
              _construirOpcion(
                context,
                icono: Icons.location_on_outlined,
                titulo: 'Dirección',
                subtitulo: _direccion,
                onTap: () => _abrirMapa(context),
              ),
              const SizedBox(height: 10),
              _construirMapa(context),
              const SizedBox(height: 10),
              _construirOpcion(
                context,
                icono: Icons.language,
                titulo: 'Página web',
                subtitulo: 'mutxamelcf.es',
                onTap: () => _abrirUrl(context, _urlWeb),
              ),
              const SizedBox(height: 10),
              _construirOpcion(
                context,
                icono: Icons.phone_outlined,
                titulo: 'Teléfono',
                subtitulo: _telefonoVisible,
                onTap: () => _llamar(context),
              ),
              const SizedBox(height: 10),
              _construirOpcion(
                context,
                icono: Icons.email_outlined,
                titulo: 'Email',
                subtitulo: _email,
                onTap: () => _enviarEmail(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _construirSeccion(
            context,
            titulo: 'Síguenos',
            icono: Icons.share_outlined,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: kRedesSociales
                    .map((red) => _construirIconoRedSocial(context, red))
                    .toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              '© ${DateTime.now().year} Mutxamel Club de Fútbol',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabecera() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Image.asset('assets/images/escudo.png', height: 80),

          const SizedBox(height: 14),

          const Text(
            'Mutxamel Club de Fútbol',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Dónde estamos y cómo contactar con el club',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _construirSeccion(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: colors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...children,
      ],
    );
  }

  Widget _construirOpcion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.azul.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: colors.primary, size: 24),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirMapa(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrirMapa(context),
          child: Image.network(
            _mapaEstaticoUrl,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _construirMapaRespaldo(context);
            },
          ),
        ),
      ),
    );
  }

  /// Respaldo si el servicio de mapa estático (sin API key) fallara:
  /// una tarjeta pulsable que abre igualmente Google Maps.
  Widget _construirMapaRespaldo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 180,
      child: Material(
        color: colors.surfaceContainerHighest,
        child: InkWell(
          onTap: () => _abrirMapa(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 36, color: colors.primary),
              const SizedBox(height: 8),
              Text(
                'Ver en Google Maps',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirIconoRedSocial(BuildContext context, RedSocial red) {
    final colors = Theme.of(context).colorScheme;
    final imagenUrl = '${AppConfig.mediaBaseUrl}/images/${red.imagen}';

    return InkWell(
      onTap: () => _abrirUrl(context, red.url),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.network(
          imagenUrl,
          width: 44,
          height: 44,
          semanticLabel: red.nombre,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.azul.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.public, color: colors.primary),
            );
          },
        ),
      ),
    );
  }
}
