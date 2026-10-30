import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_detalle_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_familia_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_form_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_partido_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_partido_service.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/invitados/models/invitacion_model.dart';
import 'package:app_mutxamel_cf/features/invitados/services/invitados_service.dart';
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

// ---- dobles ---------------------------------------------------------------------------

class _FakeConvocatoriaService extends ConvocatoriaService {
  final List<({List<int>? jugadores, List<int>? invitados})> guardadas = [];
  final List<({int convocatoria, List<int>? invitados})> actualizadas = [];
  Object? fallo;
  ConvocatoriaModel? tras;

  @override
  Future<ConvocatoriaModel> obtenerPorId(int convocatoriaId) async => tras!;

  @override
  Future<ConvocatoriaModel> crear({
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
    List<int>? invitadosIds,
  }) async {
    if (fallo != null) throw fallo!;

    guardadas.add((jugadores: jugadoresIds, invitados: invitadosIds));

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
  }) async {
    if (fallo != null) throw fallo!;

    guardadas.add((jugadores: jugadoresIds, invitados: invitadosIds));
    actualizadas.add((convocatoria: convocatoriaId, invitados: invitadosIds));

    return _convocatoria();
  }
}

class _FakeInvitados extends InvitadosService {
  List<EquipoInvitableModel> equipos = const [
    EquipoInvitableModel(
      equipoId: 2,
      nombre: 'Cadete B',
      categoria: 'Cadete',
      grupo: 'B',
    ),
    EquipoInvitableModel(
      equipoId: 3,
      nombre: 'Infantil A',
      categoria: 'Infantil',
      grupo: 'A',
    ),
  ];

  Map<int, List<JugadorInvitableModel>> jugadores = {
    2: const [
      JugadorInvitableModel(jugadorId: 1, nombre: 'Ana Pérez', dorsal: 7),
      JugadorInvitableModel(jugadorId: 2, nombre: 'Biel Gil', dorsal: 9),
      JugadorInvitableModel(jugadorId: 4, nombre: 'Dani Ruiz', dorsal: 11),
      JugadorInvitableModel(
        jugadorId: 5,
        nombre: 'Eva Mas',
        dorsal: 5,
        bloqueado: true,
        motivoBloqueo: 'Ya está invitado con Cadete C el 14/11/2026',
      ),
    ],
    3: const [
      JugadorInvitableModel(jugadorId: 3, nombre: 'Carla Sanz', dorsal: 4),
    ],
  };

  final List<String> llamadas = [];
  Object? falloAlLiberar;

  @override
  Future<List<EquipoInvitableModel>> obtenerEquipos(int partidoId) async {
    llamadas.add('equipos:$partidoId');
    return equipos;
  }

  @override
  Future<List<JugadorInvitableModel>> obtenerJugadores(
    int partidoId,
    int equipoId,
  ) async {
    llamadas.add('jugadores:$partidoId:$equipoId');
    return jugadores[equipoId] ?? [];
  }

  @override
  Future<InvitacionResultadoModel> liberar(int invitacionId) async {
    llamadas.add('liberar:$invitacionId');

    if (falloAlLiberar != null) throw falloAlLiberar!;

    return InvitacionResultadoModel(
      id: invitacionId,
      estado: EstadoInvitacion.autorizado,
    );
  }
}

class _FakeJustificaciones extends JustificacionPartidoService {
  @override
  Future<List<JustificacionPartidoModel>> obtener(int partidoId) async => [];
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async => [
    _jugador(100, 'Pablo', 'Garcia'),
    _jugador(101, 'Luis', 'Lopez'),
    _jugador(102, 'Ana', 'Ruiz'),
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
      dia: DateTime(2026, 10, 24),
      hora: '11:00',
    ),
  ];
}

PlayerModel _jugador(int id, String nombre, String apellidos) => PlayerModel(
  id: id,
  nombre: nombre,
  apellidos: apellidos,
  categoria: 'Cadete',
  equipo: 'Cadete A',
  deporte: 'F',
);

ConvocatoriaJugadorModel _propio(int id, String nombre) =>
    ConvocatoriaJugadorModel(jugadorId: id, jugador: nombre);

ConvocatoriaJugadorModel _invitado(
  int id,
  String nombre,
  EstadoInvitacion estado, {
  String origen = 'Cadete B',
  String? motivoRechazo,
  bool ausente = false,
  String? motivoAusencia,
}) => ConvocatoriaJugadorModel(
  jugadorId: id,
  jugador: nombre,
  invitado: true,
  equipoOrigenId: 2,
  equipoOrigen: origen,
  estadoInvitacion: estado,
  motivoRechazo: motivoRechazo,
  ausenciaJustificada: ausente,
  motivoAusencia: motivoAusencia,
);

ConvocatoriaModel _convocatoria({List<ConvocatoriaJugadorModel>? jugadores}) =>
    ConvocatoriaModel(
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
      jugadores:
          jugadores ??
          [
            _propio(100, 'Pablo Garcia'),
            _propio(101, 'Luis Lopez'),
            _invitado(1, 'Ana Pérez', EstadoInvitacion.autorizado),
            _invitado(2, 'Biel Gil', EstadoInvitacion.pendienteCoordinacion),
            _invitado(
              3,
              'Carla Sanz',
              EstadoInvitacion.pendienteEntrenador,
              origen: 'Infantil A',
            ),
            _invitado(
              4,
              'Dani Ruiz',
              EstadoInvitacion.rechazado,
              motivoRechazo: 'Ese día juega con su equipo',
            ),
          ],
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
  required _FakeConvocatoriaService convocatorias,
  required _FakeInvitados invitados,
}) => ConvocatoriaFormPage(
  equipo: _equipo,
  convocatoria: convocatoria,
  teamService: _FakeTeamService(),
  matchService: _FakeMatchService(),
  convocatoriaService: convocatorias,
  justificacionService: _FakeJustificaciones(),
  invitadosService: invitados,
);

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  // ---- formulario: elegir invitados ---------------------------------------------------

  group('formulario', () {
    testWidgets('al crear, la sección sale debajo de los jugadores y sin partido '
        'no se puede añadir', (tester) async {
      await _pintar(
        tester,
        _formulario(
          convocatorias: _FakeConvocatoriaService(),
          invitados: _FakeInvitados(),
        ),
      );

      expect(find.text('Jugadores de otros equipos'), findsOneWidget);
      expect(find.text('Invitados: 0 de 3'), findsOneWidget);
      expect(
        find.text(
          'Elige primero el partido para poder invitar a jugadores de otros equipos.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('invitados-anadir')),
            )
            .onPressed,
        isNull,
      );

      // Debajo de los jugadores del equipo.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('invitados-seccion'))).dy,
        greaterThan(
          tester
              .getBottomLeft(
                find.byKey(const ValueKey('jugador-convocatoria-102')),
              )
              .dy,
        ),
      );
    });

    testWidgets('elegir equipo y jugadores, volver y guardar envía invitadosIds', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatoriaService();
      final invitados = _FakeInvitados();

      await _pintar(
        tester,
        _formulario(convocatorias: convocatorias, invitados: invitados),
      );

      // Elige el partido.
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Pego C.F.').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('invitados-anadir')));
      await tester.pumpAndSettle();

      // Los equipos que permite el servidor para ese partido.
      expect(invitados.llamadas, ['equipos:30']);
      expect(find.byKey(const ValueKey('invitables-equipo-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('invitables-equipo-3')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('invitables-equipo-2')));
      await tester.pumpAndSettle();

      expect(invitados.llamadas.last, 'jugadores:30:2');

      await tester.tap(find.byKey(const ValueKey('invitable-1')));
      await tester.tap(find.byKey(const ValueKey('invitable-2')));
      await tester.pumpAndSettle();

      expect(find.text('Invitados: 2 de 3'), findsOneWidget);

      // Atrás desde los jugadores vuelve a la lista de equipos y conserva lo elegido.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('invitables-equipo-2')), findsOneWidget);
      expect(find.text('Invitados: 2 de 3'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('invitables-equipo-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('invitable-3')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('invitados-listo')));
      await tester.pumpAndSettle();

      // De vuelta en el formulario, cada invitado con su equipo y a falta de enviar.
      expect(find.text('Invitados: 3 de 3'), findsWidgets);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Invitado · Cadete B'), findsNWidgets(2));
      expect(find.text('Invitado · Infantil A'), findsOneWidget);
      expect(
        find.text('Se enviará a coordinación al guardar'),
        findsNWidgets(3),
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('invitados-anadir')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Máximo 3 invitados por convocatoria'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.enterText(find.byType(TextField), 'Vestuarios');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar convocatoria'));
      await tester.pumpAndSettle();

      expect(convocatorias.guardadas, hasLength(1));
      // Los del equipo van en jugadoresIds; los de otros equipos, en invitadosIds.
      expect(convocatorias.guardadas.single.jugadores, [100]);
      expect(convocatorias.guardadas.single.invitados!.toSet(), {1, 2, 3});
    });

    testWidgets('al guardar sin invitados se manda la lista vacía, no null', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatoriaService();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(
            jugadores: [_propio(100, 'Pablo Garcia')],
          ),
          convocatorias: convocatorias,
          invitados: _FakeInvitados(),
        ),
      );

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(convocatorias.guardadas.single.invitados, isEmpty);
      expect(convocatorias.guardadas.single.invitados, isNotNull);
    });

    testWidgets('no deja pasar de 3 invitados y lo dice', (tester) async {
      final invitados = _FakeInvitados();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(
            jugadores: [_propio(100, 'Pablo Garcia')],
          ),
          convocatorias: _FakeConvocatoriaService(),
          invitados: invitados,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invitados-anadir')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('invitables-equipo-2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('invitable-1')));
      await tester.tap(find.byKey(const ValueKey('invitable-2')));
      await tester.tap(find.byKey(const ValueKey('invitable-4')));
      await tester.pumpAndSettle();

      expect(find.text('Invitados: 3 de 3'), findsOneWidget);

      // Eva está bloqueada; aun desbloqueada no cabría un cuarto.
      invitados.jugadores[2] = const [
        JugadorInvitableModel(jugadorId: 3, nombre: 'Carla Sanz', dorsal: 4),
      ];
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('invitables-equipo-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('invitable-3')));
      await tester.pumpAndSettle();

      expect(find.text('Máximo 3 invitados por convocatoria'), findsOneWidget);
      expect(find.text('Invitados: 3 de 3'), findsOneWidget);

      // Quitar uno de los marcados libera sitio.
      await tester.tap(find.byKey(const ValueKey('invitable-3')));
      await tester.pumpAndSettle();
      expect(find.text('Invitados: 3 de 3'), findsOneWidget);
    });

    testWidgets(
      'un jugador bloqueado por otra invitación ese día no se puede elegir',
      (tester) async {
        await _pintar(
          tester,
          _formulario(
            convocatoria: _convocatoria(
              jugadores: [_propio(100, 'Pablo Garcia')],
            ),
            convocatorias: _FakeConvocatoriaService(),
            invitados: _FakeInvitados(),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('invitados-anadir')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('invitables-equipo-2')));
        await tester.pumpAndSettle();

        expect(
          find.text('Ya está invitado con Cadete C el 14/11/2026'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('invitable-5')));
        await tester.pumpAndSettle();

        expect(find.text('Invitados: 0 de 3'), findsOneWidget);
      },
    );

    testWidgets('si el partido no puede invitar a nadie, lo explica', (
      tester,
    ) async {
      final invitados = _FakeInvitados()..equipos = const [];

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(
            jugadores: [_propio(100, 'Pablo Garcia')],
          ),
          convocatorias: _FakeConvocatoriaService(),
          invitados: invitados,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invitados-anadir')));
      await tester.pumpAndSettle();

      expect(
        find.text('Este equipo no puede invitar a jugadores de otros equipos.'),
        findsOneWidget,
      );
    });
  });

  // ---- formulario: editar --------------------------------------------------------------

  group('editar una convocatoria con invitados', () {
    testWidgets(
      'los invitados salen aparte de los jugadores del equipo, con su estado',
      (tester) async {
        await _pintar(
          tester,
          _formulario(
            convocatoria: _convocatoria(),
            convocatorias: _FakeConvocatoriaService(),
            invitados: _FakeInvitados(),
          ),
        );

        // El contador del equipo solo cuenta a los suyos.
        expect(find.text('2 seleccionados'), findsOneWidget);
        expect(find.text('Invitados: 3 de 3'), findsWidgets);

        expect(find.text('Pendiente de coordinación'), findsOneWidget);
        expect(
          find.text('Pendiente de que su entrenador lo autorice'),
          findsOneWidget,
        );
        expect(find.text('Rechazado por coordinación'), findsOneWidget);
        expect(
          find.text('Motivo: Ese día juega con su equipo'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'al guardar no se reenvían los rechazados y los del equipo van aparte',
      (tester) async {
        final convocatorias = _FakeConvocatoriaService();

        await _pintar(
          tester,
          _formulario(
            convocatoria: _convocatoria(),
            convocatorias: convocatorias,
            invitados: _FakeInvitados(),
          ),
        );

        await tester.tap(find.text('Guardar cambios'));
        await tester.pumpAndSettle();

        final guardada = convocatorias.guardadas.single;

        // 100 y 101 son del equipo: los invitados NO van en jugadoresIds.
        expect(guardada.jugadores!.toSet(), {100, 101});
        // 1 autorizado, 2 y 3 pendientes; el 4 (rechazado) se quita.
        expect(guardada.invitados!.toSet(), {1, 2, 3});
      },
    );

    testWidgets(
      'quitar un invitado con la X lo saca de la lista que se envía',
      (tester) async {
        final convocatorias = _FakeConvocatoriaService();

        await _pintar(
          tester,
          _formulario(
            convocatoria: _convocatoria(),
            convocatorias: convocatorias,
            invitados: _FakeInvitados(),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('invitado-quitar-2')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('invitado-2')), findsNothing);
        expect(find.text('Invitados: 2 de 3'), findsWidgets);

        await tester.tap(find.text('Guardar cambios'));
        await tester.pumpAndSettle();

        expect(convocatorias.guardadas.single.invitados!.toSet(), {1, 3});
      },
    );

    testWidgets(
      'un invitado desestimado por la familia se ve como ausencia y no cuenta',
      (tester) async {
        await _pintar(
          tester,
          _formulario(
            convocatoria: _convocatoria(
              jugadores: [
                _propio(100, 'Pablo Garcia'),
                _invitado(
                  1,
                  'Ana Pérez',
                  EstadoInvitacion.autorizado,
                  ausente: true,
                  motivoAusencia: 'Cumpleaños',
                ),
              ],
            ),
            convocatorias: _FakeConvocatoriaService(),
            invitados: _FakeInvitados(),
          ),
        );

        expect(find.text('Ausencia justificada'), findsOneWidget);
        expect(find.text('Motivo: Cumpleaños'), findsOneWidget);
        expect(find.text('Invitados: 0 de 3'), findsWidgets);
      },
    );
  });

  // ---- 409 -----------------------------------------------------------------------------

  group('409 al guardar', () {
    ApiException conflicto(String codigo, int jugadorId) => ApiException(
      'texto del servidor que no se usa',
      statusCode: 409,
      datos: {
        'codigo': codigo,
        'mensaje': 'texto del servidor que no se usa',
        'jugadorId': jugadorId,
        'equipoDestino': 'Cadete C',
        'fecha': '2026-11-14',
      },
    );

    testWidgets('JUGADOR_INVITADO_ESE_DIA nombra al jugador propio y al equipo', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatoriaService()
        ..fallo = conflicto('JUGADOR_INVITADO_ESE_DIA', 100);

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(),
          convocatorias: convocatorias,
          invitados: _FakeInvitados(),
        ),
      );

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('dialogo-conflicto-invitacion')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Pablo Garcia ya va invitado con Cadete C ese día, así que no puedes '
          'convocarlo con tu equipo.',
        ),
        findsOneWidget,
      );
      expect(find.text('texto del servidor que no se usa'), findsNothing);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('dialogo-conflicto-invitacion')),
        findsNothing,
      );
    });

    testWidgets('JUGADOR_YA_INVITADO_ESE_DIA nombra al invitado y al equipo', (
      tester,
    ) async {
      final convocatorias = _FakeConvocatoriaService()
        ..fallo = conflicto('JUGADOR_YA_INVITADO_ESE_DIA', 2);

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(),
          convocatorias: convocatorias,
          invitados: _FakeInvitados(),
        ),
      );

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Biel Gil ya está autorizado como invitado con Cadete C ese día. '
          'Elige a otro jugador.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('otro error sigue siendo el aviso de siempre', (tester) async {
      final convocatorias = _FakeConvocatoriaService()
        ..fallo = const ApiException('Más de 3', statusCode: 400);

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(),
          convocatorias: convocatorias,
          invitados: _FakeInvitados(),
        ),
      );

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('dialogo-conflicto-invitacion')),
        findsNothing,
      );
      expect(find.textContaining('Más de 3'), findsOneWidget);
    });
  });

  // ---- detalle del entrenador que convoca ----------------------------------------------

  group('detalle de la convocatoria', () {
    Future<void> detalle(
      WidgetTester tester,
      ConvocatoriaModel convocatoria, {
      _FakeConvocatoriaService? servicio,
      _FakeInvitados? invitados,
      LiberarInvitacion? liberar,
    }) => _pintar(
      tester,
      ConvocatoriaDetallePage(
        equipo: _equipo,
        convocatoria: convocatoria,
        service: servicio ?? _FakeConvocatoriaService(),
        invitadosService: invitados ?? _FakeInvitados(),
        liberar: liberar,
        ahora: () => DateTime(2026, 10, 1),
      ),
    );

    testWidgets('cada invitado muestra su equipo de origen y su estado', (
      tester,
    ) async {
      await detalle(tester, _convocatoria());

      // Los que juegan: 2 propios + 1 invitado autorizado.
      expect(find.text('3 convocados'), findsOneWidget);

      expect(find.text('Invitado · Cadete B'), findsNWidgets(3));
      expect(find.text('Invitado · Infantil A'), findsOneWidget);

      // Autorizado: normal, sin texto de estado.
      expect(find.byKey(const ValueKey('estado-invitacion-1')), findsNothing);
      expect(find.text('Pendiente de coordinación'), findsOneWidget);
      expect(
        find.text('Pendiente de que su entrenador lo autorice'),
        findsOneWidget,
      );
      expect(find.text('Rechazado por coordinación'), findsOneWidget);
      expect(find.text('Motivo: Ese día juega con su equipo'), findsOneWidget);

      // Aviso arriba para elegir a otro.
      expect(
        find.byKey(const ValueKey('banner-invitados-rechazados')),
        findsOneWidget,
      );
      expect(
        find.text('1 invitado rechazado por coordinación'),
        findsOneWidget,
      );
    });

    testWidgets(
      'quitar a un rechazado guarda la convocatoria sin él ni los demás cambios',
      (tester) async {
        final servicio = _FakeConvocatoriaService()..tras = _convocatoria();

        await detalle(tester, _convocatoria(), servicio: servicio);

        expect(find.byKey(const ValueKey('quitar-invitado-1')), findsNothing);

        await tester.tap(find.byKey(const ValueKey('quitar-invitado-4')));
        await tester.pumpAndSettle();

        expect(servicio.actualizadas.single.convocatoria, 20);
        // Se conservan los demás invitados; los jugadores del equipo no se tocan (null).
        expect(servicio.actualizadas.single.invitados!.toSet(), {1, 2, 3});
        expect(servicio.guardadas.single.jugadores, isNull);
        expect(find.text('Jugador invitado quitado'), findsOneWidget);
      },
    );

    testWidgets(
      'un invitado desestimado por su familia se ve como ausencia y se puede quitar',
      (tester) async {
        final servicio = _FakeConvocatoriaService()..tras = _convocatoria();

        await detalle(
          tester,
          _convocatoria(
            jugadores: [
              _propio(100, 'Pablo Garcia'),
              _invitado(
                1,
                'Ana Pérez',
                EstadoInvitacion.autorizado,
                ausente: true,
                motivoAusencia: 'Cumpleaños',
              ),
            ],
          ),
          servicio: servicio,
        );

        expect(find.text('Ausencia justificada'), findsWidgets);
        expect(find.text('Motivo: Cumpleaños'), findsOneWidget);
        expect(
          find.text(
            'La familia no puede ir. Quítalo y convoca a otro jugador.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('banner-ausencias')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('quitar-invitado-1')));
        await tester.pumpAndSettle();

        expect(servicio.actualizadas.single.invitados, isEmpty);
      },
    );

    testWidgets('sin invitados la pantalla es la de siempre', (tester) async {
      await detalle(
        tester,
        _convocatoria(jugadores: [_propio(100, 'Pablo Garcia')]),
      );

      expect(find.text('1 convocado'), findsOneWidget);
      expect(find.textContaining('Invitado'), findsNothing);
      expect(
        find.byKey(const ValueKey('banner-invitados-rechazados')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('banner-liberar-invitacion')),
        findsNothing,
      );
    });
  });

  // ---- entrenador del equipo de origen: liberar -------------------------------------------

  group('liberar al jugador desde su convocatoria', () {
    final propia = _convocatoria(
      jugadores: [_propio(100, 'Pablo Garcia'), _propio(101, 'Luis Lopez')],
    );

    testWidgets('explica el solapamiento y ofrece "Liberar a <jugador>"', (
      tester,
    ) async {
      await _pintar(
        tester,
        ConvocatoriaDetallePage(
          equipo: _equipo,
          convocatoria: propia,
          service: _FakeConvocatoriaService()..tras = propia,
          invitadosService: _FakeInvitados(),
          liberar: const LiberarInvitacion(invitacionId: 31, jugadorId: 101),
          ahora: () => DateTime(2026, 10, 1),
        ),
      );

      expect(
        find.byKey(const ValueKey('banner-liberar-invitacion')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Luis Lopez ha sido invitado por otro equipo el mismo día que juega el '
          'tuyo. Si puede jugar con ellos, libéralo de tu convocatoria.',
        ),
        findsOneWidget,
      );
      expect(find.text('Liberar a Luis Lopez'), findsOneWidget);
    });

    testWidgets(
      'liberar llama al servidor, avisa y recarga la convocatoria sin él',
      (tester) async {
        final invitados = _FakeInvitados();
        final sinLuis = _convocatoria(
          jugadores: [_propio(100, 'Pablo Garcia')],
        );

        await _pintar(
          tester,
          ConvocatoriaDetallePage(
            equipo: _equipo,
            convocatoria: propia,
            service: _FakeConvocatoriaService()..tras = sinLuis,
            invitadosService: invitados,
            liberar: const LiberarInvitacion(invitacionId: 31, jugadorId: 101),
            ahora: () => DateTime(2026, 10, 1),
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('boton-liberar-invitacion')),
        );
        await tester.pumpAndSettle();

        expect(invitados.llamadas, ['liberar:31']);
        expect(find.text('Luis Lopez liberado'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('banner-liberar-invitacion')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('convocado-101')), findsNothing);
        expect(find.text('1 convocado'), findsOneWidget);
      },
    );

    testWidgets(
      'si entretanto quedó autorizado con otro equipo, el 409 se explica',
      (tester) async {
        final invitados = _FakeInvitados()
          ..falloAlLiberar = const ApiException(
            'x',
            statusCode: 409,
            datos: {
              'codigo': 'JUGADOR_YA_INVITADO_ESE_DIA',
              'jugadorId': 101,
              'equipoDestino': 'Cadete C',
            },
          );

        await _pintar(
          tester,
          ConvocatoriaDetallePage(
            equipo: _equipo,
            convocatoria: propia,
            service: _FakeConvocatoriaService()..tras = propia,
            invitadosService: invitados,
            liberar: const LiberarInvitacion(invitacionId: 31, jugadorId: 101),
            ahora: () => DateTime(2026, 10, 1),
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('boton-liberar-invitacion')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Luis Lopez ya está autorizado como invitado con Cadete C ese día. '
            'Elige a otro jugador.',
          ),
          findsOneWidget,
        );
        // Sigue pudiendo liberarlo (o no) más tarde: el aviso no desaparece.
        expect(
          find.byKey(const ValueKey('banner-liberar-invitacion')),
          findsOneWidget,
        );
      },
    );

    testWidgets('sin aviso de liberar no hay banner ni botón', (tester) async {
      await _pintar(
        tester,
        ConvocatoriaDetallePage(
          equipo: _equipo,
          convocatoria: propia,
          service: _FakeConvocatoriaService(),
          invitadosService: _FakeInvitados(),
          ahora: () => DateTime(2026, 10, 1),
        ),
      );

      expect(
        find.byKey(const ValueKey('boton-liberar-invitacion')),
        findsNothing,
      );
    });
  });

  // ---- familia y jugador: "No puede ir" --------------------------------------------------

  group('"No puede ir" del jugador invitado', () {
    final convocatoria = ConvocatoriaPartidoModel(
      convocatoriaId: 20,
      rival: 'Pego C.F.',
      fecha: DateTime(2026, 11, 14),
      hora: '11:00',
      campo: 'Municipal',
      horaCitacion: '10:00',
      lugarCitacion: 'Vestuarios',
      convocado: true,
      convocados: const [
        ConvocadoPartidoModel(nombre: 'Ana', apellidos: 'Pérez', dorsal: 7),
      ],
    );

    Widget pagina(_FakeInvitadosDesestimar invitados, {String? invitadoCon}) =>
        ConvocatoriaFamiliaPage(
          partidoId: 30,
          jugadorId: 1,
          jugadorNombre: 'Ana',
          jugadorApellidos: 'Pérez',
          invitadoCon: invitadoCon,
          puedeDesestimar: invitadoCon != null,
          service: _FakeConvocatoriaPartido(convocatoria),
          invitadosService: invitados,
          justificacionService: _FakeJustificaciones(),
        );

    testWidgets('marca "Invitado con <equipo>" y el motivo es obligatorio', (
      tester,
    ) async {
      final invitados = _FakeInvitadosDesestimar();

      await _pintar(tester, pagina(invitados, invitadoCon: 'Cadete A'));

      expect(find.text('Invitado con Cadete A'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('boton-no-puede-ir')));
      await tester.pumpAndSettle();

      // Sin motivo (o demasiado corto) no se envía.
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Indica el motivo (mínimo 3 caracteres)'),
        findsOneWidget,
      );
      expect(invitados.desestimadas, isEmpty);

      await tester.enterText(find.byType(TextField), 'No');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(invitados.desestimadas, isEmpty);
    });

    testWidgets(
      'enviar manda el aviso al entrenador que lo convocó (desestimar)',
      (tester) async {
        final invitados = _FakeInvitadosDesestimar();

        await _pintar(tester, pagina(invitados, invitadoCon: 'Cadete A'));

        await tester.tap(find.byKey(const ValueKey('boton-no-puede-ir')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Tiene un cumpleaños familiar',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
        await tester.pumpAndSettle();

        // Va al endpoint de desestimar, no al de justificar.
        expect(invitados.desestimadas, ['30:1:Tiene un cumpleaños familiar']);
        expect(find.text('Aviso enviado al entrenador'), findsOneWidget);
        expect(find.text('Ausencia justificada'), findsOneWidget);
      },
    );

    testWidgets('si falla, el diálogo se queda con un mensaje genérico', (
      tester,
    ) async {
      final invitados = _FakeInvitadosDesestimar()..falla = true;

      await _pintar(tester, pagina(invitados, invitadoCon: 'Cadete A'));

      await tester.tap(find.byKey(const ValueKey('boton-no-puede-ir')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Motivo válido');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Aviso enviado al entrenador'), findsNothing);
    });

    testWidgets('un jugador del propio equipo no ve nada de invitados', (
      tester,
    ) async {
      await _pintar(tester, pagina(_FakeInvitadosDesestimar()));

      expect(find.byKey(const ValueKey('convocatoria-invitado')), findsNothing);
      expect(find.byKey(const ValueKey('boton-no-puede-ir')), findsNothing);
    });

    testWidgets(
      'fuera de plazo no hay botón, pero sigue marcado como invitado',
      (tester) async {
        await _pintar(
          tester,
          ConvocatoriaFamiliaPage(
            partidoId: 30,
            jugadorId: 1,
            jugadorNombre: 'Ana',
            jugadorApellidos: 'Pérez',
            invitadoCon: 'Cadete A',
            service: _FakeConvocatoriaPartido(convocatoria),
            invitadosService: _FakeInvitadosDesestimar(),
          ),
        );

        expect(find.text('Invitado con Cadete A'), findsOneWidget);
        expect(find.byKey(const ValueKey('boton-no-puede-ir')), findsNothing);
      },
    );
  });
}

class _FakeConvocatoriaPartido extends ConvocatoriaPartidoService {
  final ConvocatoriaPartidoModel modelo;

  _FakeConvocatoriaPartido(this.modelo);

  @override
  Future<ConvocatoriaPartidoModel> obtener({
    required int partidoId,
    required int jugadorId,
  }) async => modelo;
}

class _FakeInvitadosDesestimar extends InvitadosService {
  final List<String> desestimadas = [];
  bool falla = false;

  @override
  Future<JustificacionPartidoModel> desestimar({
    required int partidoId,
    required int jugadorId,
    required String motivo,
  }) async {
    if (falla) throw Exception('sin red');

    desestimadas.add('$partidoId:$jugadorId:$motivo');

    return JustificacionPartidoModel(
      partidoId: partidoId,
      jugadorId: jugadorId,
      jugador: 'Ana',
      motivo: motivo,
    );
  }
}
