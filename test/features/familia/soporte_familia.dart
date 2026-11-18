import 'dart:convert';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prepara el almacenamiento de pruebas y deja la app sin usuario.
void prepararAlmacenamiento() {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
    <String, String>{},
  );
  AuthManager.olvidarUsuario();
}

/// Una sesión guardada (token) para las llamadas autenticadas.
Future<void> iniciarSesionDePrueba({List<String> roles = const []}) async {
  await AuthSession.guardarSesion(
    LoginResponse(
      token: 'jwt-prueba',
      usuarioId: 7,
      email: 'ana@example.com',
      roles: roles,
    ),
  );
}

http.Response json(Object? cuerpo, [int estado = 200]) => http.Response(
  jsonEncode(cuerpo),
  estado,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Pinta [home] en una app con las localizaciones y el tema pedidos. [tamano] es el de la pantalla lógica (por defecto
/// un iPhone pequeño), [escala] el tamaño de letra y [oscuro] el modo oscuro.
Future<void> pintarFamilia(
  WidgetTester tester,
  Widget home, {
  Size tamano = const Size(375, 667),
  double escala = 1.0,
  bool oscuro = false,
  String idioma = 'es',
  Map<String, WidgetBuilder> rutas = const {},
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      locale: Locale(idioma),
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: oscuro ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      routes: {
        '/club': (_) => const Scaffold(body: Text('AREA CLUB')),
        ...rutas,
      },
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
