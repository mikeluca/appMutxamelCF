import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/pages/mis_clasificaciones_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/teams/models/standings_model.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/features/teams/pages/team_standings_page.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeTeamService extends TeamService {
  final List<TeamModel> equipos;
  final Map<int, StandingsModel?> clasificaciones;
  final Set<int> fallan;

  _FakeTeamService({
    this.equipos = const [],
    this.clasificaciones = const {},
    this.fallan = const {},
  });

  @override
  Future<List<TeamModel>> obtenerEquipos() async => equipos;

  @override
  Future<StandingsModel?> obtenerClasificacion(int equipoId) async {
    if (fallan.contains(equipoId)) {
      throw Exception('fallo de red');
    }
    return clasificaciones[equipoId];
  }
}

TeamModel _equipo(int id, String nombre) => TeamModel(
  id: id,
  categoria: 'Cat $id',
  grupo: '',
  orden: '',
  nombre: nombre,
  deporte: 'F',
);

StandingsModel _clasificacion(int posicion, int puntos, int jornada) =>
    StandingsModel(
      competicion: 'Liga',
      jornada: jornada,
      fechaImportacion: DateTime(2026, 10, 19),
      filas: [
        StandingsRowModel(
          posicion: posicion,
          equipo: 'Mutxamel C.F.',
          esNuestro: true,
          puntos: puntos,
          pj: jornada,
          pg: 0,
          pe: 0,
          pp: 0,
          gf: 0,
          gc: 0,
        ),
      ],
    );

PerfilApp _perfil(
  List<String> roles, {
  List<PerfilJugador> jugadores = const [],
  List<PerfilEquipo> equipos = const [],
}) => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: roles,
  jugadores: jugadores,
  equipos: equipos,
);

PerfilJugador _jugador(int id, String nombre, String equipo, int? equipoId) =>
    PerfilJugador(
      id: id,
      nombre: nombre,
      apellidos: 'Garcia',
      equipo: equipo,
      equipoId: equipoId,
    );

Future<void> _pintar(WidgetTester tester, Widget home) async {
  // Alto de sobra: el menú del Área club es una lista perezosa y, con más
  // opciones, las últimas quedarían sin construir.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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

Future<void> _menuClub(WidgetTester tester, List<String> roles) async {
  await AuthManager.establecerUsuario(
    AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
  );
  await _pintar(tester, const ClubPage());
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('menú Área club', () {
    for (final rol in ['JUGADOR', 'FAMILIAR', 'ENTRENADOR']) {
      testWidgets('$rol ve "Mis clasificaciones"', (tester) async {
        await _menuClub(tester, [rol]);

        expect(find.text('Mis clasificaciones'), findsOneWidget);
        expect(find.text('Clasificación de tus equipos'), findsOneWidget);
        expect(find.byIcon(Icons.leaderboard_outlined), findsOneWidget);
      });
    }

    for (final rol in ['COORDINADOR', 'ADMIN_APP']) {
      testWidgets('$rol ve "Clasificaciones" de todos los equipos', (
        tester,
      ) async {
        await _menuClub(tester, [rol]);

        expect(find.text('Clasificaciones'), findsOneWidget);
        expect(find.text('Clasificación de todos los equipos'), findsOneWidget);
        expect(find.text('Mis clasificaciones'), findsNothing);
      });
    }

    testWidgets('quien solo es RETRANSMISION no la ve', (tester) async {
      await _menuClub(tester, ['RETRANSMISION']);

      expect(find.text('Mis clasificaciones'), findsNothing);
      expect(find.text('Clasificaciones'), findsNothing);
      expect(find.byIcon(Icons.leaderboard_outlined), findsNothing);
    });
  });

  group('MisClasificacionesPage', () {
    testWidgets(
      'COORDINADOR ve todos los equipos, los sin clasificación al final',
      (tester) async {
        final servicio = _FakeTeamService(
          equipos: [
            _equipo(1, 'Primer Equipo'),
            _equipo(2, 'Cadete A'),
            _equipo(3, 'Alevín B'),
          ],
          clasificaciones: {3: _clasificacion(3, 12, 6)},
          fallan: {2},
        );

        await _pintar(
          tester,
          MisClasificacionesPage(
            cargarPerfil: () async => _perfil(['COORDINADOR']),
            teamService: servicio,
          ),
        );

        // Título de gestión global; el equipo que falla no rompe la lista.
        expect(find.text('Clasificaciones'), findsOneWidget);
        expect(find.text('Primer Equipo'), findsOneWidget);
        expect(find.text('Cadete A'), findsOneWidget);
        expect(find.text('Alevín B'), findsOneWidget);

        expect(find.text('3º · 12 pts · J6'), findsOneWidget);
        expect(find.text('Sin clasificación todavía'), findsNWidgets(2));

        // El único con clasificación sube arriba del todo.
        final conDatos = tester.getTopLeft(find.text('Alevín B')).dy;
        expect(
          conDatos,
          lessThan(tester.getTopLeft(find.text('Primer Equipo')).dy),
        );
        expect(conDatos, lessThan(tester.getTopLeft(find.text('Cadete A')).dy));
      },
    );

    testWidgets('con varios roles gana el más amplio (COORDINADOR ve todos)', (
      tester,
    ) async {
      await _pintar(
        tester,
        MisClasificacionesPage(
          cargarPerfil: () async => _perfil(
            ['FAMILIAR', 'COORDINADOR'],
            jugadores: [_jugador(10, 'Pablo', 'Cadete A', 2)],
          ),
          teamService: _FakeTeamService(
            equipos: [_equipo(1, 'Primer Equipo'), _equipo(2, 'Cadete A')],
          ),
        ),
      );

      expect(find.text('Primer Equipo'), findsOneWidget);
      expect(find.text('Cadete A'), findsOneWidget);
    });

    testWidgets(
      'FAMILIAR con dos hijos en el mismo equipo ve una sola entrada',
      (tester) async {
        final perfil = _perfil(
          ['FAMILIAR'],
          jugadores: [
            _jugador(10, 'Pablo', 'Cadete A', 2),
            _jugador(11, 'Lucia', 'Cadete A', 2),
            _jugador(12, 'Sin id', 'Equipo raro', null),
            _jugador(13, 'Marta', 'Alevín B', 3),
          ],
        );

        await _pintar(
          tester,
          MisClasificacionesPage(
            cargarPerfil: () async => perfil,
            teamService: _FakeTeamService(),
          ),
        );

        expect(find.text('Cadete A'), findsOneWidget);
        expect(find.text('Alevín B'), findsOneWidget);
        expect(find.text('Equipo raro'), findsNothing);
        expect(find.textContaining('Pablo Garcia'), findsOneWidget);
        expect(find.textContaining('Lucia Garcia'), findsOneWidget);
        expect(find.text('Mis clasificaciones'), findsOneWidget);
      },
    );

    test('ENTRENADOR suma sus equipos sin duplicar los de sus jugadores', () {
      final perfil = _perfil(
        ['ENTRENADOR', 'JUGADOR'],
        jugadores: [_jugador(10, 'Pablo', 'Cadete A', 2)],
        equipos: [
          PerfilEquipo(id: 2, nombre: 'Cadete A'),
          PerfilEquipo(id: 5, nombre: 'Infantil B'),
        ],
      );

      final entradas = construirEntradasClasificacion(perfil, const []);

      expect(entradas.map((e) => e.equipoId), [2, 5]);
      expect(entradas.first.jugadores, ['Pablo Garcia']);
    });

    testWidgets('con un solo equipo abre directamente su clasificación', (
      tester,
    ) async {
      await _pintar(
        tester,
        MisClasificacionesPage(
          cargarPerfil: () async => _perfil(
            ['JUGADOR'],
            jugadores: [_jugador(10, 'Pablo', 'Cadete A', 2)],
          ),
          teamService: _FakeTeamService(
            clasificaciones: {2: _clasificacion(1, 9, 3)},
          ),
        ),
      );

      expect(find.byType(TeamStandingsPage), findsOneWidget);
      expect(find.byType(MisClasificacionesPage), findsNothing);
    });

    testWidgets('sin equipos muestra el estado vacío', (tester) async {
      await _pintar(
        tester,
        MisClasificacionesPage(
          cargarPerfil: () async => _perfil(['FAMILIAR']),
          teamService: _FakeTeamService(),
        ),
      );

      expect(find.text('No tienes equipos asociados.'), findsOneWidget);
    });

    testWidgets('si falla el perfil muestra el error con reintento', (
      tester,
    ) async {
      var intentos = 0;

      await _pintar(
        tester,
        MisClasificacionesPage(
          cargarPerfil: () async {
            intentos++;
            if (intentos == 1) throw Exception('sin red');
            return _perfil(['FAMILIAR']);
          },
          teamService: _FakeTeamService(),
        ),
      );

      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('No tienes equipos asociados.'), findsOneWidget);
    });

    testWidgets('al pulsar una tarjeta abre la clasificación del equipo', (
      tester,
    ) async {
      await _pintar(
        tester,
        MisClasificacionesPage(
          cargarPerfil: () async => _perfil(['COORDINADOR']),
          teamService: _FakeTeamService(
            equipos: [_equipo(1, 'Primer Equipo'), _equipo(2, 'Cadete A')],
          ),
        ),
      );

      await tester.tap(find.text('Cadete A'));
      await tester.pumpAndSettle();

      expect(find.byType(TeamStandingsPage), findsOneWidget);
      expect(find.text('Clasificación no disponible todavía'), findsOneWidget);
    });
  });
}
