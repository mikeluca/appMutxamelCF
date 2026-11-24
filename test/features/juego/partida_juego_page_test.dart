import 'package:app_mutxamel_cf/features/juego/estado_mutxigol.dart';
import 'package:app_mutxamel_cf/features/juego/logica/atrapa_logica.dart';
import 'package:app_mutxamel_cf/features/juego/logica/penaltis_logica.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/partida_juego_page.dart';
import 'package:app_mutxamel_cf/features/juego/pages/ranking_juego_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

/// Avanza [segundos] de partida, fotograma a fotograma (la partida no avanza más de 50 ms por fotograma).
Future<void> _avanzar(WidgetTester tester, double segundos) async {
  final fotogramas = (segundos * 1000 / 16).round();

  for (var i = 0; i < fotogramas; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pintar(
  WidgetTester tester,
  Juego juego, {
  JuegoServiceFalso? servicio,
  bool conSesion = false,
  PerfilJuego? perfil,
}) async {
  pantallaDeMovil(tester, alto: 800);

  await tester.pumpWidget(
    appDePrueba(
      PartidaJuegoPage(
        juego: juego,
        conSesion: conSesion,
        perfil: perfil,
        servicio: servicio ?? JuegoServiceFalso(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final vibraciones = <String>[];

  setUp(() {
    EstadoMutxigol.reiniciar();
    vibraciones.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
          if (llamada.method == 'HapticFeedback.vibrate') {
            vibraciones.add('${llamada.arguments}');
          }

          return null;
        });
  });

  tearDown(() {
    EstadoMutxigol.reiniciar();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('la partida', () {
    testWidgets('empieza con una cuenta atrás de 3 segundos y entonces se juega', (tester) async {
      await _pintar(tester, Juego.toques);

      expect(find.byKey(const ValueKey('cuenta-atras')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await _avanzar(tester, 1.1);

      expect(find.text('2'), findsOneWidget);

      await _avanzar(tester, 1.0);

      expect(find.text('1'), findsOneWidget);

      await _avanzar(tester, 1.1);

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(find.text('Puntos: 0'), findsOneWidget);

      // Se pinta a Mutxigol de Toques con su equipación.
      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.toques)),
        findsOneWidget,
      );
    });

    testWidgets('durante la cuenta atrás el juego no avanza ni admite toques', (tester) async {
      await _pintar(tester, Juego.toques);

      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 1.0);

      expect(find.text('Puntos: 0'), findsOneWidget);
    });

    testWidgets('con la equipación rosa se pintan las poses rosas', (tester) async {
      EstadoMutxigol.equipacion.value = Equipacion.rosa;

      await _pintar(tester, Juego.atrapa);

      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.rosa, PoseMutxigol.atrapando)),
        findsOneWidget,
      );
      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.atrapando)),
        findsNothing,
      );
    });

    testWidgets('el botón de pausa para el juego y Continuar lo reanuda', (tester) async {
      await _pintar(tester, Juego.toques);
      await _avanzar(tester, 3.2);

      await tester.tap(find.byKey(const ValueKey('pausa')));
      await tester.pump();

      expect(find.text('Juego en pausa'), findsOneWidget);

      // En pausa pasa el tiempo y el balón no cae: no se acaba la partida.
      await _avanzar(tester, 3);

      expect(find.byKey(const ValueKey('otra-vez')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('reanudar')));
      await tester.pump();
      await _avanzar(tester, 2);

      // Reanudada, sin tocar nada, el balón cae y se acaba.
      expect(find.byKey(const ValueKey('otra-vez')), findsOneWidget);
    });

    testWidgets('la cuenta atrás también se puede pausar y sigue donde estaba', (tester) async {
      await _pintar(tester, Juego.toques);
      await _avanzar(tester, 1.0);

      await tester.tap(find.byKey(const ValueKey('pausa')));
      await tester.pump();
      await _avanzar(tester, 5);
      await tester.tap(find.byKey(const ValueKey('reanudar')));
      await tester.pump();

      expect(find.byKey(const ValueKey('cuenta-atras')), findsOneWidget);
    });

    testWidgets('con la app en segundo plano el juego se pausa solo', (tester) async {
      await _pintar(tester, Juego.toques);
      await _avanzar(tester, 3.2);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(find.text('Juego en pausa'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Al volver sigue en pausa hasta que el jugador lo reanude.
      expect(find.text('Juego en pausa'), findsOneWidget);
    });

    testWidgets('salir cierra la pantalla y el juego deja de correr', (tester) async {
      pantallaDeMovil(tester, alto: 800);

      await tester.pumpWidget(
        appDePrueba(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PartidaJuegoPage(
                      juego: Juego.penaltis,
                      servicio: JuegoServiceFalso(),
                    ),
                  ),
                ),
                child: const Text('Jugar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Jugar'));
      await tester.pump();
      await _avanzar(tester, 1);

      expect(find.byType(PartidaJuegoPage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('salir')));

      // Al salir, el Ticker se libera: no queda nada que pinte fotogramas y la pantalla se asienta.
      await tester.pumpAndSettle();

      expect(find.byType(PartidaJuegoPage), findsNothing);
    });

    testWidgets('Penaltis enseña las 3 vidas y Toques no', (tester) async {
      await _pintar(tester, Juego.penaltis);

      expect(find.byKey(const ValueKey('marcador-vidas')), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNWidgets(3));
      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.portero)),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await _pintar(tester, Juego.toques);

      expect(find.byKey(const ValueKey('marcador-vidas')), findsNothing);
    });
  });

  group('al acabar', () {
    testWidgets('sin sesión: fin de partida, no se envía nada y se pide iniciar sesión', (tester) async {
      final servicio = JuegoServiceFalso();

      await _pintar(tester, Juego.toques, servicio: servicio);
      await _avanzar(tester, 3.2);
      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 3);

      expect(find.byKey(const ValueKey('fin-puntos')), findsOneWidget);
      expect(find.text('1 puntos'), findsOneWidget);
      expect(find.byKey(const ValueKey('aviso-sin-sesion')), findsOneWidget);
      expect(servicio.guardadas, isEmpty);
      // El récord de esta sesión (solo en memoria) se recuerda.
      expect(EstadoMutxigol.recordDeLaSesion(Juego.toques), 1);
    });

    testWidgets('con sesión y alias: se envía sola con juego, puntos y duración, y se enseña la respuesta', (tester) async {
      final servicio = JuegoServiceFalso()
        ..resultado = const ResultadoPuntuacion(
          recordSemana: true,
          recordHistorico: true,
          posicionSemana: 1,
          posicionHistorico: 5,
        );

      await _pintar(
        tester,
        Juego.toques,
        servicio: servicio,
        conSesion: true,
        perfil: const PerfilJuego(alias: 'Ana'),
      );
      await _avanzar(tester, 3.2);
      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 3);

      expect(servicio.guardadas, hasLength(1));

      final (juego, puntos, duracionMs) = servicio.guardadas.single;

      expect(juego, Juego.toques);
      expect(puntos, 1);
      expect(duracionMs, greaterThanOrEqualTo(3000));

      expect(find.byKey(const ValueKey('record-semana')), findsOneWidget);
      expect(find.text('Histórico: puesto 5'), findsOneWidget);
      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.celebrando)),
        findsOneWidget,
      );
    });

    testWidgets('con sesión y sin alias: pide el alias y no envía hasta tenerlo', (tester) async {
      final servicio = JuegoServiceFalso();

      await _pintar(
        tester,
        Juego.toques,
        servicio: servicio,
        conSesion: true,
        perfil: const PerfilJuego(),
      );
      await _avanzar(tester, 3.2);
      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 3);

      expect(find.byKey(const ValueKey('aviso-sin-alias')), findsOneWidget);
      expect(servicio.guardadas, isEmpty);

      await tester.tap(find.byKey(const ValueKey('elegir-alias')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('campo-alias')), 'Mutxigol10');
      await tester.tap(find.byKey(const ValueKey('guardar-alias')));
      await tester.pumpAndSettle();

      expect(servicio.actualizaciones, [('Mutxigol10', null)]);
      expect(servicio.guardadas, hasLength(1));
    });

    testWidgets('sin red: mensaje discreto y reintentar manda la puntuación', (tester) async {
      final servicio = JuegoServiceFalso()
        ..errorAlGuardar = Exception('sin red')
        ..errorUnaVez = true;

      await _pintar(
        tester,
        Juego.toques,
        servicio: servicio,
        conSesion: true,
        perfil: const PerfilJuego(alias: 'Ana'),
      );
      await _avanzar(tester, 3.2);
      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 3);

      expect(find.text('No se ha podido guardar tu puntuación.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reintentar-envio')));
      await tester.pump();

      expect(servicio.guardadas, hasLength(1));
      expect(find.byKey(const ValueKey('reintentar-envio')), findsNothing);
    });

    testWidgets('Otra vez empieza una partida nueva con su cuenta atrás', (tester) async {
      await _pintar(tester, Juego.toques);
      await _avanzar(tester, 3.2);
      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 3);

      await tester.tap(find.byKey(const ValueKey('otra-vez')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const ValueKey('fin-puntos')), findsNothing);
      expect(find.byKey(const ValueKey('cuenta-atras')), findsOneWidget);
      expect(find.text('Puntos: 0'), findsOneWidget);
    });

    testWidgets('el botón Ranking abre el ranking de ese juego', (tester) async {
      await _pintar(tester, Juego.toques);
      await _avanzar(tester, 3.2);
      await _avanzar(tester, 3);

      await tester.tap(find.byKey(const ValueKey('ver-ranking')));
      await tester.pumpAndSettle();

      expect(find.byType(RankingJuegoPage), findsOneWidget);
    });
  });

  group('cada juego se juega con el dedo', () {
    testWidgets('Atrapa: arrastrar mueve a Mutxigol y se atrapa lo que cae', (tester) async {
      pantallaDeMovil(tester, alto: 800);

      late AtrapaLogica logica;

      await tester.pumpWidget(
        appDePrueba(
          PartidaJuegoPage(
            juego: Juego.atrapa,
            servicio: JuegoServiceFalso(),
            crearLogica: (alto) =>
                logica = AtrapaLogica(alto: alto, soltarSolo: false),
          ),
        ),
      );
      await tester.pump();
      await _avanzar(tester, 3.2);

      await tester.dragFrom(const Offset(180, 600), const Offset(100, 0));
      await tester.pump();

      expect(logica.x, greaterThan(250));

      logica.soltar(TipoCaida.balon, logica.x);
      await _avanzar(tester, 4);

      expect(logica.puntos, 1);
      expect(find.text('Puntos: 1'), findsOneWidget);
    });

    testWidgets('Penaltis: deslizar desde el balón hacia la portería tira', (tester) async {
      pantallaDeMovil(tester, alto: 800);

      late PenaltisLogica logica;

      await tester.pumpWidget(
        appDePrueba(
          PartidaJuegoPage(
            juego: Juego.penaltis,
            servicio: JuegoServiceFalso(),
            crearLogica: (alto) => logica = PenaltisLogica(
              alto: alto,
              random: AleatorioFalso(),
            ),
          ),
        ),
      );
      await tester.pump();
      await _avanzar(tester, 3.2);

      final reposo = logica.balonReposo;

      await tester.dragFrom(reposo, const Offset(0, -110));
      await tester.pump();

      expect(logica.tiros, 1);
      expect(logica.fase, isNot(FasePenalti.apuntando));
    });

    testWidgets('vibra ligeramente al marcar y al perder', (tester) async {
      await _pintar(tester, Juego.toques);
      await _avanzar(tester, 3.2);
      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 3);

      // Un toque (punto) y el suelo (fallo).
      expect(vibraciones, hasLength(2));
      expect(vibraciones.first, contains('lightImpact'));
      expect(vibraciones.last, contains('mediumImpact'));
    });
  });
}
