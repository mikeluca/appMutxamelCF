import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

class _PartidosFalsos extends MatchService {
  final List<MatchModel> partidos;

  _PartidosFalsos(this.partidos);

  @override
  Future<List<MatchModel>> obtenerResultados() async => partidos;
}

MatchModel _p(String categoria, String equipo, int equipoId, String rival) =>
    MatchModel(
      id: equipoId * 10,
      equipoId: equipoId,
      categoria: categoria,
      equipo: equipo,
      rival: rival,
      resultado: '1-0',
      dia: DateTime(2026, 11, 22),
    );

// Ya llega agrupada por categoría (el orden del backend): Primer Equipo, Cadete, Alevín.
final _partidos = [
  _p('Primer Equipo', 'Primer Equipo', 1, 'Pego'),
  _p('Cadete', 'Cadete A', 2, 'Altea'),
  _p('Cadete', 'Cadete B', 3, 'Calpe'),
  _p('Alevín', 'Alevín A', 4, 'Dénia'),
  _p('Alevín', 'Alevín B', 5, 'Jávea'),
];

PerfilApp _perfil({List<int> equipos = const [], List<int> hijos = const []}) =>
    PerfilApp(
      usuarioId: 1,
      email: 'a@b.c',
      roles: const ['FAMILIAR'],
      jugadores: [
        for (final id in hijos)
          PerfilJugador(
            id: 100 + id,
            nombre: 'Hijo$id',
            apellidos: 'García',
            equipoId: id,
            equipo: 'Equipo $id',
          ),
      ],
      equipos: [
        for (final id in equipos) PerfilEquipo(id: id, nombre: 'Equipo $id'),
      ],
    );

Future<void> _pintar(
  WidgetTester tester, {
  Future<PerfilApp> Function()? perfil,
  List<MatchModel>? partidos,
  double alto = 4000,
}) async {
  // Alta, para que la lista (que construye solo lo visible) tenga todas las tarjetas a la vista.
  tester.view.physicalSize = Size(800, alto);
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
      home: MatchesPage(
        matchService: _PartidosFalsos(partidos ?? _partidos),
        cargarPerfil: perfil,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _conSesion() => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['FAMILIAR']),
);

/// Los chips, en el orden en que se ven.
List<String> _chips(WidgetTester tester) => tester
    .widgetList<ChoiceChip>(find.byType(ChoiceChip))
    .map((c) => (c.label as Text).data!)
    .toList();

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  setUp(AuthManager.olvidarUsuario);
  tearDown(AuthManager.olvidarUsuario);

  testWidgets('chips: Todos y una por categoría, en el orden de la lista', (
    tester,
  ) async {
    await _pintar(tester);

    expect(_chips(tester), ['Todos', 'Primer Equipo', 'Cadete', 'Alevín']);
    // "Todos" está elegido de partida y se ven todos los equipos.
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('chip-todos')))
          .selected,
      isTrue,
    );
    expect(find.text('Pego'), findsOneWidget);
    expect(find.text('Jávea'), findsOneWidget);
  });

  testWidgets(
    'elegir una categoría deja solo sus equipos, y "Todos" lo vuelve a dejar todo',
    (tester) async {
      await _pintar(tester);

      await tester.tap(find.byKey(const ValueKey('chip-categoria-Cadete')));
      await tester.pumpAndSettle();

      expect(find.text('Altea'), findsOneWidget);
      expect(find.text('Calpe'), findsOneWidget);
      expect(find.text('Pego'), findsNothing);
      expect(find.text('Dénia'), findsNothing);
      expect(find.text('Jávea'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('chip-categoria-Cadete')),
            )
            .selected,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('chip-categoria-Alevín')));
      await tester.pumpAndSettle();

      expect(find.text('Dénia'), findsOneWidget);
      expect(find.text('Altea'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('chip-todos')));
      await tester.pumpAndSettle();

      expect(find.text('Pego'), findsOneWidget);
      expect(find.text('Altea'), findsOneWidget);
      expect(find.text('Jávea'), findsOneWidget);
    },
  );

  testWidgets('la fila queda fija arriba al hacer scroll', (tester) async {
    // Muchos partidos para que haya scroll.
    final muchos = [
      for (var i = 0; i < 30; i++) _p('Cadete', 'Cadete A', 2, 'Rival $i'),
    ];

    await _pintar(tester, partidos: muchos, alto: 700);

    final antes = tester
        .getTopLeft(find.byKey(const ValueKey('chip-todos')))
        .dy;

    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(find.text('Rival 0'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('chip-todos'))).dy,
      antes,
    );
  });

  testWidgets(
    'con letra grande los chips no se cortan: la fila se desplaza en horizontal',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MatchesPage(matchService: _PartidosFalsos(_partidos)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final fila = find.byKey(const ValueKey('filtro-categorias'));
      final desplazable = tester.widget<SingleChildScrollView>(fila);

      expect(desplazable.scrollDirection, Axis.horizontal);

      // El último chip se alcanza desplazando la fila.
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('chip-categoria-Alevín')),
        fila,
        const Offset(-100, 0),
      );

      expect(
        find.byKey(const ValueKey('chip-categoria-Alevín')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  group('Mis equipos', () {
    testWidgets('sin sesión no hay chip', (tester) async {
      await _pintar(tester, perfil: () async => _perfil(equipos: [2]));

      expect(find.byKey(const ValueKey('chip-mis-equipos')), findsNothing);
      expect(_chips(tester), isNot(contains('Mis equipos')));
    });

    testWidgets('con sesión pero sin equipos no hay chip', (tester) async {
      await _conSesion();

      await _pintar(tester, perfil: () async => _perfil());

      expect(find.byKey(const ValueKey('chip-mis-equipos')), findsNothing);
    });

    testWidgets('si no se puede cargar el perfil no hay chip ni error', (
      tester,
    ) async {
      await _conSesion();

      await _pintar(tester, perfil: () async => throw Exception('sin red'));

      expect(find.byKey(const ValueKey('chip-mis-equipos')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'con sesión y equipos (los suyos y los de sus hijos), justo después de "Todos"',
      (tester) async {
        await _conSesion();

        await _pintar(
          tester,
          perfil: () async => _perfil(equipos: [2], hijos: [5]),
        );

        expect(_chips(tester), [
          'Todos',
          'Mis equipos',
          'Primer Equipo',
          'Cadete',
          'Alevín',
        ]);

        await tester.tap(find.byKey(const ValueKey('chip-mis-equipos')));
        await tester.pumpAndSettle();

        // Cadete A (el suyo como entrenador) y Alevín B (su hijo).
        expect(find.text('Altea'), findsOneWidget);
        expect(find.text('Jávea'), findsOneWidget);
        expect(find.text('Pego'), findsNothing);
        expect(find.text('Calpe'), findsNothing);
        expect(find.text('Dénia'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('chip-todos')));
        await tester.pumpAndSettle();

        expect(find.text('Pego'), findsOneWidget);
        expect(find.text('Dénia'), findsOneWidget);
      },
    );

    testWidgets('al cerrar la sesión el chip desaparece y vuelve "Todos"', (
      tester,
    ) async {
      await _conSesion();

      await _pintar(tester, perfil: () async => _perfil(equipos: [2]));
      await tester.tap(find.byKey(const ValueKey('chip-mis-equipos')));
      await tester.pumpAndSettle();

      expect(find.text('Pego'), findsNothing);

      AuthManager.olvidarUsuario();
      AuthManager.cambios.value++;
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chip-mis-equipos')), findsNothing);
      expect(find.text('Pego'), findsOneWidget);
    });
  });
}
