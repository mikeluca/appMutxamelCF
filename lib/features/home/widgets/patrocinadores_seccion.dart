import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/patrocinador.dart';

/// Construye la imagen de red de un logo; solo para tests (evita la caché de imágenes real).
typedef ConstructorLogoPatrocinador =
    Widget Function(String url, bool circular, Widget alternativa);

/// La sección "Nuestros patrocinadores" de la portada: título, subtítulo y la cuadrícula de logos con
/// su nombre debajo. Mientras carga deja un hueco de la misma altura; si falla o no hay patrocinadores no
/// pinta nada (ni título ni subtítulo).
class PatrocinadoresSeccion extends StatelessWidget {
  /// Solo para tests.
  static ConstructorLogoPatrocinador? constructorDeRed;

  /// Alto aproximado de un logo con su nombre; el hueco de "cargando" lo reserva sin saltos de diseño.
  static const double _alturaFila = 150;

  final bool cargando;
  final List<Patrocinador> patrocinadores;

  const PatrocinadoresSeccion({
    super.key,
    required this.cargando,
    required this.patrocinadores,
  });

  @override
  Widget build(BuildContext context) {
    if (!cargando && patrocinadores.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),

        Text(
          t.homeOurSponsors,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        if (cargando)
          const SizedBox(
            key: ValueKey('patrocinadores-cargando'),
            height: _alturaFila,
            width: double.infinity,
          )
        else ...[
          Text(
            t.homeSponsorsHint,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth >= 480 ? 3 : 2;
              const separacion = 12.0;
              final ancho =
                  (constraints.maxWidth - separacion * (columnas - 1)) /
                  columnas;

              return Wrap(
                spacing: separacion,
                runSpacing: separacion,
                children: [
                  for (final p in patrocinadores)
                    SizedBox(
                      width: ancho,
                      child: _Tile(patrocinador: p),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final Patrocinador patrocinador;

  const _Tile({required this.patrocinador});

  Future<void> _abrir(BuildContext context) async {
    final uri = Uri.tryParse(patrocinador.url!);
    final mensajes = ScaffoldMessenger.of(context);
    final error = AppLocalizations.of(context).linkOpenError;

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      mensajes.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = '${AppConfig.mediaBaseUrl}${patrocinador.imagenUrl}';

    final alternativa = Container(
      color: AppColors.azulOscuro.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.azul,
      ),
    );

    final construir = PatrocinadoresSeccion.constructorDeRed;

    final imagen = construir != null
        ? construir(url, patrocinador.circular, alternativa)
        : CachedNetworkImage(
            imageUrl: url,
            fit: patrocinador.circular ? BoxFit.cover : BoxFit.contain,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, _) => alternativa,
            errorWidget: (_, _, _) => alternativa,
          );

    final contenido = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  patrocinador.circular ? 100 : 8,
                ),
                child: SizedBox.expand(child: imagen),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              patrocinador.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    // Sin enlace (Aresala): no se puede tocar.
    if (patrocinador.url == null) {
      return Semantics(
        label: patrocinador.nombre,
        excludeSemantics: true,
        child: contenido,
      );
    }

    return Semantics(
      label: patrocinador.nombre,
      button: true,
      link: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrir(context),
        child: contenido,
      ),
    );
  }
}
