import 'dart:convert';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/pages/mis_jugadores_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/auth/services/resumen_temporada_service.dart';
import 'package:app_mutxamel_cf/features/continuidad/models/continuidad_model.dart';
import 'package:app_mutxamel_cf/features/continuidad/pages/continuidad_page.dart';
import 'package:app_mutxamel_cf/features/continuidad/services/continuidad_service.dart';
import 'package:app_mutxamel_cf/features/continuidad/widgets/continuidad_card.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/features/auth/models/resumen_temporada_model.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

class _FakeContinuidad extends ContinuidadService {
  List<ContinuidadJugadorModel> lista;
  Object? falloAlListar;
  Object? falloAlResponder;
  final List<(int, String)> respuestas = [];

  _FakeContinuidad(this.lista);

  @override
  Future<List<ContinuidadJugadorModel>> listar() async {
    if (falloAlListar != null) throw falloAlListar!;

    return lista;
  }

  @override
  Future<ContinuidadJugadorModel> responder(int jugadorId, String respuesta) async {
    respuestas.add((jugadorId, respuesta));

    if (falloAlResponder != null) throw falloAlResponder!;

    final actual = lista.firstWhere((j) => j.jugadorId == jugadorId);

    return ContinuidadJugadorModel(
      jugadorId: jugadorId,
      nombre: actual.nombre,
      categoria: actual.categoria,
      temporadaId: actual.temporadaId,
      temporada: actual.temporada,
      respuesta: respuesta,
      fechaRespuesta: DateTime(2027, 5, 3, 9, 30),
    );
  }
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async => [];
}

class _FakeResumen extends ResumenTemporadaService {
  @override
  Future<ResumenTemporadaModel> obtenerResumen(int jugadorId) async {
    throw const ApiException('sin datos', statusCode: 404);
  }
}

ContinuidadJugadorModel _pablo({
  String respuesta = 'PENDIENTE',
  DateTime? fecha,
}) => ContinuidadJugadorModel(
  jugadorId: 1,
  nombre: 'Pablo Pérez',
  categoria: 'Alevín',
  temporadaId: 7,
  temporada: '2027/2028',
  respuesta: respuesta,
  fechaRespuesta: fecha,
);

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

PerfilApp _perfil({String? equipo, String? categoria, int? equipoId}) {
  return PerfilApp(
    usuarioId: 1,
    email: 'f@b.c',
    roles: const ['FAMILIAR'],
    jugadores: [
      PerfilJugador(
        id: 1,
        nombre: 'Pablo',
        apellidos: 'Pérez',
        categoria: categoria,
        equipo: equipo,
        equipoId: equipoId,
        deporte: 'F',
      ),
    ],
    equipos: const [],
  );
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(<String, String>{});
  });

  group('modelo', () {
    test('lee todos los campos del contrato', () {
      final j = ContinuidadJugadorModel.fromJson({
        'jugadorId': 1,
        'nombre': 'Pablo Pérez',
        'categoria': 'Alevín',
        'temporadaId': 7,
        'temporada': '2027/2028',
        'respuesta': 'NO_SIGUE',
        'fechaRespuesta': '2027-05-03T09:30:00',
      });

      expect(j.jugadorId, 1);
      expect(j.nombre, 'Pablo Pérez');
      expect(j.temporada, '2027/2028');
      expect(j.respuesta, respuestaNoSigue);
      expect(j.contestada, isTrue);
      expect(j.fechaRespuesta, DateTime(2027, 5, 3, 9, 30));
    });

    test('PENDIENTE sin fecha es "sin contestar"', () {
      final j = ContinuidadJugadorModel.fromJson({
        'jugadorId': 1,
        'nombre': 'Pablo Pérez',
        'temporadaId': 7,
        'temporada': '2027/2028',
        'respuesta': 'PENDIENTE',
        'fechaRespuesta': null,
      });

      expect(j.contestada, isFalse);
      expect(j.fechaRespuesta, isNull);
    });

    test('la fecha también se lee si llega como lista', () {
      final j = ContinuidadJugadorModel.fromJson({
        'jugadorId': 1,
        'nombre': 'P',
        'temporadaId': 7,
        'temporada': 'X',
        'respuesta': 'SIGUE',
        'fechaRespuesta': [2027, 5, 3, 9, 30, 0],
      });

      expect(j.fechaRespuesta, DateTime(2027, 5, 3, 9, 30));
    });
  });

  group('servicio', () {
    Future<void> iniciarSesion() => AuthSession.guardarSesion(
      LoginResponse(token: 't', usuarioId: 1, email: 'a@a.com', roles: const []),
    );

    test('listar pide GET /app/continuidad con el token', () async {
      await iniciarSesion();

      final lista = await conMockHttp((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/app/continuidad'));
        expect(request.headers['Authorization'], 'Bearer t');
        return http.Response(
          jsonEncode([
            {
              'jugadorId': 1,
              'nombre': 'Pablo Pérez',
              'categoria': 'Alevín',
              'temporadaId': 7,
              'temporada': '2027/2028',
              'respuesta': 'PENDIENTE',
              'fechaRespuesta': null,
            },
          ]),
          200,
        );
      }, () => ContinuidadService().listar());

      expect(lista, hasLength(1));
      expect(lista.single.respuesta, 'PENDIENTE');
    });

    test('una lista vacía es una lista vacía', () async {
      await iniciarSesion();

      final lista = await conMockHttp(
        (request) async => http.Response('[]', 200),
        () => ContinuidadService().listar(),
      );

      expect(lista, isEmpty);
    });

    test('responder hace PUT con {respuesta} y devuelve el estado nuevo', () async {
      await iniciarSesion();

      final nuevo = await conMockHttp((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, endsWith('/app/continuidad/1'));
        expect(jsonDecode(request.body), {'respuesta': 'DUDA'});
        return http.Response(
          jsonEncode({
            'jugadorId': 1,
            'nombre': 'Pablo Pérez',
            'temporadaId': 7,
            'temporada': '2027/2028',
            'respuesta': 'DUDA',
            'fechaRespuesta': '2027-05-03T09:30:00',
          }),
          200,
        );
      }, () => ContinuidadService().responder(1, 'DUDA'));

      expect(nuevo.respuesta, respuestaDuda);
    });

    test('un 403 llega como ApiException con su código', () async {
      await iniciarSesion();

      await expectLater(
        conMockHttp(
          (request) async =>
              http.Response('No tienes vinculado a este jugador.', 403),
          () => ContinuidadService().responder(1, 'SIGUE'),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('tarjeta', () {
    testWidgets('pregunta, ofrece Sí / No / Aún no lo sé y avisa de la respuesta', (
      tester,
    ) async {
      final respuestas = <String>[];

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ContinuidadCard(jugador: _pablo(), onResponder: respuestas.add),
          ),
        ),
      );

      expect(
        find.text('¿Seguirá Pablo Pérez en la temporada 2027/2028?'),
        findsOneWidget,
      );
      expect(find.text('Sí'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Aún no lo sé'), findsOneWidget);
      expect(find.text('Sin contestar todavía'), findsOneWidget);

      await tester.tap(find.text('Aún no lo sé'));
      await tester.tap(find.text('Sí'));

      expect(respuestas, ['DUDA', 'SIGUE']);
    });

    testWidgets('muestra la respuesta actual con su fecha y deja cambiarla', (
      tester,
    ) async {
      final respuestas = <String>[];

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ContinuidadCard(
              jugador: _pablo(
                respuesta: 'NO_SIGUE',
                fecha: DateTime(2027, 5, 3, 9, 30),
              ),
              onResponder: respuestas.add,
            ),
          ),
        ),
      );

      expect(find.text('Tu respuesta: No · 03/05/2027'), findsOneWidget);
      expect(
        find.text('Puedes cambiarla hasta el cierre de la temporada.'),
        findsOneWidget,
      );

      // La opción ya elegida no se vuelve a enviar; las otras sí.
      await tester.tap(find.text('No'), warnIfMissed: false);
      await tester.tap(find.text('Sí'));

      expect(respuestas, ['SIGUE']);
    });

    testWidgets('mientras se guarda no deja volver a pulsar', (tester) async {
      final respuestas = <String>[];

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ContinuidadCard(
              jugador: _pablo(),
              guardando: true,
              onResponder: respuestas.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sí'));

      expect(respuestas, isEmpty);
    });
  });

  group('pantalla de continuidad', () {
    testWidgets('lista las tarjetas y guarda la respuesta', (tester) async {
      final servicio = _FakeContinuidad([_pablo()]);

      await tester.pumpWidget(_app(ContinuidadPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(
        find.text('¿Seguirá Pablo Pérez en la temporada 2027/2028?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sí'));
      await tester.pumpAndSettle();

      expect(servicio.respuestas, [(1, 'SIGUE')]);
      expect(find.text('Tu respuesta: Sí · 03/05/2027'), findsOneWidget);
      expect(find.text('Respuesta guardada'), findsOneWidget);
    });

    testWidgets('sin nada que confirmar lo dice con un texto claro', (tester) async {
      await tester.pumpWidget(
        _app(ContinuidadPage(servicio: _FakeContinuidad([]))),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tienes nada que confirmar ahora.'), findsOneWidget);
    });

    testWidgets('si falla al guardar, avisa y no cambia la respuesta', (tester) async {
      final servicio = _FakeContinuidad([_pablo()])
        ..falloAlResponder = const ApiException(
          'El jugador no tiene que confirmar.',
          statusCode: 400,
        );

      await tester.pumpWidget(_app(ContinuidadPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(find.text('El jugador no tiene que confirmar.'), findsOneWidget);
      expect(find.text('Sin contestar todavía'), findsOneWidget);
    });

    testWidgets('si falla al cargar ofrece reintentar', (tester) async {
      final servicio = _FakeContinuidad([_pablo()])
        ..falloAlListar = const ApiException('sin red');

      await tester.pumpWidget(_app(ContinuidadPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);

      servicio.falloAlListar = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(
        find.text('¿Seguirá Pablo Pérez en la temporada 2027/2028?'),
        findsOneWidget,
      );
    });
  });

  group('Mis jugadores', () {
    Future<void> pintar(
      WidgetTester tester, {
      required PerfilApp perfil,
      required List<ContinuidadJugadorModel> continuidad,
    }) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          MisJugadoresPage(
            cargarPerfil: () async => perfil,
            teamService: _FakeTeamService(),
            resumenService: _FakeResumen(),
            continuidadService: _FakeContinuidad(continuidad),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la tarjeta de continuidad y se puede contestar', (
      tester,
    ) async {
      await pintar(
        tester,
        perfil: _perfil(equipo: 'Alevín A', equipoId: 5),
        continuidad: [_pablo()],
      );

      expect(
        find.text('¿Seguirá Pablo Pérez en la temporada 2027/2028?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sí'));
      await tester.pumpAndSettle();

      expect(find.text('Tu respuesta: Sí · 03/05/2027'), findsOneWidget);
    });

    testWidgets('con la lista vacía no se muestra nada de continuidad', (tester) async {
      await pintar(
        tester,
        perfil: _perfil(equipo: 'Alevín A', equipoId: 5),
        continuidad: [],
      );

      expect(find.textContaining('Seguirá'), findsNothing);
      expect(find.text('Aún no lo sé'), findsNothing);
      expect(find.text('Pablo Pérez'), findsOneWidget);
    });

    testWidgets('si falla la carga de continuidad la ficha sigue igual', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          MisJugadoresPage(
            cargarPerfil: () async => _perfil(equipo: 'Alevín A', equipoId: 5),
            teamService: _FakeTeamService(),
            resumenService: _FakeResumen(),
            continuidadService: _FakeContinuidad([_pablo()])
              ..falloAlListar = const ApiException('sin red'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pablo Pérez'), findsOneWidget);
      expect(find.text('Aún no lo sé'), findsNothing);
    });

    testWidgets('en un equipo de pretemporada muestra "<Categoría> · Pretemporada"', (
      tester,
    ) async {
      await pintar(
        tester,
        perfil: _perfil(
          equipo: 'Alevín (Pretemporada)',
          categoria: 'Alevín',
          equipoId: 10,
        ),
        continuidad: [],
      );

      expect(find.text('Alevín · Pretemporada'), findsOneWidget);
      expect(find.text('Alevín (Pretemporada)'), findsNothing);
    });

    testWidgets('en pretemporada sin categoría la saca del nombre del equipo', (
      tester,
    ) async {
      await pintar(
        tester,
        perfil: _perfil(equipo: 'Infantil (Pretemporada)', equipoId: 10),
        continuidad: [],
      );

      expect(find.text('Infantil · Pretemporada'), findsOneWidget);
    });

    testWidgets('"Sin equipo esta temporada" se mantiene para quien no tiene equipo', (
      tester,
    ) async {
      await pintar(tester, perfil: _perfil(), continuidad: []);

      expect(find.text('Sin equipo esta temporada'), findsOneWidget);
    });

    testWidgets('un equipo normal se muestra con su nombre', (tester) async {
      await pintar(
        tester,
        perfil: _perfil(equipo: 'Alevín A', categoria: 'Alevín', equipoId: 5),
        continuidad: [],
      );

      expect(find.text('Alevín A'), findsOneWidget);
    });
  });

  group('pretemporada en el perfil', () {
    test('se reconoce por el sufijo, sin mirar mayúsculas ni espacios', () {
      expect(esNombreDePretemporada('Alevín (Pretemporada)'), isTrue);
      expect(esNombreDePretemporada('  alevín (PRETEMPORADA) '), isTrue);
      expect(esNombreDePretemporada('Alevín A'), isFalse);
      expect(esNombreDePretemporada(null), isFalse);
      expect(esNombreDePretemporada(''), isFalse);
    });
  });
}
