import 'package:app_mutxamel_cf/core/widget/escudo_rival.dart';
import 'package:app_mutxamel_cf/features/juego/envio_puntuacion.dart';
import 'package:app_mutxamel_cf/features/juego/estado_mutxigol.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/mutxigol_page.dart';
import 'package:app_mutxamel_cf/features/juego/pages/partida_juego_page.dart';
import 'package:app_mutxamel_cf/features/juego/pages/ranking_juego_page.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/fin_de_partida.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/leyenda_atrapa.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

/// iPhone pequeño (320 × 568), letra al doble de grande y, en cada caso, claro y oscuro: nada se desborda.
Widget _app(Widget home, {required bool oscuro, String idioma = 'es'}) {
  return MaterialApp(
    locale: Locale(idioma),
    theme: oscuro ? ThemeData.dark() : ThemeData.light(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
      child: child!,
    ),
    home: home,
  );
}

void _iphonePequeno(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final oscuro in [false, true]) {
    for (final idioma in ['es', 'ca', 'en']) {
      final modo = oscuro ? 'oscuro' : 'claro';

      testWidgets('el menú con letra grande en iPhone pequeño ($modo, $idioma)', (tester) async {
        _iphonePequeno(tester);

        await tester.pumpWidget(
          _app(MutxigolPage(servicio: JuegoServiceFalso()), oscuro: oscuro, idioma: idioma),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Se llega a todo desplazando.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('boton-ranking')),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('el ranking con letra grande en iPhone pequeño ($modo, $idioma)', (tester) async {
        _iphonePequeno(tester);

        final servicio = JuegoServiceFalso(
          perfilInicial: const PerfilJuego(alias: 'UnAliasLargoDe15'),
          filas: {
            (Juego.cabezazos, PeriodoRanking.semana): [
              const FilaRanking(posicion: 1, alias: 'UnAliasLargoDe15', puntos: 120),
              const FilaRanking(posicion: 2, alias: 'Otro alias largo', puntos: 99),
            ],
          },
        );

        await tester.pumpWidget(
          _app(RankingJuegoPage(servicio: servicio, conSesion: true), oscuro: oscuro, idioma: idioma),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('el fin de partida con letra grande en iPhone pequeño ($modo, $idioma)', (tester) async {
        _iphonePequeno(tester);

        final servicio = JuegoServiceFalso()
          ..resultado = const ResultadoPuntuacion(
            recordSemana: true,
            recordHistorico: true,
            posicionSemana: 12,
            posicionHistorico: 345,
          );
        final envio = EnvioPuntuacion(
          servicio: servicio,
          juego: Juego.cabezazos,
          puntos: 12,
          duracion: const Duration(seconds: 40),
          conSesion: true,
          alias: 'Ana',
        );

        await tester.pumpWidget(
          _app(
            Scaffold(
              body: SingleChildScrollView(
                child: FinDePartida(
                  equipacion: Equipacion.rosa,
                  puntos: 12,
                  recordAnterior: 3,
                  envio: envio,
                  onOtraVez: () {},
                  onRanking: () {},
                  onElegirAlias: () {},
                  onSalir: () {},
                ),
              ),
            ),
            oscuro: oscuro,
            idioma: idioma,
          ),
        );
        await envio.iniciar();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('los cuatro juegos y la leyenda en iPhone pequeño con letra grande ($modo, $idioma)', (tester) async {
        _iphonePequeno(tester);

        EstadoMutxigol.reiniciar();
        EstadoMutxigol.leyendaAtrapaVista = true;
        EscudoRival.constructorDeRed = (url, tamano, generico) =>
            SizedBox(width: tamano, height: tamano);
        addTearDown(() => EscudoRival.constructorDeRed = null);

        for (final juego in Juego.values) {
          await tester.pumpWidget(
            _app(
              PartidaJuegoPage(
                juego: juego,
                servicio: JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(),
              ),
              oscuro: oscuro,
              idioma: idioma,
            ),
          );
          await tester.pump();
          await tester.pump();

          // Parejas empieza con la primera carta; los demás, tras la cuenta atrás.
          for (var i = 0; i < 230; i++) {
            await tester.pump(const Duration(milliseconds: 16));
          }

          expect(tester.takeException(), isNull, reason: juego.codigo);
        }

        // La leyenda de Atrapa (la más larga) con todo su texto.
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => LeyendaAtrapa.mostrar(context),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
            oscuro: oscuro,
            idioma: idioma,
          ),
        );
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('leyenda-atrapa')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('el fin de partida de Parejas con el tiempo en iPhone pequeño ($modo, $idioma)', (tester) async {
        _iphonePequeno(tester);

        final servicio = JuegoServiceFalso()
          ..resultado = const ResultadoPuntuacion(
            esTiempo: true,
            recordSemana: true,
            posicionSemana: 12,
          );
        final envio = EnvioPuntuacion(
          servicio: servicio,
          juego: Juego.parejas,
          puntos: 8,
          duracion: const Duration(milliseconds: 83450),
          conSesion: true,
          alias: 'Ana',
        );

        await tester.pumpWidget(
          _app(
            Scaffold(
              body: SingleChildScrollView(
                child: FinDePartida(
                  equipacion: Equipacion.azul,
                  juego: Juego.parejas,
                  puntos: 8,
                  tiempoMs: 83450,
                  recordAnterior: 90000,
                  envio: envio,
                  onOtraVez: () {},
                  onRanking: () {},
                  onElegirAlias: () {},
                ),
              ),
            ),
            oscuro: oscuro,
            idioma: idioma,
          ),
        );
        await envio.iniciar();
        await tester.pumpAndSettle();

        expect(find.textContaining('1:23,4'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('dentro del juego los tamaños son fijos: la letra grande no lo descoloca', (tester) async {
    _iphonePequeno(tester);

    await tester.pumpWidget(
      _app(
        PartidaJuegoPage(juego: Juego.cabezazos, servicio: JuegoServiceFalso()),
        oscuro: true,
      ),
    );
    await tester.pump();

    final marcador = tester.widget<Text>(find.byKey(const ValueKey('marcador-puntos')));

    expect(tester.takeException(), isNull);
    expect(marcador.style!.fontSize, 20);

    // El texto del marcador se pinta sin escalar (MediaQuery sin escala dentro del juego).
    final escala = MediaQuery.textScalerOf(
      tester.element(find.byKey(const ValueKey('marcador-puntos'))),
    );

    expect(escala, TextScaler.noScaling);
  });
}
