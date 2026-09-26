import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/news_model.dart';
import 'news_detail_page.dart';
import '../services/news_services.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const int _noticiasPorPagina = 5;

  final NewsService _newsService = NewsService();

  List<NewsModel> _noticias = [];

  bool _cargandoInicial = true;
  bool _cargandoMas = false;

  // Hasta que una página devuelva menos de _noticiasPorPagina
  // noticias, asumimos que puede haber más antiguas que cargar.
  bool _hayMasAntiguas = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNoticias(esInicial: true);
  }

  Future<void> _cargarNoticias({bool esInicial = false}) async {
    if (esInicial) {
      setState(() {
        _cargandoInicial = true;
        _error = null;
      });
    }

    try {
      final noticias = await _newsService.obtenerNoticias();

      if (!mounted) return;

      setState(() {
        _noticias = noticias;
        _error = null;
        _cargandoInicial = false;
        _hayMasAntiguas = noticias.length >= _noticiasPorPagina;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoInicial = false;

        if (esInicial) {
          _error = e.toString();
        }
      });

      // Si falla un pull-to-refresh (no la carga inicial), mantenemos
      // la lista que ya había en pantalla y solo avisamos con un
      // snackbar, en vez de sustituirla por la pantalla de error.
      if (!esInicial && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).homeNewsLoadError)),
        );
      }
    }
  }

  Future<void> _cargarMasNoticias() async {
    if (!_hayMasAntiguas || _cargandoMas || _noticias.isEmpty) return;

    setState(() => _cargandoMas = true);

    try {
      final masNoticias = await _newsService.obtenerNoticias(
        antesId: _noticias.last.id,
      );

      if (!mounted) return;

      setState(() {
        _noticias = [..._noticias, ...masNoticias];
        _hayMasAntiguas = masNoticias.length >= _noticiasPorPagina;
        _cargandoMas = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _cargandoMas = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).newsLoadMoreError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: AppLocalizations.of(context).newsTitle),
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    final t = AppLocalizations.of(context);

    if (_cargandoInicial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(t.homeNewsLoadError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _cargarNoticias(esInicial: true),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_noticias.isEmpty) {
      return Center(child: Text(t.homeNoNewsAvailable));
    }

    return RefreshIndicator(
      onRefresh: _cargarNoticias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _noticias.length + 1,
        itemBuilder: (context, index) {
          if (index == _noticias.length) {
            return _construirPieDeLista();
          }

          return _construirTarjetaNoticia(_noticias[index]);
        },
      ),
    );
  }

  Widget _construirPieDeLista() {
    if (!_hayMasAntiguas) {
      return const SizedBox.shrink();
    }

    if (_cargandoMas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _cargarMasNoticias,
          icon: const Icon(Icons.expand_more),
          label: Text(AppLocalizations.of(context).newsLoadMore),
        ),
      ),
    );
  }

  Widget _construirTarjetaNoticia(NewsModel noticia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewsDetailPage(noticia: noticia),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Image.network(
                (noticia.imagenUrl != null && noticia.imagenUrl!.isNotEmpty)
                    ? '${AppConfig.apiBaseUrl}/public/noticias/${noticia.id}/imagen-mini'
                    // Sin imagen asociada: mismo fallback que ya usa
                    // la web (noticia3.jpg), para que ninguna noticia
                    // se quede sin imagen al mostrar.
                    : '${AppConfig.mediaBaseUrl}/images/noticia3.jpg',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      noticia.titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    noticia.contenido,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
