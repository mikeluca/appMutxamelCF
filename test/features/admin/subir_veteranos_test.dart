import 'dart:convert';
import 'dart:typed_data';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/utils/selector_ficheros.dart';
import 'package:app_mutxamel_cf/features/admin/models/ffcv_model.dart';
import 'package:app_mutxamel_cf/features/admin/pages/subir_datos_ffcv_page.dart';
import 'package:app_mutxamel_cf/features/admin/services/ffcv_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
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

import '../../support/http_test_helpers.dart';

class _Selector implements SelectorFicheros {
  FicheroElegido? siguiente;
  final List<List<String>> pedidos = [];

  @override
  Future<FicheroElegido?> elegir({required List<String> extensiones}) async {
    pedidos.add(extensiones);

    return siguiente;
  }
}

class _Fake extends FfcvService {
  Object? fallo;
  final List<String> llamadas = [];

  @override
  Future<PrevisualizacionVeteranosModel> previsualizarVeteranos({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    llamadas.add('previsualizar:$nombreArchivo:${bytes.length}');
    if (fallo != null) throw fallo!;

    return _previa();
  }

  @override
  Future<ResultadoVeteranosModel> confirmarVeteranos() async {
    llamadas.add('confirmar');
    if (fallo != null) throw fallo!;

    return const ResultadoVeteranosModel(
      competiciones: 2,
      filas: 15,
      nombres: ['Liga Veteranos Ciudad de Alicante', 'Copa grupo C'],
      clubesCreados: ['UA VETERANOS'],
    );
  }
}

PrevisualizacionVeteranosModel _previa() =>
    PrevisualizacionVeteranosModel.fromJson({
      'equipoId': 9,
      'equipoNombre': 'Veteranos',
      'competiciones': [
        {
          'nombre': 'Liga Veteranos Ciudad de Alicante',
          'jornada': 5,
          'posicionNuestra': 2,
          'tabla': [
            {
              'posicion': 1,
              'equipo': 'UA VETERANOS',
              'pj': 5,
              'pg': 4,
              'pe': 1,
              'pp': 0,
              'gf': 10,
              'gc': 3,
              'dif': 7,
              'puntos': 13,
              'esNuestro': false,
            },
            {
              'posicion': 2,
              'equipo': 'MUTXAMEL C.F.V',
              'pj': 5,
              'pg': 3,
              'pe': 1,
              'pp': 1,
              'gf': 8,
              'gc': 5,
              'dif': 3,
              'puntos': 10,
              'esNuestro': true,
            },
          ],
          'clubesACrear': ['UA VETERANOS'],
        },
        {
          'nombre': 'Copa grupo C',
          'jornada': 2,
          'posicionNuestra': 3,
          'tabla': [
            {'posicion': 1, 'equipo': 'SPORTING OKTA', 'esNuestro': false},
            {'posicion': 2, 'equipo': 'MUTXAMEL C.F.V', 'esNuestro': true},
          ],
          'clubesACrear': ['SPORTING OKTA'],
        },
      ],
      'clubesACrear': ['UA VETERANOS', 'SPORTING OKTA'],
    });

Widget _app(Widget home) => MaterialApp(
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

Future<void> _abrir(
  WidgetTester tester,
  _Fake servicio,
  _Selector selector, {
  Size tamano = const Size(800, 3200),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _app(
      SubirDatosFfcvPage(
        servicio: servicio,
        selector: selector,
        equipos: () async => const [],
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('pestana-veteranos')));
  await tester.pumpAndSettle();
}

FicheroElegido _html() => FicheroElegido(
  nombre: 'Score Table.html',
  bytes: Uint8List.fromList([1, 2, 3]),
);

Future<void> _elegirYPrevisualizar(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'el tercer apartado explica cómo conseguir el fichero y pide html',
    (tester) async {
      final selector = _Selector()..siguiente = _html();

      await _abrir(tester, _Fake(), selector);

      expect(
        find.text(
          'Abre ligaveteranosalicante.es/scoretable en el navegador, guárdala como página web y súbela aquí',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
      await tester.pumpAndSettle();

      expect(selector.pedidos.single, ['html', 'htm']);
      expect(find.text('Score Table.html'), findsOneWidget);
    },
  );

  testWidgets(
    'elegir, previsualizar (cada competición, el Mutxamel destacado y los clubes nuevos) y confirmar',
    (tester) async {
      final servicio = _Fake();
      final selector = _Selector()..siguiente = _html();

      await _abrir(tester, servicio, selector);
      await _elegirYPrevisualizar(tester);

      expect(servicio.llamadas, ['previsualizar:Score Table.html:3']);
      expect(
        find.text('2 clasificación(es) en las que aparece el Mutxamel'),
        findsOneWidget,
      );
      expect(find.text('Liga Veteranos Ciudad de Alicante'), findsOneWidget);
      expect(find.text('Copa grupo C'), findsOneWidget);
      expect(find.text('Jornada 5 (máximo de PJ)'), findsOneWidget);
      expect(find.text('MUTXAMEL C.F.V'), findsNWidgets(2));

      // La fila nuestra, destacada (solo una por tabla).
      final destacadas = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final d = c.decoration;

            return c.key is ValueKey &&
                (c.key as ValueKey).value.toString().startsWith(
                  'fila-veteranos',
                ) &&
                d is BoxDecoration &&
                d.border != null;
          });
      expect(destacadas, hasLength(2));

      // Clubes nuevos, destacados.
      expect(find.byKey(const ValueKey('ffcv-clubes-nuevos')), findsOneWidget);
      expect(find.text('SPORTING OKTA'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Se guardarán 2 clasificaciones'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(servicio.llamadas, hasLength(1));

      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar-dialogo')));
      await tester.pumpAndSettle();

      expect(servicio.llamadas.last, 'confirmar');
      expect(
        find.text('2 clasificación(es) guardada(s), 15 filas.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ffcv-clubes-creados')), findsOneWidget);
      expect(find.byKey(const ValueKey('ffcv-confirmar')), findsNothing);
    },
  );

  testWidgets('un fichero que no es la página da el error del servidor', (
    tester,
  ) async {
    final servicio = _Fake()
      ..fallo = const ApiException(
        'No parece la clasificación de la Liga Veteranos Ciudad de Alicante',
        statusCode: 400,
      );

    await _abrir(tester, servicio, _Selector()..siguiente = _html());
    await _elegirYPrevisualizar(tester);

    expect(
      find.text(
        'No parece la clasificación de la Liga Veteranos Ciudad de Alicante',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ffcv-confirmar')), findsNothing);
  });

  testWidgets('quien no es administrador recibe el 403 del servidor', (
    tester,
  ) async {
    final servicio = _Fake()
      ..fallo = const ApiException(
        'Solo un administrador puede importar los datos de la FFCV',
        statusCode: 403,
      );

    await _abrir(tester, servicio, _Selector()..siguiente = _html());
    await _elegirYPrevisualizar(tester);

    expect(
      find.text('Solo un administrador puede importar los datos de la FFCV'),
      findsOneWidget,
    );
  });

  testWidgets(
    'con letra grande en un iPhone pequeño y en oscuro no se desborda',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _abrir(
        tester,
        _Fake(),
        _Selector()..siguiente = _html(),
        tamano: const Size(320, 568),
      );
      await _elegirYPrevisualizar(tester);

      expect(tester.takeException(), isNull);
    },
  );

  group('FfcvService', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        <String, String>{},
      );
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const ['ADMIN_APP'],
        ),
      );
    });

    test('previsualiza subiendo el html y confirma sin cuerpo', () async {
      final previa = await conMockHttp(
        (request) async {
          expect(request.method, 'POST');
          expect(
            request.url.path,
            endsWith('/app/admin/ffcv/veteranos/previsualizar'),
          );
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          expect(request.body, contains('filename="score.html"'));

          return http.Response(
            jsonEncode({'equipoNombre': 'Veteranos', 'competiciones': []}),
            200,
          );
        },
        () => FfcvService().previsualizarVeteranos(
          bytes: [1, 2],
          nombreArchivo: 'score.html',
        ),
      );

      expect(previa.equipoNombre, 'Veteranos');

      final resultado = await conMockHttp((request) async {
        expect(
          request.url.path,
          endsWith('/app/admin/ffcv/veteranos/confirmar'),
        );
        expect(request.body, isEmpty);

        return http.Response(
          jsonEncode({'competiciones': 2, 'filas': 15}),
          200,
        );
      }, () => FfcvService().confirmarVeteranos());

      expect(resultado.filas, 15);
    });
  });
}
