import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/models/resumen_temporada_model.dart';
import 'package:app_mutxamel_cf/features/auth/services/resumen_temporada_service.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/pages/mis_jugadores_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/mi_convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_form_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatorias_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/mis_convocatorias_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeConvocatoriaService extends ConvocatoriaService {
  List<MiConvocatoriaModel> mias;
  final List<ConvocatoriaModel> delEquipo;
  Object? falloAlResponder;
  int fallosAlCargar;

  final List<
    ({int convocatoria, int jugador, String respuesta, String? motivo})
  >
  enviadas = [];

  _FakeConvocatoriaService({
    this.mias = const [],
    this.delEquipo = const [],
    this.falloAlResponder,
    this.fallosAlCargar = 0,
  });

  @override
  Future<List<MiConvocatoriaModel>> obtenerMias() async {
    if (fallosAlCargar > 0) {
      fallosAlCargar--;
      throw Exception('sin red');
    }
    return mias;
  }

  @override
  Future<List<ConvocatoriaModel>> obtenerPorEquipo(int equipoId) async =>
      delEquipo;

  @override
  Future<MiConvocatoriaModel> responder({
    required int convocatoriaId,
    required int jugadorId,
    required String respuesta,
    String? motivo,
  }) async {
    if (falloAlResponder != null) {
      throw falloAlResponder!;
    }

    enviadas.add((
      convocatoria: convocatoriaId,
      jugador: jugadorId,
      respuesta: respuesta,
      motivo: motivo,
    ));

    final actual = mias.firstWhere(
      (c) => c.convocatoriaId == convocatoriaId && c.jugadorId == jugadorId,
    );

    return _copiar(
      actual,
      respuesta: respuesta,
      motivo: respuesta == 'VA' ? null : motivo,
    );
  }
}

MiConvocatoriaModel _copiar(
  MiConvocatoriaModel c, {
  String? respuesta,
  String? motivo,
}) => MiConvocatoriaModel(
  convocatoriaId: c.convocatoriaId,
  jugadorId: c.jugadorId,
  jugador: c.jugador,
  equipoId: c.equipoId,
  equipo: c.equipo,
  rival: c.rival,
  fechaPartido: c.fechaPartido,
  horaPartido: c.horaPartido,
  campo: c.campo,
  local: c.local,
  cancelado: c.cancelado,
  horaConvocatoria: c.horaConvocatoria,
  lugarConvocatoria: c.lugarConvocatoria,
  respuesta: respuesta,
  motivo: motivo,
  fechaRespuesta: DateTime(2026, 10, 21, 10),
  puedeResponder: c.puedeResponder,
  limiteRespuesta: c.limiteRespuesta,
);

MiConvocatoriaModel _mia({
  int convocatoria = 1,
  int jugador = 100,
  String nombre = 'Pablo Garcia',
  String rival = 'Pego C.F.',
  String? respuesta,
  String? motivo,
  bool puedeResponder = true,
  bool cancelado = false,
}) => MiConvocatoriaModel(
  convocatoriaId: convocatoria,
  jugadorId: jugador,
  jugador: nombre,
  equipoId: 5,
  equipo: 'Cadete A',
  rival: rival,
  fechaPartido: DateTime(2026, 10, 24),
  horaPartido: '11:00',
  campo: 'Campo Municipal',
  horaConvocatoria: '09:30',
  lugarConvocatoria: 'Vestuarios',
  respuesta: respuesta,
  motivo: motivo,
  puedeResponder: puedeResponder,
  cancelado: cancelado,
  limiteRespuesta: DateTime(2026, 10, 24, 9, 30),
);

Future<void> _pintar(WidgetTester tester, Widget home) async {
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

Future<void> _conUsuario(List<String> roles) => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
);

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('MisConvocatoriasPage', () {
    testWidgets('muestra la convocatoria sin responder con Va y No puede', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR']);

      await _pintar(
        tester,
        MisConvocatoriasPage(service: _FakeConvocatoriaService(mias: [_mia()])),
      );

      expect(find.text('Pego C.F.'), findsOneWidget);
      expect(find.textContaining('11:00'), findsOneWidget);
      expect(find.text('Convocatoria: 09:30 · Vestuarios'), findsOneWidget);
      expect(find.text('Sin responder'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Va'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'No puede'), findsOneWidget);
    });

    testWidgets('responder "Va" lo guarda y marca el estado', (tester) async {
      await _conUsuario(['JUGADOR']);
      final servicio = _FakeConvocatoriaService(mias: [_mia()]);

      await _pintar(tester, MisConvocatoriasPage(service: servicio));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Va'));
      await tester.pumpAndSettle();

      expect(servicio.enviadas.single.respuesta, 'VA');
      expect(servicio.enviadas.single.motivo, isNull);
      expect(find.text('Sin responder'), findsNothing);
      expect(find.text('Respuesta guardada'), findsOneWidget);
      // El elegido pasa a botón relleno; se puede cambiar.
      expect(find.widgetWithText(FilledButton, 'Va'), findsOneWidget);
    });

    testWidgets('"No puede" exige motivo: sin él no se envía nada', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR']);
      final servicio = _FakeConvocatoriaService(mias: [_mia()]);

      await _pintar(tester, MisConvocatoriasPage(service: servicio));

      await tester.tap(find.widgetWithText(OutlinedButton, 'No puede'));
      await tester.pumpAndSettle();

      // Motivo vacío y motivo demasiado corto: error y diálogo abierto.
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Indica el motivo (mínimo 3 caracteres)'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Indica el motivo (mínimo 3 caracteres)'),
        findsOneWidget,
      );

      expect(servicio.enviadas, isEmpty);

      // Con motivo válido se envía y se ve debajo del estado.
      await tester.enterText(find.byType(TextField), 'Enfermo');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(servicio.enviadas.single.respuesta, 'NO_PUEDE');
      expect(servicio.enviadas.single.motivo, 'Enfermo');
      expect(find.text('Motivo: Enfermo'), findsOneWidget);
      expect(find.text('No puede'), findsWidgets);
    });

    testWidgets('cancelar el diálogo no envía nada', (tester) async {
      await _conUsuario(['JUGADOR']);
      final servicio = _FakeConvocatoriaService(mias: [_mia()]);

      await _pintar(tester, MisConvocatoriasPage(service: servicio));

      await tester.tap(find.widgetWithText(OutlinedButton, 'No puede'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.enviadas, isEmpty);
    });

    testWidgets('con el plazo cerrado no hay botones y se dice hasta cuándo', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR']);

      await _pintar(
        tester,
        MisConvocatoriasPage(
          service: _FakeConvocatoriaService(
            mias: [_mia(puedeResponder: false, respuesta: 'VA')],
          ),
        ),
      );

      expect(
        find.text('Plazo de respuesta cerrado (24/10 09:30)'),
        findsOneWidget,
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      // Se sigue viendo lo que se respondió.
      expect(find.text('Va'), findsOneWidget);
    });

    testWidgets('un partido cancelado no se puede responder', (tester) async {
      await _conUsuario(['JUGADOR']);

      await _pintar(
        tester,
        MisConvocatoriasPage(
          service: _FakeConvocatoriaService(mias: [_mia(cancelado: true)]),
        ),
      );

      expect(find.text('Partido cancelado'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('un familiar ve el nombre de cada hijo bajo el mismo partido', (
      tester,
    ) async {
      await _conUsuario(['FAMILIAR']);

      await _pintar(
        tester,
        MisConvocatoriasPage(
          service: _FakeConvocatoriaService(
            mias: [
              _mia(),
              _mia(
                jugador: 101,
                nombre: 'Lucia Garcia',
                respuesta: 'NO_PUEDE',
                motivo: 'Examen',
              ),
            ],
          ),
        ),
      );

      // Un solo partido, dos filas de jugador.
      expect(find.text('Pego C.F.'), findsOneWidget);
      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(find.text('Lucia Garcia'), findsOneWidget);
      expect(find.text('Motivo: Examen'), findsOneWidget);
    });

    testWidgets('un jugador con una sola convocatoria no ve su propio nombre', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR']);

      await _pintar(
        tester,
        MisConvocatoriasPage(service: _FakeConvocatoriaService(mias: [_mia()])),
      );

      expect(find.text('Pablo Garcia'), findsNothing);
    });

    testWidgets('sin convocatorias muestra el estado vacío', (tester) async {
      await _conUsuario(['JUGADOR']);

      await _pintar(
        tester,
        MisConvocatoriasPage(service: _FakeConvocatoriaService()),
      );

      expect(find.text('No tienes convocatorias próximas'), findsOneWidget);
    });

    testWidgets('si falla la carga muestra el error y se puede reintentar', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR']);

      await _pintar(
        tester,
        MisConvocatoriasPage(
          service: _FakeConvocatoriaService(mias: [_mia()], fallosAlCargar: 1),
        ),
      );

      expect(
        find.text('No se han podido cargar las convocatorias.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Pego C.F.'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza la respuesta se avisa y se recarga', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR']);
      final servicio = _FakeConvocatoriaService(
        mias: [_mia()],
        falloAlResponder: Exception('El plazo para responder ha terminado'),
      );

      await _pintar(tester, MisConvocatoriasPage(service: servicio));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Va'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('El plazo para responder ha terminado'),
        findsOneWidget,
      );
    });
  });

  group('vista del entrenador', () {
    ConvocatoriaModel convocatoria() => ConvocatoriaModel(
      id: 9,
      equipoId: 5,
      equipo: 'Cadete A',
      partidoId: 30,
      rival: 'Pego C.F.',
      campo: 'Municipal',
      fechaPartido: '2026-10-24',
      horaPartido: '11:00',
      horaConvocatoria: '09:30',
      lugarConvocatoria: 'Vestuarios',
      usuarioEntrenadorId: 1,
      jugadores: [
        ConvocatoriaJugadorModel(
          jugadorId: 1,
          jugador: 'Ana Uno',
          respuesta: 'VA',
        ),
        ConvocatoriaJugadorModel(
          jugadorId: 2,
          jugador: 'Beto Dos',
          respuesta: 'NO_PUEDE',
          motivo: 'Lesionado',
        ),
        ConvocatoriaJugadorModel(jugadorId: 3, jugador: 'Carla Tres'),
        ConvocatoriaJugadorModel(jugadorId: 4, jugador: 'Dani Cuatro'),
      ],
    );

    test('el resumen cuenta los que van, no pueden y faltan por responder', () {
      final c = convocatoria();

      expect(c.van, 1);
      expect(c.noPueden, 1);
      expect(c.sinResponder, 2);
    });

    testWidgets('la lista de convocatorias muestra el resumen', (tester) async {
      await _pintar(
        tester,
        ConvocatoriasPage(
          equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
          service: _FakeConvocatoriaService(delEquipo: [convocatoria()]),
        ),
      );

      expect(
        find.text('1 van · 1 no pueden · 2 sin responder'),
        findsOneWidget,
      );
    });

    testWidgets(
      'el detalle muestra el resumen, un icono por jugador y el motivo',
      (tester) async {
        final c = convocatoria();

        // Pantalla alta: el ListView es perezoso y el resumen queda bajo el
        // formulario del partido.
        tester.view.physicalSize = const Size(800, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await _pintar(
          tester,
          ConvocatoriaFormPage(
            equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
            convocatoria: c,
            teamService: _FakeTeamService([
              for (final j in c.jugadores) _jugador(j.jugadorId, j.jugador),
              _jugador(5, 'Eva Cinco'),
            ]),
            matchService: _FakeMatchService(),
            convocatoriaService: _FakeConvocatoriaService(),
          ),
        );

        expect(
          find.text('1 van · 1 no pueden · 2 sin responder'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsNWidgets(2));
        expect(find.text('Motivo: Lesionado'), findsOneWidget);

        // Eva no está convocada: no lleva icono de respuesta.
        expect(find.text('Eva Cinco'), findsOneWidget);
      },
    );
  });

  group('Mi ficha', () {
    PerfilApp perfil(List<String> roles) => PerfilApp(
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
          dorsal: 9,
          posicion: 'Delantero',
        ),
      ],
      equipos: const [],
    );

    testWidgets(
      'un JUGADOR ve su ficha directamente, sin cabecera de "jugadores"',
      (tester) async {
        await _pintar(
          tester,
          MisJugadoresPage(
            soloMiFicha: true,
            cargarPerfil: () async => perfil(['JUGADOR']),
            teamService: _FakeTeamService([_jugador(100, 'Pablo')]),
            resumenService: _SinResumen(),
          ),
        );

        expect(find.text('Mi ficha'), findsOneWidget);
        expect(find.text('Pablo Garcia'), findsOneWidget);
        expect(find.text('Cadete A'), findsOneWidget);
        expect(find.text('Delantero'), findsOneWidget);
        expect(find.text('Mis jugadores'), findsNothing);
      },
    );

    testWidgets('para familias se mantiene "Mis jugadores"', (tester) async {
      await _pintar(
        tester,
        MisJugadoresPage(
          cargarPerfil: () async => perfil(['FAMILIAR']),
          teamService: _FakeTeamService([_jugador(100, 'Pablo')]),
          resumenService: _SinResumen(),
        ),
      );

      expect(find.text('Mis jugadores'), findsWidgets);
      expect(find.text('Mi ficha'), findsNothing);
    });

    testWidgets(
      'el menú ofrece "Mi ficha" al JUGADOR y "Mis jugadores" al FAMILIAR',
      (tester) async {
        await _conUsuario(['JUGADOR']);
        await _pintar(tester, const ClubPage());

        expect(find.text('Mi ficha'), findsOneWidget);
        expect(find.text('Mis jugadores'), findsNothing);
        expect(find.text('Mis convocatorias'), findsOneWidget);
      },
    );

    testWidgets('JUGADOR y FAMILIAR a la vez conservan "Mis jugadores"', (
      tester,
    ) async {
      await _conUsuario(['JUGADOR', 'FAMILIAR']);
      await _pintar(tester, const ClubPage());

      expect(find.text('Mis jugadores'), findsOneWidget);
      expect(find.text('Mi ficha'), findsNothing);
      expect(find.text('Mis convocatorias'), findsOneWidget);
    });
  });

  group('menú Área club: Mis convocatorias', () {
    for (final roles in [
      ['JUGADOR'],
      ['FAMILIAR'],
    ]) {
      testWidgets('${roles.first} la ve', (tester) async {
        await _conUsuario(roles);
        await _pintar(tester, const ClubPage());

        expect(find.text('Mis convocatorias'), findsOneWidget);
        expect(find.byIcon(Icons.how_to_reg_outlined), findsOneWidget);
      });
    }

    for (final rol in [
      'ENTRENADOR',
      'COORDINADOR',
      'ADMIN_APP',
      'RETRANSMISION',
    ]) {
      testWidgets('$rol solo no la ve', (tester) async {
        await _conUsuario([rol]);
        await _pintar(tester, const ClubPage());

        expect(find.text('Mis convocatorias'), findsNothing);
      });
    }
  });

  group('aviso de convocatoria', () {
    test('abre "Mis convocatorias" a JUGADOR y FAMILIAR', () async {
      for (final rol in ['JUGADOR', 'FAMILIAR']) {
        await _conUsuario([rol]);

        expect(abreMisConvocatorias('Nueva convocatoria'), isTrue, reason: rol);
      }
    });

    test('no lo hace para otros roles ni para otros mensajes', () async {
      await _conUsuario(['ENTRENADOR']);
      expect(abreMisConvocatorias('Nueva convocatoria'), isFalse);

      await _conUsuario(['JUGADOR']);
      expect(abreMisConvocatorias('Falta justificada'), isFalse);
      expect(abreMisConvocatorias(null), isFalse);
    });
  });
}

PlayerModel _jugador(int id, String nombre) => PlayerModel(
  id: id,
  nombre: nombre.split(' ').first,
  apellidos: nombre.split(' ').skip(1).join(' '),
  categoria: 'Cadete',
  equipo: 'Cadete A',
  deporte: 'F',
);

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
  ];
}

/// Sin red: el resumen de temporada llega vacío.
class _SinResumen extends ResumenTemporadaService {
  @override
  Future<ResumenTemporadaModel> obtenerResumen(int jugadorId) async =>
      const ResumenTemporadaModel();
}
