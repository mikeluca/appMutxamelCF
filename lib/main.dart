import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';
import 'features/public/public_shell_page.dart';

void main() {
  runApp(const MutxamelCfApp());
}

class MutxamelCfApp extends StatelessWidget {
  const MutxamelCfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mutxamel CF',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashPage(),
        '/public': (context) => const PublicShellPage(),
      },
    );
  }
}
