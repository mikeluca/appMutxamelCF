import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/version/control_version.dart';
import 'package:app_mutxamel_cf/core/version/pantalla_version_obsoleta.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _remota = VersionRemota(
  minimaAndroid: '1.0.5',
  minimaIos: '1.0.7',
  recomendadaAndroid: '1.0.10',
  recomendadaIos: '1.0.12',
  urlAndroid: 'https://play.google.com/store/apps/details?id=x',
  urlIos: 'https://apps.apple.com/app/x',
);

Widget _app(Widget home) {
  return MaterialApp(
    navigatorKey: AppNavigator.navigatorKey,
    locale: const Locale('es'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void _preparar({
  String instalada = '1.0.2',
  VersionRemota? remota = _remota,
  bool ios = false,
  List<Uri>? abiertas,
  DateTime? ahora,
}) {
  ControlVersion.reiniciar();
  ControlVersion.obtenerInstalada = () async => instalada;
  ControlVersion.obtenerRemota = () async =>
      remota ?? (throw Exception('sin red'));
  ControlVersion.esIos = () => ios;
  ControlVersion.ahora = () => ahora ?? DateTime(2026, 10, 22, 10);
  ControlVersion.abrirUrl = (url) async {
    abiertas?.add(url);
    return true;
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('compararVersiones', () {
    test('compara por partes numéricas, no por texto', () {
      expect(compararVersiones('1.0.10', '1.0.9'), greaterThan(0));
      expect(compararVersiones('1.0.9', '1.0.10'), lessThan(0));
      expect(compararVersiones('2.0.0', '1.99.99'), greaterThan(0));
      expect(compararVersiones('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('iguales, con partes que faltan y con número de compilación', () {
      expect(compararVersiones('1.0.2', '1.0.2'), 0);
      expect(compararVersiones('1.0', '1.0.0'), 0);
      expect(compararVersiones('1', '1.0.0'), 0);
      expect(compararVersiones('1.0.2+6', '1.0.2'), 0);
      expect(compararVersiones('1.0.2+9', '1.0.3+1'), lessThan(0));
      expect(compararVersiones('1.0.2-beta', '1.0.2'), 0);
    });

    test('una parte que no es un número cuenta como 0', () {
      expect(compararVersiones('1.x.2', '1.0.2'), 0);
      expect(compararVersiones('', '0.0.1'), lessThan(0));
    });
  });

  group('evaluarVersion', () {
    test('anterior a la mínima de su plataforma: obligatoria', () {
      expect(
        evaluarVersion(instalada: '1.0.4', remota: _remota, esIos: false),
        EstadoVersion.obligatoria,
      );
      // La mínima de iOS es otra: 1.0.5 sirve en Android pero no en iOS.
      expect(
        evaluarVersion(instalada: '1.0.5', remota: _remota, esIos: false),
        EstadoVersion.recomendada,
      );
      expect(
        evaluarVersion(instalada: '1.0.5', remota: _remota, esIos: true),
        EstadoVersion.obligatoria,
      );
    });

    test('entre la mínima y la recomendada: solo recomendada', () {
      expect(
        evaluarVersion(instalada: '1.0.9', remota: _remota, esIos: false),
        EstadoVersion.recomendada,
      );
      expect(
        evaluarVersion(instalada: '1.0.5', remota: _remota, esIos: false),
        EstadoVersion.recomendada,
      );
    });

    test('la recomendada o una posterior: actualizada', () {
      expect(
        evaluarVersion(instalada: '1.0.10', remota: _remota, esIos: false),
        EstadoVersion.actualizada,
      );
      expect(
        evaluarVersion(instalada: '1.1.0', remota: _remota, esIos: false),
        EstadoVersion.actualizada,
      );
    });

    test('1.0.10 no es anterior a 1.0.9', () {
      const remota = VersionRemota(
        minimaAndroid: '1.0.9',
        minimaIos: '1.0.9',
        recomendadaAndroid: '1.0.9',
        recomendadaIos: '1.0.9',
        urlAndroid: '',
        urlIos: '',
      );

      expect(
        evaluarVersion(instalada: '1.0.10', remota: remota, esIos: false),
        EstadoVersion.actualizada,
      );
    });

    test('una mínima o recomendada vacía no exige nada', () {
      const remota = VersionRemota(
        minimaAndroid: '',
        minimaIos: '',
        recomendadaAndroid: '',
        recomendadaIos: '',
        urlAndroid: '',
        urlIos: '',
      );

      expect(
        evaluarVersion(instalada: '0.0.1', remota: remota, esIos: false),
        EstadoVersion.actualizada,
      );
    });
  });

  test('VersionRemota.fromJson lee los seis campos', () {
    final remota = VersionRemota.fromJson({
      'minimaAndroid': '1.0.1',
      'minimaIos': '1.0.2',
      'recomendadaAndroid': '1.0.3',
      'recomendadaIos': '1.0.4',
      'urlAndroid': 'a',
      'urlIos': 'i',
    });

    expect(remota.minima(esIos: false), '1.0.1');
    expect(remota.minima(esIos: true), '1.0.2');
    expect(remota.recomendada(esIos: false), '1.0.3');
    expect(remota.recomendada(esIos: true), '1.0.4');
    expect(remota.url(esIos: false), 'a');
    expect(remota.url(esIos: true), 'i');
  });

  group('los tres casos al comprobar', () {
    testWidgets('obsoleta: pantalla bloqueante con "Actualizar" que abre la '
        'tienda', (tester) async {
      final abiertas = <Uri>[];
      _preparar(instalada: '1.0.2', abiertas: abiertas);

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));

      final estado = await tester.runAsync(ControlVersion.comprobar);
      await tester.pumpAndSettle();

      expect(estado, EstadoVersion.obligatoria);
      expect(ControlVersion.bloqueada, isTrue);
      expect(find.byType(PantallaVersionObsoleta), findsOneWidget);
      expect(
        find.text(
          'Hay una nueva versión de la app. Actualízala para seguir usándola',
        ),
        findsOneWidget,
      );
      // Sustituye a todo lo demás: la home ya no está.
      expect(find.text('home'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('boton-actualizar-version')));
      await tester.pump();

      expect(abiertas.single.toString(), _remota.urlAndroid);
    });

    testWidgets('en iOS abre la ficha de la App Store', (tester) async {
      final abiertas = <Uri>[];
      _preparar(instalada: '1.0.2', ios: true, abiertas: abiertas);

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
      await tester.runAsync(ControlVersion.comprobar);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('boton-actualizar-version')));
      await tester.pump();

      expect(abiertas.single.toString(), _remota.urlIos);
    });

    testWidgets('la pantalla bloqueante no se puede cerrar', (tester) async {
      _preparar(instalada: '1.0.2');

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
      await tester.runAsync(ControlVersion.comprobar);
      await tester.pumpAndSettle();

      // El botón atrás del sistema no hace nada.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(PantallaVersionObsoleta), findsOneWidget);

      // Y no hay ningún botón de cerrar.
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(CloseButton), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('solo recomendada: no bloquea; avisa con "Actualizar" / "Más '
        'tarde" una vez al día', (tester) async {
      final abiertas = <Uri>[];
      _preparar(instalada: '1.0.8', abiertas: abiertas);

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
      ControlVersion.splashTerminado();

      final estado = await tester.runAsync(ControlVersion.comprobar);
      expect(estado, EstadoVersion.recomendada);
      expect(ControlVersion.bloqueada, isFalse);

      // Primer aviso del día: "Más tarde" lo cierra sin abrir la tienda.
      unawaited(ControlVersion.avisarSiProcede());
      await tester.pumpAndSettle();

      expect(find.text('Nueva versión disponible'), findsOneWidget);
      expect(find.text('Más tarde'), findsOneWidget);

      await tester.tap(find.text('Más tarde'));
      await tester.pumpAndSettle();

      expect(abiertas, isEmpty);
      expect(find.text('home'), findsOneWidget);

      // El mismo día no vuelve a salir.
      unawaited(ControlVersion.avisarSiProcede());
      await tester.pumpAndSettle();

      expect(find.text('Nueva versión disponible'), findsNothing);

      // Al día siguiente sí; "Actualizar" abre la tienda.
      ControlVersion.ahora = () => DateTime(2026, 10, 23, 10);

      unawaited(ControlVersion.avisarSiProcede());
      await tester.pumpAndSettle();

      expect(find.text('Nueva versión disponible'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Actualizar'));
      await tester.pumpAndSettle();

      expect(abiertas.single.toString(), _remota.urlAndroid);
    });

    testWidgets('no avisa mientras dura el splash', (tester) async {
      _preparar(instalada: '1.0.8');

      await tester.pumpWidget(_app(const Scaffold(body: Text('splash'))));
      await tester.runAsync(ControlVersion.comprobar);

      await ControlVersion.avisarSiProcede();
      await tester.pumpAndSettle();

      expect(find.text('Nueva versión disponible'), findsNothing);
    });

    testWidgets('actualizada: no pasa nada', (tester) async {
      _preparar(instalada: '1.0.10');

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
      ControlVersion.splashTerminado();

      final estado = await tester.runAsync(ControlVersion.comprobar);
      await ControlVersion.avisarSiProcede();
      await tester.pumpAndSettle();

      expect(estado, EstadoVersion.actualizada);
      expect(ControlVersion.bloqueada, isFalse);
      expect(find.text('Nueva versión disponible'), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(await AppPreferences.obtenerUltimoAvisoVersion(), isNull);
    });

    testWidgets('si la consulta falla (sin red), la app sigue normal', (
      tester,
    ) async {
      _preparar(remota: null);

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
      ControlVersion.splashTerminado();

      final estado = await tester.runAsync(ControlVersion.comprobar);
      await ControlVersion.avisarSiProcede();
      await tester.pumpAndSettle();

      expect(estado, isNull);
      expect(ControlVersion.bloqueada, isFalse);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('si no se puede leer la versión instalada, tampoco bloquea', (
      tester,
    ) async {
      _preparar();
      ControlVersion.obtenerInstalada = () async => throw Exception('plugin');

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));

      final estado = await tester.runAsync(ControlVersion.comprobar);

      expect(estado, isNull);
      expect(ControlVersion.bloqueada, isFalse);
    });
  });
}

void unawaited(Future<void> future) {}
