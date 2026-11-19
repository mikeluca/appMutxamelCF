import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/errores/informes_errores.dart';
import 'package:app_mutxamel_cf/core/notifications/services/permiso_notificaciones.dart';
import 'package:app_mutxamel_cf/features/auth/pages/ajustes_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Pasarela implements PasarelaInformes {
  final List<bool> recogida = [];

  @override
  Future<void> activarRecogida(bool activada) async => recogida.add(activada);

  @override
  Future<void> registrarErrorDeFlutter(FlutterErrorDetails detalles) async {}

  @override
  Future<void> registrarError(Object error, StackTrace pila) async {}

  @override
  Future<void> poner(String clave, String valor) async {}
}

void main() {
  late _Pasarela pasarela;
  late EstadoPermisoAvisos estado;
  late int ajustes;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthManager.olvidarUsuario();

    pasarela = _Pasarela();
    InformesErrores.pasarela = pasarela;
    InformesErrores.esDebug = () => false;

    estado = EstadoPermisoAvisos.concedido;
    ajustes = 0;

    final leer = PermisoNotificaciones.leerEstado;
    final abrir = PermisoNotificaciones.abrirAjustes;
    PermisoNotificaciones.leerEstado = () async => estado;
    PermisoNotificaciones.abrirAjustes = () async => ajustes++;
    addTearDown(() {
      PermisoNotificaciones.leerEstado = leer;
      PermisoNotificaciones.abrirAjustes = abrir;
    });
  });

  Future<void> pintar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AjustesPage(
          temaActual: 'system',
          onTemaChanged: (_) async {},
          idiomaActual: 'es',
          onIdiomaChanged: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'el interruptor "Enviar informes de errores" está activado por defecto',
    (tester) async {
      await pintar(tester);

      expect(find.text('Enviar informes de errores'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);
    },
  );

  testWidgets('apagarlo guarda la preferencia y desactiva la recogida', (
    tester,
  ) async {
    await pintar(tester);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(await AppPreferences.obtenerInformesErrores(), isFalse);
    expect(pasarela.recogida.last, isFalse);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(await AppPreferences.obtenerInformesErrores(), isTrue);
    expect(pasarela.recogida.last, isTrue);
  });

  testWidgets('el interruptor refleja la preferencia guardada', (tester) async {
    SharedPreferences.setMockInitialValues({'informes_errores': false});

    await pintar(tester);

    expect(tester.widget<Switch>(find.byType(Switch).last).value, isFalse);
  });

  testWidgets(
    'con el permiso de notificaciones denegado, aviso con "Abrir ajustes"',
    (tester) async {
      estado = EstadoPermisoAvisos.denegado;

      await pintar(tester);

      expect(
        find.byKey(const ValueKey('aviso-permiso-denegado')),
        findsOneWidget,
      );
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ajustes-abrir-ajustes')));
      await tester.pump();

      expect(ajustes, 1);
    },
  );

  testWidgets('con el permiso concedido o sin decidir no sale el aviso', (
    tester,
  ) async {
    await pintar(tester);

    expect(find.byKey(const ValueKey('aviso-permiso-denegado')), findsNothing);
  });
}
