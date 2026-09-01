import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../news/news_page.dart';

class PublicShellPage extends StatefulWidget {
  const PublicShellPage({super.key});

  @override
  State<PublicShellPage> createState() => _PublicShellPageState();
}

class _PublicShellPageState extends State<PublicShellPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
  HomePage(),
  NewsPage(),
  Center(
    child: Text(
      'Partidos',
      style: TextStyle(fontSize: 28),
    ),
  ),
  Center(
    child: Text(
      'Área Club',
      style: TextStyle(fontSize: 28),
    ),
  ),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock),
            label: 'Área Club',
          ),
        ],
      ),
    );
  }
}