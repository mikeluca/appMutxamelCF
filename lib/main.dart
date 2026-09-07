import 'package:flutter/material.dart';

import 'core/config/app_preferences.dart';
import 'core/theme/app_theme.dart';

import 'features/matches/pages/matches_page.dart';
import 'features/public/public_shell_page.dart';
import 'features/splash/splash_page.dart';

import 'routing/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/club_page.dart';
import 'features/auth/pages/mi_perfil_page.dart';
import 'features/auth/pages/mis_jugadores_page.dart';
import 'features/auth/pages/mis_partidos_page.dart';
import 'features/auth/pages/mis_equipos_page.dart';
import 'features/auth/pages/ajustes_page.dart';
import 'core/notifications/services/push_notification_service.dart';
import 'features/auth/pages/comunicaciones_page.dart';
import 'core/navigation/app_navigator.dart';
import 'core/notifications/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalNotificationService.inicializar();

  await PushNotificationService.inicializar();

  final temaGuardado = await AppPreferences.obtenerTema();

  runApp(MutxamelCfApp(temaInicial: temaGuardado));
}

class MutxamelCfApp extends StatefulWidget {
  final String temaInicial;

  const MutxamelCfApp({super.key, required this.temaInicial});

  @override
  State<MutxamelCfApp> createState() => _MutxamelCfAppState();
}

class _MutxamelCfAppState extends State<MutxamelCfApp> {
  late String _temaActual;

  @override
  void initState() {
    super.initState();

    _temaActual = widget.temaInicial;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.procesarNotificacionInicial();
    });
  }

  ThemeMode get _themeMode {
    switch (_temaActual) {
      case 'light':
        return ThemeMode.light;

      case 'dark':
        return ThemeMode.dark;

      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _cambiarTema(String tema) async {
    await AppPreferences.guardarTema(tema);

    if (!mounted) return;

    setState(() {
      _temaActual = tema;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'appMTX',
      debugShowCheckedModeBanner: false,

      navigatorKey: AppNavigator.navigatorKey,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: _themeMode,

      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (context) => const SplashPage(),
        AppRoutes.public: (context) => const PublicShellPage(),
        AppRoutes.matches: (context) => const MatchesPage(),

        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.club: (context) => const ClubPage(),
        AppRoutes.profile: (context) => const MiPerfilPage(),
        AppRoutes.players: (context) => const MisJugadoresPage(),
        AppRoutes.myMatches: (context) => const MisPartidosPage(),
        AppRoutes.myTeams: (context) => const MisEquiposPage(),
        AppRoutes.settings: (context) =>
            AjustesPage(temaActual: _temaActual, onTemaChanged: _cambiarTema),
        AppRoutes.communication: (context) => const ComunicacionesPage(),
      },
    );
  }
}
