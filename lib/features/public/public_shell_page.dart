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
      // false (el valor por defecto) para que el Scaffold reserve el
      // espacio exacto que ocupa la barra de navegación flotante:
      // con extendBody: true el body se extendía por debajo de ella
      // y el contenido que llegaba hasta el final de cada página
      // (p.ej. el botón "Crear pedido" de la Tienda) quedaba tapado.
      extendBody: false,

      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: _buildFloatingNavigationBar(),
    );
  }

  Widget _buildFloatingNavigationBar() {
    final t = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.76),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
            height: 54,
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
    );
  }
}
