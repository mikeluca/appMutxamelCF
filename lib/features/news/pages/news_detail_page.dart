import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/news_model.dart';

class NewsDetailPage extends StatelessWidget {
  final NewsModel noticia;

  const NewsDetailPage({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    final String imagenUrl = noticia.imagenUrl ?? '';

    // Sin imagen asociada: mismo fallback que ya usa la web
    // (noticia3.jpg), para que ninguna noticia se quede sin imagen
    // al mostrar.
    final String urlImagenMostrada = imagenUrl.isNotEmpty
        ? '${AppConfig.apiBaseUrl}/public/noticias/${noticia.id}/imagen-mini'
        : '${AppConfig.mediaBaseUrl}/images/noticia3.jpg';

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(
          titulo: AppLocalizations.of(context).newsDetailTitle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la noticia
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.network(
                urlImagenMostrada,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Contenido de la noticia
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      noticia.titulo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Fecha
                  if (noticia.fecha != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatearFecha(noticia.fecha!),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Contenido
                  Text(
                    noticia.contenido,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }
}
