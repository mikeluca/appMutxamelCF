import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_detalle_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_form_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatorias_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
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
  final List<ConvocatoriaModel> delEquipo;
  ConvocatoriaModel? porId;
  Object? falloAlObtener;

  final List<
    ({
      int convocatoria,
      int partido,
      String hora,
      String lugar,
      List<int>? jugadores,
    })
  >
  actualizadas = [];

  final List<List<int>> creadas = [];

  _FakeConvocatoriaService({this.delEquipo = const [], this.porId});

  @override
  Future<List<ConvocatoriaModel>> obtenerPorEquipo(int equipoId) async =>
      delEquipo;

  @override
  Future<ConvocatoriaModel> obtenerPorId(int convocatoriaId) async {
    if (falloAlObtener != null) {
      throw falloAlObtener!;
    }
    return porId!;
  }

  @override
  Future<ConvocatoriaModel> crear({
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
  }) async {
    creadas.add(jugadoresIds);
    return _convocatoria();
  }

  @override
  Future<ConvocatoriaModel> actualizar({
    required int convocatoriaId,
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    List<int>? jugadoresIds,
  }) async {
    actualizadas.add((
      convocatoria: convocatoriaId,
      partido: partidoId,
      hora: horaConvocatoria,
      lugar: lugarConvocatoria,
      jugadores: jugadoresIds,
    ));
    return _convocatoria();
  }
}

class _FakeJustificacionPartidoService extends JustificacionPartidoService {
  final List<JustificacionPartidoModel> ausencias;
  final List<int> consultas = [];
  bool falla = false;

  _FakeJustificacionPartidoService([this.ausencias = const []]);

  @override
  Future<List<JustificacionPartidoModel>> obtener(int partidoId) async {
    consultas.add(partidoId);

    if (falla) {
      throw Exception('403');
    }

    return ausencias;
  }
}

class _FakeTeamService extends TeamService {
  final List<PlayerModel> jugadores;

  _FakeTeamService(this.jugadores);

  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async => jugadores;
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
    MatchModel(
      id: 31,
      equipoId: 5,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Elx',
      dia: DateTime(2026, 10, 25),
      hora: '12:00',
    ),
  ];
}

// ---- datos ----------------------------------------------------------------------------

PlayerModel _jugador(int id, String nombre) => PlayerModel(
  id: id,
  nombre: nombre.split(' ').first,
  apellidos: nombre.split(' ').skip(1).join(' '),
  categoria: 'Cadete',
  equipo: 'Cadete A',
  deporte: 'F',
);

final _jugadores = [
  _jugador(100, 'Pablo Garcia'),
  _jugador(101, 'Luis Lopez'),
  _jugador(102, 'Ana Ruiz'),
];

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
            ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo Garcia'),
            ConvocatoriaJugadorModel(jugadorId: 101, jugador: 'Luis Lopez'),
          ],
    );

final _equipo = PerfilEquipo(id: 5, nombre: 'Cadete A');

Future<void> _pintar(
  WidgetTester tester,
  Widget home, {
  GlobalKey<NavigatorState>? key,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: key,
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

Future<void> _conUsuario(List<String> roles) => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
);

Widget _formulario({
  ConvocatoriaModel? convocatoria,
  _FakeConvocatoriaService? convocatorias,
  _FakeJustificacionPartidoService? justificaciones,
}) => ConvocatoriaFormPage(
  equipo: _equipo,
  convocatoria: convocatoria,
  teamService: _FakeTeamService(_jugadores),
  matchService: _FakeMatchService(),
  convocatoriaService: convocatorias ?? _FakeConvocatoriaService(),
  justificacionService: justificaciones ?? _FakeJustificacionPartidoService(),
);

JustificacionPartidoModel _ausencia(
  int jugador,
  String nombre,
  String motivo,
) => JustificacionPartidoModel(
  partidoId: 30,
  jugadorId: jugador,
  jugador: nombre,
  motivo: motivo,
);

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  // ---- modelo -------------------------------------------------------------------------

  group('ConvocatoriaModel', () {
    test('lee ausenciaJustificada y motivoAusencia de cada convocado', () {
      final c = ConvocatoriaModel.fromJson({
        'id': 20,
        'equipoId': 5,
        'equipo': 'Cadete A',
        'partidoId': 30,
        'rival': 'Pego C.F.',
        'fechaPartido': '2026-10-24',
        'usuarioEntrenadorId': 1,
        'jugadores': [
          {'jugadorId': 100, 'jugador': 'Pablo Garcia'},
          {
            'jugadorId': 101,
            'jugador': 'Luis Lopez',
            'ausenciaJustificada': true,
            'motivoAusencia': 'Examen',
          },
        ],
      });

      expect(c.jugadores[0].ausenciaJustificada, isFalse);
      expect(c.jugadores[0].motivoAusencia, isNull);
      expect(c.jugadores[1].ausenciaJustificada, isTrue);
      expect(c.jugadores[1].motivoAusencia, 'Examen');
      expect(c.ausentes.map((j) => j.jugadorId), [101]);
    });

    test('JustificacionPartidoModel lee la respuesta del servidor', () {
      final j = JustificacionPartidoModel.fromJson({
        'partidoId': 30,
        'jugadorId': 101,
        'jugador': 'Luis Lopez',
        'motivo': 'Examen',
        'fechaCreacion': '2026-10-21T10:00:00',
      });

      expect(j.jugadorId, 101);
      expect(j.motivo, 'Examen');
      expect(j.fechaCreacion, DateTime(2026, 10, 21, 10));
    });
  });

  // ---- formulario del entrenador -----------------------------------------------------------

  group('formulario de convocatoria', () {
    testWidgets('un jugador con ausencia justificada sale deshabilitado, con '
        'etiqueta y motivo', (tester) async {
      final convocatorias = _FakeConvocatoriaService();
      final justificaciones = _FakeJustificacionPartidoService([
        _ausencia(101, 'Luis Lopez', 'Examen de mates'),
      ]);

      await _pintar(
        tester,
        _formulario(
          convocatorias: convocatorias,
          justificaciones: justificaciones,
        ),
      );

      // Se elige el partido: entonces se consultan sus ausencias.
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Pego C.F.').last);
      await tester.pumpAndSettle();

      expect(justificaciones.consultas, [30]);
      expect(find.text('Ausencia justificada'), findsOneWidget);
      expect(find.text('Motivo: Examen de mates'), findsOneWidget);

      // Pulsar al justificado no lo marca...
      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-101')));
      await tester.pumpAndSettle();
      expect(find.text('0 seleccionados'), findsOneWidget);

      // ...y al resto sí.
      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.pumpAndSettle();
      expect(find.text('1 seleccionados'), findsOneWidget);
    });

    testWidgets('cambiar de partido recalcula las ausencias y descarta a quien '
        'ya no se puede convocar', (tester) async {
      final justificaciones = _FakeJustificacionPartidoService([
        _ausencia(100, 'Pablo Garcia', 'Viaje'),
      ]);

      await _pintar(tester, _formulario(justificaciones: justificaciones));

      // Sin partido elegido, Pablo se marca...
      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.pumpAndSettle();
      expect(find.text('1 seleccionados'), findsOneWidget);

      // ...y al elegir un partido en el que está justificado se desmarca.
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Pego C.F.').last);
      await tester.pumpAndSettle();

      expect(find.text('0 seleccionados'), findsOneWidget);
      expect(find.text('Ausencia justificada'), findsOneWidget);
    });

    testWidgets('si falla la consulta de ausencias el formulario sigue '
        'funcionando', (tester) async {
      final justificaciones = _FakeJustificacionPartidoService()..falla = true;

      await _pintar(tester, _formulario(justificaciones: justificaciones));

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Pego C.F.').last);
      await tester.pumpAndSettle();

      expect(find.text('Ausencia justificada'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.pumpAndSettle();
      expect(find.text('1 seleccionados'), findsOneWidget);
    });

    testWidgets('al editar se pueden añadir y quitar jugadores y se envía la '
        'lista', (tester) async {
      final convocatorias = _FakeConvocatoriaService();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(),
          convocatorias: convocatorias,
          justificaciones: _FakeJustificacionPartidoService(),
        ),
      );

      // Estaban 100 y 101; sale el 100 y entra el 102.
      expect(find.text('2 seleccionados'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-102')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(convocatorias.actualizadas, hasLength(1));
      expect(convocatorias.actualizadas.single.convocatoria, 20);
      expect(convocatorias.actualizadas.single.jugadores!.toSet(), {101, 102});
    });

    testWidgets('al editar, un convocado que ya había justificado se ve en '
        'rojo y se puede quitar', (tester) async {
      final convocatorias = _FakeConvocatoriaService();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(),
          convocatorias: convocatorias,
          justificaciones: _FakeJustificacionPartidoService([
            _ausencia(101, 'Luis Lopez', 'Examen'),
          ]),
        ),
      );

      expect(find.text('Ausencia justificada'), findsOneWidget);
      expect(find.text('Motivo: Examen'), findsOneWidget);

      // Está convocado: se puede quitar...
      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-101')));
      await tester.pumpAndSettle();
      expect(find.text('1 seleccionados'), findsOneWidget);

      // ...y, una vez quitado, ya no se puede volver a marcar.
      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-101')));
      await tester.pumpAndSettle();
      expect(find.text('1 seleccionados'), findsOneWidget);
    });

    testWidgets('no se guarda una convocatoria sin jugadores', (tester) async {
      final convocatorias = _FakeConvocatoriaService();

      await _pintar(
        tester,
        _formulario(
          convocatoria: _convocatoria(),
          convocatorias: convocatorias,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
      await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-101')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(convocatorias.actualizadas, isEmpty);
    });
  });

  // ---- detalle del entrenador -------------------------------------------------------------

  group('detalle de la convocatoria', () {
    final banner = find.byKey(const ValueKey('banner-ausencias'));

    testWidgets('sin ausencias no hay banner', (tester) async {
      await _pintar(
        tester,
        ConvocatoriaDetallePage(
          equipo: _equipo,
          convocatoria: _convocatoria(),
          service: _FakeConvocatoriaService(),
        ),
      );

      expect(banner, findsNothing);
      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(find.text('Luis Lopez'), findsOneWidget);
      expect(find.text('2 convocados'), findsOneWidget);
    });

    testWidgets('con ausencias: banner arriba, aviso en rojo y motivo', (
      tester,
    ) async {
      await _pintar(
        tester,
        ConvocatoriaDetallePage(
          equipo: _equipo,
          convocatoria: _convocatoria(
            jugadores: [
              ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo Garcia'),
              ConvocatoriaJugadorModel(
                jugadorId: 101,
                jugador: 'Luis Lopez',
                ausenciaJustificada: true,
                motivoAusencia: 'Examen de mates',
              ),
              ConvocatoriaJugadorModel(
                jugadorId: 102,
                jugador: 'Ana Ruiz',
                ausenciaJustificada: true,
                motivoAusencia: 'Viaje',
              ),
            ],
          ),
          service: _FakeConvocatoriaService(),
        ),
      );

      expect(banner, findsOneWidget);
      expect(
        find.text('2 jugadores convocados han justificado su ausencia'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: banner,
          matching: find.widgetWithText(FilledButton, 'Editar convocatoria'),
        ),
        findsOneWidget,
      );

      // Solo los dos justificados llevan la etiqueta y su motivo.
      expect(find.text('Ausencia justificada'), findsNWidgets(2));
      expect(find.text('Motivo: Examen de mates'), findsOneWidget);
      expect(find.text('Motivo: Viaje'), findsOneWidget);

      final etiquetaRoja = tester.widget<Text>(
        find
            .descendant(
              of: find.byKey(const ValueKey('convocado-101')),
              matching: find.text('Ausencia justificada'),
            )
            .first,
      );
      expect(etiquetaRoja.style?.color, Colors.redAccent);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('convocado-100')),
          matching: find.text('Ausencia justificada'),
        ),
        findsNothing,
      );
    });

    testWidgets('con una sola ausencia el banner va en singular', (
      tester,
    ) async {
      await _pintar(
        tester,
        ConvocatoriaDetallePage(
          equipo: _equipo,
          convocatoria: _convocatoria(
            jugadores: [
              ConvocatoriaJugadorModel(
                jugadorId: 101,
                jugador: 'Luis Lopez',
                ausenciaJustificada: true,
                motivoAusencia: 'Examen',
              ),
            ],
          ),
          service: _FakeConvocatoriaService(),
        ),
      );

      expect(
        find.text('1 jugador convocado ha justificado su ausencia'),
        findsOneWidget,
      );
    });

    testWidgets('el botón del banner abre la edición y, al guardar, se '
        'recarga la convocatoria', (tester) async {
      final recargada = _convocatoria(
        jugadores: [
          ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo Garcia'),
          ConvocatoriaJugadorModel(jugadorId: 102, jugador: 'Ana Ruiz'),
        ],
      );
      final servicio = _FakeConvocatoriaService(porId: recargada);

      ConvocatoriaModel? editada;

      await _pintar(
        tester,
        ConvocatoriaDetallePage(
          equipo: _equipo,
          service: servicio,
          // El formulario de edición, simulado: "guarda" al pulsar su botón.
          formularioBuilder: (convocatoria) {
            editada = convocatoria;

            return Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('GUARDAR FALSO'),
                ),
              ),
            );
          },
          convocatoria: _convocatoria(
            jugadores: [
              ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo Garcia'),
              ConvocatoriaJugadorModel(
                jugadorId: 101,
                jugador: 'Luis Lopez',
                ausenciaJustificada: true,
                motivoAusencia: 'Examen',
              ),
            ],
          ),
        ),
      );

      expect(banner, findsOneWidget);

      // El botón del banner abre la edición de esta convocatoria.
      await tester.tap(
        find.descendant(
          of: banner,
          matching: find.widgetWithText(FilledButton, 'Editar convocatoria'),
        ),
      );
      await tester.pumpAndSettle();

      expect(editada?.id, 20);

      await tester.tap(find.text('GUARDAR FALSO'));
      await tester.pumpAndSettle();

      // Tras guardar se vuelve a leer la convocatoria: sale el que había
      // justificado, entra otro y desaparece el aviso.
      expect(find.text('Luis Lopez'), findsNothing);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(banner, findsNothing);
    });
  });

  // ---- lista del entrenador ----------------------------------------------------------------

  group('lista de convocatorias', () {
    testWidgets('cada tarjeta cuenta convocados y ausencias justificadas', (
      tester,
    ) async {
      await _pintar(
        tester,
        ConvocatoriasPage(
          equipo: _equipo,
          service: _FakeConvocatoriaService(
            delEquipo: [
              _convocatoria(
                jugadores: [
                  ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo'),
                  ConvocatoriaJugadorModel(
                    jugadorId: 101,
                    jugador: 'Luis',
                    ausenciaJustificada: true,
                    motivoAusencia: 'Examen',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Pego C.F.'), findsOneWidget);
      expect(find.text('2 convocados'), findsOneWidget);
      expect(find.text('1 ausencia justificada'), findsOneWidget);
      // Ya no hay recuento "van / no pueden / sin responder".
      expect(find.textContaining('sin responder'), findsNothing);
    });

    testWidgets('sin ausencias solo cuenta convocados', (tester) async {
      await _pintar(
        tester,
        ConvocatoriasPage(
          equipo: _equipo,
          service: _FakeConvocatoriaService(delEquipo: [_convocatoria()]),
        ),
      );

      expect(find.text('2 convocados'), findsOneWidget);
      expect(find.textContaining('ausencia'), findsNothing);
    });

    testWidgets('al tocar una convocatoria se abre su detalle', (tester) async {
      await _pintar(
        tester,
        ConvocatoriasPage(
          equipo: _equipo,
          service: _FakeConvocatoriaService(delEquipo: [_convocatoria()]),
        ),
      );

      await tester.tap(find.text('Pego C.F.'));
      await tester.pumpAndSettle();

      expect(find.byType(ConvocatoriaDetallePage), findsOneWidget);
    });
  });

  // ---- aviso de convocatoria -----------------------------------------------------------------

  group('destino del aviso de convocatoria', () {
    test('CONVOCATORIA lleva a JUGADOR y FAMILIAR al calendario, en el día '
        'del partido', () async {
      for (final rol in ['JUGADOR', 'FAMILIAR']) {
        await _conUsuario([rol]);

        expect(
          destinoDeAvisoConvocatoria(
            tipo: 'CONVOCATORIA',
            titulo: 'Otro título',
            datos: {'fechaPartido': '2026-10-24', 'convocatoriaId': '20'},
          ),
          AbrirCalendario(DateTime(2026, 10, 24)),
          reason: rol,
        );
      }
    });

    test('sin fecha en el aviso se abre el calendario en hoy', () async {
      await _conUsuario(['JUGADOR']);

      expect(
        destinoDeAvisoConvocatoria(tipo: 'CONVOCATORIA'),
        const AbrirCalendario(),
      );
      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA',
          datos: {'fechaPartido': 'no es una fecha'},
        ),
        const AbrirCalendario(),
      );
    });

    test(
      'un push antiguo (tipo COMUNICACION) se reconoce por el título',
      () async {
        await _conUsuario(['FAMILIAR']);

        expect(
          destinoDeAvisoConvocatoria(
            tipo: 'COMUNICACION',
            titulo: ' Nueva convocatoria ',
          ),
          const AbrirCalendario(),
        );
        expect(
          destinoDeAvisoConvocatoria(titulo: 'Nueva convocatoria'),
          const AbrirCalendario(),
        );
      },
    );

    test(
      'el entrenador no abre el calendario con el aviso de convocatoria',
      () async {
        for (final rol in ['ENTRENADOR', 'COORDINADOR', 'RETRANSMISION']) {
          await _conUsuario([rol]);

          expect(
            destinoDeAvisoConvocatoria(tipo: 'CONVOCATORIA'),
            isNull,
            reason: rol,
          );
          expect(
            destinoDeAvisoConvocatoria(titulo: 'Nueva convocatoria'),
            isNull,
            reason: rol,
          );
        }
      },
    );

    test('CONVOCATORIA_EDITAR lleva a editar esa convocatoria', () async {
      for (final rol in ['ENTRENADOR', 'COORDINADOR']) {
        await _conUsuario([rol]);

        expect(
          destinoDeAvisoConvocatoria(
            tipo: 'CONVOCATORIA_EDITAR',
            datos: {'convocatoriaId': '20'},
          ),
          const EditarConvocatoria(20),
          reason: rol,
        );
      }
    });

    test(
      'CONVOCATORIA_EDITAR sin un convocatoriaId válido no lleva a ningún sitio',
      () async {
        await _conUsuario(['ENTRENADOR']);

        for (final datos in <Map<String, dynamic>>[
          {},
          {'convocatoriaId': ''},
          {'convocatoriaId': 'abc'},
          {'convocatoriaId': '0'},
          {'convocatoriaId': '-3'},
        ]) {
          expect(
            destinoDeAvisoConvocatoria(
              tipo: 'CONVOCATORIA_EDITAR',
              titulo: 'Nueva convocatoria',
              datos: datos,
            ),
            isNull,
            reason: '$datos',
          );
        }
      },
    );

    test('otros tipos y mensajes no son de convocatoria', () async {
      await _conUsuario(['JUGADOR']);

      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'COMUNICACION',
          titulo: 'Falta justificada',
        ),
        isNull,
      );
      expect(destinoDeAvisoConvocatoria(tipo: 'RESULTADO'), isNull);
      expect(destinoDeAvisoConvocatoria(), isNull);
      expect(destinoDeAvisoConvocatoria(tipo: '', titulo: ''), isNull);
    });

    test('el payload de la notificación local ida y vuelta', () {
      for (final destino in <DestinoConvocatoria>[
        const AbrirCalendario(),
        AbrirCalendario(DateTime(2026, 10, 24)),
        AbrirCalendario(DateTime(2026, 1, 5)),
        const EditarConvocatoria(20),
      ]) {
        expect(destinoDePayload(payloadDeDestino(destino)), destino);
      }

      expect(
        payloadDeDestino(AbrirCalendario(DateTime(2026, 1, 5))),
        'CALENDARIO:2026-01-05',
      );
      expect(
        payloadDeDestino(const EditarConvocatoria(20)),
        'CONVOCATORIA_EDITAR:20',
      );
    });

    test('los payloads que no son de convocatoria se ignoran', () {
      for (final payload in [
        'COMUNICACION:12',
        'PRIVADA:7',
        'CONVOCATORIA_EDITAR:',
        'CONVOCATORIA_EDITAR:x',
        'CONVOCATORIA_EDITAR:0',
        '',
      ]) {
        expect(destinoDePayload(payload), isNull, reason: payload);
      }
    });
  });

  // ---- navegación al tocar el push -------------------------------------------------------------

  group('navegación del aviso de convocatoria', () {
    tearDown(() {
      AppNavigator.constructorCalendario = null;
      AppNavigator.constructorEdicion = null;
    });

    testWidgets('CONVOCATORIA abre el calendario en el día del partido', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR']);
      DateTime? diaPedido = DateTime(1900);

      AppNavigator.constructorCalendario = (dia) {
        diaPedido = dia;
        return const Scaffold(body: Text('CALENDARIO FALSO'));
      };

      await _pintar(
        tester,
        const Scaffold(body: Text('INICIO')),
        key: AppNavigator.navigatorKey,
      );

      final destino = destinoDeAvisoConvocatoria(
        tipo: 'CONVOCATORIA',
        datos: {'fechaPartido': '2026-10-24', 'convocatoriaId': '20'},
      )!;

      // La navegación espera a que se cierre la pantalla: no se aguarda.
      unawaited(AppNavigator.abrirDestinoConvocatoria(destino));
      await tester.pumpAndSettle();

      expect(find.text('CALENDARIO FALSO'), findsOneWidget);
      expect(diaPedido, DateTime(2026, 10, 24));
    });

    testWidgets('CONVOCATORIA_EDITAR abre directamente la edición de esa '
        'convocatoria', (tester) async {
      await _conUsuario(['ENTRENADOR']);
      ConvocatoriaModel? abierta;

      AppNavigator.constructorEdicion = (convocatoria) {
        abierta = convocatoria;
        return const Scaffold(body: Text('EDICION FALSA'));
      };

      await _pintar(
        tester,
        const Scaffold(body: Text('INICIO')),
        key: AppNavigator.navigatorKey,
      );

      final destino = destinoDeAvisoConvocatoria(
        tipo: 'CONVOCATORIA_EDITAR',
        datos: {'convocatoriaId': '20'},
      )!;

      unawaited(
        AppNavigator.abrirEdicionConvocatoria(
          (destino as EditarConvocatoria).convocatoriaId,
          servicio: _FakeConvocatoriaService(porId: _convocatoria()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EDICION FALSA'), findsOneWidget);
      expect(abierta?.id, 20);
      expect(abierta?.partidoId, 30);
    });

    testWidgets('si no se puede cargar la convocatoria (403) no se abre nada', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);

      AppNavigator.constructorEdicion = (_) =>
          const Scaffold(body: Text('EDICION FALSA'));

      await _pintar(
        tester,
        const Scaffold(body: Text('INICIO')),
        key: AppNavigator.navigatorKey,
      );

      final servicio = _FakeConvocatoriaService()
        ..falloAlObtener = Exception('403');

      unawaited(AppNavigator.abrirEdicionConvocatoria(20, servicio: servicio));
      await tester.pumpAndSettle();

      expect(find.text('EDICION FALSA'), findsNothing);
      expect(find.text('INICIO'), findsOneWidget);
      // Y se avisa de que ya no está disponible.
      expect(
        find.text('Esta convocatoria ya no está disponible'),
        findsOneWidget,
      );
    });

    testWidgets('si la convocatoria ya no existe se avisa igual', (
      tester,
    ) async {
      await _conUsuario(['ENTRENADOR']);

      AppNavigator.constructorEdicion = (_) =>
          const Scaffold(body: Text('EDICION FALSA'));

      await _pintar(
        tester,
        const Scaffold(body: Text('INICIO')),
        key: AppNavigator.navigatorKey,
      );

      final servicio = _FakeConvocatoriaService()
        ..falloAlObtener = Exception('La convocatoria no existe');

      unawaited(AppNavigator.abrirEdicionConvocatoria(99, servicio: servicio));
      await tester.pumpAndSettle();

      expect(find.text('EDICION FALSA'), findsNothing);
      expect(
        find.text('Esta convocatoria ya no está disponible'),
        findsOneWidget,
      );
    });
  });
}
