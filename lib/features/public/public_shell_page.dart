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

  void _seleccionar(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      _homeKey.currentState?.actualizarContadorNotificaciones();
    }
  }

  // Barra propia en lugar de NavigationBar: esta fuerza una altura mínima
  // y su propio SafeArea, y quedaba más alta que icono + texto. Aquí la
  // altura es exactamente la del contenido.
  Widget _buildFloatingNavigationBar() {
    final t = AppLocalizations.of(context);

    final items = [
      (Icons.home_outlined, Icons.home, t.navHome),
      (Icons.article_outlined, Icons.article, t.navNews),
      (Icons.sports_soccer_outlined, Icons.sports_soccer, t.navMatches),
      (Icons.storefront_outlined, Icons.storefront, t.navStore),
      (Icons.info_outline, Icons.info, t.navClub),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.76),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icono: items[i].$1,
                      iconoSeleccionado: items[i].$2,
                      etiqueta: items[i].$3,
                      seleccionado: i == _currentIndex,
                      onTap: () => _seleccionar(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icono,
    required this.iconoSeleccionado,
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  final IconData icono;
  final IconData iconoSeleccionado;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).navigationBarTheme;
    final estiloEtiqueta = theme.labelTextStyle?.resolve({
      if (seleccionado) WidgetState.selected,
    });

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 32,
            decoration: BoxDecoration(
              color: seleccionado ? theme.indicatorColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(seleccionado ? iconoSeleccionado : icono),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: estiloEtiqueta,
          ),
        ],
      ),
    );
  }
}
