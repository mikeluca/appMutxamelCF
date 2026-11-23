import 'package:app_mutxamel_cf/features/teams/models/standings_model.dart';
import 'package:app_mutxamel_cf/features/teams/widgets/team_standings_section.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

StandingsRowModel _fila(int pos, String equipo, {bool nuestro = false}) =>
    StandingsRowModel(
      posicion: pos,
      equipo: equipo,
      esNuestro: nuestro,
      puntos: 10 - pos,
      pj: 5,
      pg: 3,
      pe: 1,
      pp: 1,
      gf: 8,
      gc: 5,
    );

StandingsModel _liga({bool fiable = true}) => StandingsModel(
  competicion: 'Liga Veteranos Ciudad de Alicante',
  jornada: 5,
  fechaImportacion: DateTime(2026, 11, 23, 10),
  jornadaFiable: fiable,
  filas: [
    _fila(1, 'MARISTAS CAFÉ TAVIRA F.V.'),
    _fila(2, 'C.D. BETIS FLORIDA'),
    _fila(3, 'MUTXAMEL C.F.V', nuestro: true),
  ],
);

StandingsModel _copa() => StandingsModel(
  competicion: 'Copa grupo C',
  jornada: 2,
  fechaImportacion: DateTime(2026, 11, 23, 10),
  filas: [_fila(1, 'SPORTING OKTA'), _fila(2, 'MUTXAMEL C.F.V', nuestro: true)],
);

Future<void> _pintar(
  WidgetTester tester,
  StandingsModel modelo, {
  Size tamano = const Size(360, 800),
  ThemeData? tema,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      theme: tema,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TeamStandingsSection(future: Future.value(modelo)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

StandingsModel _dos() {
  final liga = _liga();

  return StandingsModel(
    competicion: liga.competicion,
    jornada: liga.jornada,
    fechaImportacion: liga.fechaImportacion,
    filas: liga.filas,
    competiciones: [liga, _copa()],
  );
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('el contrato', () {
    test('lee competiciones, la principal la primera; sin ellas, ninguna', () {
      final Map<String, dynamic> json = {
        'competicion': 'Liga',
        'jornada': 5,
        'fechaImportacion': '2026-11-23T10:00:00',
        'clasificacion': [
          {'posicion': 1, 'equipo': 'A', 'esNuestro': true},
        ],
        'competiciones': [
          {
            'competicion': 'Liga',
            'jornada': 5,
            'clasificacion': [
              {'posicion': 1, 'equipo': 'A', 'esNuestro': true},
            ],
          },
          {
            'competicion': 'Copa grupo C',
            'jornadaFiable': false,
            'clasificacion': [
              {'posicion': 1, 'equipo': 'B'},
            ],
          },
        ],
      };

      final m = StandingsModel.fromJson(json);

      expect(m.pestanas.map((c) => c.competicion), ['Liga', 'Copa grupo C']);
      expect(m.pestanas[1].jornadaFiable, isFalse);
      expect(m.jornadaFiable, isTrue);

      // Una sola competición (o un backend antiguo): sin pestañas.
      expect(
        StandingsModel.fromJson({...json, 'competiciones': []}).pestanas,
        isEmpty,
      );
      expect(
        StandingsModel.fromJson({
          ...json,
          'competiciones': [(json['competiciones'] as List)[0]],
        }).pestanas,
        isEmpty,
      );
    });
  });

  testWidgets('con dos competiciones hay selector y se cambia de una a otra', (
    tester,
  ) async {
    await _pintar(tester, _dos());

    expect(
      find.byKey(const ValueKey('selector-competiciones')),
      findsOneWidget,
    );
    // La primera es la liga.
    expect(find.byKey(const ValueKey('competicion-0')), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('competicion-0')))
          .selected,
      isTrue,
    );
    expect(find.text('SPORTING OKTA'), findsNothing);
    expect(find.text('MARISTAS CAFÉ TAVIRA'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('competicion-1')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('competicion-1')))
          .selected,
      isTrue,
    );
    expect(find.text('SPORTING OKTA'), findsOneWidget);
    expect(find.text('MARISTAS CAFÉ TAVIRA'), findsNothing);

    // Y se vuelve a la liga.
    await tester.tap(find.byKey(const ValueKey('competicion-0')));
    await tester.pumpAndSettle();
    expect(find.text('MARISTAS CAFÉ TAVIRA'), findsOneWidget);
  });

  testWidgets('con una sola competición no hay selector: igual que siempre', (
    tester,
  ) async {
    await _pintar(tester, _liga());

    expect(find.byKey(const ValueKey('selector-competiciones')), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Liga Veteranos Ciudad de Alicante'), findsOneWidget);
  });

  testWidgets('la fila nuestra va resaltada y su nombre no se toca', (
    tester,
  ) async {
    await _pintar(tester, _dos());

    // MUTXAMEL C.F.V es nuestro equipo: se queda tal cual (los rivales pierden las siglas).
    expect(find.text('MUTXAMEL C.F.V'), findsOneWidget);
    expect(find.text('BETIS FLORIDA'), findsOneWidget);
    expect(find.text('C.D. BETIS FLORIDA'), findsNothing);

    final resaltadas = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;

          return d is BoxDecoration && d.border != null && d.color != null;
        })
        .toList();

    expect(resaltadas, hasLength(1));
  });

  testWidgets('la fecha de actualización y la jornada si es fiable', (
    tester,
  ) async {
    await _pintar(tester, _dos());

    expect(find.textContaining('23/11'), findsOneWidget);
    expect(find.textContaining('Jornada 5'), findsOneWidget);
  });

  testWidgets('si el backend marca la jornada como no fiable, no se enseña', (
    tester,
  ) async {
    await _pintar(tester, _liga(fiable: false));

    expect(find.textContaining('Jornada'), findsNothing);
    expect(find.textContaining('23/11'), findsOneWidget);
  });

  testWidgets(
    'con letra grande en un iPhone pequeño y en oscuro no se desborda',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pintar(
        tester,
        _dos(),
        tamano: const Size(320, 568),
        tema: ThemeData.dark(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('competicion-1')), findsOneWidget);
    },
  );
}
