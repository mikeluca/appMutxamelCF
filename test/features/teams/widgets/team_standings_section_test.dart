import 'package:app_mutxamel_cf/features/teams/models/standings_model.dart';
import 'package:app_mutxamel_cf/features/teams/widgets/team_standings_section.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _filas = [
  StandingsRowModel(
    posicion: 1,
    equipo: 'Monnegre',
    esNuestro: false,
    puntos: 9,
    pj: 3,
    pg: 3,
    pe: 0,
    pp: 0,
    gf: 8,
    gc: 1,
  ),
  StandingsRowModel(
    posicion: 2,
    equipo: 'Mutxamel C.F.',
    esNuestro: true,
    puntos: 6,
    pj: 3,
    pg: 2,
    pe: 0,
    pp: 1,
    gf: 5,
    gc: 3,
  ),
];

final _clasificacion = StandingsModel(
  competicion: 'Primera FFCV, Grup 4',
  jornada: 3,
  fechaImportacion: DateTime(2026, 10, 19, 10, 30),
  filas: _filas,
);

Future<void> _pintar(
  WidgetTester tester,
  Future<StandingsModel?> future, {
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
          child: TeamStandingsSection(future: future),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  testWidgets('sin datos muestra el estado vacío', (tester) async {
    await _pintar(tester, Future.value(null));

    expect(find.text('Clasificación no disponible todavía'), findsOneWidget);
  });

  testWidgets('con la lista vacía muestra el estado vacío', (tester) async {
    await _pintar(
      tester,
      Future.value(
        StandingsModel(
          competicion: 'X',
          jornada: 1,
          fechaImportacion: null,
          filas: const [],
        ),
      ),
    );

    expect(find.text('Clasificación no disponible todavía'), findsOneWidget);
  });

  testWidgets('si falla la carga muestra el error', (tester) async {
    // Con retraso: el FutureBuilder ya está escuchando cuando falla.
    await _pintar(
      tester,
      Future<StandingsModel?>.delayed(
        Duration.zero,
        () => throw Exception('x'),
      ),
    );

    expect(
      find.text('No se ha podido cargar la clasificación.'),
      findsOneWidget,
    );
  });

  testWidgets('en móvil estrecho solo Pos, Equipo, PJ y Pts', (tester) async {
    await _pintar(tester, Future.value(_clasificacion));

    expect(find.text('Jornada 3 · actualizado el 19/10'), findsOneWidget);
    expect(find.text('Pos'), findsOneWidget);
    expect(find.text('Equipo'), findsOneWidget);
    expect(find.text('PJ'), findsOneWidget);
    expect(find.text('Pts'), findsOneWidget);
    expect(find.text('Monnegre'), findsOneWidget);
    expect(find.text('Mutxamel C.F.'), findsOneWidget);

    expect(find.text('GF'), findsNothing);
    expect(find.text('GC'), findsNothing);
    expect(find.text('G'), findsNothing);
  });

  testWidgets('en pantalla ancha (móvil girado) añade G/E/P/GF/GC', (
    tester,
  ) async {
    await _pintar(
      tester,
      Future.value(_clasificacion),
      tamano: const Size(800, 400),
    );

    for (final columna in ['G', 'E', 'P', 'GF', 'GC']) {
      expect(find.text(columna), findsOneWidget, reason: columna);
    }
  });

  testWidgets('solo nuestra fila va en negrita y resaltada', (tester) async {
    await _pintar(tester, Future.value(_clasificacion));

    final nuestra = tester.widget<Text>(find.text('Mutxamel C.F.'));
    final rival = tester.widget<Text>(find.text('Monnegre'));

    expect(nuestra.style?.fontWeight, FontWeight.bold);
    expect(rival.style?.fontWeight, FontWeight.normal);

    final contenedor = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Mutxamel C.F.'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoracion = contenedor.decoration! as BoxDecoration;

    expect(decoracion.color, isNotNull);
    expect(decoracion.border, isNotNull);
  });

  testWidgets('se pinta también con el tema oscuro', (tester) async {
    await _pintar(tester, Future.value(_clasificacion), tema: ThemeData.dark());

    expect(find.text('Mutxamel C.F.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
