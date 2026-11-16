import 'package:app_mutxamel_cf/features/directo/widgets/partido_visible.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// La app mínima con los textos en [locale] (castellano por defecto) y, si se pide, la animación reducida.
Widget appCon(
  Widget home, {
  Locale locale = const Locale('es'),
  bool reducirAnimaciones = false,
  GlobalKey<NavigatorState>? navegador,
}) {
  return MaterialApp(
    navigatorKey: navegador,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, hijo) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: reducirAnimaciones),
      child: hijo!,
    ),
    home: Scaffold(body: home),
  );
}

/// Pantalla de 400x900 para que todo quepa.
void pantalla(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  PartidoVisible.reiniciar();
}

/// Anota las vibraciones del sistema ("HapticFeedbackType.heavyImpact", "...lightImpact").
List<String> anotarVibraciones(WidgetTester tester) {
  final vibraciones = <String>[];

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (llamada) async {
      if (llamada.method == 'HapticFeedback.vibrate') {
        vibraciones.add(llamada.arguments.toString());
      }

      return null;
    },
  );

  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  return vibraciones;
}
