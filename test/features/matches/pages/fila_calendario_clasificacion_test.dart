import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pintar(
  WidgetTester tester,
  MatchModel partido, {
  Size tamano = const Size(390, 900),
  double letra = 1,
  Brightness brillo = Brightness.light,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brillo),
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(letra)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: PartidoListaCard(partido: partido)),
      ),
    ),
  );
}

MatchModel _proximo({int? equipoId = 7}) => MatchModel(
  equipoId: equipoId,
  categoria: 'Cadete',
  equipo: 'Cadete A',
  rival: 'Pego C.F.',
  dia: DateTime.now().add(const Duration(days: 20)),
  hora: '11:00',
  campo: 'Camp Municipal',
);

final _calendario = find.text('Añadir a mi calendario');
final _clasificacion = find.text('Ver clasificación');

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  testWidgets(
    'calendario a la izquierda y clasificación a la derecha, en la misma fila',
    (tester) async {
      // La letra de los tests (Ahem) es más ancha que la real: una pantalla ancha para que quepan juntos.
      await _pintar(tester, _proximo(), tamano: const Size(900, 900));

      expect(_calendario, findsOneWidget);
      expect(_clasificacion, findsOneWidget);

      final cal = tester.getRect(_calendario);
      final cla = tester.getRect(_clasificacion);

      // Misma fila (centros a la misma altura), calendario a la izquierda.
      expect((cal.center.dy - cla.center.dy).abs(), lessThan(2));
      expect(cal.right, lessThan(cla.left));
      expect(
        find.byKey(const ValueKey('fila-calendario-clasificacion')),
        findsOneWidget,
      );

      // Y la fila está debajo del campo, no en una fila aparte del calendario.
      expect(
        cal.top,
        greaterThan(tester.getRect(find.text('Camp Municipal')).bottom),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'con letra grande en un iPhone pequeño bajan uno debajo del otro sin cortarse',
    (tester) async {
      await _pintar(
        tester,
        _proximo(),
        tamano: const Size(360, 900),
        letra: 1.3,
      );

      final cal = tester.getRect(_calendario);
      final cla = tester.getRect(_clasificacion);

      expect(cla.top, greaterThanOrEqualTo(cal.bottom - 1));
      expect(cal.left, greaterThanOrEqualTo(0));
      expect(cal.right, lessThanOrEqualTo(360));
      expect(cla.left, greaterThanOrEqualTo(0));
      expect(cla.right, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('en modo oscuro se ven los dos botones', (tester) async {
    await _pintar(
      tester,
      _proximo(),
      brillo: Brightness.dark,
      tamano: const Size(900, 900),
    );

    expect(_calendario, findsOneWidget);
    expect(_clasificacion, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin clasificación el calendario queda solo en la fila', (
    tester,
  ) async {
    await _pintar(tester, _proximo(equipoId: null));

    expect(_calendario, findsOneWidget);
    expect(_clasificacion, findsNothing);
    expect(
      find.byKey(const ValueKey('fila-calendario-clasificacion')),
      findsNothing,
    );
  });
}
