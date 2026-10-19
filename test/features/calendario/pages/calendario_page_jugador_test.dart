import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/calendario/model/calendario_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/justificacion_falta_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/sesion_entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/temporada_model.dart';
import 'package:app_mutxamel_cf/features/calendario/pages/calendario_page.dart';
import 'package:app_mutxamel_cf/features/calendario/services/calendario_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:app_mutxamel_cf/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeCalendarioService extends CalendarioService {
  final CalendarioModel calendario;
  final List<({int sesion, int jugador, String? motivo})> justificaciones = [];
  final List<int?> jugadoresConsultados = [];

  _FakeCalendarioService(this.calendario);

  @override
  Future<TemporadaModel?> obtenerTemporadaActiva() async => null;

  @override
  Future<CalendarioModel> obtenerCalendario({
    required int equipoId,
    required DateTime desde,
    required DateTime hasta,
    int? jugadorId,
  }) async {
    jugadoresConsultados.add(jugadorId);
    return calendario;
  }

  @override
  Future<JustificacionFaltaModel> justificarFalta({
    required int sesionId,
    required int jugadorId,
    String? motivo,
  }) async {
    justificaciones.add((sesion: sesionId, jugador: jugadorId, motivo: motivo));

    return JustificacionFaltaModel(
      id: 1,
      sesionId: sesionId,
      jugadorId: jugadorId,
      jugador: 'Pablo Garcia',
      usuarioAppId: 1,
      motivo: motivo,
    );
  }
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<TeamModel>> obtenerEquipos() async => [];
}

/// El calendario muestra los eventos del día seleccionado, que al abrirlo es hoy.
DateTime _enDias(int dias) {
  final hoy = DateTime.now();
  return DateTime(hoy.year, hoy.month, hoy.day).add(Duration(days: dias));
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
  ],
  equipos: const [],
);

CalendarioModel _calendario({String? respuesta}) => CalendarioModel(
  sesiones: [
    SesionEntrenamientoModel(
      id: 7,
      equipoId: 5,
      equipo: 'Cadete A',
      fecha: _enDias(0),
      hora: '18:00',
      lugar: 'Campo Municipal',
      estado: 'PROGRAMADA',
    ),
  ],
  partidos: [
    MatchModel(
      id: 30,
      equipoId: 5,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Pego C.F.',
      dia: _enDias(0),
      hora: '11:00',
      convocado: true,
      respuestaConvocatoria: respuesta,
    ),
  ],
);

Future<void> _pintar(
  WidgetTester tester,
  _FakeCalendarioService servicio,
  List<String> roles, {
  Map<String, WidgetBuilder> rutas = const {},
}) async {
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
      routes: rutas,
      home: CalendarioPage(
        calendarioService: servicio,
        teamService: _FakeTeamService(),
        cargarPerfil: () async => _perfil(roles),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  testWidgets(
    'un usuario solo JUGADOR ve su entrenamiento y puede justificar la falta',
    (tester) async {
      final servicio = _FakeCalendarioService(_calendario());

      await _pintar(tester, servicio, ['JUGADOR']);

      // El calendario se pide con SU jugador (igual que un familiar).
      expect(servicio.jugadoresConsultados, [100]);
      expect(find.text('Cadete A — Pablo Garcia'), findsWidgets);
      expect(find.text('Campo Municipal'), findsOneWidget);

      // Pulsar el entrenamiento abre el diálogo para justificar la falta.
      await tester.tap(find.text('Campo Municipal'));
      await tester.pumpAndSettle();

      expect(find.text('Justificar falta a entrenamiento'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Examen');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(servicio.justificaciones.single.sesion, 7);
      expect(servicio.justificaciones.single.jugador, 100);
      expect(servicio.justificaciones.single.motivo, 'Examen');
    },
  );

  testWidgets('un FAMILIAR ve exactamente lo mismo que un JUGADOR', (
    tester,
  ) async {
    final servicio = _FakeCalendarioService(_calendario());

    await _pintar(tester, servicio, ['FAMILIAR']);

    expect(servicio.jugadoresConsultados, [100]);
    expect(find.text('Cadete A — Pablo Garcia'), findsWidgets);

    await tester.tap(find.text('Campo Municipal'));
    await tester.pumpAndSettle();

    expect(find.text('Justificar falta a entrenamiento'), findsOneWidget);
  });

  testWidgets('un partido convocado muestra el estado de la respuesta', (
    tester,
  ) async {
    await _pintar(
      tester,
      _FakeCalendarioService(_calendario(respuesta: 'NO_PUEDE')),
      ['JUGADOR'],
    );

    expect(find.text('Convocado'), findsOneWidget);
    expect(find.text('No puede'), findsOneWidget);
  });

  testWidgets('un partido convocado sin responder lo indica', (tester) async {
    await _pintar(tester, _FakeCalendarioService(_calendario()), ['FAMILIAR']);

    expect(find.text('Convocado'), findsOneWidget);
    expect(find.text('Sin responder'), findsOneWidget);
  });

  testWidgets('pulsar el partido convocado lleva a "Mis convocatorias"', (
    tester,
  ) async {
    await _pintar(
      tester,
      _FakeCalendarioService(_calendario()),
      ['JUGADOR'],
      rutas: {
        AppRoutes.myCallups: (_) =>
            const Scaffold(body: Center(child: Text('PANTALLA CONVOCATORIAS'))),
      },
    );

    await tester.tap(find.text('Pego C.F.'));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA CONVOCATORIAS'), findsOneWidget);
  });
}
