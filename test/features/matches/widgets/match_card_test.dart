import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';

Future<void> _pintar(WidgetTester tester, MatchModel match) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: MatchCard(match: match))),
    ),
  );
}

void main() {
  testWidgets('con campo, la tarjeta tiene "Cómo llegar" con ese campo', (tester) async {
    final abiertas = <Uri>[];
    ComoLlegar.esIos = () => true;
    ComoLlegar.abrirUrl = (url) async {
      abiertas.add(url);
      return true;
    };
    addTearDown(() => ComoLlegar.esIos = () => false);

    await _pintar(
      tester,
      const MatchModel(
        categoria: 'Primer Equipo',
        equipo: 'Primer Equipo',
        rival: 'Pego C.F.',
        campo: 'Camp Municipal de Mutxamel',
      ),
    );

    await tester.tap(find.byIcon(Icons.directions));
    await tester.pump();

    expect(abiertas.single.host, 'maps.apple.com');
    expect(abiertas.single.queryParameters['q'], 'Camp Municipal de Mutxamel');
  });

  testWidgets('sin campo no hay "Cómo llegar"', (tester) async {
    await _pintar(
      tester,
      const MatchModel(categoria: 'Primer Equipo', equipo: 'Primer Equipo', rival: 'Pego C.F.'),
    );

    expect(find.byIcon(Icons.directions), findsNothing);
  });

  testWidgets('si el Mutxamel es local, su equipo va a la izquierda', (tester) async {
    await _pintar(
      tester,
      const MatchModel(categoria: 'Primer Equipo', equipo: 'Primer Equipo', rival: 'Pego C.F.', local: true),
    );

    final izquierda = tester.getCenter(find.text('Primer Equipo')).dx;
    final derecha = tester.getCenter(find.text('Pego C.F.')).dx;

    expect(izquierda, lessThan(derecha));
  });

  testWidgets('si el Mutxamel es visitante, su equipo va a la derecha', (tester) async {
    await _pintar(
      tester,
      const MatchModel(categoria: 'Primer Equipo', equipo: 'Primer Equipo', rival: 'Pego C.F.', local: false),
    );

    final izquierda = tester.getCenter(find.text('Pego C.F.')).dx;
    final derecha = tester.getCenter(find.text('Primer Equipo')).dx;

    expect(izquierda, lessThan(derecha));
  });

  testWidgets('visitante con resultado 1-2 muestra Pego a la izquierda y 2-1', (tester) async {
    await _pintar(
      tester,
      const MatchModel(
        categoria: 'Primer Equipo',
        equipo: 'Primer Equipo',
        rival: 'Pego C.F.',
        resultado: '1-2',
        local: false,
      ),
    );

    expect(find.text('2-1'), findsOneWidget);
    expect(find.text('1-2'), findsNothing);
    expect(
      tester.getCenter(find.text('Pego C.F.')).dx,
      lessThan(tester.getCenter(find.text('Primer Equipo')).dx),
    );
  });

  testWidgets('local con resultado 2-1 se muestra tal cual', (tester) async {
    await _pintar(
      tester,
      const MatchModel(
        categoria: 'Primer Equipo',
        equipo: 'Primer Equipo',
        rival: 'Pego C.F.',
        resultado: '2-1',
      ),
    );

    expect(find.text('2-1'), findsOneWidget);
  });

  testWidgets('pendiente de resultado: sin marcador y con "Pendiente de resultado"', (tester) async {
    await _pintar(
      tester,
      const MatchModel(
        categoria: 'Primer Equipo',
        equipo: 'Primer Equipo',
        rival: 'Pego C.F.',
        pendienteResultado: true,
        local: false,
      ),
    );

    expect(find.text('Pendiente de resultado'), findsOneWidget);
    expect(find.text('-'), findsNothing);

    final izquierda = tester.getCenter(find.text('Pego C.F.')).dx;
    final derecha = tester.getCenter(find.text('Primer Equipo')).dx;

    expect(izquierda, lessThan(derecha));
  });

  group('portada en directo', () {
    const enJuego = MatchModel(
      categoria: 'Primer Equipo',
      equipo: 'Primer Equipo',
      rival: 'Pego C.F.',
      hora: '17:00',
      enJuego: true,
      fase: 'PRIMERA_PARTE',
      golesFavor: 2,
      golesContra: 1,
    );

    testWidgets('en juego: letrero destacado y marcador en directo, sin "Descanso"', (tester) async {
      await _pintar(tester, enJuego);

      expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);
      expect(find.byKey(const ValueKey('marcador-en-directo')), findsOneWidget);
      expect(find.text('2 - 1'), findsOneWidget);
      expect(find.text('Descanso'), findsNothing);
      expect(find.text('Pego C.F.'), findsOneWidget);
    });

    testWidgets('en juego como visitante el marcador va con el local a la izquierda', (tester) async {
      await _pintar(
        tester,
        const MatchModel(
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: 'Pego C.F.',
          local: false,
          enJuego: true,
          fase: 'SEGUNDA_PARTE',
          golesFavor: 2,
          golesContra: 1,
        ),
      );

      expect(find.text('1 - 2'), findsOneWidget);
    });

    testWidgets('en el descanso, debajo del marcador, sale "Descanso"', (tester) async {
      await _pintar(
        tester,
        const MatchModel(
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: 'Pego C.F.',
          enJuego: true,
          fase: 'DESCANSO',
          golesFavor: 0,
          golesContra: 0,
        ),
      );

      expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);
      expect(find.byKey(const ValueKey('descanso')), findsOneWidget);
      expect(find.text('Descanso'), findsOneWidget);
    });

    for (final (idioma, letrero, descanso) in [
      ('ca', 'PARTIT EN JOC', 'Descans'),
      ('en', 'MATCH IN PROGRESS', 'Half-time'),
    ]) {
      testWidgets('el letrero y el descanso salen en $idioma', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(idioma),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: MatchCard(
                  match: MatchModel(
                    categoria: 'Primer Equipo',
                    equipo: 'Primer Equipo',
                    rival: 'Pego C.F.',
                    enJuego: true,
                    fase: 'DESCANSO',
                    golesFavor: 1,
                    golesContra: 0,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text(letrero), findsOneWidget);
        expect(find.text(descanso), findsOneWidget);
      });
    }

    testWidgets('finalizado con goleadores: "Goles: ..." debajo del resultado', (tester) async {
      await _pintar(
        tester,
        const MatchModel(
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: 'Pego C.F.',
          resultado: '3-1',
          golesFavor: 3,
          golesContra: 1,
          fase: 'FINALIZADO',
          goleadores: ['Pepe (2)', 'Juanma'],
        ),
      );

      expect(find.text('3-1'), findsOneWidget);
      expect(find.text('Goles: Pepe (2), Juanma'), findsOneWidget);
      expect(find.text('PARTIDO EN JUEGO'), findsNothing);
    });

    testWidgets('finalizado sin goleadores no enseña la línea de goles', (tester) async {
      await _pintar(
        tester,
        const MatchModel(
          categoria: 'Primer Equipo',
          equipo: 'Primer Equipo',
          rival: 'Pego C.F.',
          resultado: '0-1',
          fase: 'FINALIZADO',
        ),
      );

      expect(find.byKey(const ValueKey('goleadores')), findsNothing);
    });

    testWidgets('compatibilidad: sin los campos nuevos la tarjeta es la de siempre', (tester) async {
      final match = MatchModel.fromJson({
        'categoria': 'Primer Equipo',
        'equipo': 'Primer Equipo',
        'rival': 'Pego C.F.',
        'resultado': '2-1',
        'golesFavor': 2,
        'golesContra': 1,
      });

      expect(match.enJuego, isFalse);
      expect(match.fase, isNull);
      expect(match.goleadores, isEmpty);

      await _pintar(tester, match);

      expect(find.text('2-1'), findsOneWidget);
      expect(find.text('PARTIDO EN JUEGO'), findsNothing);
      expect(find.byKey(const ValueKey('goleadores')), findsNothing);
    });

    test('el modelo lee enJuego, fase y goleadores del backend', () {
      final match = MatchModel.fromJson({
        'rival': 'Pego C.F.',
        'enJuego': true,
        'fase': 'SEGUNDA_PARTE',
        'golesFavor': 1,
        'golesContra': 0,
        'goleadores': ['Pepe'],
      });

      expect(match.enJuego, isTrue);
      expect(match.fase, 'SEGUNDA_PARTE');
      expect(match.marcadorEnDirecto, '1 - 0');
      expect(match.goleadores, ['Pepe']);
    });
  });
}
