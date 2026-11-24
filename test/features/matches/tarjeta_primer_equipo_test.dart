import 'package:app_mutxamel_cf/features/directo/widgets/cuenta_atras_bloques.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

/// La tarjeta del Primer Equipo en Partidos (con ficha) y la del próximo partido de Inicio.

MatchModel _partido({
  int id = 30,
  int equipoId = 1,
  String equipo = 'Primer Equipo',
  String rival = 'Pego',
}) => MatchModel(
  id: id,
  equipoId: equipoId,
  categoria: equipo,
  equipo: equipo,
  rival: rival,
  tipo: 'LIGA',
  dia: DateTime(2099, 11, 22),
  hora: '17:00',
  campo: 'Camp Municipal',
);

Future<void> _pintar(
  WidgetTester tester,
  Widget hijo, {
  double ancho = 390,
  double escala = 1,
}) async {
  tester.view.physicalSize = Size(ancho, 1400);
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: hijo)),
    ),
  );
}

double _arriba(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('Partidos: tarjeta del Primer Equipo con ficha', () {
    testWidgets(
      '"Añadir a mi calendario" y "Clasificación" van en la misma fila',
      (tester) async {
        // La letra de los tests (Ahem) es más ancha que la real: 390 dp reales equivalen aquí a una pantalla ancha.
        await _pintar(tester, PartidoListaCard(partido: _partido()), ancho: 900);

        expect(
          find.byKey(const ValueKey('fila-calendario-clasificacion')),
          findsOneWidget,
        );

        final calendario = find.text('Añadir a mi calendario');
        final clasificacion = find.text('Clasificación');

        expect(calendario, findsOneWidget);
        expect(clasificacion, findsOneWidget);
        expect(
          _arriba(tester, calendario),
          closeTo(_arriba(tester, clasificacion), 1),
        );
      },
    );

    testWidgets('igual que en el Filial y los demás equipos (sin ficha)', (
      tester,
    ) async {
      final filial = _partido(id: 9, equipoId: 7, equipo: 'Filial');

      await _pintar(tester, PartidoListaCard(partido: filial), ancho: 900);

      expect(
        _arriba(tester, find.text('Añadir a mi calendario')),
        closeTo(_arriba(tester, find.text('Clasificación')), 1),
      );

      // El contenido mide lo mismo: el mismo relleno a los lados.
      final anchoFilial = tester
          .getSize(find.byKey(const ValueKey('fila-calendario-clasificacion')))
          .width;

      await _pintar(tester, PartidoListaCard(partido: _partido()), ancho: 900);

      expect(
        tester
            .getSize(find.byKey(const ValueKey('fila-calendario-clasificacion')))
            .width,
        closeTo(anchoFilial, 0.5),
      );
    });

    testWidgets(
      'con ficha o sin ella, la fila se apila o no a los mismos anchos (mismo relleno)',
      (tester) async {
        for (final ancho in [330.0, 390.0, 480.0, 600.0, 700.0, 800.0, 900.0]) {
          bool enUnaFila() =>
              (_arriba(tester, find.text('Añadir a mi calendario')) -
                      _arriba(tester, find.text('Clasificación')))
                  .abs() <
              2;

          await _pintar(tester, PartidoListaCard(partido: _partido()), ancho: ancho);

          final conFicha = enUnaFila();

          await _pintar(
            tester,
            PartidoListaCard(partido: _partido(id: 9, equipoId: 7, equipo: 'Filial')),
            ancho: ancho,
          );

          expect(conFicha, enUnaFila(), reason: 'ancho $ancho');
        }
      },
    );

    testWidgets('el chevron va en la fila de la cabecera, pegado a la derecha', (
      tester,
    ) async {
      await _pintar(tester, PartidoListaCard(partido: _partido()));

      final chevron = find.byKey(const ValueKey('chevron-ficha'));
      final cabecera = find.text('PRÓXIMO PARTIDO');

      expect(chevron, findsOneWidget);

      // Misma fila que el texto de la cabecera y a su derecha.
      expect(
        tester.getCenter(chevron).dy,
        closeTo(tester.getCenter(cabecera).dy, 3),
      );
      expect(
        tester.getTopLeft(chevron).dx,
        greaterThanOrEqualTo(tester.getTopRight(cabecera).dx),
      );

      // Pegado al borde derecho de la tarjeta (14 de relleno).
      final tarjeta = tester.getRect(find.byType(Card).first);

      expect(tarjeta.right - tester.getRect(chevron).right, closeTo(14, 1));

      // Ya no está centrado en el lateral: queda por encima de los escudos.
      expect(
        tester.getCenter(chevron).dy,
        lessThan(tester.getCenter(find.text('Pego')).dy),
      );
    });

    testWidgets('la etiqueta del tipo no choca con el chevron', (tester) async {
      await _pintar(tester, PartidoListaCard(partido: _partido()));

      final etiqueta = tester.getRect(find.text('Liga'));
      final chevron = tester.getRect(
        find.byKey(const ValueKey('chevron-ficha')),
      );

      expect(etiqueta.overlaps(chevron), isFalse);
    });

    testWidgets(
      'toda la tarjeta sigue siendo pulsable y abre la ficha, con su Semantics',
      (tester) async {
        final semantica = tester.ensureSemantics();

        await _pintar(tester, PartidoListaCard(partido: _partido()));

        expect(
          tester.widget(find.byKey(const ValueKey('abrir-ficha'))),
          isA<InkWell>(),
        );
        expect(
          tester.getSemantics(find.byKey(const ValueKey('abrir-ficha'))).label,
          contains('Ver partido contra Pego'),
        );

        await tester.tap(find.text('Pego'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.widget<FichaPartidoPage>(find.byType(FichaPartidoPage)).partidoId,
          30,
        );

        await tester.pumpWidget(const SizedBox());
        semantica.dispose();
      },
    );

    testWidgets('con letra grande se apilan igual que en las demás tarjetas', (
      tester,
    ) async {
      double separacion() =>
          _arriba(tester, find.text('Clasificación')) -
          _arriba(tester, find.text('Añadir a mi calendario'));

      await _pintar(tester, PartidoListaCard(partido: _partido()), escala: 2);

      final conFicha = separacion();

      await _pintar(
        tester,
        PartidoListaCard(partido: _partido(id: 9, equipoId: 7, equipo: 'Filial')),
        escala: 2,
      );

      final sinFicha = separacion();

      expect(tester.takeException(), isNull);
      expect(conFicha > 1, sinFicha > 1);
    });
  });

  group('Inicio: tarjeta del próximo partido', () {
    Future<void> inicio(
      WidgetTester tester, {
      String rival = 'Pego',
      double escala = 1,
      double ancho = 390,
    }) {
      return _pintar(
        tester,
        MatchCard(
          match: _partido(rival: rival),
          mostrarPrimerEquipo: true,
          ahora: () => DateTime.utc(2099, 11, 20, 12),
        ),
        ancho: ancho,
        escala: escala,
      );
    }

    testWidgets('los escudos miden 84×100 y más que un bloque de la cuenta atrás', (
      tester,
    ) async {
      await inicio(tester);

      final escudo = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/escudo.png',
      );

      expect(escudo, findsOneWidget);
      expect(tester.getSize(escudo), const Size(84, 100));

      final bloque = tester.getSize(find.byKey(const ValueKey('bloque-horas')));

      expect(tester.getSize(escudo).height, greaterThan(bloque.height));
      expect(tester.getSize(escudo).width, greaterThan(bloque.width));
    });

    testWidgets(
      'de arriba abajo: tipo, escudos con VS, cuenta atrás, fecha, campo y calendario',
      (tester) async {
        await inicio(tester);

        final ys = [
          _arriba(tester, find.text('Liga')),
          _arriba(tester, find.text('VS')),
          _arriba(tester, find.byKey(const ValueKey('cuenta-atras-bloques'))),
          _arriba(tester, find.byIcon(Icons.calendar_today_outlined)),
          _arriba(tester, find.text('Camp Municipal')),
          _arriba(tester, find.text('Añadir a mi calendario')),
        ];

        for (var i = 1; i < ys.length; i++) {
          expect(ys[i], greaterThan(ys[i - 1]), reason: 'elemento $i');
        }
      },
    );

    testWidgets('la tarjeta no es más alta que antes de los escudos grandes (421 con la letra de los tests)', (
      tester,
    ) async {
      await inicio(tester);

      expect(
        tester.getSize(find.byType(Card).first).height,
        lessThanOrEqualTo(421),
      );
    });

    testWidgets('"VS" queda centrado y la cuenta atrás no pasa de su ancho máximo', (
      tester,
    ) async {
      await inicio(tester);

      expect(tester.getCenter(find.text('VS')).dx, closeTo(195, 12));

      final fila = tester.getSize(
        find.byKey(const ValueKey('cuenta-atras-bloques')),
      );

      expect(fila.width, lessThanOrEqualTo(CuentaAtrasBloques.anchoMaximo));
    });

    testWidgets('con un rival de nombre larguísimo y letra grande nada se descuadra', (
      tester,
    ) async {
      for (final escala in [1.0, 1.6]) {
        await inicio(
          tester,
          rival:
              'Club Deportivo Atlético Internacional de la Vega Baja del Segura B',
          escala: escala,
          ancho: 320,
        );

        expect(tester.takeException(), isNull, reason: 'escala $escala');
        expect(find.text('VS'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('cuenta-atras-bloques')),
          findsOneWidget,
        );

        final vs = tester.getCenter(find.text('VS')).dx;

        expect(vs, greaterThan(100));
        expect(vs, lessThan(220));
      }
    });
  });
}
