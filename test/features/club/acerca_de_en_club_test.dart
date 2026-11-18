import 'package:app_mutxamel_cf/features/auth/pages/acerca_de_page.dart';
import 'package:app_mutxamel_cf/features/auth/pages/ajustes_page.dart';
import 'package:app_mutxamel_cf/features/club/pages/club_info_page.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pintar(
  WidgetTester tester,
  Widget home, {
  String idioma = 'es',
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(idioma),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Mutxamel CF',
      packageName: 'es.mutxamelcf.app',
      version: '1.0.11',
      buildNumber: '19',
      buildSignature: '',
    );
  });

  group('Club (parte pública)', () {
    testWidgets(
      'lleva "Acerca de" debajo de las redes sociales (sin depender de la sesión)',
      (tester) async {
        await _pintar(tester, const ClubInfoPage(mostrarMapa: false));

        final acerca = find.text('Acerca de Mutxamel C.F.');

        expect(acerca, findsOneWidget);
        expect(
          tester.getTopLeft(acerca).dy,
          greaterThan(tester.getTopLeft(find.text('Síguenos')).dy),
        );
      },
    );

    testWidgets('al pulsarlo abre la pantalla Acerca de', (tester) async {
      await _pintar(tester, const ClubInfoPage(mostrarMapa: false));

      await tester.ensureVisible(find.text('Acerca de Mutxamel C.F.'));
      await tester.tap(find.text('Acerca de Mutxamel C.F.'));
      await tester.pumpAndSettle();

      expect(find.byType(AcercaDePage), findsOneWidget);
    });

    testWidgets('sale en catalán y en inglés', (tester) async {
      await _pintar(
        tester,
        const ClubInfoPage(mostrarMapa: false),
        idioma: 'ca',
      );
      expect(find.text('Sobre Mutxamel C.F.'), findsOneWidget);

      await _pintar(
        tester,
        const ClubInfoPage(mostrarMapa: false),
        idioma: 'en',
      );
      expect(find.text('About Mutxamel C.F.'), findsOneWidget);
    });
  });

  testWidgets('Ajustes ya no lo repite', (tester) async {
    await _pintar(
      tester,
      AjustesPage(
        temaActual: 'system',
        onTemaChanged: (_) async {},
        idiomaActual: 'es',
        onIdiomaChanged: (_) async {},
      ),
    );

    expect(find.text('Acerca de Mutxamel C.F.'), findsNothing);
    expect(find.text('Información de la aplicación'), findsNothing);
  });
}
