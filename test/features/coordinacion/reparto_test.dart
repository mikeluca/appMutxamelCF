import 'dart:convert';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/coordinacion/models/reparto_model.dart';
import 'package:app_mutxamel_cf/features/coordinacion/pages/alta_prueba_page.dart';
import 'package:app_mutxamel_cf/features/coordinacion/pages/reparto_page.dart';
import 'package:app_mutxamel_cf/features/coordinacion/services/reparto_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

JugadorRepartoModel _jugador(
  int id,
  String nombre, {
  int? dorsal,
  String estado = 'CONFIRMADO',
  bool definitivo = false,
}) => JugadorRepartoModel(
  jugadorId: id,
  nombre: nombre,
  anioNacimiento: 2015,
  dorsal: dorsal,
  estado: estado,
  equipoDefinitivo: definitivo,
);

RepartoCategoriaModel _reparto({List<JugadorRepartoModel>? porAsignar}) {
  return RepartoCategoriaModel(
    categoria: 'Alevín',
    pretemporada: const EquipoRepartoModel(
      equipoId: 10,
      nombre: 'Alevín (Pretemporada)',
      grupo: 'P',
      modalidad: 'F8',
      activo: true,
    ),
    porAsignar:
        porAsignar ??
        [
          _jugador(1, 'Ana Pérez'),
          _jugador(2, 'Biel Gil', estado: 'PRUEBA'),
          _jugador(4, 'Carla Sanz'),
        ],
    equipos: [
      EquipoRepartoModel(
        equipoId: 11,
        nombre: 'Alevín A',
        grupo: 'A',
        modalidad: 'F8',
        activo: true,
        jugadores: [_jugador(3, 'Eva Ruiz', dorsal: 9, definitivo: true)],
      ),
      const EquipoRepartoModel(
        equipoId: 12,
        nombre: 'Alevín B',
        grupo: 'B',
        modalidad: 'F8',
        activo: false,
      ),
    ],
  );
}

class _FakeReparto extends RepartoService {
  RepartoCategoriaModel reparto = _reparto();
  List<String> categorias = ['Alevín', 'Cadete'];

  /// Si es true, la primera asignación con pruebas responde PRUEBAS_SIN_CONFIRMAR.
  bool exigirConfirmacion = true;
  Object? falloAlAsignar;
  Object? falloAlDevolver;
  Object? falloAlCrear;
  Object? falloAlPedirCategorias;
  List<String> avisos = [];

  final List<String> repartosPedidos = [];
  final List<({int equipoId, List<AsignacionJugador> jugadores, bool confirmar})>
  asignaciones = [];
  final List<List<int>> devoluciones = [];
  final List<String> equiposCreados = [];

  @override
  Future<List<String>> obtenerCategorias() async {
    if (falloAlPedirCategorias != null) throw falloAlPedirCategorias!;

    return categorias;
  }

  @override
  Future<RepartoCategoriaModel> obtenerReparto(String categoria) async {
    repartosPedidos.add(categoria);

    return reparto;
  }

  @override
  Future<ResultadoRepartoModel> asignar({
    required int equipoId,
    required List<AsignacionJugador> jugadores,
    bool confirmarPruebas = false,
  }) async {
    asignaciones.add((
      equipoId: equipoId,
      jugadores: jugadores,
      confirmar: confirmarPruebas,
    ));

    if (falloAlAsignar != null) throw falloAlAsignar!;

    final pruebas = [
      for (final j in jugadores)
        for (final p in reparto.porAsignar)
          if (p.jugadorId == j.jugadorId && p.esPrueba) p.nombre,
    ];

    if (pruebas.isNotEmpty && !confirmarPruebas && exigirConfirmacion) {
      throw PruebasSinConfirmarException(pruebas);
    }

    return ResultadoRepartoModel(
      asignados: jugadores.length,
      avisos: avisos,
      pruebasConfirmadas: pruebas,
    );
  }

  @override
  Future<ResultadoDevolucionModel> devolver(List<int> jugadorIds) async {
    devoluciones.add(jugadorIds);

    if (falloAlDevolver != null) throw falloAlDevolver!;

    return ResultadoDevolucionModel(devueltos: jugadorIds.length);
  }

  @override
  Future<EquipoRepartoModel> crearEquipo(String categoria) async {
    equiposCreados.add(categoria);

    if (falloAlCrear != null) throw falloAlCrear!;

    return const EquipoRepartoModel(
      equipoId: 40,
      nombre: 'Alevín C',
      grupo: 'C',
      modalidad: 'F8',
      activo: false,
    );
  }
}

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

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _elegirEquipo(WidgetTester tester, String nombre) async {
  await tester.tap(find.byKey(const ValueKey('reparto-equipo-destino')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nombre).last);
  await tester.pumpAndSettle();
}

Future<void> _marcar(WidgetTester tester, int jugadorId) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(ValueKey('reparto-jugador-$jugadorId')),
      matching: find.byType(Checkbox),
    ),
  );
  await tester.pump();
}

Future<void> _dorsal(WidgetTester tester, int jugadorId, String texto) async {
  await tester.enterText(
    find.byKey(ValueKey('reparto-dorsal-$jugadorId')),
    texto,
  );
  await tester.pump();
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  group('modelo', () {
    test('lee el reparto de una categoría', () {
      final r = RepartoCategoriaModel.fromJson({
        'categoria': 'Alevín',
        'pretemporada': {
          'equipoId': 10,
          'nombre': 'Alevín (Pretemporada)',
          'grupo': 'P',
          'modalidad': 'F8',
          'activo': true,
          'jugadores': [],
        },
        'porAsignar': [
          {
            'jugadorId': 2,
            'nombre': 'Biel Gil',
            'anioNacimiento': 2015,
            'dorsal': null,
            'estado': 'PRUEBA',
            'equipoDefinitivo': false,
          },
        ],
        'equipos': [
          {
            'equipoId': 11,
            'nombre': 'Alevín A',
            'grupo': 'A',
            'modalidad': 'F8',
            'activo': false,
            'jugadores': [
              {
                'jugadorId': 3,
                'nombre': 'Eva Ruiz',
                'anioNacimiento': 2014,
                'dorsal': 9,
                'estado': 'CONFIRMADO',
                'equipoDefinitivo': true,
              },
            ],
          },
        ],
      });

      expect(r.categoria, 'Alevín');
      expect(r.pretemporada!.nombre, 'Alevín (Pretemporada)');
      expect(r.porAsignar.single.esPrueba, isTrue);
      expect(r.porAsignar.single.dorsal, isNull);
      expect(r.equipos.single.activo, isFalse);
      expect(r.equipos.single.jugadores.single.dorsal, 9);
    });

    test('una categoría sin pretemporada llega con pretemporada null', () {
      final r = RepartoCategoriaModel.fromJson({
        'categoria': 'Cadete',
        'pretemporada': null,
        'porAsignar': [],
        'equipos': [],
      });

      expect(r.pretemporada, isNull);
    });

    test('lee los resultados de asignar y de devolver', () {
      final a = ResultadoRepartoModel.fromJson({
        'asignados': 2,
        'avisos': ['El dorsal 7 está repetido'],
        'equipoActivado': true,
        'pretemporadaVaciada': false,
        'pruebasConfirmadas': ['Biel Gil'],
      });
      final d = ResultadoDevolucionModel.fromJson({
        'devueltos': 2,
        'pretemporadaReactivada': true,
      });

      expect(a.asignados, 2);
      expect(a.avisos, ['El dorsal 7 está repetido']);
      expect(a.equipoActivado, isTrue);
      expect(a.pruebasConfirmadas, ['Biel Gil']);
      expect(d.devueltos, 2);
      expect(d.pretemporadaReactivada, isTrue);
    });
  });

  group('dorsales repetidos', () {
    final equipo = EquipoRepartoModel(
      equipoId: 11,
      nombre: 'Alevín A',
      activo: true,
      jugadores: [_jugador(3, 'Eva Ruiz', dorsal: 9, definitivo: true)],
    );

    test('avisa de los que repiten el dorsal de alguien del equipo', () {
      expect(dorsalesRepetidos({1: 9, 2: 7}, equipo), {1});
    });

    test('avisa de los que repiten entre sí', () {
      expect(dorsalesRepetidos({1: 7, 2: 7, 4: 8}, equipo), {1, 2});
    });

    test('sin dorsal o sin coincidencias no avisa', () {
      expect(dorsalesRepetidos({1: null, 2: null}, equipo), isEmpty);
      expect(dorsalesRepetidos({1: 5, 2: 6}, equipo), isEmpty);
      expect(dorsalesRepetidos({1: 5}, null), isEmpty);
    });
  });

  group('servicio', () {
    Future<void> iniciarSesion() => AuthSession.guardarSesion(
      LoginResponse(token: 't', usuarioId: 1, email: 'a@a.com', roles: const []),
    );

    test('categorías y reparto con la categoría codificada en la URL', () async {
      await iniciarSesion();

      final categorias = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/reparto/categorias'));
        expect(request.headers['Authorization'], 'Bearer t');
        return http.Response(jsonEncode(['Alevín', 'Cadete']), 200);
      }, () => RepartoService().obtenerCategorias());

      expect(categorias, ['Alevín', 'Cadete']);

      final reparto = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/reparto'));
        expect(request.url.queryParameters['categoria'], 'Alevín');
        return http.Response(
          jsonEncode({
            'categoria': 'Alevín',
            'pretemporada': null,
            'porAsignar': [],
            'equipos': [],
          }),
          200,
        );
      }, () => RepartoService().obtenerReparto('Alevín'));

      expect(reparto.categoria, 'Alevín');
    });

    test('asignar envía el cuerpo del contrato', () async {
      await iniciarSesion();

      final resultado = await conMockHttp((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/app/reparto/asignar'));
        expect(jsonDecode(request.body), {
          'equipoId': 11,
          'jugadores': [
            {'jugadorId': 1, 'dorsal': 7},
            {'jugadorId': 2, 'dorsal': null},
          ],
          'confirmarPruebas': false,
        });
        return http.Response(
          jsonEncode({
            'asignados': 2,
            'avisos': [],
            'equipoActivado': true,
            'pretemporadaVaciada': false,
            'pruebasConfirmadas': [],
          }),
          200,
        );
      }, () => RepartoService().asignar(
        equipoId: 11,
        jugadores: const [AsignacionJugador(1, 7), AsignacionJugador(2, null)],
      ));

      expect(resultado.asignados, 2);
    });

    test('el 409 PRUEBAS_SIN_CONFIRMAR se convierte en su excepción', () async {
      await iniciarSesion();

      await expectLater(
        conMockHttp(
          (request) async => http.Response(
            jsonEncode({
              'codigo': 'PRUEBAS_SIN_CONFIRMAR',
              'mensaje': 'Hay jugadores de prueba',
              'pruebas': ['Biel Gil'],
            }),
            409,
          ),
          () => RepartoService().asignar(
            equipoId: 11,
            jugadores: const [AsignacionJugador(2, 3)],
          ),
        ),
        throwsA(
          isA<PruebasSinConfirmarException>().having(
            (e) => e.pruebas,
            'pruebas',
            ['Biel Gil'],
          ),
        ),
      );
    });

    test('otro 409 sigue siendo una ApiException', () async {
      await iniciarSesion();

      await expectLater(
        conMockHttp(
          (request) async => http.Response('No hay temporada activa.', 409),
          () => RepartoService().asignar(
            equipoId: 11,
            jugadores: const [AsignacionJugador(1, 3)],
          ),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('devolver, crear equipo y alta de prueba usan sus rutas', () async {
      await iniciarSesion();

      final devolucion = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/reparto/devolver'));
        expect(jsonDecode(request.body), {
          'jugadorIds': [1, 3],
        });
        return http.Response(
          jsonEncode({'devueltos': 2, 'pretemporadaReactivada': false}),
          200,
        );
      }, () => RepartoService().devolver([1, 3]));
      expect(devolucion.devueltos, 2);

      final equipo = await conMockHttp((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/app/reparto/equipos'));
        expect(request.url.queryParameters['categoria'], 'Alevín');
        return http.Response(
          jsonEncode({
            'equipoId': 40,
            'nombre': 'Alevín C',
            'grupo': 'C',
            'modalidad': 'F8',
            'activo': false,
            'jugadores': [],
          }),
          201,
        );
      }, () => RepartoService().crearEquipo('Alevín'));
      expect(equipo.nombre, 'Alevín C');
      expect(equipo.activo, isFalse);

      final prueba = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/pruebas'));
        expect(jsonDecode(request.body), {
          'nombre': 'Luis',
          'apellidos': 'Gil',
          'anioNacimiento': 2016,
        });
        return http.Response(
          jsonEncode({
            'jugadorId': 99,
            'categoria': 'Alevín',
            'temporadaId': 7,
            'estado': 'PRUEBA',
          }),
          201,
        );
      }, () => RepartoService().altaPrueba(
        nombre: 'Luis',
        apellidos: 'Gil',
        anioNacimiento: 2016,
      ));
      expect(prueba.jugadorId, 99);
      expect(prueba.categoria, 'Alevín');
    });
  });

  group('pantalla de reparto', () {
    testWidgets('muestra la categoría, los jugadores por asignar y los equipos', (
      tester,
    ) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(servicio.repartosPedidos, ['Alevín']);
      expect(find.text('Por asignar (3)'), findsOneWidget);
      expect(find.text('Equipo de pretemporada: Alevín (Pretemporada)'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Prueba'), findsOneWidget);
      expect(find.text('Eva Ruiz'), findsOneWidget);
      expect(find.text('#9'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('sin categorías lo dice con un texto claro', (tester) async {
      final servicio = _FakeReparto()..categorias = [];

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay categorías con equipos en la temporada activa.'),
        findsOneWidget,
      );
    });

    testWidgets('un 403 al cargar dice que no hay permiso y ofrece reintentar', (
      tester,
    ) async {
      final servicio = _FakeReparto()
        ..falloAlPedirCategorias = const ApiException('no', statusCode: 403);

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('un 409 al cargar explica que falta la temporada', (tester) async {
      final servicio = _FakeReparto()
        ..falloAlPedirCategorias = const ApiException('x', statusCode: 409);

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Todavía no hay una temporada disponible'),
        findsOneWidget,
      );
    });

    testWidgets('cambiar de categoría pide su reparto', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reparto-categoria')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadete').last);
      await tester.pumpAndSettle();

      expect(servicio.repartosPedidos, ['Alevín', 'Cadete']);
    });

    testWidgets('asigna varios jugadores a un equipo con el dorsal de cada uno', (
      tester,
    ) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await _marcar(tester, 1);
      await _marcar(tester, 4);
      await _dorsal(tester, 1, '7');
      await _dorsal(tester, 4, '10');
      await _elegirEquipo(tester, 'Alevín B');

      expect(find.text('Asignar seleccionados (2)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pumpAndSettle();

      final asignacion = servicio.asignaciones.single;
      expect(asignacion.equipoId, 12);
      expect(asignacion.confirmar, isFalse);
      expect(
        asignacion.jugadores.map((j) => (j.jugadorId, j.dorsal)).toList(),
        containsAll([(1, 7), (4, 10)]),
      );
      expect(find.text('2 jugadores asignados'), findsOneWidget);
      // Después de asignar se vuelve a pedir el reparto.
      expect(servicio.repartosPedidos, hasLength(2));
    });

    testWidgets('avisa si el dorsal se repite entre los elegidos o con el equipo', (
      tester,
    ) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(_app(RepartoPage(servicio: _FakeReparto())));
      await tester.pumpAndSettle();

      await _marcar(tester, 1);
      await _marcar(tester, 4);
      await _elegirEquipo(tester, 'Alevín A');

      // 9 es el dorsal de Eva Ruiz en el Alevín A.
      await _dorsal(tester, 1, '9');
      await _dorsal(tester, 4, '8');

      expect(find.text('Dorsal repetido'), findsOneWidget);

      // Entre ellos.
      await _dorsal(tester, 1, '8');

      expect(find.text('Dorsal repetido'), findsNWidgets(2));

      await _dorsal(tester, 1, '5');

      expect(find.text('Dorsal repetido'), findsNothing);
    });

    testWidgets('sin jugadores o sin equipo elegido no asigna y lo dice', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pump();
      expect(find.text('Selecciona al menos un jugador.'), findsOneWidget);

      await _marcar(tester, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pump();
      expect(find.text('Elige un equipo'), findsWidgets);

      expect(servicio.asignaciones, isEmpty);
    });

    testWidgets('un dorsal fuera de 0 a 99 no se envía', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await _marcar(tester, 1);
      await _dorsal(tester, 1, '100');
      await _elegirEquipo(tester, 'Alevín B');
      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pump();

      expect(find.text('El dorsal tiene que estar entre 0 y 99.'), findsOneWidget);
      expect(servicio.asignaciones, isEmpty);
    });

    testWidgets('con un jugador de prueba pide confirmación y repite con '
        'confirmarPruebas: true', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await _marcar(tester, 2);
      await _elegirEquipo(tester, 'Alevín A');
      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pumpAndSettle();

      expect(find.text('Jugadores de prueba'), findsOneWidget);
      expect(find.text('Biel Gil pasarán a CONFIRMADO. ¿Continuar?'), findsOneWidget);
      expect(servicio.asignaciones.single.confirmar, isFalse);

      await tester.tap(find.byKey(const ValueKey('reparto-confirmar')));
      await tester.pumpAndSettle();

      expect(servicio.asignaciones, hasLength(2));
      expect(servicio.asignaciones.last.confirmar, isTrue);
      expect(find.text('1 jugador asignado'), findsOneWidget);
    });

    testWidgets('si no se confirma la prueba, no se repite la petición', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await _marcar(tester, 2);
      await _elegirEquipo(tester, 'Alevín A');
      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.asignaciones, hasLength(1));
    });

    testWidgets('muestra los avisos de dorsal de la respuesta', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto()
        ..avisos = ['El dorsal 9 está repetido en Alevín A: Ana Pérez, Eva Ruiz'];

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await _marcar(tester, 1);
      await _dorsal(tester, 1, '9');
      await _elegirEquipo(tester, 'Alevín A');
      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pumpAndSettle();

      expect(find.text('Avisos'), findsOneWidget);
      expect(
        find.text('El dorsal 9 está repetido en Alevín A: Ana Pérez, Eva Ruiz'),
        findsOneWidget,
      );
    });

    testWidgets('un 400 al asignar enseña el motivo del servidor', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto()
        ..falloAlAsignar = const ApiException(
          'Ana Pérez está de baja.',
          statusCode: 400,
        );

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await _marcar(tester, 1);
      await _elegirEquipo(tester, 'Alevín A');
      await tester.tap(find.byKey(const ValueKey('reparto-asignar')));
      await tester.pumpAndSettle();

      expect(find.text('Ana Pérez está de baja.'), findsOneWidget);
    });

    testWidgets('devolver a la pretemporada pide confirmación', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('reparto-miembro-3')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Eva Ruiz vuelve a la pretemporada de su categoría, sin dorsal. ¿Continuar?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('reparto-confirmar')));
      await tester.pumpAndSettle();

      expect(servicio.devoluciones, [
        [3],
      ]);
      expect(find.text('1 jugador devuelto a la pretemporada'), findsOneWidget);
    });

    testWidgets('cancelar la devolución no hace nada', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('reparto-miembro-3')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.devoluciones, isEmpty);
    });

    testWidgets('crea un equipo nuevo de la categoría tras confirmar', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto();

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reparto-nuevo-equipo')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Se creará un equipo nuevo de Alevín con la siguiente letra libre. ¿Continuar?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('reparto-confirmar')));
      await tester.pumpAndSettle();

      expect(servicio.equiposCreados, ['Alevín']);
      expect(
        find.text('Equipo Alevín C creado. Se activará al asignarle el primer jugador.'),
        findsOneWidget,
      );
    });

    testWidgets('sin jugadores por asignar lo dice y sin equipos invita a crear el '
        'primero', (tester) async {
      _pantallaGrande(tester);
      final servicio = _FakeReparto()
        ..reparto = const RepartoCategoriaModel(categoria: 'Alevín');

      await tester.pumpWidget(_app(RepartoPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(
        find.text('No queda ningún jugador por asignar en esta categoría.'),
        findsOneWidget,
      );
      expect(
        find.text('Esta categoría no tiene equipos definitivos: crea el primero.'),
        findsOneWidget,
      );
    });
  });

  group('alta de prueba', () {
    testWidgets('valida los campos antes de enviar', (tester) async {
      final servicio = _FakeAlta();

      await tester.pumpWidget(_app(AltaPruebaPage(servicio: servicio)));

      await tester.tap(find.byKey(const ValueKey('prueba-guardar')));
      await tester.pump();

      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      expect(find.text('Escribe un año válido (por ejemplo, 2016)'), findsOneWidget);
      expect(servicio.altas, isEmpty);
    });

    testWidgets('da de alta y dice en qué categoría ha quedado', (tester) async {
      final servicio = _FakeAlta();

      await tester.pumpWidget(_app(AltaPruebaPage(servicio: servicio)));

      await tester.enterText(find.byKey(const ValueKey('prueba-nombre')), ' Luis ');
      await tester.enterText(find.byKey(const ValueKey('prueba-apellidos')), 'Gil');
      await tester.enterText(find.byKey(const ValueKey('prueba-anio')), '2016');
      await tester.tap(find.byKey(const ValueKey('prueba-guardar')));
      await tester.pumpAndSettle();

      expect(servicio.altas.single, ('Luis', 'Gil', 2016));
      expect(
        find.text('Jugador de prueba creado en la categoría Alevín'),
        findsOneWidget,
      );
      // El formulario queda listo para el siguiente.
      expect(find.text('Luis'), findsNothing);
    });

    testWidgets('un 400 y un 409 se muestran en texto claro', (tester) async {
      final servicio = _FakeAlta()
        ..fallo = const ApiException(
          'Ninguna categoría formativa cubre su edad (30 años) en 2027/2028.',
          statusCode: 400,
        );

      await tester.pumpWidget(_app(AltaPruebaPage(servicio: servicio)));

      await tester.enterText(find.byKey(const ValueKey('prueba-nombre')), 'Luis');
      await tester.enterText(find.byKey(const ValueKey('prueba-apellidos')), 'Gil');
      await tester.enterText(find.byKey(const ValueKey('prueba-anio')), '1996');
      await tester.tap(find.byKey(const ValueKey('prueba-guardar')));
      await tester.pumpAndSettle();

      expect(
        find.text('Ninguna categoría formativa cubre su edad (30 años) en 2027/2028.'),
        findsOneWidget,
      );

      servicio.fallo = const ApiException('No hay siguiente', statusCode: 409);
      await tester.tap(find.byKey(const ValueKey('prueba-guardar')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Todavía no hay una temporada disponible'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('prueba-creado')), findsNothing);
    });

    testWidgets('un 403 dice que no hay permiso', (tester) async {
      final servicio = _FakeAlta()
        ..fallo = const ApiException('no', statusCode: 403);

      await tester.pumpWidget(_app(AltaPruebaPage(servicio: servicio)));

      await tester.enterText(find.byKey(const ValueKey('prueba-nombre')), 'Luis');
      await tester.enterText(find.byKey(const ValueKey('prueba-apellidos')), 'Gil');
      await tester.enterText(find.byKey(const ValueKey('prueba-anio')), '2016');
      await tester.tap(find.byKey(const ValueKey('prueba-guardar')));
      await tester.pumpAndSettle();

      expect(find.text('No tienes permiso'), findsOneWidget);
    });
  });
}

class _FakeAlta extends RepartoService {
  Object? fallo;
  final List<(String, String, int)> altas = [];

  @override
  Future<PruebaCreadaModel> altaPrueba({
    required String nombre,
    required String apellidos,
    required int anioNacimiento,
  }) async {
    altas.add((nombre, apellidos, anioNacimiento));

    if (fallo != null) throw fallo!;

    return const PruebaCreadaModel(jugadorId: 99, categoria: 'Alevín');
  }
}
