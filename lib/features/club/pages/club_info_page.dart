import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';
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

  // Mismo iframe de Google Maps (URL pública de "embed", sin API
  // key) que ya usa contacto.html en la web, apuntando a la sede del
  // club (Calle los Olmos S/N, Mutxamel).
  static const String _mapaEmbedUrl =
      'https://www.google.com/maps/embed?pb=!1m17!1m12!1m3!1d957.0062670822804'
      '!2d-0.44529438041417635!3d38.407682941178706!2m3!1f0!2f0!3f0'
      '!3m2!1i1024!2i768!4f13.1!3m2!1m1!2zMzjCsDI0JzI5LjAiTiAwwrAyNic0MS4zIlc'
      '!5e1!3m2!1ses!2ses!4v1754845797624!5m2!1ses!2ses';

  Future<void> _abrirUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).linkOpenError)),
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
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.clubTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _construirCabecera(context),

          const SizedBox(height: 24),

          _construirSeccion(
            context,
            titulo: t.clubWhereWeAre,
            icono: Icons.place_outlined,
            children: [
              _construirOpcion(
                context,
                icono: Icons.location_on_outlined,
                titulo: t.clubAddress,
                subtitulo: _direccion,
                onTap: () => _abrirMapa(context),
              ),
              const SizedBox(height: 10),
              _construirMapa(context),
              const SizedBox(height: 10),
              _construirOpcion(
                context,
                icono: Icons.language,
                titulo: t.clubWebsite,
                subtitulo: 'mutxamelcf.es',
                onTap: () => _abrirUrl(context, _urlWeb),
              ),
              const SizedBox(height: 10),
              _construirOpcion(
                context,
                icono: Icons.phone_outlined,
                titulo: t.clubPhone,
                subtitulo: _telefonoVisible,
                onTap: () => _llamar(context),
              ),
              const SizedBox(height: 10),
              _construirOpcion(
                context,
                icono: Icons.email_outlined,
                titulo: t.clubEmail,
                subtitulo: _email,
                onTap: () => _enviarEmail(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _construirSeccion(
            context,
            titulo: t.clubFollowUs,
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
              t.clubCopyright(DateTime.now().year),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabecera(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Stack(
      children: [
        Container(
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

              Text(
                t.clubFullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                t.clubTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: t.clubSettingsTooltip,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ),
      ],
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
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: _MapaEmbebido(
          url: _mapaEmbedUrl,
          onErrorAbrirMapa: () => _abrirMapa(context),
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

/// Mapa de la sede del club incrustado con un WebView cargando la
/// URL pública de "embed" de Google Maps (la misma que usa la web
/// dentro de un `<iframe>`), sin necesidad de API key.
///
/// Si el WebView fallara al cargar (p.ej. sin conexión), cae a una
/// tarjeta de respaldo pulsable que abre Google Maps en una app
/// externa, para no dejar nunca la sección sin ninguna forma de ver
/// el mapa.
class _MapaEmbebido extends StatefulWidget {
  final String url;
  final VoidCallback onErrorAbrirMapa;

  const _MapaEmbebido({required this.url, required this.onErrorAbrirMapa});

  @override
  State<_MapaEmbebido> createState() => _MapaEmbebidoState();
}

class _MapaEmbebidoState extends State<_MapaEmbebido> {
  late final WebViewController _controller;

  bool _error = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (!mounted) return;

            setState(() => _error = true);
          },
        ),
      )
      ..loadHtmlString(_htmlConIframe(widget.url));
  }

  /// La API de Google Maps Embed comprueba que se está cargando
  /// dentro de un <iframe> (window.top != window.self) y, si no,
  /// muestra el error "The Google Maps Embed API must be used in an
  /// iframe" en vez del mapa. Cargar la URL directamente con
  /// loadRequest la deja como documento de nivel superior del
  /// WebView, así que falla esa comprobación. Envolviéndola en un
  /// HTML mínimo con un <iframe> de verdad, la página del mapa sí
  /// se considera embebida y se muestra con normalidad.
  static String _htmlConIframe(String url) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>html, body, iframe { margin: 0; padding: 0; width: 100%; height: 100%; border: 0; }</style>
  </head>
  <body>
    <iframe src="$url" allowfullscreen loading="lazy"></iframe>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _construirRespaldo(context);
    }

    return WebViewWidget(controller: _controller);
  }

  Widget _construirRespaldo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      child: InkWell(
        onTap: widget.onErrorAbrirMapa,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 36, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).clubViewOnGoogleMaps,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
