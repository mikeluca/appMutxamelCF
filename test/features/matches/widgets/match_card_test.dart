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
}
