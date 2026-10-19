import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/models/resumen_temporada_model.dart';
import 'package:app_mutxamel_cf/features/auth/pages/mis_jugadores_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/resumen_temporada_service.dart';
import 'package:app_mutxamel_cf/features/auth/widgets/resumen_temporada_section.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _conDatos = ResumenTemporadaModel(
  temporada: '2026/2027',
  convocado: 9,
  goles: 3,
  asistencias: 2,
  amarillas: 1,
  rojas: 0,
  entrenamientosTotal: 20,
  entrenamientosAsistidos: 18,
  faltas: 1,
  justificadas: 1,
  porcentaje: 90,
  convocatoriasVa: 8,
  convocatoriasNoPuede: 1,
  convocatoriasSinResponder: 0,
);

class _FakeResumenService extends ResumenTemporadaService {
  final Map<int, ResumenTemporadaModel> resumenes;
  final Set<int> fallan;

  _FakeResumenService({this.resumenes = const {}, this.fallan = const {}});

  @override
  Future<ResumenTemporadaModel> obtenerResumen(int jugadorId) async {
    if (fallan.contains(jugadorId)) {
      throw Exception('403');
    }
    return resumenes[jugadorId] ?? const ResumenTemporadaModel();
  }
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async => [];
}

Future<void> _pintar(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 3000);
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
      home: Scaffold(body: SingleChildScrollView(child: home)),
    ),
  );
  await tester.pumpAndSettle();
}

PerfilApp _perfil(List<String> roles) => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: roles,
  jugadores: [
    PerfilJugador(
      id: 100,
      nombre: 'Pablo',
      apellidos: 'Garcia',
      equipo: 'Cadete A',
      equipoId: 5,
    ),
    PerfilJugador(
      id: 101,
      nombre: 'Lucia',
      apellidos: 'Garcia',
      equipo: 'Alevín B',
      equipoId: 8,
    ),
  ],
  equipos: const [],
);

void main() {
  group('ResumenTemporadaModel', () {
    test('lee el JSON del backend', () {
      final r = ResumenTemporadaModel.fromJson({
        'temporada': {
          'nombre': '2026/2027',
          'inicio': '2026-09-01',
          'fin': '2027-06-30',
        },
        'partidos': {
          'convocado': 9,
          'goles': 3,
          'asistencias': 2,
          'amarillas': 1,
          'rojas': 0,
        },
        'entrenamientos': {
          'total': 20,
          'asistidos': 18,
          'faltas': 1,
          'justificadas': 1,
          'porcentaje': 90,
        },
        'convocatorias': {'va': 8, 'noPuede': 1, 'sinResponder': 0},
      });

      expect(r.temporada, '2026/2027');
      expect(r.goles, 3);
      expect(r.entrenamientosAsistidos, 18);
      expect(r.porcentaje, 90);
      expect(r.convocatoriasNoPuede, 1);
      expect(r.hayDatos, isTrue);
    });

    test('sin temporada activa no hay datos aunque los contadores sean 0', () {
      final r = ResumenTemporadaModel.fromJson({
        'temporada': null,
        'partidos': {'goles': 0},
        'entrenamientos': {'total': 0, 'porcentaje': null},
        'convocatorias': <String, dynamic>{},
      });

      expect(r.temporada, isNull);
      expect(r.porcentaje, isNull);
      expect(r.hayDatos, isFalse);
    });

    test('con temporada pero todo a cero tampoco hay datos', () {
      expect(
        const ResumenTemporadaModel(temporada: '2026/2027').hayDatos,
        isFalse,
      );
    });
  });

  group('ResumenTemporadaSection', () {
    testWidgets('con datos muestra tarjetas, entrenamientos y convocatorias', (
      tester,
    ) async {
      await _pintar(tester, const ResumenTemporadaSection(resumen: _conDatos));

      expect(find.text('Temporada 2026/2027'), findsOneWidget);

      // Tarjetas pequeñas: etiqueta y valor.
      for (final etiqueta in [
        'Goles',
        'Asistencias',
        'Amarillas',
        'Rojas',
        'Convocatorias',
      ]) {
        expect(find.text(etiqueta), findsWidgets, reason: etiqueta);
      }
      expect(find.text('3'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

      expect(find.text('Entrenamientos'), findsOneWidget);
      expect(find.text('18 de 20 (90 %)'), findsOneWidget);
      expect(find.text('1 falta · 1 justificada'), findsOneWidget);

      expect(
        find.text('Va: 8 · No puede: 1 · Sin responder: 0'),
        findsOneWidget,
      );
      expect(find.text('Todavía no hay datos de esta temporada'), findsNothing);
    });

    testWidgets('los plurales de faltas y justificadas', (tester) async {
      await _pintar(
        tester,
        const ResumenTemporadaSection(
          resumen: ResumenTemporadaModel(
            temporada: '2026/2027',
            entrenamientosTotal: 10,
            entrenamientosAsistidos: 6,
            faltas: 3,
            justificadas: 0,
            porcentaje: 60,
          ),
        ),
      );

      expect(find.text('3 faltas · 0 justificadas'), findsOneWidget);
    });

    testWidgets('sin datos (resumen nulo) lo dice', (tester) async {
      await _pintar(tester, const ResumenTemporadaSection(resumen: null));

      expect(find.text('Temporada'), findsOneWidget);
      expect(
        find.text('Todavía no hay datos de esta temporada'),
        findsOneWidget,
      );
      expect(find.text('Goles'), findsNothing);
    });

    testWidgets('sin temporada activa lo dice', (tester) async {
      await _pintar(
        tester,
        const ResumenTemporadaSection(resumen: ResumenTemporadaModel()),
      );

      expect(
        find.text('Todavía no hay datos de esta temporada'),
        findsOneWidget,
      );
    });

    testWidgets('con porcentaje nulo no inventa un porcentaje', (tester) async {
      await _pintar(
        tester,
        const ResumenTemporadaSection(
          resumen: ResumenTemporadaModel(
            temporada: '2026/2027',
            goles: 2,
            convocado: 1,
            porcentaje: null,
          ),
        ),
      );

      expect(find.text('Todavía no hay entrenamientos'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      // Los goles sí se ven.
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('el 0 % es un porcentaje, no "sin datos"', (tester) async {
      await _pintar(
        tester,
        const ResumenTemporadaSection(
          resumen: ResumenTemporadaModel(
            temporada: '2026/2027',
            entrenamientosTotal: 4,
            entrenamientosAsistidos: 0,
            faltas: 4,
            porcentaje: 0,
          ),
        ),
      );

      expect(find.text('0 de 4 (0 %)'), findsOneWidget);
    });

    test('resumen corto: entrenamientos y goles', () async {
      late AppLocalizations t;
      await _conLocalizaciones((l) => t = l);

      expect(
        ResumenTemporadaSection.resumenCorto(t, _conDatos),
        'Entrenamientos 18/20 · 3 goles',
      );
      expect(
        ResumenTemporadaSection.resumenCorto(
          t,
          const ResumenTemporadaModel(
            temporada: 'x',
            goles: 1,
            entrenamientosTotal: 0,
          ),
        ),
        '1 gol',
      );
      expect(ResumenTemporadaSection.resumenCorto(t, null), isNull);
      expect(
        ResumenTemporadaSection.resumenCorto(t, const ResumenTemporadaModel()),
        isNull,
      );
    });
  });

  group('en la ficha', () {
    testWidgets(
      '"Mis jugadores": cada hijo con su resumen corto y la sección',
      (tester) async {
        await _pintar(
          tester,
          SizedBox(
            height: 2800,
            child: MisJugadoresPage(
              cargarPerfil: () async => _perfil(['FAMILIAR']),
              teamService: _FakeTeamService(),
              resumenService: _FakeResumenService(
                resumenes: {
                  100: _conDatos,
                  101: const ResumenTemporadaModel(
                    temporada: '2026/2027',
                    goles: 1,
                    entrenamientosTotal: 5,
                    entrenamientosAsistidos: 5,
                    porcentaje: 100,
                  ),
                },
              ),
            ),
          ),
        );

        expect(find.text('Entrenamientos 18/20 · 3 goles'), findsOneWidget);
        expect(find.text('Entrenamientos 5/5 · 1 gol'), findsOneWidget);
        expect(find.text('Temporada 2026/2027'), findsNWidgets(2));
        expect(find.text('18 de 20 (90 %)'), findsOneWidget);
      },
    );

    testWidgets('"Mi ficha": la sección completa y sin resumen corto', (
      tester,
    ) async {
      final perfil = _perfil(['JUGADOR']);

      await _pintar(
        tester,
        SizedBox(
          height: 2800,
          child: MisJugadoresPage(
            soloMiFicha: true,
            cargarPerfil: () async => PerfilApp(
              usuarioId: 1,
              email: 'a@b.c',
              roles: const ['JUGADOR'],
              jugadores: [perfil.jugadores.first],
              equipos: const [],
            ),
            teamService: _FakeTeamService(),
            resumenService: _FakeResumenService(resumenes: {100: _conDatos}),
          ),
        ),
      );

      expect(find.text('Temporada 2026/2027'), findsOneWidget);
      expect(find.text('18 de 20 (90 %)'), findsOneWidget);
      expect(find.text('Entrenamientos 18/20 · 3 goles'), findsNothing);
    });

    testWidgets('si el resumen falla, la ficha sigue y dice que no hay datos', (
      tester,
    ) async {
      await _pintar(
        tester,
        SizedBox(
          height: 2800,
          child: MisJugadoresPage(
            cargarPerfil: () async => _perfil(['FAMILIAR']),
            teamService: _FakeTeamService(),
            resumenService: _FakeResumenService(
              resumenes: {101: _conDatos},
              fallan: {100},
            ),
          ),
        ),
      );

      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(
        find.text('Todavía no hay datos de esta temporada'),
        findsOneWidget,
      );
      expect(find.text('Temporada 2026/2027'), findsOneWidget);
    });
  });
}

Future<void> _conLocalizaciones(void Function(AppLocalizations) alta) async {
  alta(await AppLocalizations.delegate.load(const Locale('es')));
}
