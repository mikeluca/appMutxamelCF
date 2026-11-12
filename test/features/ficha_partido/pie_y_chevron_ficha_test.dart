import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Que se vea que la tarjeta del Primer Equipo se puede pulsar: pie "Ver partido" / "Seguir en directo" en la
/// portada y chevron en Partidos/Resultados; sin ficha, todo como antes. Y la portada ya no pinta los goleadores.

const _primerEquipo = MatchModel(
  id: 30,
  equipoId: 1,
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'Pego C.F.',
  hora: '17:00',
);

const _enJuego = MatchModel(
  id: 30,
  equipoId: 1,
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'Pego C.F.',
  enJuego: true,
  fase: 'PRIMERA_PARTE',
  golesFavor: 1,
  golesContra: 0,
);

const _otroEquipo = MatchModel(
  id: 9,
  equipoId: 7,
  categoria: 'Cadete',
  equipo: 'Cadete A',
  rival: 'Pego C.F.',
);

const _descanso = MatchModel(
  id: 9,
  equipoId: 1,
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'DESCANSA',
  descansa: true,
);

const _sinId = MatchModel(
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: '',
);

Future<void> _pintar(
  WidgetTester tester,
  Widget hijo, {
  Locale locale = const Locale('es'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: hijo)),
    ),
  );
}

Widget _portada(MatchModel m) => MatchCard(match: m, mostrarPrimerEquipo: true);

Future<void> _tocarYCerrar(WidgetTester tester, Finder donde, int partidoId) async {
  await tester.tap(donde);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  expect(
    tester.widget<FichaPartidoPage>(find.byType(FichaPartidoPage)).partidoId,
    partidoId,
  );

  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('portada', () {
    testWidgets('el resultado ya no pinta la línea de goleadores aunque lleguen', (
      tester,
    ) async {
      await _pintar(
        tester,
        _portada(
          const MatchModel(
            id: 30,
            equipoId: 1,
            categoria: 'Primer Equipo',
            equipo: 'Primer Equipo',
            rival: 'Pego C.F.',
            resultado: '3-1',
            golesFavor: 3,
            golesContra: 1,
            fase: 'FINALIZADO',
            goleadores: ['Pepe (2)', 'Juanma'],
          ),
        ),
      );

      expect(find.text('3-1'), findsOneWidget);
      expect(find.byKey(const ValueKey('goleadores')), findsNothing);
      expect(find.textContaining('Goles'), findsNothing);
      expect(find.textContaining('Pepe'), findsNothing);
      // El resto de la tarjeta se queda igual: y el pie invita a abrir la ficha.
      expect(find.text('Ver partido'), findsOneWidget);
    });

    testWidgets('con ficha: pie con separador, "Ver partido" y chevron a la derecha en el color primario', (
      tester,
    ) async {
      await _pintar(tester, _portada(_primerEquipo));

      final pie = find.byKey(const ValueKey('pie-ficha'));
      expect(pie, findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('Ver partido'), findsOneWidget);
      expect(find.text('Seguir en directo'), findsNothing);

      final primario = Theme.of(tester.element(pie)).colorScheme.primary;
      final texto = tester.widget<Text>(find.text('Ver partido'));
      expect(texto.style!.color, primario);
      expect(texto.style!.fontSize, lessThanOrEqualTo(13));

      final chevron = find.descendant(of: pie, matching: find.byIcon(Icons.chevron_right));
      expect(chevron, findsOneWidget);
      expect(tester.widget<Icon>(chevron).color, primario);
      // El chevron va a la derecha del texto.
      expect(
        tester.getTopLeft(chevron).dx,
        greaterThan(tester.getTopRight(find.text('Ver partido')).dx - 1),
      );
    });

    testWidgets('con el partido en juego el pie dice "Seguir en directo", y el letrero se queda', (
      tester,
    ) async {
      await _pintar(tester, _portada(_enJuego));

      expect(find.text('Seguir en directo'), findsOneWidget);
      expect(find.text('Ver partido'), findsNothing);
      expect(find.byKey(const ValueKey('letrero-en-juego')), findsOneWidget);
      expect(find.byKey(const ValueKey('marcador-en-directo')), findsOneWidget);
    });

    testWidgets('los textos del pie en catalán e inglés', (tester) async {
      await _pintar(tester, _portada(_primerEquipo), locale: const Locale('ca'));
      expect(find.text('Veure el partit'), findsOneWidget);

      await _pintar(tester, _portada(_enJuego), locale: const Locale('ca'));
      expect(find.text('Seguir en directe'), findsOneWidget);

      await _pintar(tester, _portada(_primerEquipo), locale: const Locale('en'));
      expect(find.text('View match'), findsOneWidget);

      await _pintar(tester, _portada(_enJuego), locale: const Locale('en'));
      expect(find.text('Follow live'), findsOneWidget);
    });

    testWidgets('sin ficha (otro equipo, descanso, sin id o fuera de la portada) no hay pie ni chevron', (
      tester,
    ) async {
      for (final partido in [_otroEquipo, _descanso, _sinId]) {
        await _pintar(tester, _portada(partido));

        expect(find.byKey(const ValueKey('pie-ficha')), findsNothing);
        expect(find.byKey(const ValueKey('abrir-ficha')), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
        expect(find.text('Ver partido'), findsNothing);
      }

      // Mismo partido del Primer Equipo pero sin mostrarPrimerEquipo (Mis partidos): como siempre.
      await _pintar(tester, MatchCard(match: _primerEquipo));
      expect(find.byKey(const ValueKey('abrir-ficha')), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('tocar la tarjeta (el pie, el marcador) abre la ficha, con un InkWell dentro de la tarjeta', (
      tester,
    ) async {
      await _pintar(tester, _portada(_primerEquipo));

      final ink = find.byKey(const ValueKey('abrir-ficha'));
      expect(tester.widget(ink), isA<InkWell>());
      expect(tester.widget<InkWell>(ink).borderRadius, BorderRadius.circular(8));
      expect(
        find.descendant(of: find.byType(Card), matching: ink),
        findsOneWidget,
      );

      await _tocarYCerrar(tester, find.text('Ver partido'), 30);
    });

    testWidgets('con el partido en juego, tocar "Seguir en directo" también abre la ficha', (
      tester,
    ) async {
      await _pintar(tester, _portada(_enJuego));

      await _tocarYCerrar(tester, find.text('Seguir en directo'), 30);
    });

    testWidgets('"Cómo llegar" sigue abriendo el mapa por su cuenta, sin abrir la ficha', (
      tester,
    ) async {
      final abiertas = <Uri>[];
      ComoLlegar.esIos = () => true;
      ComoLlegar.abrirUrl = (url) async {
        abiertas.add(url);
        return true;
      };
      addTearDown(() => ComoLlegar.esIos = () => false);

      await _pintar(
        tester,
        _portada(
          const MatchModel(
            id: 30,
            equipoId: 1,
            categoria: 'Primer Equipo',
            equipo: 'Primer Equipo',
            rival: 'Pego C.F.',
            campo: 'Camp Municipal de Mutxamel',
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pump();

      expect(abiertas.single.queryParameters['q'], 'Camp Municipal de Mutxamel');
      expect(find.byType(FichaPartidoPage), findsNothing);
    });

    testWidgets('se anuncia como botón "Ver partido contra <rival>" para lectores de pantalla', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();

      await _pintar(tester, _portada(_primerEquipo));

      final nodo = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Ver partido contra Pego C.F.')),
      );
      expect(nodo.label, contains('Ver partido contra Pego C.F.'));
      expect(nodo.flagsCollection.isButton, isTrue);

      semantica.dispose();
    });

    testWidgets('la etiqueta del tipo de partido no tapa el pie', (tester) async {
      await _pintar(
        tester,
        _portada(
          const MatchModel(
            id: 30,
            equipoId: 1,
            categoria: 'Primer Equipo',
            equipo: 'Primer Equipo',
            rival: 'Pego C.F.',
            tipo: 'LIGA',
          ),
        ),
      );

      final etiqueta = find.text('Liga');
      expect(etiqueta, findsOneWidget);
      expect(
        tester.getBottomLeft(etiqueta).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byKey(const ValueKey('pie-ficha'))).dy),
      );
    });
  });

  group('Partidos / Resultados', () {
    testWidgets('el Primer Equipo con ficha lleva chevron al final de la fila y se abre al tocar', (
      tester,
    ) async {
      await _pintar(tester, const PartidoListaCard(partido: _primerEquipo));

      expect(find.byKey(const ValueKey('chevron-ficha')), findsOneWidget);
      expect(tester.widget(find.byKey(const ValueKey('abrir-ficha'))), isA<InkWell>());

      await _tocarYCerrar(tester, find.text('Pego C.F.'), 30);
    });

    testWidgets('también un partido ya jugado', (tester) async {
      await _pintar(
        tester,
        const PartidoListaCard(
          partido: MatchModel(
            id: 44,
            equipoId: 1,
            categoria: 'Primer Equipo',
            equipo: 'Primer Equipo',
            rival: 'Villena',
            resultado: '2-1',
            golesFavor: 2,
            golesContra: 1,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('chevron-ficha')), findsOneWidget);
    });

    testWidgets('otros equipos y descansos, sin chevron ni InkWell', (tester) async {
      for (final partido in [_otroEquipo, _descanso, _sinId]) {
        await _pintar(tester, PartidoListaCard(partido: partido));

        expect(find.byKey(const ValueKey('chevron-ficha')), findsNothing);
        expect(find.byKey(const ValueKey('abrir-ficha')), findsNothing);
      }
    });

    testWidgets('se anuncia como botón "Ver partido contra <rival>"', (tester) async {
      final semantica = tester.ensureSemantics();

      await _pintar(tester, const PartidoListaCard(partido: _primerEquipo));

      expect(
        find.bySemanticsLabel(RegExp('Ver partido contra Pego C.F.')),
        findsOneWidget,
      );

      semantica.dispose();
    });

    testWidgets('"Cómo llegar" sigue abriendo el mapa sin abrir la ficha', (tester) async {
      final abiertas = <Uri>[];
      ComoLlegar.esIos = () => true;
      ComoLlegar.abrirUrl = (url) async {
        abiertas.add(url);
        return true;
      };
      addTearDown(() => ComoLlegar.esIos = () => false);

      await _pintar(
        tester,
        const PartidoListaCard(
          partido: MatchModel(
            id: 30,
            equipoId: 1,
            categoria: 'Primer Equipo',
            equipo: 'Primer Equipo',
            rival: 'Pego C.F.',
            campo: 'Camp Municipal de Mutxamel',
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pump();

      expect(abiertas, hasLength(1));
      expect(find.byType(FichaPartidoPage), findsNothing);
    });
  });
}
