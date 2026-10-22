import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/models/resumen_temporada_model.dart';
import 'package:app_mutxamel_cf/features/auth/pages/equipo_gestion_page.dart';
import 'package:app_mutxamel_cf/features/auth/widgets/resumen_temporada_section.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/partido_estadisticas_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/resultado_partido_form_page.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/estadisticas_equipo_model.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/features/teams/pages/estadisticas_equipo_page.dart';
import 'package:app_mutxamel_cf/features/teams/services/estadisticas_equipo_service.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _FakeMatchService extends MatchService {
  final bool admite;
  int? golesFavorGuardados;
  List<EstadisticaJugadorModel>? jugadoresGuardados;

  _FakeMatchService(this.admite);

  @override
  Future<PartidoEstadisticasModel> obtenerEstadisticas(int partidoId) async =>
      PartidoEstadisticasModel(
        partidoId: partidoId,
        admiteEstadisticas: admite,
      );

  @override
  Future<PartidoEstadisticasModel> guardarEstadisticas({
    required int partidoId,
    required int golesFavor,
    required int golesContra,
    required List<EstadisticaJugadorModel> jugadores,
  }) async {
    golesFavorGuardados = golesFavor;
    jugadoresGuardados = jugadores;
    return PartidoEstadisticasModel(partidoId: partidoId);
  }
}

class _FakeTeamService extends TeamService {
  int llamadas = 0;

  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async {
    llamadas++;
    return const [
      PlayerModel(
        id: 1,
        nombre: 'Pablo',
        apellidos: 'Garcia',
        categoria: 'Benjamín',
        equipo: 'Benjamín A',
        deporte: 'F',
      ),
    ];
  }
}

class _FakeConvocatoriaService extends ConvocatoriaService {
  int llamadas = 0;

  @override
  Future<List<ConvocatoriaModel>> obtenerPorEquipo(int equipoId) async {
    llamadas++;
    return const [];
  }
}

class _FakeEstadisticasService extends EstadisticasEquipoService {
  final bool admite;

  _FakeEstadisticasService(this.admite);

  @override
  Future<EstadisticasEquipoModel> obtenerEstadisticas(int equipoId) async =>
      EstadisticasEquipoModel(
        goleadores: admite
            ? const [
                JugadorDestacadoModel(
                  jugadorId: 1,
                  nombre: 'Pablo Garcia',
                  dorsal: 9,
                  goles: 4,
                  asistencias: 1,
                  partidos: 3,
                ),
              ]
            : const [],
        asistentes: const [],
        entrenamientos: const EntrenamientosEquipoModel(
          sesiones: 2,
          asistenciaMedia: 80,
          porJugador: [],
        ),
        partidos: const PartidosEquipoModel(
          jugados: 3,
          ganados: 2,
          empatados: 1,
          perdidos: 0,
          golesFavor: 7,
          golesContra: 2,
        ),
        admiteEstadisticas: admite,
      );
}

const _partido = MatchModel(
  id: 10,
  equipoId: 5,
  categoria: 'Benjamín',
  equipo: 'Benjamín A',
  rival: 'Rival CF',
);

void main() {
  group('Formulario de resultado', () {
    testWidgets('F8: solo marcador, nota y sin cargar jugadores', (
      tester,
    ) async {
      final partidos = _FakeMatchService(false);
      final equipos = _FakeTeamService();
      final convocatorias = _FakeConvocatoriaService();

      await tester.pumpWidget(
        _app(
          ResultadoPartidoFormPage(
            partido: _partido,
            matchService: partidos,
            teamService: equipos,
            convocatoriaService: convocatorias,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goles a favor'), findsOneWidget);
      expect(find.text('Goles en contra'), findsOneWidget);
      expect(
        find.text('En fútbol 8 solo se registra el resultado'),
        findsOneWidget,
      );
      expect(find.text('Estadísticas por jugador'), findsNothing);
      expect(find.text('Pablo Garcia'), findsNothing);
      expect(equipos.llamadas, 0);
      expect(convocatorias.llamadas, 0);

      await tester.enterText(find.byType(TextField).first, '4');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(partidos.golesFavorGuardados, 4);
      expect(partidos.jugadoresGuardados, isEmpty);
    });

    testWidgets('F11: carga la plantilla y muestra las estadísticas', (
      tester,
    ) async {
      final equipos = _FakeTeamService();

      await tester.pumpWidget(
        _app(
          ResultadoPartidoFormPage(
            partido: _partido,
            matchService: _FakeMatchService(true),
            teamService: equipos,
            convocatoriaService: _FakeConvocatoriaService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estadísticas por jugador'), findsOneWidget);
      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(
        find.text('En fútbol 8 solo se registra el resultado'),
        findsNothing,
      );
      expect(equipos.llamadas, 1);
    });
  });

  group('Gestión del equipo', () {
    testWidgets('F8, F5 y sin modalidad no muestran Tarjetas', (tester) async {
      for (final modalidad in ['F8', 'F5', null]) {
        await tester.pumpWidget(
          _app(
            EquipoGestionPage(
              equipo: PerfilEquipo(
                id: 5,
                nombre: 'Benjamín A',
                modalidad: modalidad,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tarjetas'), findsNothing, reason: '$modalidad');
        expect(find.text('Estadísticas'), findsOneWidget);
      }
    });

    testWidgets('F11 muestra Tarjetas', (tester) async {
      await tester.pumpWidget(
        _app(
          EquipoGestionPage(
            equipo: PerfilEquipo(id: 5, nombre: 'Cadete A', modalidad: 'F11'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tarjetas'), findsOneWidget);
    });
  });

  group('Estadísticas del equipo', () {
    final equipo = PerfilEquipo(id: 5, nombre: 'Benjamín A');

    testWidgets('F8 oculta goleadores y asistentes sin estado vacío', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          EstadisticasEquipoPage(
            equipo: equipo,
            servicio: _FakeEstadisticasService(false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goleadores'), findsNothing);
      expect(find.text('Asistentes'), findsNothing);
      expect(find.text('Asistencia a entrenamientos'), findsOneWidget);
    });

    testWidgets('F11 muestra goleadores y asistentes', (tester) async {
      await tester.pumpWidget(
        _app(
          EstadisticasEquipoPage(
            equipo: equipo,
            servicio: _FakeEstadisticasService(true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goleadores'), findsOneWidget);
      expect(find.text('Asistentes'), findsOneWidget);
      expect(find.text('Pablo Garcia'), findsOneWidget);
    });
  });

  group('Resumen de temporada del jugador', () {
    ResumenTemporadaModel resumen(bool admite) => ResumenTemporadaModel(
      temporada: '2026/2027',
      convocado: 9,
      goles: admite ? 3 : 0,
      entrenamientosTotal: 20,
      entrenamientosAsistidos: 18,
      porcentaje: 90,
      admiteEstadisticas: admite,
    );

    testWidgets('F8 oculta goles, asistencias, amarillas y rojas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(Scaffold(body: ResumenTemporadaSection(resumen: resumen(false)))),
      );

      for (final etiqueta in ['Goles', 'Asistencias', 'Amarillas', 'Rojas']) {
        expect(find.text(etiqueta), findsNothing, reason: etiqueta);
      }
      expect(find.text('Convocatorias'), findsOneWidget);
    });

    testWidgets('F11 muestra las cuatro fichas', (tester) async {
      await tester.pumpWidget(
        _app(Scaffold(body: ResumenTemporadaSection(resumen: resumen(true)))),
      );

      for (final etiqueta in ['Goles', 'Asistencias', 'Amarillas', 'Rojas']) {
        expect(find.text(etiqueta), findsOneWidget, reason: etiqueta);
      }
    });

    testWidgets('el resumen corto de F8 es solo entrenamientos', (
      tester,
    ) async {
      late AppLocalizations t;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              t = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        ResumenTemporadaSection.resumenCorto(t, resumen(false)),
        'Entrenamientos 18/20',
      );
      expect(
        ResumenTemporadaSection.resumenCorto(t, resumen(true)),
        'Entrenamientos 18/20 · 3 goles',
      );
    });
  });

  group('Modelos', () {
    test('TeamModel lee modalidad', () {
      final f11 = TeamModel.fromJson({'id': 1, 'modalidad': 'F11'});
      final f8 = TeamModel.fromJson({'id': 2, 'modalidad': 'F8'});
      final sin = TeamModel.fromJson({'id': 3});

      expect(f11.admiteEstadisticas, isTrue);
      expect(f8.admiteEstadisticas, isFalse);
      expect(sin.modalidad, isNull);
      expect(sin.admiteEstadisticas, isFalse);
    });

    test('estadísticas, tarjetas y resumen leen admiteEstadisticas', () {
      expect(
        PartidoEstadisticasModel.fromJson({
          'admiteEstadisticas': false,
        }).admiteEstadisticas,
        isFalse,
      );
      expect(PartidoEstadisticasModel.fromJson({}).admiteEstadisticas, isTrue);

      final tarjetas = TarjetasEquipoModel.fromJson({
        'admiteEstadisticas': false,
        'jugadores': [],
      });
      expect(tarjetas.admiteEstadisticas, isFalse);
      expect(tarjetas.jugadores, isEmpty);
      // Respuesta antigua: lista a secas.
      expect(TarjetasEquipoModel.fromJson([]).admiteEstadisticas, isTrue);

      expect(
        ResumenTemporadaModel.fromJson({
          'admiteEstadisticas': false,
        }).admiteEstadisticas,
        isFalse,
      );
      expect(
        EstadisticasEquipoModel.fromJson({
          'admiteEstadisticas': false,
        }).admiteEstadisticas,
        isFalse,
      );
    });
  });
}
