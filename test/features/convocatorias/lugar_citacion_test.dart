import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/equipacion_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_form_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/equipacion_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/justificacion_partido_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/justificacion_partido_service.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/player_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

class _FakeEquipaciones extends EquipacionService {
  @override
  Future<List<EquipacionModel>> obtenerActivas() async => [];
}

class _FakeJustificaciones extends JustificacionPartidoService {
  @override
  Future<List<JustificacionPartidoModel>> obtener(int partidoId) async => [];
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<PlayerModel>> obtenerJugadores(int equipoId) async => [
    PlayerModel(
      id: 100,
      nombre: 'Pablo',
      apellidos: 'Garcia',
      categoria: 'Cadete',
      equipo: 'Cadete A',
      deporte: 'F',
    ),
  ];
}

class _FakeMatchService extends MatchService {
  final String? campo;

  _FakeMatchService(this.campo);

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
      dia: DateTime.now().add(const Duration(days: 30)),
      hora: '11:00',
      campo: campo,
    ),
  ];
}

class _FakeConvocatorias extends ConvocatoriaService {
  final List<String> lugares = [];

  ConvocatoriaModel _respuesta(String lugar) => ConvocatoriaModel(
    id: 20,
    equipoId: 5,
    equipo: 'Cadete A',
    partidoId: 30,
    rival: 'Pego C.F.',
    campo: '',
    fechaPartido: '2026-10-24',
    horaPartido: '11:00',
    horaConvocatoria: '09:30',
    lugarConvocatoria: lugar,
    usuarioEntrenadorId: 1,
    jugadores: const [],
  );

  @override
  Future<ConvocatoriaModel> crear({
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    required List<int> jugadoresIds,
    List<int>? invitadosIds,
    int? equipacionId,
    int? equipacionMochilaId,
  }) async {
    lugares.add(lugarConvocatoria);

    return _respuesta(lugarConvocatoria);
  }

  @override
  Future<ConvocatoriaModel> actualizar({
    required int convocatoriaId,
    required int partidoId,
    required String horaConvocatoria,
    required String lugarConvocatoria,
    List<int>? jugadoresIds,
    List<int>? invitadosIds,
    bool indicarEquipaje = false,
    int? equipacionId,
    int? equipacionMochilaId,
  }) async {
    lugares.add(lugarConvocatoria);

    return _respuesta(lugarConvocatoria);
  }
}

final _equipo = PerfilEquipo(id: 5, nombre: 'Cadete A');

ConvocatoriaModel _guardada(String lugar) => ConvocatoriaModel(
  id: 20,
  equipoId: 5,
  equipo: 'Cadete A',
  partidoId: 30,
  rival: 'Pego C.F.',
  campo: 'Camp de Pego',
  fechaPartido: '2026-10-24',
  horaPartido: '11:00',
  horaConvocatoria: '09:30',
  lugarConvocatoria: lugar,
  usuarioEntrenadorId: 1,
  jugadores: [
    ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo Garcia'),
  ],
);

Future<void> _pintar(
  WidgetTester tester, {
  String? campo,
  required _FakeConvocatorias convocatorias,
  ConvocatoriaModel? convocatoria,
}) async {
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
      home: ConvocatoriaFormPage(
        equipo: _equipo,
        convocatoria: convocatoria,
        partidoIdInicial: convocatoria == null ? 30 : null,
        teamService: _FakeTeamService(),
        matchService: _FakeMatchService(campo),
        convocatoriaService: convocatorias,
        justificacionService: _FakeJustificaciones(),
        equipacionService: _FakeEquipaciones(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _desplegable = find.byWidgetPredicate(
  (w) =>
      w is DropdownButtonFormField &&
      w.key is ValueKey &&
      (w.key! as ValueKey).value.toString().startsWith('lugar-citacion-'),
);

final _otro = find.byKey(const ValueKey('lugar-citacion-otro'));

Finder _seleccionada(String texto) =>
    find.descendant(of: _desplegable, matching: find.text(texto));

Future<void> _elegir(WidgetTester tester, String texto) async {
  await tester.ensureVisible(_desplegable);
  await tester.tap(_desplegable);
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto).last);
  await tester.pumpAndSettle();
}

Future<void> _pulsarGuardar(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(ElevatedButton));
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('jugador-convocatoria-100')));
  await tester.pumpAndSettle();
  await _pulsarGuardar(tester);
}

/// Cuántas opciones con ese texto hay en el desplegable abierto (incluida la elegida).
Future<int> _veces(WidgetTester tester, String texto) async {
  await tester.ensureVisible(_desplegable);
  await tester.tap(_desplegable);
  await tester.pumpAndSettle();

  final veces = find.text(texto).evaluate().length;

  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();

  return veces;
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('crear', () {
    testWidgets('por defecto va el campo del partido', (tester) async {
      final api = _FakeConvocatorias();
      await _pintar(tester, campo: 'Camp de Pego', convocatorias: api);

      expect(find.text('Lugar de citación'), findsOneWidget);
      expect(_seleccionada('Camp de Pego'), findsOneWidget);
      expect(_otro, findsNothing);

      await _guardar(tester);

      expect(api.lugares, ['Camp de Pego']);
    });

    testWidgets('elegir Camp Nou Los Olmos Mutxamel', (tester) async {
      final api = _FakeConvocatorias();
      await _pintar(tester, campo: 'Camp de Pego', convocatorias: api);

      await _elegir(tester, campoCasaTexto);
      await _guardar(tester);

      expect(api.lugares, [campoCasaTexto]);
    });

    testWidgets('Otro… exige escribir el lugar y lo guarda tal cual', (
      tester,
    ) async {
      final api = _FakeConvocatorias();
      await _pintar(tester, campo: 'Camp de Pego', convocatorias: api);

      await _elegir(tester, 'Otro…');

      expect(_otro, findsOneWidget);

      await _guardar(tester);

      expect(api.lugares, isEmpty);
      expect(find.text('Escribe el lugar de citación'), findsWidgets);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tester.enterText(_otro, '  Bar Manolo  ');
      await tester.pump();
      await _pulsarGuardar(tester);

      expect(api.lugares, ['Bar Manolo']);
    });

    testWidgets('partido sin campo: Camp Nou por defecto y sin opción de campo', (
      tester,
    ) async {
      final api = _FakeConvocatorias();
      await _pintar(tester, campo: null, convocatorias: api);

      expect(_seleccionada(campoCasaTexto), findsOneWidget);
      // La elegida (cerrado) + su opción en el menú abierto; ninguna otra de lugar.
      expect(await _veces(tester, campoCasaTexto), 2);
      expect(await _veces(tester, 'Otro…'), 1);

      await _guardar(tester);

      expect(api.lugares, [campoCasaTexto]);
    });

    testWidgets('si el campo ya es Camp Nou no se repite la opción', (
      tester,
    ) async {
      final api = _FakeConvocatorias();
      await _pintar(
        tester,
        campo: ' camp NOU los olmos   mutxamel ',
        convocatorias: api,
      );

      expect(_seleccionada('camp NOU los olmos   mutxamel'), findsOneWidget);
      expect(await _veces(tester, 'camp NOU los olmos   mutxamel'), 2);
      expect(await _veces(tester, campoCasaTexto), 0);

      await _guardar(tester);

      expect(api.lugares, ['camp NOU los olmos   mutxamel']);
    });
  });

  group('editar', () {
    testWidgets('igual al campo: se preselecciona el campo', (tester) async {
      final api = _FakeConvocatorias();
      await _pintar(
        tester,
        campo: 'Camp de Pego',
        convocatorias: api,
        convocatoria: _guardada('camp de pego'),
      );

      expect(_seleccionada('Camp de Pego'), findsOneWidget);
      expect(_otro, findsNothing);
    });

    testWidgets('igual a Camp Nou Los Olmos: se preselecciona esa opción', (
      tester,
    ) async {
      final api = _FakeConvocatorias();
      await _pintar(
        tester,
        campo: 'Camp de Pego',
        convocatorias: api,
        convocatoria: _guardada(campoCasaTexto),
      );

      expect(_seleccionada(campoCasaTexto), findsOneWidget);
      expect(_otro, findsNothing);
    });

    testWidgets('cualquier otro texto: Otro… con el texto ya escrito', (
      tester,
    ) async {
      final api = _FakeConvocatorias();
      await _pintar(
        tester,
        campo: 'Camp de Pego',
        convocatorias: api,
        convocatoria: _guardada('Vestuarios'),
      );

      expect(_seleccionada('Otro…'), findsOneWidget);
      expect(tester.widget<TextField>(_otro).controller!.text, 'Vestuarios');

      await _pulsarGuardar(tester);

      expect(api.lugares, ['Vestuarios']);
    });

    testWidgets('vacío: el defecto de una convocatoria nueva', (tester) async {
      final api = _FakeConvocatorias();
      await _pintar(
        tester,
        campo: 'Camp de Pego',
        convocatorias: api,
        convocatoria: _guardada(''),
      );

      expect(_seleccionada('Camp de Pego'), findsOneWidget);
    });

    testWidgets('cambiar el lugar guarda el texto nuevo', (tester) async {
      final api = _FakeConvocatorias();
      await _pintar(
        tester,
        campo: 'Camp de Pego',
        convocatorias: api,
        convocatoria: _guardada('Vestuarios'),
      );

      await _elegir(tester, campoCasaTexto);
      await _pulsarGuardar(tester);

      expect(api.lugares, [campoCasaTexto]);
    });
  });
}
