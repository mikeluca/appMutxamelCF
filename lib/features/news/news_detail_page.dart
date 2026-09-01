import 'package:flutter/material.dart';

import 'models/news_model.dart';

class NewsDetailPage extends StatelessWidget {
  final NewsModel noticia;

  const NewsDetailPage({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    final imageUrl = noticia.fullImagenUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Noticia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
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
                    debugPrint('ERROR IMAGEN: $error');
                    debugPrint('URL IMAGEN: $imageUrl');
                    debugPrint('STACK: $stackTrace');

                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_outlined, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Error cargando imagen',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            Text(
              noticia.titulo,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            if (noticia.fecha != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatearFecha(noticia.fecha!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 20),

            Text(
              noticia.contenido,
              style: Theme.of(context).textTheme.bodyLarge,
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
