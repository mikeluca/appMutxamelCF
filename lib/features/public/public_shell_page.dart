import 'package:flutter/material.dart';

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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: 'Noticias',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_soccer_outlined),
                selectedIcon: Icon(Icons.sports_soccer),
                label: 'Partidos',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Tienda',
              ),
              NavigationDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: 'Club',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
