import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../club/pages/club_info_page.dart';
import '../home/home_page.dart';
import '../matches/pages/matches_page.dart';
import '../news/pages/news_page.dart';
import '../store/pages/store_page.dart';

class PublicShellPage extends StatefulWidget {
  const PublicShellPage({super.key});

  @override
  State<PublicShellPage> createState() => _PublicShellPageState();
}

class _PublicShellPageState extends State<PublicShellPage> {
  int _currentIndex = 0;

  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomePage(key: _homeKey),
      const NewsPage(),
      const MatchesPage(),
      const StorePage(),
      const ClubInfoPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // true para que el contenido se vea alrededor/detrás de la barra
      // flotante al hacer scroll. El Scaffold suma la altura de la barra
      // al MediaQuery.padding.bottom del body, y cada página lo añade al
      // padding inferior de su scroll para que el final no quede tapado
      // (p.ej. el botón "Crear pedido" de la Tienda).
      extendBody: true,

      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: _buildFloatingNavigationBar(),
    );
  }

  Widget _buildFloatingNavigationBar() {
    final t = AppLocalizations.of(context);

    // NavigationBar añade su propio SafeArea inferior, que dejaba un hueco
    // vacío bajo los iconos: se aplica fuera de la barra y se quita dentro.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.76),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });

                  if (index == 0) {
                    _homeKey.currentState?.actualizarContadorNotificaciones();
                  }
                },
                height: 64,
                elevation: 0,
                backgroundColor: Colors.transparent,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: t.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.article_outlined),
                    selectedIcon: const Icon(Icons.article),
                    label: t.navNews,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.sports_soccer_outlined),
                    selectedIcon: const Icon(Icons.sports_soccer),
                    label: t.navMatches,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.storefront_outlined),
                    selectedIcon: const Icon(Icons.storefront),
                    label: t.navStore,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.info_outline),
                    selectedIcon: const Icon(Icons.info),
                    label: t.navClub,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
