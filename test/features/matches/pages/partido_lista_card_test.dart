import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/teams/pages/team_standings_page.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

Future<void> _pintar(WidgetTester tester, MatchModel partido) {
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
      home: Scaffold(
        body: SingleChildScrollView(child: PartidoListaCard(partido: partido)),
      ),
    ),
  );
}

const _proximo = MatchModel(
  equipoId: 7,
  categoria: 'Cadete',
  equipo: 'Cadete A',
  rival: 'Pego C.F.',
);

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  final tarjetas = <String, MatchModel>{
    'próximo partido': _proximo,
    'resultado': const MatchModel(
      equipoId: 7,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Pego C.F.',
      resultado: '2-1',
      golesFavor: 2,
      golesContra: 1,
    ),
    'descanso': const MatchModel(
      equipoId: 7,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'DESCANSA',
      descansa: true,
    ),
  };

  for (final entrada in tarjetas.entries) {
    testWidgets('${entrada.key} con equipoId muestra "Ver clasificación"', (
      tester,
    ) async {
      await _pintar(tester, entrada.value);

      expect(find.text('Ver clasificación'), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard_outlined), findsOneWidget);
    });

    testWidgets('${entrada.key} sin equipoId no muestra el botón', (
      tester,
    ) async {
      final m = entrada.value;

      await _pintar(
        tester,
        MatchModel(
          categoria: m.categoria,
          equipo: m.equipo,
          rival: m.rival,
          resultado: m.resultado,
          golesFavor: m.golesFavor,
          golesContra: m.golesContra,
          descansa: m.descansa,
        ),
      );

      expect(find.text('Ver clasificación'), findsNothing);
      expect(find.byIcon(Icons.leaderboard_outlined), findsNothing);
    });
  }

  testWidgets('el botón abre la clasificación del equipo', (tester) async {
    Uri? pedida;

    await http.runWithClient(() async {
      await _pintar(tester, _proximo);

      await tester.tap(find.text('Ver clasificación'));
      await tester.pumpAndSettle();

      expect(find.byType(TeamStandingsPage), findsOneWidget);
      // El nombre del equipo va en la barra de título.
      expect(find.text('Cadete A'), findsWidgets);
      // El mock responde 404: aún no hay clasificación.
      expect(find.text('Clasificación no disponible todavía'), findsOneWidget);
    }, () => _clienteQueResponde404((uri) => pedida = uri));

    expect(pedida?.path, endsWith('/public/equipos/7/clasificacion'));
  });
}

http.Client _clienteQueResponde404(void Function(Uri) alPedir) {
  return _Cliente404(alPedir);
}

class _Cliente404 extends http.BaseClient {
  final void Function(Uri) alPedir;

  _Cliente404(this.alPedir);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    alPedir(request.url);

    return http.StreamedResponse(
      Stream.value(const <int>[]),
      404,
      request: request,
    );
  }
}
