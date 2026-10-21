import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_form_page.dart';
import 'package:app_mutxamel_cf/features/coordinacion/models/coordinacion_model.dart';
import 'package:app_mutxamel_cf/features/coordinacion/pages/fin_de_semana_page.dart';
import 'package:app_mutxamel_cf/features/coordinacion/pages/seguimiento_jugadores_page.dart';
import 'package:app_mutxamel_cf/features/coordinacion/services/coordinacion_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/justificacion_partido_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/justificacion_partido_service.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeCoordinacion extends CoordinacionService {
  FinDeSemanaModel finDeSemana = _panel();
  List<SeguimientoJugadorModel> seguimiento = _jugadores();
  int dias = 30;
  Object? fallo;

  final List<DateTime?> fechasPedidas = [];
  final List<String> periodosPedidos = [];
  final List<int> detallesPedidos = [];

  @override
  Future<FinDeSemanaModel> obtenerFinDeSemana({DateTime? fecha}) async {
    fechasPedidas.add(fecha);

    if (fallo != null) throw fallo!;

    // Devuelve el fin de semana de la fecha pedida (o el de la semana de hoy).
    final base = fecha ?? DateTime(2026, 10, 23);

    return FinDeSemanaModel(
      desde: base,
      hasta: DateTime(base.year, base.month, base.day + 2),
      sinConvocatoria: finDeSemana.sinConvocatoria,
      resultadosPendientes: finDeSemana.resultadosPendientes,
      descansan: finDeSemana.descansan,
      sinPartido: finDeSemana.sinPartido,
      ultimaImportacionFfcv: finDeSemana.ultimaImportacionFfcv,
    );
  }

  @override
  Future<SeguimientoModel> obtenerSeguimiento({
    String periodo = periodoSeguimiento30d,
  }) async {
    periodosPedidos.add(periodo);

    if (fallo != null) throw fallo!;

    return SeguimientoModel(
      dias: dias,
      jugadores: periodo == periodoSeguimientoTemporada
          ? [
              ...seguimiento,
              _jugador(9, 'Marta Gil', 'Alevín A', faltas: 6, mal: 0),
            ]
          : seguimiento,
    );
  }

  @override
  Future<SeguimientoDetalleModel> obtenerDetalle(
    int jugadorId, {
    String periodo = periodoSeguimiento30d,
  }) async {
    detallesPedidos.add(jugadorId);

    return SeguimientoDetalleModel(
      jugador: seguimiento.firstWhere((j) => j.jugadorId == jugadorId),
      incidencias: [
        IncidenciaEntrenamientoModel(
          fecha: DateTime(2026, 10, 19),
          estado: 'FALTA',
        ),
        IncidenciaEntrenamientoModel(
          fecha: DateTime(2026, 10, 14),
          estado: 'MAL_COMPORTAMIENTO',
        ),
      ],
    );
  }
}

PartidoPanelModel _partido(
  int id,
  String equipo,
  String rival, {
  int retraso = 0,
}) => PartidoPanelModel(
  equipoId: id,
  equipo: equipo,
  partidoId: id * 10,
  rival: rival,
  dia: DateTime(2099, 10, 24),
  hora: '11:00',
  local: true,
  diasDeRetraso: retraso,
);

FinDeSemanaModel _panel({bool vacio = false}) => FinDeSemanaModel(
  desde: DateTime(2026, 10, 23),
  hasta: DateTime(2026, 10, 25),
  sinConvocatoria: vacio ? [] : [_partido(2, 'Cadete A', 'Pego C.F.')],
  resultadosPendientes: vacio
      ? []
      : [_partido(1, 'Primer Equipo', 'Elx', retraso: 3)],
  descansan: vacio
      ? []
      : [const EquipoPanelModel(equipoId: 4, equipo: 'Alevín A', jornada: 8)],
  sinPartido: vacio
      ? []
      : [const EquipoPanelModel(equipoId: 3, equipo: 'Infantil A')],
  ultimaImportacionFfcv: vacio ? null : DateTime(2026, 10, 21, 8, 30),
);

SeguimientoJugadorModel _jugador(
  int id,
  String nombre,
  String equipo, {
  int faltas = 0,
  int mal = 0,
  int retrasos = 0,
}) => SeguimientoJugadorModel(
  jugadorId: id,
  nombre: nombre,
  equipo: equipo,
  faltas: faltas,
  faltasJustificadas: 1,
  malComportamiento: mal,
  retrasos: retrasos,
  ultimaIncidencia: DateTime(2026, 10, 19),
  motivo: faltas > 0 && mal > 0
      ? 'AMBOS'
      : (faltas > 0 ? 'FALTAS' : 'COMPORTAMIENTO'),
);

List<SeguimientoJugadorModel> _jugadores() => [
  _jugador(1, 'Pablo Garcia', 'Cadete A', faltas: 5, mal: 2, retrasos: 3),
  _jugador(2, 'Luis Lopez', 'Infantil A', mal: 2),
  _jugador(3, 'Ana Ruiz', 'Cadete A', faltas: 3),
];

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
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('Fin de semana', () {
    testWidgets('muestra las cabeceras con fechas, las secciones con su '
        'contador y la nota de importación', (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(
        _app(FinDeSemanaPage(servicio: _FakeCoordinacion())),
      );
      await tester.pumpAndSettle();

      expect(find.text('23/10/2026 - 25/10/2026'), findsOneWidget);

      for (final seccion in [
        'Sin convocatoria',
        'Resultados pendientes',
        'Descansan',
        'Sin partido ni descanso',
      ]) {
        expect(find.text(seccion), findsOneWidget);
      }

      expect(find.text('¿Falta importar la jornada?'), findsOneWidget);
      expect(find.text('Cadete A - Pego C.F.'), findsOneWidget);
      expect(find.text('Primer Equipo - Elx'), findsOneWidget);
      expect(find.textContaining('Hace 3 días'), findsOneWidget);
      expect(find.text('Jornada 8'), findsOneWidget);
      expect(find.text('Infantil A'), findsOneWidget);
      expect(find.textContaining('21/10/2026'), findsOneWidget);

      // Con cosas pendientes no hay "Todo al día".
      expect(find.text('Todo al día'), findsNothing);
    });

    testWidgets('las secciones se pliegan', (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(
        _app(FinDeSemanaPage(servicio: _FakeCoordinacion())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sin convocatoria'));
      await tester.pumpAndSettle();

      expect(find.text('Cadete A - Pego C.F.'), findsNothing);
      expect(find.text('Primer Equipo - Elx'), findsOneWidget);
    });

    testWidgets('sin nada pendiente muestra "Todo al día" con un check verde', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion()..finDeSemana = _panel(vacio: true);

      await tester.pumpWidget(_app(FinDeSemanaPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('Todo al día'), findsOneWidget);
      expect(find.text('Sin convocatoria'), findsNothing);

      final icono = tester.widget<Icon>(
        find.byIcon(Icons.check_circle_outline),
      );

      expect(icono.color, const Color(0xFF16A34A));
    });

    testWidgets('las flechas van al fin de semana anterior y al siguiente', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion();

      await tester.pumpWidget(_app(FinDeSemanaPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Fin de semana anterior'));
      await tester.pumpAndSettle();

      expect(find.text('16/10/2026 - 18/10/2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Fin de semana siguiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fin de semana siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('30/10/2026 - 01/11/2026'), findsOneWidget);
      expect(servicio.fechasPedidas, [
        null,
        DateTime(2026, 10, 16),
        DateTime(2026, 10, 23),
        DateTime(2026, 10, 30),
      ]);
    });

    testWidgets(
      'un partido sin convocatoria abre el formulario de convocatoria '
      'con ese partido',
      (tester) async {
        _pantallaGrande(tester);

        PartidoPanelModel? abierto;

        await tester.pumpWidget(
          _app(
            FinDeSemanaPage(
              servicio: _FakeCoordinacion(),
              constructorConvocatoria: (partido) {
                abierto = partido;
                return const Scaffold(body: Text('CONVOCATORIA'));
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cadete A - Pego C.F.'));
        await tester.pumpAndSettle();

        expect(find.text('CONVOCATORIA'), findsOneWidget);
        expect(abierto?.partidoId, 20);
        expect(abierto?.equipoId, 2);
      },
    );

    testWidgets('un resultado pendiente abre el formulario de resultado de ese '
        'partido', (tester) async {
      _pantallaGrande(tester);

      PartidoPanelModel? abierto;

      await tester.pumpWidget(
        _app(
          FinDeSemanaPage(
            servicio: _FakeCoordinacion(),
            constructorResultado: (partido) {
              abierto = partido;
              return const Scaffold(body: Text('RESULTADO'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Primer Equipo - Elx'));
      await tester.pumpAndSettle();

      expect(find.text('RESULTADO'), findsOneWidget);
      expect(abierto?.partidoId, 10);
    });

    testWidgets('al volver del formulario se recarga el panel', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion();

      await tester.pumpWidget(
        _app(
          FinDeSemanaPage(
            servicio: servicio,
            constructorConvocatoria: (_) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('VOLVER'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadete A - Pego C.F.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VOLVER'));
      await tester.pumpAndSettle();

      expect(servicio.fechasPedidas, hasLength(2));
    });

    testWidgets('con un error muestra el aviso y reintenta', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion()..fallo = Exception('sin red');

      await tester.pumpWidget(_app(FinDeSemanaPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se ha podido conectar'), findsOneWidget);

      servicio.fallo = null;

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Sin convocatoria'), findsOneWidget);
    });

    testWidgets('el formulario de convocatoria abre con el partido '
        'preseleccionado', (tester) async {
      _pantallaGrande(tester);

      final justificaciones = _FakeJustificaciones();

      await tester.pumpWidget(
        _app(
          ConvocatoriaFormPage(
            equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
            partidoIdInicial: 31,
            teamService: _FakeTeam(),
            matchService: _FakeMatches(),
            justificacionService: justificaciones,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El partido 31 (Elx) está elegido: se pidieron sus ausencias.
      expect(justificaciones.consultas, [31]);
      expect(find.textContaining('Elx'), findsWidgets);
    });
  });

  group('Seguimiento de jugadores', () {
    testWidgets(
      'muestra tarjetas con chips y la fecha de la última incidencia',
      (tester) async {
        _pantallaGrande(tester);

        await tester.pumpWidget(
          _app(SeguimientoJugadoresPage(servicio: _FakeCoordinacion())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pablo Garcia'), findsOneWidget);
        expect(find.text('5 faltas'), findsOneWidget);
        expect(find.text('2 mal comportamiento'), findsNWidgets(2));
        expect(find.text('3 faltas'), findsOneWidget);
        expect(find.text('Última incidencia: 19/10/2026'), findsNWidgets(3));
        expect(find.text('Datos solo para coordinación'), findsOneWidget);
      },
    );

    testWidgets('el selector cambia de periodo y vuelve a pedir los datos', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion();

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marta Gil'), findsNothing);

      await tester.tap(find.text('Temporada'));
      await tester.pumpAndSettle();

      expect(servicio.periodosPedidos, ['30d', 'temporada']);
      expect(find.text('Marta Gil'), findsOneWidget);
    });

    testWidgets('el filtro por equipo deja solo los jugadores de ese equipo', (
      tester,
    ) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: _FakeCoordinacion())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Todos los equipos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Infantil A').last);
      await tester.pumpAndSettle();

      expect(find.text('Luis Lopez'), findsOneWidget);
      expect(find.text('Pablo Garcia'), findsNothing);
      expect(find.text('Ana Ruiz'), findsNothing);
    });

    testWidgets('sin jugadores sobre los umbrales muestra el estado vacío', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion()..seguimiento = [];

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Ningún jugador llega a los umbrales en este periodo'),
        findsOneWidget,
      );
    });

    testWidgets('al pulsar un jugador muestra sus incidencias con fecha y '
        'estado', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion();

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: servicio)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      expect(servicio.detallesPedidos, [1]);
      expect(find.text('19/10/2026'), findsOneWidget);
      expect(find.text('14/10/2026'), findsOneWidget);
      expect(find.text('Falta'), findsOneWidget);
      expect(find.text('Mal comportamiento'), findsOneWidget);
    });
  });

  group('Seguimiento: contadores, periodo y permisos', () {
    testWidgets('la tarjeta lleva los chips de justificadas y retrasos y el '
        'periodo usa los días que manda el servidor', (tester) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion()..dias = 45;

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Últimos 45 días'), findsOneWidget);
      expect(find.text('Últimos 30 días'), findsNothing);
      expect(find.text('1 justificada'), findsNWidgets(3));
      expect(find.text('3 retrasos'), findsOneWidget);
    });

    testWidgets('el detalle muestra en la cabecera todos los contadores', (
      tester,
    ) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: _FakeCoordinacion())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      expect(find.text('5 faltas'), findsOneWidget);
      expect(find.text('2 mal comportamiento'), findsOneWidget);
      expect(find.text('1 justificada'), findsOneWidget);
      expect(find.text('3 retrasos'), findsOneWidget);
    });

    testWidgets('un 403 muestra "No tienes permiso", no un error de conexión', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion()
        ..fallo = const ApiException('prohibido', statusCode: 403);

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.textContaining('No se ha podido conectar'), findsNothing);
    });

    testWidgets('el panel del fin de semana también distingue el 403', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion()
        ..fallo = const ApiException('prohibido', statusCode: 403);

      await tester.pumpWidget(_app(FinDeSemanaPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.textContaining('No se ha podido conectar'), findsNothing);
    });

    testWidgets('un fallo de red sigue siendo un error de conexión', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final servicio = _FakeCoordinacion()..fallo = Exception('sin red');

      await tester.pumpWidget(
        _app(SeguimientoJugadoresPage(servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No se ha podido conectar'), findsOneWidget);
    });
  });

  group('Formulario de convocatoria desde el panel', () {
    testWidgets('pide el partido con incluirPartidoId para poder '
        'preseleccionarlo', (tester) async {
      _pantallaGrande(tester);

      final partidos = _FakeMatches();

      await tester.pumpWidget(
        _app(
          ConvocatoriaFormPage(
            equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
            partidoIdInicial: 31,
            teamService: _FakeTeam(),
            matchService: partidos,
            justificacionService: _FakeJustificaciones(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(partidos.incluidos, [31]);
    });

    for (final caso in {
      'cancelado': MatchModel(
        id: 32,
        equipoId: 5,
        categoria: 'Cadete',
        equipo: 'Cadete A',
        rival: 'Cancelado FC',
        dia: DateTime(2099, 10, 26),
        cancelado: true,
      ),
      'de un día anterior a hoy': MatchModel(
        id: 33,
        equipoId: 5,
        categoria: 'Cadete',
        equipo: 'Cadete A',
        rival: 'Pasado FC',
        dia: DateTime(2020, 1, 15),
      ),
      'que ya tiene convocatoria': MatchModel(
        id: 34,
        equipoId: 5,
        categoria: 'Cadete',
        equipo: 'Cadete A',
        rival: 'Convocado FC',
        dia: DateTime(2099, 10, 27),
        tieneConvocatoria: true,
      ),
    }.entries) {
      testWidgets('un partido ${caso.key} no se preselecciona y avisa con el '
          'SnackBar', (tester) async {
        _pantallaGrande(tester);

        final justificaciones = _FakeJustificaciones();

        await tester.pumpWidget(
          _app(
            ConvocatoriaFormPage(
              equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
              partidoIdInicial: caso.value.id,
              teamService: _FakeTeam(),
              matchService: _FakeMatches([caso.value]),
              justificacionService: justificaciones,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No se eligió: ni se pidieron sus ausencias ni aparece su rival como elegido.
        expect(justificaciones.consultas, isEmpty);
        expect(
          find.text('Este partido ya no admite convocatoria'),
          findsOneWidget,
        );
        expect(find.text(caso.value.rival), findsNothing);
      });
    }

    testWidgets('un partido válido sí se preselecciona y no hay SnackBar', (
      tester,
    ) async {
      _pantallaGrande(tester);

      final justificaciones = _FakeJustificaciones();

      await tester.pumpWidget(
        _app(
          ConvocatoriaFormPage(
            equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
            partidoIdInicial: 31,
            teamService: _FakeTeam(),
            matchService: _FakeMatches(),
            justificacionService: justificaciones,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(justificaciones.consultas, [31]);
      expect(find.text('Este partido ya no admite convocatoria'), findsNothing);
    });

    test(
      'MatchModel lee tieneConvocatoria (nulo si el servidor no lo manda)',
      () {
        expect(
          MatchModel.fromJson({
            'rival': 'X',
            'tieneConvocatoria': true,
          }).tieneConvocatoria,
          isTrue,
        );
        expect(MatchModel.fromJson({'rival': 'X'}).tieneConvocatoria, isNull);
      },
    );

    testWidgets('si el partido no viene en la lista se avisa con un SnackBar', (
      tester,
    ) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(
        _app(
          ConvocatoriaFormPage(
            equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
            partidoIdInicial: 999,
            teamService: _FakeTeam(),
            matchService: _FakeMatches(),
            justificacionService: _FakeJustificaciones(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Este partido ya no admite convocatoria'),
        findsOneWidget,
      );
    });
  });

  group('Menú del Área club por rol', () {
    Future<void> pintarClub(WidgetTester tester, List<String> roles) async {
      _pantallaGrande(tester);

      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
      );

      await tester.pumpWidget(_app(const ClubPage()));
      await tester.pump();
    }

    tearDown(AuthManager.olvidarUsuario);

    for (final rol in ['COORDINADOR', 'ADMIN_APP']) {
      testWidgets('$rol ve las dos opciones, tras "Todos los equipos"', (
        tester,
      ) async {
        await pintarClub(tester, [rol]);

        expect(find.text('Fin de semana'), findsOneWidget);
        expect(find.text('Seguimiento de jugadores'), findsOneWidget);
        expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
        expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);

        final equipos = tester.getTopLeft(find.text('Todos los equipos')).dy;
        final fin = tester.getTopLeft(find.text('Fin de semana')).dy;
        final seguimiento = tester
            .getTopLeft(find.text('Seguimiento de jugadores'))
            .dy;

        expect(equipos, lessThan(fin));
        expect(fin, lessThan(seguimiento));
      });
    }

    for (final rol in ['ENTRENADOR', 'FAMILIAR', 'JUGADOR']) {
      testWidgets('$rol no las ve', (tester) async {
        await pintarClub(tester, [rol]);

        expect(find.text('Fin de semana'), findsNothing);
        expect(find.text('Seguimiento de jugadores'), findsNothing);
      });
    }
  });

  test('los modelos leen el JSON del backend', () {
    final panel = FinDeSemanaModel.fromJson({
      'desde': '2026-10-23',
      'hasta': '2026-10-25',
      'sinConvocatoria': [
        {
          'equipoId': 2,
          'equipo': 'Cadete A',
          'partidoId': 20,
          'rival': 'Pego',
          'dia': '2026-10-24',
          'hora': '11:00',
          'local': false,
        },
      ],
      'resultadosPendientes': [],
      'descansan': [
        {'equipoId': 4, 'equipo': 'Alevín A', 'jornada': 8},
      ],
      'sinPartido': [],
      'resumen': {'ultimaImportacionFfcv': '2026-10-21T08:30:00'},
    });

    expect(panel.sinConvocatoria.single.local, isFalse);
    expect(panel.sinConvocatoria.single.dia, DateTime(2026, 10, 24));
    expect(panel.descansan.single.jornada, 8);
    expect(panel.ultimaImportacionFfcv, DateTime(2026, 10, 21, 8, 30));
    expect(panel.todoAlDia, isFalse);
  });
}

class _FakeJustificaciones extends JustificacionPartidoService {
  final List<int> consultas = [];

  @override
  Future<List<JustificacionPartidoModel>> obtener(int partidoId) async {
    consultas.add(partidoId);
    return [];
  }
}

class _FakeTeam extends TeamService {
  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async => [];
}

class _FakeMatches extends MatchService {
  final List<int?> incluidos = [];

  /// Partidos extra que devuelve el servidor (p. ej. el pedido con incluirPartidoId).
  final List<MatchModel> extra;

  _FakeMatches([this.extra = const []]);

  @override
  Future<List<MatchModel>> obtenerPartidosSinConvocatoria(
    int equipoId, {
    int? incluirPartidoId,
  }) async {
    incluidos.add(incluirPartidoId);

    return _partidos();
  }

  List<MatchModel> _partidos() => [
    ...extra,
    MatchModel(
      id: 30,
      equipoId: 5,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Pego C.F.',
      dia: DateTime(2099, 10, 24),
      hora: '11:00',
    ),
    MatchModel(
      id: 31,
      equipoId: 5,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Elx',
      dia: DateTime(2099, 10, 25),
      hora: '12:00',
    ),
  ];
}
