import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widget/club_app_bar_title.dart';
import '../matches/models/match_model.dart';
import '../matches/services/match_service.dart';
import '../news/models/news_model.dart';
import '../news/pages/news_detail_page.dart';
import '../news/services/news_services.dart';
import '../../../routing/app_routes.dart';
import '../auth/services/auth_manager.dart';
import '../matches/widgets/match_card.dart';
import '../auth/services/notificacion_service.dart';
import '../auth/pages/notificaciones_page.dart';
import 'models/patrocinador.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final MatchService _matchService = MatchService();
  final NewsService _newsService = NewsService();

  int _notificacionesNoLeidas = 0;

  late Future<MatchModel?> _futureMatch;
  late Future<List<NewsModel>> _futureNews;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();

    _futureMatch = _matchService.obtenerResultadoPrimerEquipo();

    _futureNews = _newsService.obtenerNoticias();

    _cargarContadorNotificaciones();
  }

  Future<void> _cargarContadorNotificaciones() async {
    try {
      final cantidad = await NotificacionService.contarNoLeidas();

      if (!mounted) return;

      setState(() {
        _notificacionesNoLeidas = cantidad;
      });
    } catch (_) {
      // Si falla el contador no impedimos
      // que funcione el resto de la pantalla.
    }
  }

  Future<void> actualizarContadorNotificaciones() async {
    await _cargarContadorNotificaciones();
  }

  Future<void> _recargar() async {
    setState(() {
      _futureMatch = _matchService.obtenerResultadoPrimerEquipo();

      _futureNews = _newsService.obtenerNoticias();
    });

    await Future.wait([
      _futureMatch,
      _futureNews,
      _cargarContadorNotificaciones(),
    ]);
  }

  Future<void> _abrirAreaClub() async {
    final sesionValida = await AuthManager.restaurarSesion();

    if (!mounted) return;

    if (sesionValida) {
      Navigator.pushNamed(context, AppRoutes.club);
    } else {
      Navigator.pushNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: ClubAppBarTitle(titulo: AppConstants.appName),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notificaciones',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificacionesPage(),
                    ),
                  );

                  _cargarContadorNotificaciones();
                },
              ),
              if (_notificacionesNoLeidas > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dorado,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _notificacionesNoLeidas > 99
                          ? '99+'
                          : '$_notificacionesNoLeidas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          TextButton.icon(
            onPressed: _abrirAreaClub,
            icon: const Icon(Icons.login, size: 19),
            label: const Text(
              'Área Club',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<MatchModel?>(
                future: _futureMatch,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _MatchLoadingCard();
                  }

                  if (snapshot.hasError) {
                    return _MatchErrorCard(
                      onRetry: () {
                        setState(() {
                          _futureMatch = _matchService
                              .obtenerResultadoPrimerEquipo();
                        });
                      },
                    );
                  }

                  final match = snapshot.data;

                  if (match == null) {
                    return const _MatchUnavailableCard();
                  }

                  return MatchCard(match: match, mostrarPrimerEquipo: true);
                },
              ),

              const SizedBox(height: 28),

              _buildSectionTitle('Últimas noticias'),

              const SizedBox(height: 12),

              _buildMainNews(),

              const SizedBox(height: 28),

              _buildSectionTitle('Nuestros patrocinadores'),

              const SizedBox(height: 12),

              _buildPatrocinadores(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: _colors.onSurface,
      ),
    );
  }

  Widget _buildMainNews() {
    return FutureBuilder<List<NewsModel>>(
      future: _futureNews,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'No se han podido cargar las noticias.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _futureNews = _newsService.obtenerNoticias();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final noticias = snapshot.data ?? [];

        if (noticias.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No hay noticias disponibles.')),
            ),
          );
        }

        final noticiasMostrar = noticias.take(3).toList();

        return Column(
          children: noticiasMostrar
              .map(
                (noticia) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNewsCard(noticia),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildNewsCard(NewsModel noticia) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(noticia: noticia),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (noticia.imagenUrl != null && noticia.imagenUrl!.isNotEmpty)
              Image.network(
                '${AppConfig.mediaBaseUrl}'
                '${noticia.imagenUrl}',
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildNewsImagePlaceholder();
                },
              )
            else
              // Sin imagen asociada: mismo fallback que ya usa la
              // web (noticia3.jpg) en vez de un icono generico, para
              // que ninguna noticia se quede sin imagen al mostrar.
              Image.network(
                '${AppConfig.mediaBaseUrl}/images/noticia3.jpg',
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildNewsImagePlaceholder();
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                noticia.titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsImagePlaceholder() {
    return Container(
      height: 170,
      width: double.infinity,
      color: AppColors.azulOscuro.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.article_outlined, size: 50, color: AppColors.azul),
      ),
    );
  }

  // ============================================================
  // PATROCINADORES
  // ============================================================

  Widget _buildPatrocinadores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pulsa en las imágenes para conocer más '
          'acerca de nuestros patrocinadores.',
          style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 480 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kPatrocinadores.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                return _buildPatrocinadorTile(kPatrocinadores[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPatrocinadorTile(Patrocinador patrocinador) {
    final imagenUrl =
        '${AppConfig.mediaBaseUrl}/images/${patrocinador.imagen}';

    final imagen = SizedBox.expand(
      child: Image.network(
        imagenUrl,
        fit: patrocinador.circular ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.azulOscuro.withValues(alpha: 0.08),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.azul,
            ),
          );
        },
      ),
    );

    final tarjeta = Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(patrocinador.circular ? 100 : 8),
          child: imagen,
        ),
      ),
    );

    // El patrocinador 9 (Aresala) no lleva enlace en la web:
    // se muestra sin acción de tap.
    if (patrocinador.url == null) {
      return tarjeta;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _abrirUrlPatrocinador(patrocinador.url!),
      child: tarjeta,
    );
  }

  Future<void> _abrirUrlPatrocinador(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se ha podido abrir el enlace')));
    }
  }
}

class _MatchLoadingCard extends StatelessWidget {
  const _MatchLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _MatchErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _MatchErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              const Text(
                'No se ha podido cargar el partido.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchUnavailableCard extends StatelessWidget {
  const _MatchUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay información disponible '
              'sobre el próximo partido.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
