import 'dart:convert';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_partido_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/equipacion_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_detalle_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_familia_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_form_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_partido_service.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/equipacion_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/justificacion_partido_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/justificacion_partido_service.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

import '../../support/http_test_helpers.dart';

// ---- dobles ---------------------------------------------------------------------------

const _primera = EquipacionModel(
  id: 1,
  nombre: 'Primera',
  camiseta: 'Blanca',
  pantalon: 'Blanco',
  medias: 'Blancas',
  colorHex: '#FFFFFF',
);

const _segunda = EquipacionModel(
  id: 2,
  nombre: 'Segunda',
  camiseta: 'Azul',
  colorHex: '#1E40AF',
);

const _entreno = EquipacionModel(id: 3, nombre: 'Entrenamiento');

class _FakeEquipaciones extends EquipacionService {
  final List<EquipacionModel> lista;
  final Object? fallo;

  _FakeEquipaciones(this.lista, {this.fallo});

  @override
  Future<List<EquipacionModel>> obtenerActivas() async {
    if (fallo != null) throw fallo!;

    return lista;
  }
}

typedef _Guardado = ({
  String metodo,
  int? equipacionId,
  int? mochilaId,
  bool indicado,
});

class _FakeConvocatorias extends ConvocatoriaService {
  final List<_Guardado> guardados = [];
  Object? fallo;

  @override
  Future<ConvocatoriaModel> crear({
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
    List<int>? invitadosIds,
    int? equipacionId,
    int? equipacionMochilaId,
  }) async {
    if (fallo != null) throw fallo!;

    guardados.add((
      metodo: 'crear',
      equipacionId: equipacionId,
      mochilaId: equipacionMochilaId,
      indicado: true,
    ));

    return _convocatoria();
  }

  @override
  Future<ConvocatoriaModel> actualizar({
    required int convocatoriaId,
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    List<int>? jugadoresIds,
    List<int>? invitadosIds,
    bool indicarEquipaje = false,
    int? equipacionId,
    int? equipacionMochilaId,
  }) async {
    if (fallo != null) throw fallo!;

    guardados.add((
      metodo: 'actualizar',
      equipacionId: equipacionId,
      mochilaId: equipacionMochilaId,
      indicado: indicarEquipaje,
    ));

    return _convocatoria();
  }
}

class _FakeJustificaciones extends JustificacionPartidoService {
  @override
  Future<List<JustificacionPartidoModel>> obtener(int partidoId) async => [];
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async => [
    PlayerModel(
      id: 100,
      nombre: 'Pablo',
      apellidos: 'Garcia',
      categoria: 'Cadete',
      equipo: 'Cadete A',
      deporte: 'F',
    ),
  ];
}

class _FakeMatchService extends MatchService {
  @override
  Future<List<MatchModel>> obtenerPartidosSinConvocatoria(
    int equipoId, {
    int? incluirPartidoId,
  }) async => [
    MatchModel(
      id: 30,
      equipoId: 5,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Pego C.F.',
      // Siempre en el futuro: un partido pasado no se puede preseleccionar.
      dia: DateTime.now().add(const Duration(days: 30)),
      hora: '11:00',
    ),
  ];
}

class _FakeFamilia extends ConvocatoriaPartidoService {
  final ConvocatoriaPartidoModel convocatoria;

  _FakeFamilia(this.convocatoria);

  @override
  Future<ConvocatoriaPartidoModel> obtener({
    required int partidoId,
    required int jugadorId,
  }) async => convocatoria;
}

ConvocatoriaModel _convocatoria({
  EquipacionModel? equipacion,
  EquipacionModel? mochila,
}) => ConvocatoriaModel(
  id: 20,
  equipoId: 5,
  equipo: 'Cadete A',
  partidoId: 30,
  rival: 'Pego C.F.',
  campo: 'Campo Municipal',
  fechaPartido: '2026-10-24',
  horaPartido: '11:00',
  horaConvocatoria: '09:30',
  lugarConvocatoria: 'Vestuarios',
  usuarioEntrenadorId: 1,
  jugadores: [ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo Garcia')],
  equipacion: equipacion,
  equipacionMochila: mochila,
);

final _equipo = PerfilEquipo(id: 5, nombre: 'Cadete A');

Future<void> _pintar(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 4000);
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
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _formulario({
  ConvocatoriaModel? convocatoria,
  required _FakeConvocatorias convocatorias,
  required EquipacionService equipaciones,
}) => ConvocatoriaFormPage(
  equipo: _equipo,
  convocatoria: convocatoria,
  partidoIdInicial: convocatoria == null ? 30 : null,
  teamService: _FakeTeamService(),
  matchService: _FakeMatchService(),
  convocatoriaService: convocatorias,
  justificacionService: _FakeJustificaciones(),
  equipacionService: equipaciones,
);

ConvocatoriaPartidoModel _paraFamilia({
  EquipacionModel? equipacion,
  EquipacionModel? mochila,
}) => ConvocatoriaPartidoModel(
  convocatoriaId: 20,
  rival: 'Pego C.F.',
  fecha: DateTime(2026, 10, 24),
  hora: '11:00',
  campo: 'Municipal',
  horaCitacion: '09:30',
  lugarCitacion: 'Vestuarios',
  convocado: true,
  equipacion: equipacion,
  equipacionMochila: mochila,
);

Future<void> _guardar(WidgetTester tester) async {
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

Future<void> _elegir(WidgetTester tester, Key selector, String texto) async {
  await tester.ensureVisible(find.byKey(selector));
  await tester.tap(find.byKey(selector));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  // ---- modelos y servicios ------------------------------------------------------------

  group('modelos', () {
    test('el equipaje lee el JSON y su color', () {
      final e = EquipacionModel.fromJson({
        'id': 2,
        'nombre': 'Segunda',
        'camiseta': 'Azul',
        'pantalon': null,
        'medias': '  ',
        'colorHex': '#1e40af',
      });

      expect(e.nombre, 'Segunda');
      expect(e.camiseta, 'Azul');
      expect(e.pantalon, isNull);
      expect(e.medias, isNull);
      expect(e.color, const Color(0xFF1E40AF));
      expect(e.tieneDetalle, isTrue);
    });

    test('un colorHex no válido o ausente no da color', () {
      expect(
        EquipacionModel.fromJson({'id': 1, 'nombre': 'A', 'colorHex': 'azul'}).color,
        isNull,
      );
      expect(EquipacionModel.fromJson({'id': 1, 'nombre': 'A'}).color, isNull);
      expect(_entreno.tieneDetalle, isFalse);
    });

    test('la convocatoria del entrenador lee equipacion y equipacionMochila o null', () {
      Map<String, dynamic> json(Map<String, dynamic> extra) => {
        'id': 20,
        'equipoId': 5,
        'partidoId': 30,
        'fechaPartido': '2026-10-24',
        'usuarioEntrenadorId': 1,
        'jugadores': [],
        ...extra,
      };

      final con = ConvocatoriaModel.fromJson(
        json({
          'equipacion': {'id': 2, 'nombre': 'Segunda', 'colorHex': '#1E40AF'},
          'equipacionMochila': {'id': 1, 'nombre': 'Primera'},
        }),
      );

      expect(con.equipacion?.nombre, 'Segunda');
      expect(con.equipacionMochila?.nombre, 'Primera');

      final sin = ConvocatoriaModel.fromJson(
        json({'equipacion': null, 'equipacionMochila': null}),
      );

      expect(sin.equipacion, isNull);
      expect(sin.equipacionMochila, isNull);
      expect(ConvocatoriaModel.fromJson(json({})).equipacion, isNull);
    });

    test('el detalle de jugador y familia lee equipacion y equipacionMochila', () {
      final con = ConvocatoriaPartidoModel.fromJson({
        'convocatoriaId': 20,
        'rival': 'Pego',
        'convocado': true,
        'convocados': [],
        'equipacion': {'id': 2, 'nombre': 'Segunda'},
        'equipacionMochila': {'id': 1, 'nombre': 'Primera'},
      });

      expect(con.equipacion?.id, 2);
      expect(con.equipacionMochila?.id, 1);

      final sin = ConvocatoriaPartidoModel.fromJson({
        'convocatoriaId': 20,
        'rival': 'Pego',
        'convocado': true,
        'equipacion': null,
        'equipacionMochila': null,
      });

      expect(sin.equipacion, isNull);
      expect(sin.equipacionMochila, isNull);
    });
  });

  group('servicios', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(<String, String>{});
      await AuthSession.guardarSesion(
        LoginResponse(token: 'tok', usuarioId: 1, email: 'a@a.com', roles: const []),
      );
    });

    final respuesta = jsonEncode({
      'id': 20,
      'equipoId': 5,
      'partidoId': 30,
      'fechaPartido': '2026-10-24',
      'usuarioEntrenadorId': 1,
      'jugadores': [],
    });

    test('pide GET /app/equipaciones', () async {
      final lista = await conMockHttp((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/app/equipaciones'));
        expect(request.headers['Authorization'], 'Bearer tok');

        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'nombre': 'Primera',
              'camiseta': 'Blanca',
              'pantalon': null,
              'medias': null,
              'colorHex': '#FFFFFF',
            },
          ]),
          200,
        );
      }, () => EquipacionService().obtenerActivas());

      expect(lista.single.nombre, 'Primera');
      expect(lista.single.color, const Color(0xFFFFFFFF));
    });

    test('crear envía siempre equipacionId, equipacionMochilaId y equipajeIndicado', () async {
      Map<String, dynamic>? cuerpo;

      await conMockHttp((request) async {
        cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(respuesta, 201);
      }, () => ConvocatoriaService().crear(
        partidoId: 30,
        horaConvocatoria: '09:30',
        lugarConvocatoria: 'Vestuarios',
        jugadoresIds: [100],
        equipacionId: 2,
        equipacionMochilaId: 1,
      ));

      expect(cuerpo!['equipacionId'], 2);
      expect(cuerpo!['equipacionMochilaId'], 1);
      expect(cuerpo!['equipajeIndicado'], isTrue);

      // Sin equipaje: los dos a null, pero siempre presentes y con la marca.
      await conMockHttp((request) async {
        cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(respuesta, 201);
      }, () => ConvocatoriaService().crear(
        partidoId: 30,
        horaConvocatoria: '09:30',
        lugarConvocatoria: 'Vestuarios',
        jugadoresIds: [100],
      ));

      expect(cuerpo!.containsKey('equipacionId'), isTrue);
      expect(cuerpo!['equipacionId'], isNull);
      expect(cuerpo!['equipacionMochilaId'], isNull);
      expect(cuerpo!['equipajeIndicado'], isTrue);
    });

    test('actualizar con indicarEquipaje envía los ids (null = quitar) y la marca', () async {
      Map<String, dynamic>? cuerpo;

      await conMockHttp((request) async {
        expect(request.method, 'PUT');
        cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(respuesta, 200);
      }, () => ConvocatoriaService().actualizar(
        convocatoriaId: 20,
        partidoId: 30,
        horaConvocatoria: '09:30',
        lugarConvocatoria: 'Vestuarios',
        indicarEquipaje: true,
        equipacionId: 2,
      ));

      expect(cuerpo!['equipacionId'], 2);
      expect(cuerpo!.containsKey('equipacionMochilaId'), isTrue);
      expect(cuerpo!['equipacionMochilaId'], isNull);
      expect(cuerpo!['equipajeIndicado'], isTrue);
    });

    test('actualizar sin indicarEquipaje no toca el equipaje (el servidor lo conserva)', () async {
      Map<String, dynamic>? cuerpo;

      await conMockHttp((request) async {
        cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(respuesta, 200);
      }, () => ConvocatoriaService().actualizar(
        convocatoriaId: 20,
        partidoId: 30,
        horaConvocatoria: '09:30',
        lugarConvocatoria: 'Vestuarios',
        invitadosIds: [],
      ));

      expect(cuerpo!.containsKey('equipajeIndicado'), isFalse);
      expect(cuerpo!.containsKey('equipacionId'), isFalse);
      expect(cuerpo!.containsKey('equipacionMochilaId'), isFalse);
    });
  });

  // ---- formulario ---------------------------------------------------------------------

  group('formulario', () {
    testWidgets('con la lista vacía oculta la sección y explica por qué', (tester) async {
      await _pintar(
        tester,
        _formulario(
          convocatorias: _FakeConvocatorias(),
          equipaciones: _FakeEquipaciones([]),
        ),
      );

      expect(find.byKey(const ValueKey('equipaje-seccion')), findsNothing);
      expect(find.text('El club aún no ha dado de alta los equipajes'), findsOneWidget);
    });

    testWidgets('sale debajo de hora y lugar, con "Sin indicar" y la mochila desactivada', (
      tester,
    ) async {
      await _pintar(
        tester,
        _formulario(
          convocatorias: _FakeConvocatorias(),
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      expect(find.byKey(const ValueKey('equipaje-seccion')), findsOneWidget);
      expect(find.text('Sin indicar'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('equipaje-seccion'))).dy,
        greaterThan(tester.getBottomLeft(find.text('Lugar de convocatoria')).dy),
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('equipaje-mochila-casilla')),
            )
            .onChanged,
        isNull,
      );
    });

    testWidgets('al elegir equipaje se ve el detalle y se puede marcar la mochila', (
      tester,
    ) async {
      await _pintar(
        tester,
        _formulario(
          convocatorias: _FakeConvocatorias(),
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      await _elegir(tester, const ValueKey('equipaje-selector-null'), 'Primera');

      expect(
        find.text('Camiseta Blanca · Pantalón Blanco · Medias Blancas'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('equipaje-mochila-casilla')));
      await tester.pumpAndSettle();

      // El selector de la mochila no ofrece el equipaje principal.
      await tester.tap(find.byKey(const ValueKey('equipaje-mochila-selector-null-1')));
      await tester.pumpAndSettle();
      expect(find.text('Primera'), findsOneWidget); // solo el del selector principal
      expect(find.text('Segunda'), findsOneWidget);
    });

    testWidgets('guardar al crear envía equipaje y mochila', (tester) async {
      final convocatorias = _FakeConvocatorias();

      await _pintar(
        tester,
        _formulario(
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Vestuarios');

      await _elegir(tester, const ValueKey('equipaje-selector-null'), 'Segunda');
      await tester.tap(find.byKey(const ValueKey('equipaje-mochila-casilla')));
      await tester.pumpAndSettle();
      await _elegir(
        tester,
        const ValueKey('equipaje-mochila-selector-null-2'),
        'Primera',
      );

      await _guardar(tester);

      expect(convocatorias.guardados.single.metodo, 'crear');
      expect(convocatorias.guardados.single.equipacionId, 2);
      expect(convocatorias.guardados.single.mochilaId, 1);
    });

    testWidgets('sin tocar nada se guarda sin equipaje (null, null)', (tester) async {
      final convocatorias = _FakeConvocatorias();

      await _pintar(
        tester,
        _formulario(
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera]),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Vestuarios');
      await _guardar(tester);

      expect(convocatorias.guardados.single.equipacionId, isNull);
      expect(convocatorias.guardados.single.mochilaId, isNull);
    });

    testWidgets('al editar carga el equipaje y envía equipajeIndicado con los ids', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatorias();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(equipacion: _segunda, mochila: _primera),
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('equipaje-mochila-casilla')),
            )
            .value,
        isTrue,
      );

      await _guardar(tester);

      final guardado = convocatorias.guardados.single;
      expect(guardado.metodo, 'actualizar');
      expect(guardado.indicado, isTrue);
      expect(guardado.equipacionId, 2);
      expect(guardado.mochilaId, 1);
    });

    testWidgets('al editar, "Sin indicar" quita el equipaje y la mochila', (tester) async {
      final convocatorias = _FakeConvocatorias();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(equipacion: _segunda, mochila: _primera),
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      await _elegir(tester, const ValueKey('equipaje-selector-2'), 'Sin indicar');

      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('equipaje-mochila-casilla')),
            )
            .value,
        isFalse,
      );

      await _guardar(tester);

      final guardado = convocatorias.guardados.single;
      expect(guardado.indicado, isTrue);
      expect(guardado.equipacionId, isNull);
      expect(guardado.mochilaId, isNull);
    });

    testWidgets('desmarcar la mochila la envía como null', (tester) async {
      final convocatorias = _FakeConvocatorias();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(equipacion: _segunda, mochila: _primera),
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('equipaje-mochila-casilla')));
      await tester.pumpAndSettle();
      await _guardar(tester);

      expect(convocatorias.guardados.single.equipacionId, 2);
      expect(convocatorias.guardados.single.mochilaId, isNull);
    });

    testWidgets('con la mochila marcada sin equipaje elegido avisa y no guarda', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatorias();

      await _pintar(
        tester,
        _formulario(
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Vestuarios');
      await _elegir(tester, const ValueKey('equipaje-selector-null'), 'Segunda');
      await tester.tap(find.byKey(const ValueKey('equipaje-mochila-casilla')));
      await tester.pumpAndSettle();
      await _guardar(tester);

      expect(convocatorias.guardados, isEmpty);
      expect(
        find.text('Elige el equipaje de la mochila o desmarca la casilla.'),
        findsOneWidget,
      );
    });

    testWidgets('un equipaje ya desactivado de la convocatoria sigue en el selector', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatorias();

      // La lista de activos ya no incluye "Entrenamiento", pero la convocatoria lo tiene.
      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(equipacion: _entreno),
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera]),
        ),
      );

      expect(find.text('Entrenamiento'), findsOneWidget);

      await _guardar(tester);

      expect(convocatorias.guardados.single.equipacionId, 3);
    });

    testWidgets('si la lista no carga, al editar se conserva el equipaje que tenía', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatorias();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(equipacion: _segunda),
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones(
            [],
            fallo: const ApiException('sin red'),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('equipaje-seccion')), findsNothing);

      await _guardar(tester);

      expect(convocatorias.guardados.single.equipacionId, 2);
    });

    testWidgets('un 400 del servidor se muestra en texto claro', (tester) async {
      final convocatorias = _FakeConvocatorias()
        ..fallo = const ApiException(
          'El equipaje Vieja está desactivado y no se puede elegir',
          statusCode: 400,
        );

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(equipacion: _segunda),
          convocatorias: convocatorias,
          equipaciones: _FakeEquipaciones([_primera, _segunda]),
        ),
      );

      await _guardar(tester);

      expect(
        find.textContaining('El equipaje Vieja está desactivado y no se puede elegir'),
        findsOneWidget,
      );
    });
  });

  // ---- detalle ------------------------------------------------------------------------

  group('detalle del entrenador', () {
    testWidgets('con equipaje y mochila los muestra con su detalle', (tester) async {
      await _pintar(
        tester,
        ConvocatoriaDetallePage(
          equipo: _equipo,
          convocatoria: _convocatoria(equipacion: _segunda, mochila: _primera),
        ),
      );

      expect(find.text('Equipaje: Segunda'), findsOneWidget);
      expect(find.text('Camiseta Azul'), findsOneWidget);
      expect(find.text('En la mochila: Primera'), findsOneWidget);
      expect(
        find.text('Camiseta Blanca · Pantalón Blanco · Medias Blancas'),
        findsOneWidget,
      );
    });

    testWidgets('sin equipaje no muestra nada', (tester) async {
      await _pintar(
        tester,
        ConvocatoriaDetallePage(equipo: _equipo, convocatoria: _convocatoria()),
      );

      expect(find.textContaining('Equipaje:'), findsNothing);
      expect(find.textContaining('mochila'), findsNothing);
    });
  });

  group('detalle de jugador, familia e invitados', () {
    Widget pagina(ConvocatoriaPartidoModel c) => ConvocatoriaFamiliaPage(
      partidoId: 30,
      jugadorId: 100,
      jugadorNombre: 'Pablo',
      jugadorApellidos: 'Garcia',
      service: _FakeFamilia(c),
    );

    testWidgets('con equipaje y mochila los muestra, con la muestra de color', (
      tester,
    ) async {
      await _pintar(tester, pagina(_paraFamilia(equipacion: _segunda, mochila: _primera)));

      expect(find.text('Equipaje: Segunda'), findsOneWidget);
      expect(find.text('En la mochila: Primera'), findsOneWidget);
      expect(find.byKey(const ValueKey('equipaje-principal')), findsOneWidget);
      expect(find.byKey(const ValueKey('equipaje-mochila')), findsOneWidget);

      final muestra = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(const ValueKey('equipaje-principal')),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.shape == BoxShape.circle);

      expect(muestra.color, const Color(0xFF1E40AF));
    });

    testWidgets('sin equipaje no muestra nada de equipaje, pero sí la ducha', (tester) async {
      await _pintar(tester, pagina(_paraFamilia()));

      expect(find.textContaining('Equipaje:'), findsNothing);
      expect(find.byKey(const ValueKey('equipaje-principal')), findsNothing);
      expect(find.text('🚿 Ducha recomendable después del partido'), findsOneWidget);
    });

    testWidgets('la ducha va siempre al final, también con equipaje', (tester) async {
      await _pintar(tester, pagina(_paraFamilia(equipacion: _segunda)));

      expect(find.text('🚿 Ducha recomendable después del partido'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('ducha-recomendable'))).dy,
        greaterThan(tester.getBottomLeft(find.byKey(const ValueKey('convocatoria-citacion'))).dy),
      );
    });

    for (final (codigo, equipaje, ducha) in [
      ('ca', 'Equipament: Segunda', '🚿 Dutxa recomanable després del partit'),
      ('en', 'Kit: Segunda', '🚿 Shower recommended after the match'),
    ]) {
      testWidgets('textos en $codigo', (tester) async {
        tester.view.physicalSize = const Size(800, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await initializeDateFormatting(codigo);

        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(codigo),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: pagina(_paraFamilia(equipacion: _segunda)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(equipaje), findsOneWidget);
        expect(find.text(ducha), findsOneWidget);
      });
    }
  });

  // ---- aviso "Cambio de equipaje" -------------------------------------------------------

  group('aviso Cambio de equipaje', () {
    final datos = {
      'tipo': 'CONVOCATORIA',
      'convocatoriaId': '20',
      'partidoId': '30',
      'fechaPartido': '2026-10-24',
    };

    tearDown(AuthManager.olvidarUsuario);

    test('se trata como el de cambio de hora: jugador y familia abren el detalle', () async {
      for (final rol in ['JUGADOR', 'FAMILIAR']) {
        await AuthManager.establecerUsuario(
          AuthUser(usuarioId: 1, email: 'a@b.c', roles: [rol]),
        );

        final equipaje = destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA',
          titulo: 'Cambio de equipaje',
          datos: datos,
        );
        final hora = destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA',
          titulo: 'Cambio en la convocatoria',
          datos: datos,
        );

        expect(equipaje, AbrirDetalleConvocatoria(30, DateTime(2026, 10, 24)));
        expect(equipaje, hora);
      }
    });

    test('y es un aviso de convocatoria que espera a la sesión al abrir en frío', () {
      expect(
        esAvisoDeConvocatoria(tipo: 'CONVOCATORIA', titulo: 'Cambio de equipaje'),
        isTrue,
      );
    });

    test('para el entrenador se comporta igual que el cambio de hora', () async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['ENTRENADOR']),
      );

      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA',
          titulo: 'Cambio de equipaje',
          datos: datos,
        ),
        destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA',
          titulo: 'Cambio en la convocatoria',
          datos: datos,
        ),
      );
    });
  });
}
