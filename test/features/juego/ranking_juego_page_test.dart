import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/ranking_juego_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

List<FilaRanking> _top(String prefijo, {int n = 3, int base = 20}) => [
  for (var i = 1; i <= n; i++)
    FilaRanking(posicion: i, alias: '$prefijo$i', puntos: base - i),
];

void main() {
  _pruebasDeParejas();

  testWidgets('se ve sin sesión: pestañas, "Esta semana" por defecto y alias, posición y puntos', (tester) async {
    pantallaDeMovil(tester);

    final servicio = JuegoServiceFalso(
      filas: {(Juego.atrapa, PeriodoRanking.semana): _top('Sem')},
    );

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: servicio, conSesion: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atrapa'), findsOneWidget);
    expect(find.text('Cabezazos'), findsOneWidget);
    expect(find.text('Regatea'), findsNothing);
    expect(find.text('Parejas'), findsOneWidget);
    expect(find.text('Esta semana'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);

    expect(servicio.rankingsPedidos.first, (Juego.atrapa, PeriodoRanking.semana));
    expect(find.text('Sem1'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
    expect(find.text('Sem3'), findsOneWidget);

    // Sin sesión no se pide el perfil ni hay fila resaltada.
    expect(servicio.perfilesPedidos, 0);
    expect(find.byKey(const ValueKey('tu-fila')), findsNothing);
  });

  testWidgets('semana e histórico son listas distintas', (tester) async {
    pantallaDeMovil(tester);

    final servicio = JuegoServiceFalso(
      filas: {
        (Juego.atrapa, PeriodoRanking.semana): _top('Sem'),
        (Juego.atrapa, PeriodoRanking.historico): _top('His', base: 90),
      },
    );

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: servicio, conSesion: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem1'), findsOneWidget);
    expect(find.text('His1'), findsNothing);

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    expect(servicio.rankingsPedidos, contains((Juego.atrapa, PeriodoRanking.historico)));
    expect(find.text('His1'), findsOneWidget);
    expect(find.text('Sem1'), findsNothing);

    await tester.tap(find.text('Esta semana'));
    await tester.pumpAndSettle();

    expect(find.text('Sem1'), findsOneWidget);
  });

  testWidgets('cada pestaña pide el ranking de su juego', (tester) async {
    pantallaDeMovil(tester);

    final servicio = JuegoServiceFalso(
      filas: {
        (Juego.cabezazos, PeriodoRanking.semana): _top('Toc'),
        (Juego.atrapa, PeriodoRanking.semana): _top('Atr'),
      },
    );

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: servicio, conSesion: false)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cabezazos'));
    await tester.pumpAndSettle();

    expect(find.text('Toc1'), findsOneWidget);

    await tester.tap(find.text('Atrapa'));
    await tester.pumpAndSettle();

    expect(find.text('Atr1'), findsOneWidget);
  });

  testWidgets('abre en la pestaña del juego que se le pide', (tester) async {
    pantallaDeMovil(tester);

    final servicio = JuegoServiceFalso(
      filas: {(Juego.atrapa, PeriodoRanking.semana): _top('Atr')},
    );

    await tester.pumpWidget(
      appDePrueba(
        RankingJuegoPage(
          juegoInicial: Juego.atrapa,
          servicio: servicio,
          conSesion: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atr1'), findsOneWidget);
  });

  testWidgets('con sesión, tu fila sale resaltada (sin distinguir mayúsculas)', (tester) async {
    pantallaDeMovil(tester);

    final servicio = JuegoServiceFalso(
      perfilInicial: const PerfilJuego(alias: 'sem2'),
      filas: {(Juego.atrapa, PeriodoRanking.semana): _top('Sem')},
    );

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: servicio, conSesion: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tu-fila')), findsOneWidget);
    expect(find.text('Sem2 · Tú'), findsOneWidget);
    expect(find.text('Sem1'), findsOneWidget);
    expect(find.byKey(const ValueKey('tu-posicion')), findsNothing);
  });

  testWidgets('con sesión y fuera del top 50: tu posición al final', (tester) async {
    pantallaDeMovil(tester, alto: 4000);

    final servicio = JuegoServiceFalso(
      perfilInicial: const PerfilJuego(
        alias: 'Zeta',
        juegos: {
          Juego.atrapa: MarcasDeJuego(
            semana: MarcaJuego(puntos: 3, posicion: 80),
            historico: MarcaJuego(puntos: 9, posicion: 120),
          ),
        },
      ),
      filas: {
        (Juego.atrapa, PeriodoRanking.semana): _top('Top', n: 50, base: 100),
        (Juego.atrapa, PeriodoRanking.historico): _top('Top', n: 50, base: 100),
      },
    );

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: servicio, conSesion: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Top50'), findsOneWidget);
    expect(find.byKey(const ValueKey('tu-posicion')), findsOneWidget);
    expect(find.text('#80'), findsOneWidget);
    expect(find.text('Zeta · Tú'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // La posición depende del periodo.
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    expect(find.text('#120'), findsOneWidget);
    expect(find.text('#80'), findsNothing);
  });

  testWidgets('un perfil oculto (sin posición) o sin alias no sale al final', (tester) async {
    pantallaDeMovil(tester);

    for (final perfil in const [
      PerfilJuego(
        alias: 'Zeta',
        oculto: true,
        juegos: {
          Juego.atrapa: MarcasDeJuego(semana: MarcaJuego(puntos: 3)),
        },
      ),
      PerfilJuego(),
    ]) {
      final servicio = JuegoServiceFalso(
        perfilInicial: perfil,
        filas: {(Juego.atrapa, PeriodoRanking.semana): _top('Sem')},
      );

      await tester.pumpWidget(
        appDePrueba(RankingJuegoPage(servicio: servicio, conSesion: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tu-posicion')), findsNothing);
      expect(find.byKey(const ValueKey('tu-fila')), findsNothing);
    }
  });

  testWidgets('el perfil que ya tiene quien lo abre no se vuelve a pedir', (tester) async {
    pantallaDeMovil(tester);

    final servicio = JuegoServiceFalso();

    await tester.pumpWidget(
      appDePrueba(
        RankingJuegoPage(
          servicio: servicio,
          conSesion: true,
          perfil: const PerfilJuego(alias: 'Ana'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(servicio.perfilesPedidos, 0);
  });

  testWidgets('sin puntuaciones: mensaje; con error de red: mensaje y reintentar', (tester) async {
    pantallaDeMovil(tester);

    final vacio = JuegoServiceFalso();

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: vacio, conSesion: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay puntuaciones'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());

    final roto = _ServicioQueFalla();

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: roto, conSesion: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay puntuaciones'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);

    roto.falla = false;

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay puntuaciones'), findsOneWidget);
  });
}

class _ServicioQueFalla extends JuegoServiceFalso {
  bool falla = true;

  @override
  Future<List<FilaRanking>> ranking(Juego juego, PeriodoRanking periodo) async {
    if (falla) throw const ApiException('No hay conexión a internet.');

    return const [];
  }
}

void _pruebasDeParejas() {
  testWidgets('Parejas enseña el tiempo (m:ss,d) porque la marca es TIEMPO, y Atrapa los puntos', (tester) async {
    pantallaDeMovil(tester);

    final servicio = JuegoServiceFalso(
      filas: {
        (Juego.parejas, PeriodoRanking.semana): const [
          FilaRanking(posicion: 1, alias: 'Rapido', puntos: 8, tiempoMs: 31400, esTiempo: true),
          FilaRanking(posicion: 2, alias: 'Lento', puntos: 8, tiempoMs: 83450, esTiempo: true),
        ],
        (Juego.atrapa, PeriodoRanking.semana): const [
          FilaRanking(posicion: 1, alias: 'Manos', puntos: 33, tiempoMs: 40000),
        ],
      },
    );

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(juegoInicial: Juego.parejas, servicio: servicio, conSesion: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rapido'), findsOneWidget);
    expect(find.text('0:31,4'), findsOneWidget);
    expect(find.text('1:23,4'), findsOneWidget);
    // En el ranking de tiempo no salen los 8 puntos.
    expect(find.text('8'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(servicio: servicio, conSesion: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manos'), findsOneWidget);
    expect(find.text('33'), findsOneWidget);
    expect(find.text('0:40,0'), findsNothing);
  });

  testWidgets('Parejas: tu posición fuera del top 50 sale como tiempo', (tester) async {
    pantallaDeMovil(tester, alto: 4000);

    final servicio = JuegoServiceFalso(
      perfilInicial: const PerfilJuego(
        alias: 'Zeta',
        juegos: {
          Juego.parejas: MarcasDeJuego(
            esTiempo: true,
            semana: MarcaJuego(puntos: 8, tiempoMs: 95200, posicion: 80),
          ),
        },
      ),
      filas: {
        (Juego.parejas, PeriodoRanking.semana): [
          for (var i = 1; i <= 50; i++)
            FilaRanking(posicion: i, alias: 'Top$i', puntos: 8, tiempoMs: 20000 + i * 100, esTiempo: true),
        ],
      },
    );

    await tester.pumpWidget(
      appDePrueba(RankingJuegoPage(juegoInicial: Juego.parejas, servicio: servicio, conSesion: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tu-posicion')), findsOneWidget);
    expect(find.text('#80'), findsOneWidget);
    expect(find.text('1:35,2'), findsOneWidget);
  });
}
