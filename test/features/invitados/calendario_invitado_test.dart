import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/calendario/model/calendario_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/temporada_model.dart';
import 'package:app_mutxamel_cf/features/calendario/pages/calendario_page.dart';
import 'package:app_mutxamel_cf/features/calendario/services/calendario_service.dart';
import 'package:app_mutxamel_cf/features/invitados/services/invitados_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/justificacion_partido_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/justificacion_partido_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeCalendario extends CalendarioService {
  final CalendarioModel calendario;

  _FakeCalendario(this.calendario);

  @override
  Future<TemporadaModel?> obtenerTemporadaActiva() async => null;

  @override
  Future<CalendarioModel> obtenerCalendario({
    required int equipoId,
    required DateTime desde,
    required DateTime hasta,
    int? jugadorId,
  }) async => calendario;
}

class _FakeJustificaciones extends JustificacionPartidoService {
  final List<String> llamadas = [];

  @override
  Future<JustificacionPartidoModel> justificar({
    required int partidoId,
    required int jugadorId,
    required String motivo,
  }) async {
    llamadas.add('justificar:$partidoId:$jugadorId:$motivo');

    return JustificacionPartidoModel(
      partidoId: partidoId,
      jugadorId: jugadorId,
      jugador: 'Pablo',
      motivo: motivo,
    );
  }
}

class _FakeInvitados extends InvitadosService {
  final List<String> llamadas = [];

  @override
  Future<JustificacionPartidoModel> desestimar({
    required int partidoId,
    required int jugadorId,
    required String motivo,
  }) async {
    llamadas.add('desestimar:$partidoId:$jugadorId:$motivo');

    return JustificacionPartidoModel(
      partidoId: partidoId,
      jugadorId: jugadorId,
      jugador: 'Pablo',
      motivo: motivo,
    );
  }
}

class _FakeTeams extends TeamService {
  @override
  Future<List<TeamModel>> obtenerEquipos() async => [];
}

DateTime _hoy() {
  final ahora = DateTime.now();

  return DateTime(ahora.year, ahora.month, ahora.day);
}

PerfilApp _perfil() => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: const ['FAMILIAR'],
  jugadores: [
    PerfilJugador(
      id: 100,
      nombre: 'Pablo',
      apellidos: 'Garcia',
      equipo: 'Infantil A',
      equipoId: 3,
    ),
  ],
  equipos: const [],
);

MatchModel _partido({required bool invitado}) => MatchModel(
  id: 30,
  equipoId: invitado ? 5 : 3,
  categoria: 'Cadete',
  // En un partido de invitado, el equipo es el de destino.
  equipo: invitado ? 'Cadete A' : 'Infantil A',
  rival: 'Pego C.F.',
  dia: _hoy(),
  hora: '11:00',
  convocado: true,
  puedeJustificar: true,
  invitado: invitado,
  limiteJustificacion: DateTime(2030, 10, 24, 9, 30),
);

Future<void> _pintar(
  WidgetTester tester, {
  required bool invitado,
  required _FakeJustificaciones justificaciones,
  required _FakeInvitados invitados,
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
      home: CalendarioPage(
        calendarioService: _FakeCalendario(
          CalendarioModel(
            sesiones: const [],
            partidos: [_partido(invitado: invitado)],
          ),
        ),
        teamService: _FakeTeams(),
        cargarPerfil: () async => _perfil(),
        justificacionPartidoService: justificaciones,
        invitadosService: invitados,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  testWidgets(
    'el partido de otro equipo sale marcado "Invitado con <equipo>"',
    (tester) async {
      await _pintar(
        tester,
        invitado: true,
        justificaciones: _FakeJustificaciones(),
        invitados: _FakeInvitados(),
      );

      expect(find.byKey(const ValueKey('partido-invitado')), findsOneWidget);
      expect(find.text('Invitado con Cadete A'), findsOneWidget);
      expect(find.text('Pego C.F.'), findsOneWidget);
    },
  );

  testWidgets('un partido del propio equipo no lleva la marca', (tester) async {
    await _pintar(
      tester,
      invitado: false,
      justificaciones: _FakeJustificaciones(),
      invitados: _FakeInvitados(),
    );

    expect(find.byKey(const ValueKey('partido-invitado')), findsNothing);
    expect(find.text('Justificar ausencia'), findsOneWidget);
    expect(find.text('No puede ir'), findsNothing);
  });

  testWidgets(
    'en un partido de invitado el botón es "No puede ir" y avisa con desestimar',
    (tester) async {
      final justificaciones = _FakeJustificaciones();
      final invitados = _FakeInvitados();

      await _pintar(
        tester,
        invitado: true,
        justificaciones: justificaciones,
        invitados: invitados,
      );

      expect(find.text('Justificar ausencia'), findsNothing);

      await tester.tap(find.text('No puede ir'));
      await tester.pumpAndSettle();

      // El diálogo explica a quién se avisa y exige un motivo.
      expect(
        find.textContaining('El entrenador que lo convocó recibirá un aviso'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Indica el motivo (mínimo 3 caracteres)'),
        findsOneWidget,
      );
      expect(invitados.llamadas, isEmpty);

      await tester.enterText(find.byType(TextField), 'Cumpleaños familiar');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(invitados.llamadas, ['desestimar:30:100:Cumpleaños familiar']);
      expect(justificaciones.llamadas, isEmpty);
      expect(find.text('Aviso enviado al entrenador'), findsOneWidget);
    },
  );

  testWidgets(
    'en un partido propio justificar sigue yendo al endpoint de siempre',
    (tester) async {
      final justificaciones = _FakeJustificaciones();
      final invitados = _FakeInvitados();

      await _pintar(
        tester,
        invitado: false,
        justificaciones: justificaciones,
        invitados: invitados,
      );

      await tester.tap(find.text('Justificar ausencia'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Examen');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(justificaciones.llamadas, ['justificar:30:100:Examen']);
      expect(invitados.llamadas, isEmpty);
    },
  );
}
