import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/home/home_page.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/news/models/news_model.dart';
import 'package:app_mutxamel_cf/features/news/services/news_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _MatchFalso extends MatchService {
  final MatchModel partido;

  _MatchFalso(this.partido);

  @override
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async => partido;
}

class _NoticiasFalsas extends NewsService {
  @override
  Future<List<NewsModel>> obtenerNoticias({
    int? antesId,
    int limite = 5,
  }) async => const [];
}

const _primerEquipo = MatchModel(
  id: 30,
  equipoId: 1,
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'Pego C.F.',
  hora: '17:00',
);

MaterialApp _app(Widget home) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

Future<void> _pintarPortada(WidgetTester tester, MatchModel partido) async {
  await tester.pumpWidget(
    _app(
      HomePage(
        matchService: _MatchFalso(partido),
        newsService: _NoticiasFalsas(),
        avisosDeResultados: const Stream<void>.empty(),
      ),
    ),
  );

  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

Future<void> _pintarLista(WidgetTester tester, MatchModel partido) {
  return tester.pumpWidget(
    _app(
      Scaffold(
        body: SingleChildScrollView(child: PartidoListaCard(partido: partido)),
      ),
    ),
  );
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('MatchModel.tieneFicha', () {
    test('solo el Primer Equipo con id y con partido de verdad', () {
      expect(_primerEquipo.esPrimerEquipo, isTrue);
      expect(_primerEquipo.tieneFicha, isTrue);

      // Sin id (la entrada "sin partido" o un backend antiguo).
      expect(
        const MatchModel(
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: '',
        ).tieneFicha,
        isFalse,
      );

      // Otro equipo, aunque tenga id.
      expect(
        const MatchModel(
          id: 9,
          categoria: 'Cadete',
          equipo: 'Cadete A',
          rival: 'Pego C.F.',
        ).tieneFicha,
        isFalse,
      );

      // Descanso del Primer Equipo.
      expect(
        const MatchModel(
          id: 9,
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: 'DESCANSA',
          descansa: true,
        ).tieneFicha,
        isFalse,
      );
    });

    test('el id del partido llega en el JSON de la portada y de los resultados', () {
      final partido = MatchModel.fromJson({
        'id': 30,
        'equipo': 'Primer Equipo',
        'categoria': 'Primer Equipo',
        'rival': 'Pego C.F.',
      });

      expect(partido.id, 30);
      expect(partido.tieneFicha, isTrue);
    });
  });

  group('portada', () {
    testWidgets('la tarjeta del Primer Equipo abre la ficha del partido', (tester) async {
      await _pintarPortada(tester, _primerEquipo);

      expect(find.byKey(const ValueKey('abrir-ficha')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('abrir-ficha')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final ficha = tester.widget<FichaPartidoPage>(find.byType(FichaPartidoPage));
      expect(ficha.partidoId, 30);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sin partido (sin id) la tarjeta no abre nada', (tester) async {
      await _pintarPortada(
        tester,
        const MatchModel(
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: '',
        ),
      );

      expect(find.byKey(const ValueKey('abrir-ficha')), findsNothing);
    });
  });

  group('Partidos / Resultados', () {
    testWidgets('un partido del Primer Equipo abre su ficha', (tester) async {
      await _pintarLista(tester, _primerEquipo);

      await tester.tap(find.byKey(const ValueKey('abrir-ficha')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.widget<FichaPartidoPage>(find.byType(FichaPartidoPage)).partidoId,
        30,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('un partido ya jugado del Primer Equipo también', (tester) async {
      await _pintarLista(
        tester,
        const MatchModel(
          id: 44,
          equipoId: 1,
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: 'Villena',
          resultado: '2-1',
          golesFavor: 2,
          golesContra: 1,
        ),
      );

      expect(find.byKey(const ValueKey('abrir-ficha')), findsOneWidget);
    });

    testWidgets('los demás equipos se quedan como estaban', (tester) async {
      await _pintarLista(
        tester,
        const MatchModel(
          id: 9,
          equipoId: 7,
          categoria: 'Cadete',
          equipo: 'Cadete A',
          rival: 'Pego C.F.',
        ),
      );

      expect(find.byKey(const ValueKey('abrir-ficha')), findsNothing);
      expect(find.byType(FichaPartidoPage), findsNothing);
    });
  });
}
