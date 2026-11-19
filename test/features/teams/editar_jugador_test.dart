import 'dart:convert';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/pages/jugadores_equipo_page.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/features/teams/utils/posicion_jugador.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

PlayerModel _jugador(
  int id,
  String nombre, {
  int? dorsal,
  String? posicion,
  String? codigo,
  bool editable = true,
}) {
  return PlayerModel(
    id: id,
    nombre: nombre,
    apellidos: 'Garcia',
    categoria: 'Cadete',
    equipo: 'Cadete A',
    deporte: 'F',
    dorsal: dorsal,
    posicion: posicion,
    posicionCodigo: codigo,
    editable: editable,
  );
}

class _Servicio extends TeamService {
  List<PlayerModel> jugadores;
  final List<({int id, int? dorsal, String? posicion})> guardados = [];

  /// Si no es null, el siguiente guardado falla con esto.
  Object? fallo;

  _Servicio(this.jugadores);

  @override
  Future<List<PlayerModel>> obtenerJugadoresGestion(int equipoId) async =>
      jugadores;

  @override
  Future<PlayerModel> actualizarDorsalPosicion({
    required int jugadorId,
    required int? dorsal,
    required String? posicionCodigo,
  }) async {
    guardados.add((id: jugadorId, dorsal: dorsal, posicion: posicionCodigo));

    if (fallo != null) {
      final error = fallo!;
      fallo = null;
      throw error;
    }

    // Como el backend: el texto en castellano que corresponde al código.
    const textos = {
      'PORTERO': 'Portero',
      'DEFENSA': 'Defensa',
      'CENTROCAMPISTA': 'Centrocampista',
      'EXTREMO': 'Extremo',
      'DELANTERO': 'Delantero',
    };

    return _jugador(
      jugadorId,
      'x',
      dorsal: dorsal,
      posicion: textos[posicionCodigo],
      codigo: posicionCodigo,
    );
  }
}

Widget _app(Widget hijo, {String idioma = 'es'}) {
  return MaterialApp(
    locale: Locale(idioma),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: hijo,
  );
}

Future<void> _abrirPagina(
  WidgetTester tester,
  _Servicio servicio, {
  String idioma = 'es',
}) async {
  await tester.pumpWidget(
    _app(
      JugadoresEquipoPage(
        equipo: PerfilEquipo(id: 1, nombre: 'Cadete A'),
        servicio: servicio,
      ),
      idioma: idioma,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _abrirHoja(WidgetTester tester, int id) async {
  await tester.tap(find.byKey(ValueKey('editar-jugador-$id')));
  await tester.pumpAndSettle();
}

Finder get _guardar => find.byKey(const ValueKey('guardar-jugador'));

bool _guardarActivo(WidgetTester tester) =>
    tester.widget<FilledButton>(_guardar).onPressed != null;

Future<void> _elegirPosicion(WidgetTester tester, String texto) async {
  await tester.tap(find.byKey(const ValueKey('campo-posicion')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto).last);
  await tester.pumpAndSettle();
}

void main() {
  group('botón de editar', () {
    testWidgets('solo lo ven los jugadores editables', (tester) async {
      await _abrirPagina(
        tester,
        _Servicio([
          _jugador(1, 'Pablo', dorsal: 7),
          _jugador(2, 'Luis', dorsal: 9, editable: false),
        ]),
      );

      expect(find.byKey(const ValueKey('editar-jugador-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('editar-jugador-2')), findsNothing);
      expect(find.byTooltip('Editar dorsal y posición'), findsOneWidget);
    });

    testWidgets(
      'sin permiso (editable false) no sale ninguno y todo sigue igual',
      (tester) async {
        await _abrirPagina(
          tester,
          _Servicio([_jugador(1, 'Pablo', dorsal: 7, editable: false)]),
        );

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
        expect(find.text('Pablo Garcia'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
      },
    );

    testWidgets('un backend antiguo (sin "editable") tampoco lo da', (
      tester,
    ) async {
      final jugador = PlayerModel.fromJson({
        'id': 3,
        'nombre': 'Ana',
        'apellidos': 'Perez',
      });

      expect(jugador.editable, isFalse);
      expect(jugador.posicionCodigo, isNull);
    });
  });

  group('hoja de edición', () {
    testWidgets('muestra el nombre y los valores actuales', (tester) async {
      await _abrirPagina(
        tester,
        _Servicio([
          _jugador(
            1,
            'Pablo',
            dorsal: 7,
            posicion: 'Defensa',
            codigo: 'DEFENSA',
          ),
        ]),
      );
      await _abrirHoja(tester, 1);

      expect(find.text('Pablo Garcia'), findsNWidgets(2)); // lista y título
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('campo-dorsal')))
            .controller!
            .text,
        '7',
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('campo-posicion')),
          matching: find.text('Defensa'),
        ),
        findsOneWidget,
      );
      expect(_guardarActivo(tester), isFalse); // sin cambios
    });

    testWidgets('la lista de posiciones y "Sin posición"', (tester) async {
      await _abrirPagina(tester, _Servicio([_jugador(1, 'Pablo')]));
      await _abrirHoja(tester, 1);

      await tester.tap(find.byKey(const ValueKey('campo-posicion')));
      await tester.pumpAndSettle();

      for (final texto in [
        'Sin posición',
        'Portero',
        'Defensa',
        'Centrocampista',
        'Extremo',
        'Delantero',
      ]) {
        expect(find.text(texto), findsWidgets);
      }
    });

    testWidgets(
      'una posición antigua fuera de la lista sale como opción actual',
      (tester) async {
        await _abrirPagina(
          tester,
          _Servicio([_jugador(1, 'Pablo', dorsal: 7, posicion: 'DEL')]),
        );

        // En la lista se ve el texto tal cual
        expect(find.text('DEL'), findsOneWidget);

        await _abrirHoja(tester, 1);

        expect(find.text('DEL (actual)'), findsOneWidget);
        expect(find.textContaining('al guardar se quitará'), findsOneWidget);
        expect(_guardarActivo(tester), isFalse);
      },
    );

    testWidgets('validación del dorsal: 1-99 o vacío', (tester) async {
      await _abrirPagina(
        tester,
        _Servicio([_jugador(1, 'Pablo', dorsal: 7, codigo: 'DEFENSA')]),
      );
      await _abrirHoja(tester, 1);

      final campo = find.byKey(const ValueKey('campo-dorsal'));

      await tester.enterText(campo, '0');
      await tester.pump();
      expect(find.text('El dorsal debe estar entre 1 y 99'), findsOneWidget);
      expect(_guardarActivo(tester), isFalse);

      await tester.enterText(campo, '100');
      await tester.pump();
      expect(find.text('El dorsal debe estar entre 1 y 99'), findsOneWidget);
      expect(_guardarActivo(tester), isFalse);

      await tester.enterText(campo, '99');
      await tester.pump();
      expect(find.text('El dorsal debe estar entre 1 y 99'), findsNothing);
      expect(_guardarActivo(tester), isTrue);

      await tester.enterText(campo, '1');
      await tester.pump();
      expect(_guardarActivo(tester), isTrue);

      // Vacío es válido (quitar el dorsal)
      await tester.enterText(campo, '');
      await tester.pump();
      expect(find.text('El dorsal debe estar entre 1 y 99'), findsNothing);
      expect(_guardarActivo(tester), isTrue);
    });

    testWidgets('el botón Guardar sigue visible con el teclado abierto', (
      tester,
    ) async {
      await _abrirPagina(tester, _Servicio([_jugador(1, 'Pablo', dorsal: 7)]));
      await _abrirHoja(tester, 1);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final pie = tester.getRect(_guardar);
      final alto =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(
        pie.bottom,
        lessThanOrEqualTo(alto - 300 / tester.view.devicePixelRatio),
      );
      expect(pie.top, greaterThan(0));
    });
  });

  group('guardar', () {
    testWidgets('actualiza la lista sin recargar, reordena por dorsal y avisa', (
      tester,
    ) async {
      final servicio = _Servicio([
        _jugador(1, 'Pablo', dorsal: 3),
        _jugador(2, 'Luis', dorsal: 9),
        _jugador(3, 'Ana'),
      ]);

      await _abrirPagina(tester, servicio);
      await _abrirHoja(tester, 1);

      await tester.enterText(find.byKey(const ValueKey('campo-dorsal')), '20');
      await _elegirPosicion(tester, 'Portero');
      expect(_guardarActivo(tester), isTrue);

      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(servicio.guardados.single, (
        id: 1,
        dorsal: 20,
        posicion: 'PORTERO',
      ));
      // Se cierra la hoja y sale el aviso
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Datos del jugador actualizados'), findsOneWidget);

      // La lista cambia sin pedir otra vez los jugadores: el 9, el 20 y sin dorsal, en ese orden
      final y = {
        for (final id in [1, 2, 3])
          id: tester.getTopLeft(find.byKey(ValueKey('editar-jugador-$id'))).dy,
      };

      expect(y[2]!, lessThan(y[1]!));
      expect(y[1]!, lessThan(y[3]!));
      expect(find.text('Portero'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      // El nombre se conserva (la respuesta del servidor no lo sustituye)
      expect(find.text('Pablo Garcia'), findsOneWidget);
    });

    testWidgets('se puede quitar el dorsal y la posición', (tester) async {
      final servicio = _Servicio([
        _jugador(1, 'Pablo', dorsal: 7, posicion: 'Defensa', codigo: 'DEFENSA'),
      ]);

      await _abrirPagina(tester, servicio);
      await _abrirHoja(tester, 1);

      await tester.enterText(find.byKey(const ValueKey('campo-dorsal')), '');
      await _elegirPosicion(tester, 'Sin posición');

      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(servicio.guardados.single, (id: 1, dorsal: null, posicion: null));
      expect(find.text('Defensa'), findsNothing);
      expect(find.text('7'), findsNothing);
      expect(find.text('Datos del jugador actualizados'), findsOneWidget);
    });

    testWidgets(
      'un dorsal repetido (409) enseña el mensaje del servidor en la hoja',
      (tester) async {
        final servicio = _Servicio([_jugador(1, 'Pablo', dorsal: 3)])
          ..fallo = const ApiException(
            'El dorsal 7 ya lo tiene Luis Garcia',
            statusCode: 409,
          );

        await _abrirPagina(tester, servicio);
        await _abrirHoja(tester, 1);

        await tester.enterText(find.byKey(const ValueKey('campo-dorsal')), '7');
        await tester.pump();
        await tester.tap(_guardar);
        await tester.pumpAndSettle();

        expect(
          find.text('El dorsal 7 ya lo tiene Luis Garcia'),
          findsOneWidget,
        );
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Datos del jugador actualizados'), findsNothing);
        // Se puede corregir y volver a guardar
        expect(_guardarActivo(tester), isTrue);

        await tester.enterText(find.byKey(const ValueKey('campo-dorsal')), '8');
        await tester.pump();
        expect(find.text('El dorsal 7 ya lo tiene Luis Garcia'), findsNothing);

        await tester.tap(_guardar);
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Datos del jugador actualizados'), findsOneWidget);
      },
    );

    testWidgets('sin permiso (403) lo dice con texto claro', (tester) async {
      final servicio = _Servicio([_jugador(1, 'Pablo', dorsal: 3)])
        ..fallo = const ApiException('No tienes permiso', statusCode: 403);

      await _abrirPagina(tester, servicio);
      await _abrirHoja(tester, 1);
      await tester.enterText(find.byKey(const ValueKey('campo-dorsal')), '5');
      await tester.pump();
      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('error-jugador')),
          matching: find.text('No tienes permiso'),
        ),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('sin conexión lo dice dentro de la hoja', (tester) async {
      final servicio = _Servicio([_jugador(1, 'Pablo', dorsal: 3)])
        ..fallo = const ApiException('No hay conexión a internet.');

      await _abrirPagina(tester, servicio);
      await _abrirHoja(tester, 1);
      await tester.enterText(find.byKey(const ValueKey('campo-dorsal')), '5');
      await tester.pump();
      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('error-jugador')), findsOneWidget);
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byKey(const ValueKey('error-jugador'))),
          ).connectionError,
        ),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('posición traducida', () {
    test('el código se traduce a es, ca y en', () async {
      const esperado = {
        'es': ['Portero', 'Defensa', 'Centrocampista', 'Extremo', 'Delantero'],
        'ca': ['Porter', 'Defensa', 'Centrecampista', 'Extrem', 'Davanter'],
        'en': ['Goalkeeper', 'Defender', 'Midfielder', 'Winger', 'Forward'],
      };

      for (final entrada in esperado.entries) {
        final t = await AppLocalizations.delegate.load(Locale(entrada.key));

        expect([
          for (final c in posicionesJugador) nombrePosicion(t, c),
        ], entrada.value);
      }
    });

    test('sin código sale el texto tal cual, y sin nada, null', () async {
      final t = await AppLocalizations.delegate.load(const Locale('ca'));

      expect(textoPosicion(t, codigo: null, texto: 'DEL'), 'DEL');
      expect(textoPosicion(t, codigo: 'LATERAL', texto: 'Lateral'), 'Lateral');
      expect(textoPosicion(t, codigo: 'PORTERO', texto: 'portero'), 'Porter');
      expect(textoPosicion(t, codigo: null, texto: '  '), isNull);
      expect(textoPosicion(t, codigo: null, texto: null), isNull);
    });

    testWidgets('la lista usa el código traducido al idioma de la app', (
      tester,
    ) async {
      await _abrirPagina(
        tester,
        _Servicio([
          _jugador(
            1,
            'Pablo',
            dorsal: 7,
            posicion: 'portero',
            codigo: 'PORTERO',
          ),
          _jugador(2, 'Luis', dorsal: 9, posicion: 'DEL'),
        ]),
        idioma: 'en',
      );

      expect(find.text('Goalkeeper'), findsOneWidget);
      expect(find.text('portero'), findsNothing);
      // Un valor fuera de la lista se queda con su texto
      expect(find.text('DEL'), findsOneWidget);
    });
  });

  group('TeamService.actualizarDorsalPosicion', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        <String, String>{},
      );
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const ['ENTRENADOR'],
        ),
      );
    });

    test(
      'hace PUT con los dos campos (también los nulos) y lee el jugador',
      () async {
        final jugador = await conMockHttp(
          (request) async {
            expect(request.method, 'PUT');
            expect(
              request.url.path,
              endsWith('/app/jugadores/21/dorsal-posicion'),
            );
            expect(request.headers['Authorization'], 'Bearer tok');
            expect(jsonDecode(request.body), {'dorsal': 7, 'posicion': null});

            return http.Response(
              jsonEncode({
                'id': 21,
                'nombre': 'Pablo',
                'apellidos': 'Garcia',
                'dorsal': 7,
                'posicion': null,
                'posicionCodigo': null,
                'editable': true,
              }),
              200,
            );
          },
          () => TeamService().actualizarDorsalPosicion(
            jugadorId: 21,
            dorsal: 7,
            posicionCodigo: null,
          ),
        );

        expect(jugador.dorsal, 7);
        expect(jugador.editable, isTrue);
      },
    );

    test(
      'un 409 llega como ApiException con el mensaje del servidor',
      () async {
        await expectLater(
          conMockHttp(
            (request) async =>
                http.Response('El dorsal 7 ya lo tiene Luis Garcia', 409),
            () => TeamService().actualizarDorsalPosicion(
              jugadorId: 21,
              dorsal: 7,
              posicionCodigo: 'DEFENSA',
            ),
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 409)
                .having(
                  (e) => e.message,
                  'message',
                  'El dorsal 7 ya lo tiene Luis Garcia',
                ),
          ),
        );
      },
    );
  });
}
