import 'package:app_mutxamel_cf/core/widget/escudo_rival.dart';
import 'dart:async';

import 'package:app_mutxamel_cf/features/juego/estado_mutxigol.dart';
import 'package:app_mutxamel_cf/features/juego/logica/atrapa_logica.dart';
import 'package:app_mutxamel_cf/features/juego/logica/cabezazos_logica.dart';
import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:app_mutxamel_cf/features/juego/logica/parejas_logica.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/partida_juego_page.dart';
import 'package:app_mutxamel_cf/features/juego/pages/ranking_juego_page.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/leyenda_atrapa.dart';
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

/// Una partida con la lógica de prueba (suma 1 punto a los 0,5 s y acaba a los 2 s) o, con [real], la del juego.
Future<void> _pintar(
  WidgetTester tester,
  Juego juego, {
  JuegoServiceFalso? servicio,
  bool conSesion = false,
  PerfilJuego? perfil,
  bool real = false,
  LogicaJuego Function(double alto)? crearLogica,
}) async {
  pantallaDeMovil(tester, alto: 800);

  await tester.pumpWidget(
    appDePrueba(
      PartidaJuegoPage(
        juego: juego,
        conSesion: conSesion,
        perfil: perfil,
        servicio: servicio ?? JuegoServiceFalso(),
        crearLogica:
            crearLogica ??
            (real ? null : (alto) => LogicaDePrueba(alto: alto, conVidas: true)),
      ),
    ),
  );
  await tester.pump();
}

/// Las tarjetas amarillas del marcador, llenas o vacías.
Finder _amarillas(String estado) => find.byWidgetPredicate((w) {
  final clave = w.key;

  return clave is ValueKey &&
      '${clave.value}'.startsWith('amarilla-') &&
      '${clave.value}'.endsWith(estado);
});

void main() {
  final vibraciones = <String>[];

  setUp(() {
    EstadoMutxigol.reiniciar();
    // En los tests no hace falta enseñar la leyenda antes de la primera partida (salvo en los que la prueban).
    EstadoMutxigol.leyendaAtrapaVista = true;
    vibraciones.clear();

    EscudoRival.precargadorDeRed = (contexto, url) async => true;

    EscudoRival.constructorDeRed = (url, tamano, generico) =>
        SizedBox(key: ValueKey('escudo-$url'), width: tamano, height: tamano);

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
    EscudoRival.constructorDeRed = null;
    EscudoRival.precargadorDeRed = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('la partida', () {
    testWidgets('empieza con una cuenta atrás de 3 segundos y entonces se juega', (tester) async {
      await _pintar(tester, Juego.atrapa, real: true);

      expect(find.byKey(const ValueKey('cuenta-atras')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await _avanzar(tester, 1.1);

      expect(find.text('2'), findsOneWidget);

      await _avanzar(tester, 1.0);

      expect(find.text('1'), findsOneWidget);

      await _avanzar(tester, 1.1);

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(find.text('Puntos: 0'), findsOneWidget);

      // Se pinta a Mutxigol atrapando, con su equipación.
      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.atrapando)),
        findsOneWidget,
      );
    });

    testWidgets('durante la cuenta atrás el juego no avanza ni admite toques', (tester) async {
      await _pintar(tester, Juego.atrapa, real: true);

      await tester.tapAt(const Offset(180, 150));
      await _avanzar(tester, 1.0);

      expect(find.text('Puntos: 0'), findsOneWidget);
    });

    testWidgets('con la equipación rosa se pintan las poses rosas', (tester) async {
      EstadoMutxigol.equipacion.value = Equipacion.rosa;

      await _pintar(tester, Juego.atrapa, real: true);

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
      await _pintar(tester, Juego.atrapa);
      await _avanzar(tester, 3.2);

      await tester.tap(find.byKey(const ValueKey('pausa')));
      await tester.pump();

      expect(find.text('Juego en pausa'), findsOneWidget);

      // En pausa pasa el tiempo y la partida no avanza: no se acaba.
      await _avanzar(tester, 3);

      expect(find.byKey(const ValueKey('otra-vez')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('reanudar')));
      await tester.pump();
      await _avanzar(tester, 2);

      // Reanudada, la partida sigue y se acaba.
      expect(find.byKey(const ValueKey('otra-vez')), findsOneWidget);
    });

    testWidgets('la cuenta atrás también se puede pausar y sigue donde estaba', (tester) async {
      await _pintar(tester, Juego.atrapa);
      await _avanzar(tester, 1.0);

      await tester.tap(find.byKey(const ValueKey('pausa')));
      await tester.pump();
      await _avanzar(tester, 5);
      await tester.tap(find.byKey(const ValueKey('reanudar')));
      await tester.pump();

      expect(find.byKey(const ValueKey('cuenta-atras')), findsOneWidget);
    });

    testWidgets('con la app en segundo plano el juego se pausa solo', (tester) async {
      await _pintar(tester, Juego.atrapa);
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
                      juego: Juego.atrapa,
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

    testWidgets('Atrapa enseña las 3 vidas; Cabezazos (1 vida) y Parejas no', (tester) async {
      await _pintar(tester, Juego.atrapa, real: true);

      expect(find.byKey(const ValueKey('marcador-vidas')), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNWidgets(3));

      await tester.pumpWidget(const SizedBox());
      await _pintar(tester, Juego.cabezazos, real: true);

      expect(find.byKey(const ValueKey('marcador-vidas')), findsNothing);
      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.salto)),
        findsOneWidget,
      );
    });
  });

  group('al acabar', () {
    testWidgets('sin sesión: fin de partida, no se envía nada y se pide iniciar sesión', (tester) async {
      final servicio = JuegoServiceFalso();

      await _pintar(tester, Juego.atrapa, servicio: servicio);
      await _avanzar(tester, 6);

      expect(find.byKey(const ValueKey('fin-puntos')), findsOneWidget);
      expect(find.text('1 puntos'), findsOneWidget);
      expect(find.byKey(const ValueKey('aviso-sin-sesion')), findsOneWidget);
      expect(servicio.guardadas, isEmpty);
      // El récord de esta sesión (solo en memoria) se recuerda.
      expect(EstadoMutxigol.recordDeLaSesion(Juego.atrapa), 1);
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
        Juego.atrapa,
        servicio: servicio,
        conSesion: true,
        perfil: const PerfilJuego(alias: 'Ana'),
      );
      await _avanzar(tester, 6);

      expect(servicio.guardadas, hasLength(1));

      final (juego, puntos, duracionMs) = servicio.guardadas.single;

      expect(juego, Juego.atrapa);
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
        Juego.atrapa,
        servicio: servicio,
        conSesion: true,
        perfil: const PerfilJuego(),
      );
      await _avanzar(tester, 6);

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
        Juego.atrapa,
        servicio: servicio,
        conSesion: true,
        perfil: const PerfilJuego(alias: 'Ana'),
      );
      await _avanzar(tester, 6);

      expect(find.text('No se ha podido guardar tu puntuación.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reintentar-envio')));
      await tester.pump();

      expect(servicio.guardadas, hasLength(1));
      expect(find.byKey(const ValueKey('reintentar-envio')), findsNothing);
    });

    testWidgets('Otra vez empieza una partida nueva con su cuenta atrás', (tester) async {
      await _pintar(tester, Juego.atrapa);
      await _avanzar(tester, 6);

      await tester.tap(find.byKey(const ValueKey('otra-vez')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const ValueKey('fin-puntos')), findsNothing);
      expect(find.byKey(const ValueKey('cuenta-atras')), findsOneWidget);
      expect(find.text('Puntos: 0'), findsOneWidget);
    });

    testWidgets('el botón Ranking abre el ranking de ese juego', (tester) async {
      await _pintar(tester, Juego.atrapa);
      await _avanzar(tester, 6);

      await tester.tap(find.byKey(const ValueKey('ver-ranking')));
      await tester.pumpAndSettle();

      expect(find.byType(RankingJuegoPage), findsOneWidget);
    });

    testWidgets('vibra ligeramente al marcar y al perder', (tester) async {
      await _pintar(tester, Juego.atrapa);
      await _avanzar(tester, 6);

      // Un punto y el final (fallo).
      expect(vibraciones, hasLength(2));
      expect(vibraciones.first, contains('lightImpact'));
      expect(vibraciones.last, contains('mediumImpact'));
    });
  });

  group('Atrapa balones', () {
    testWidgets('arrastrar mueve a Mutxigol y se atrapa lo que cae', (tester) async {
      late AtrapaLogica logica;

      await _pintar(
        tester,
        Juego.atrapa,
        crearLogica: (alto) =>
            logica = AtrapaLogica(alto: alto, soltarSolo: false),
      );
      await _avanzar(tester, 3.2);

      await tester.dragFrom(const Offset(180, 600), const Offset(100, 0));
      await tester.pump();

      expect(logica.x, greaterThan(250));

      logica.soltar(TipoCaida.balon, logica.x);
      await _avanzar(tester, 4);

      expect(logica.puntos, 1);
      expect(find.text('Puntos: 1'), findsOneWidget);
    });

    testWidgets('antes de la primera partida sale la leyenda con cada objeto y qué hace', (tester) async {
      EstadoMutxigol.leyendaAtrapaVista = false;

      await _pintar(tester, Juego.atrapa, real: true);

      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsOneWidget);

      for (final tipo in LeyendaAtrapa.objetos) {
        expect(find.byKey(ValueKey('leyenda-${tipo.name}')), findsOneWidget, reason: tipo.name);
        expect(find.byKey(ValueKey('objeto-${tipo.name}')), findsWidgets, reason: tipo.name);
      }

      expect(find.text('Balón dorado: +5 puntos.'), findsOneWidget);
      expect(find.text('Escudo del club: +1 vida (máximo 3).'), findsOneWidget);
      expect(find.text('Silbato: Mutxigol se queda quieto 2 segundos.'), findsOneWidget);

      // Hasta que se cierra, no hay cuenta atrás ni la partida corre.
      await _avanzar(tester, 4);

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cerrar-leyenda')));
      await tester.pump();

      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsNothing);
      expect(find.byKey(const ValueKey('cuenta-atras')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(EstadoMutxigol.leyendaAtrapaVista, isTrue);
    });

    testWidgets('en las partidas siguientes no sale sola, pero el botón "¿Cómo se juega?" la enseña', (tester) async {
      await _pintar(tester, Juego.atrapa, real: true);

      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsNothing);

      await _avanzar(tester, 3.2);
      await tester.tap(find.byKey(const ValueKey('como-se-juega')));
      await tester.pumpAndSettle();

      // La partida queda en pausa y la leyenda a la vista.
      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsOneWidget);
      expect(find.text('Juego en pausa'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cerrar-leyenda')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsNothing);
      expect(find.text('Juego en pausa'), findsOneWidget);
    });

    testWidgets('el marcador de amarillas se llena con una y se vacía al perder la vida', (tester) async {
      late AtrapaLogica logica;

      await _pintar(
        tester,
        Juego.atrapa,
        crearLogica: (alto) =>
            logica = AtrapaLogica(alto: alto, soltarSolo: false),
      );
      await _avanzar(tester, 3.2);

      expect(_amarillas('llena'), findsNothing);
      expect(_amarillas('vacia'), findsNWidgets(2));

      logica.soltar(TipoCaida.tarjetaAmarilla, logica.x);
      await _avanzar(tester, 4);

      expect(_amarillas('llena'), findsOneWidget);

      logica.soltar(TipoCaida.tarjetaAmarilla, logica.x);
      await _avanzar(tester, 4);

      expect(logica.vidas, 2);
      expect(_amarillas('llena'), findsNothing);
    });

    testWidgets('el silbato deja a Mutxigol quieto con un aviso visual', (tester) async {
      late AtrapaLogica logica;

      await _pintar(
        tester,
        Juego.atrapa,
        crearLogica: (alto) =>
            logica = AtrapaLogica(alto: alto, soltarSolo: false),
      );
      await _avanzar(tester, 3.2);

      logica.soltar(TipoCaida.silbato, logica.x);
      await _avanzar(tester, 4);

      expect(logica.congelado, isTrue);
      expect(find.byKey(const ValueKey('aviso-silbato')), findsOneWidget);

      final antes = logica.x;

      await tester.dragFrom(const Offset(180, 600), const Offset(100, 0));
      await tester.pump();

      expect(logica.x, antes);
    });
  });


  group('Cabezazos', () {
    testWidgets('no lleva cuenta atrás: empieza en espera con "Toca para saltar" y nada de "1"', (tester) async {
      late CabezazosLogica logica;

      await _pintar(
        tester,
        Juego.cabezazos,
        crearLogica: (alto) => logica = CabezazosLogica(alto: alto),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('1'), findsNothing);
      expect(find.text('Toca para saltar'), findsOneWidget);
      expect(logica.esperando, isTrue);

      await _avanzar(tester, 4);

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(find.text('1'), findsNothing);
      expect(logica.esperando, isTrue);
      expect(logica.terminado, isFalse);
      expect(logica.barreras, isEmpty);
      expect(logica.tiempoJugado, Duration.zero, reason: 'el tiempo no corre hasta el primer toque');
    });

    testWidgets('el primer toque arranca la partida y el tiempo', (tester) async {
      late CabezazosLogica logica;

      await _pintar(
        tester,
        Juego.cabezazos,
        crearLogica: (alto) => logica = CabezazosLogica(alto: alto),
      );
      await _avanzar(tester, 2);

      await tester.tapAt(const Offset(200, 300));
      await tester.pump();

      expect(logica.esperando, isFalse);
      expect(logica.velocidadVertical, lessThan(0));
      expect(find.text('Toca para saltar'), findsNothing);

      await _avanzar(tester, 0.5);

      expect(logica.tiempoJugado.inMilliseconds, inInclusiveRange(400, 600));
    });

    testWidgets('Mutxigol se pinta con el tamaño nuevo (~86 de alto visible)', (tester) async {
      await _pintar(
        tester,
        Juego.cabezazos,
        crearLogica: (alto) => CabezazosLogica(alto: alto),
      );
      await tester.pump();

      final imagen = imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.salto));

      expect(imagen, findsOneWidget);

      // Pantalla de 360 de ancho = 1 unidad de juego por punto.
      final tamano = tester.getSize(imagen);

      expect(tamano.width, CabezazosLogica.tamanoImagen);
      expect(
        tamano.height * CabezazosLogica.alturaVisibleEnImagen,
        inInclusiveRange(80, 90),
      );
    });
  });

  group('Parejas', () {
    Future<void> sinCrearLogica(WidgetTester tester, JuegoServiceFalso servicio, {double alto = 800}) async {
      pantallaDeMovil(tester, alto: alto);

      await tester.pumpWidget(
        appDePrueba(PartidaJuegoPage(juego: Juego.parejas, servicio: servicio)),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('pide 12 escudos, los precarga y solo entonces enseña el tablero 4×4 (sin cuenta atrás)', (tester) async {
      final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(12);
      final completadores = <String, Completer<bool>>{};

      EscudoRival.precargadorDeRed = (contexto, url) =>
          (completadores[url] = Completer<bool>()).future;

      await sinCrearLogica(tester, servicio);

      // Cargando: indicador y texto, sin tablero y con el cronómetro parado.
      expect(servicio.escudosPedidos, [12]);
      expect(find.byKey(const ValueKey('cargando-escudos')), findsOneWidget);
      expect(find.text('Cargando escudos…'), findsOneWidget);
      expect(find.byKey(const ValueKey('carta-0')), findsNothing);
      expect(find.byKey(const ValueKey('marcador-tiempo')), findsNothing);

      await _avanzar(tester, 3);

      expect(find.byKey(const ValueKey('carta-0')), findsNothing, reason: 'sigue descargando');

      // Cargan 8: ya se puede jugar.
      var cargados = 0;

      for (final c in completadores.values) {
        if (cargados++ < 8) c.complete(true);
      }

      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('cargando-escudos')), findsNothing);
      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);

      for (var i = 0; i < 16; i++) {
        expect(find.byKey(ValueKey('carta-$i')), findsOneWidget, reason: 'carta $i');
      }

      expect(find.byKey(const ValueKey('carta-reverso')), findsNWidgets(16));
      expect(find.text('0:00,0'), findsOneWidget);
      expect(find.text('Intentos: 0'), findsOneWidget);
      expect(find.byKey(const ValueKey('marcador-vidas')), findsNothing);
      expect(find.byKey(const ValueKey('marcador-puntos')), findsNothing);
    });

    testWidgets('con 12 pedidos y 3 que fallan, usa 8 de los buenos', (tester) async {
      final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(12);

      // Fallan los escudos 2, 5 y 9.
      EscudoRival.precargadorDeRed = (contexto, url) async =>
          !['/2?', '/5?', '/9?'].any(url.contains);

      await sinCrearLogica(tester, servicio);
      await tester.pump();

      expect(find.byKey(const ValueKey('sin-escudos')), findsNothing);

      final posiciones = await _descubrir(tester);
      final usados = posiciones.values.toSet();

      expect(usados, hasLength(8));
      expect(usados.intersection({'Club 2', 'Club 5', 'Club 9'}), isEmpty, reason: 'ninguno de los que fallaron');
      // Los 8 primeros que cargan bien, por orden del backend.
      expect(usados, {'Club 1', 'Club 3', 'Club 4', 'Club 6', 'Club 7', 'Club 8', 'Club 10', 'Club 11'});
    });

    testWidgets('con menos de 8 escudos buenos avisa y deja reintentar (y vuelve a pedir otra tanda)', (tester) async {
      final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(12);

      // Solo 5 de los 12 cargan.
      EscudoRival.precargadorDeRed = (contexto, url) async =>
          ['/1?', '/2?', '/3?', '/4?', '/5?'].any(url.contains);

      await sinCrearLogica(tester, servicio);
      await tester.pump();

      expect(find.text('Aún no hay escudos suficientes para jugar'), findsOneWidget);
      expect(find.byKey(const ValueKey('carta-0')), findsNothing);

      EscudoRival.precargadorDeRed = (contexto, url) async => true;

      await tester.tap(find.byKey(const ValueKey('reintentar-escudos')));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(servicio.escudosPedidos, [12, 12]);
      expect(find.text('Aún no hay escudos suficientes para jugar'), findsNothing);
      expect(find.byKey(const ValueKey('carta-0')), findsOneWidget);
    });

    testWidgets('si el backend devuelve menos de 8 también avisa', (tester) async {
      final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(5);

      await sinCrearLogica(tester, servicio);
      await tester.pump();

      expect(find.text('Aún no hay escudos suficientes para jugar'), findsOneWidget);
    });

    testWidgets('si no cargan 8 en 10 s, sale el aviso con Reintentar', (tester) async {
      final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(12);

      // Solo 3 cargan; el resto se queda descargando para siempre.
      EscudoRival.precargadorDeRed = (contexto, url) => ['/1?', '/2?', '/3?'].any(url.contains)
          ? Future.value(true)
          : Completer<bool>().future;

      await sinCrearLogica(tester, servicio);
      await _avanzar(tester, 9);

      expect(find.byKey(const ValueKey('cargando-escudos')), findsOneWidget);

      await _avanzar(tester, 1.5);
      await tester.pump();

      expect(find.text('Aún no hay escudos suficientes para jugar'), findsOneWidget);
      expect(find.byKey(const ValueKey('reintentar-escudos')), findsOneWidget);
    });

    testWidgets('si falla la red avisa igual y se puede salir', (tester) async {
      final servicio = JuegoServiceFalso()..errorDeEscudos = Exception('sin red');

      await sinCrearLogica(tester, servicio);

      expect(find.text('Aún no hay escudos suficientes para jugar'), findsOneWidget);
      expect(find.byKey(const ValueKey('reintentar-escudos')), findsOneWidget);
      expect(find.byKey(const ValueKey('salir')), findsOneWidget);
    });

    testWidgets('la cara de la carta nunca pinta la silueta genérica del escudo', (tester) async {
      final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(12);

      await sinCrearLogica(tester, servicio);
      await tester.pump();

      // Ni cargando ni con las cartas boca arriba (sale el escudo cargado o un hueco, nunca la silueta).
      expect(find.byKey(const ValueKey('escudo-rival')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('carta-0')));
      await tester.pump();
      await _avanzar(tester, 0.1);

      expect(find.byKey(const ValueKey('escudo-rival')), findsNothing);

      await _avanzar(tester, 0.4);

      expect(find.byKey(const ValueKey('carta-frente')), findsOneWidget);
      expect(find.byKey(const ValueKey('escudo-rival')), findsNothing);
    });

    testWidgets('una partida entera: cronómetro, pareja mala que se vuelve a girar, fin y envío con 8 puntos y el tiempo', (tester) async {
      final servicio = JuegoServiceFalso();
      late ParejasLogica logica;

      await _pintar(
        tester,
        Juego.parejas,
        servicio: servicio,
        conSesion: true,
        perfil: const PerfilJuego(alias: 'Ana'),
        crearLogica: (alto) => logica = ParejasLogica(
          alto: alto,
          escudos: escudosDePrueba(),
          random: AleatorioFalso(),
        ),
      );

      // Sin cuenta atrás y con el cronómetro parado hasta la primera carta.
      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);

      await _avanzar(tester, 1.5);

      expect(find.text('0:00,0'), findsOneWidget);

      // Un par que no coincide: se enseñan y, tras girarse, se quedan 0,8 s antes de volver a girarse.
      final cartas = logica.cartas;
      final a = cartas.first;
      final b = cartas.firstWhere((c) => c.escudo.id != a.escudo.id);

      await tester.tap(find.byKey(ValueKey('carta-${a.posicion}')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('carta-${b.posicion}')));
      await _avanzar(tester, 0.4);

      expect(find.byKey(const ValueKey('carta-frente')), findsNWidgets(2));
      expect(find.text('Intentos: 1'), findsOneWidget);
      // El cronómetro corre desde la primera carta.
      expect(find.text('0:00,0'), findsNothing);

      await _avanzar(tester, 1.3);

      expect(find.byKey(const ValueKey('carta-frente')), findsNothing);

      // Ahora las 8 parejas.
      for (var id = 1; id <= 8; id++) {
        final par = logica.cartas.where((c) => c.escudo.id == id).toList();

        await tester.tap(find.byKey(ValueKey('carta-${par[0].posicion}')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('carta-${par[1].posicion}')));
        await _avanzar(tester, 0.4);
      }

      await _avanzar(tester, 0.5);

      expect(logica.terminado, isTrue);
      expect(find.byKey(const ValueKey('fin-puntos')), findsOneWidget);
      // El fin enseña el tiempo (no los puntos).
      expect(find.textContaining('Tiempo: '), findsOneWidget);

      expect(servicio.guardadas, hasLength(1));

      final (juego, puntos, duracionMs) = servicio.guardadas.single;

      expect(juego, Juego.parejas);
      expect(puntos, 8);
      expect(duracionMs, logica.tiempoJugado.inMilliseconds);
      expect(duracionMs, greaterThan(3000));
    });

    testWidgets('Otra vez pide una tanda nueva de escudos y la precarga antes de enseñar el tablero', (tester) async {
      final servicio = JuegoServiceFalso()..escudosRespuesta = escudosDePrueba(12);

      await sinCrearLogica(tester, servicio);
      await tester.pump();

      // Se descubre el tablero y se acaban las parejas.
      final posiciones = await _descubrir(tester);

      for (final nombre in posiciones.values.toSet()) {
        final pareja = [for (final e in posiciones.entries) if (e.value == nombre) e.key];

        await tester.tap(find.byKey(ValueKey('carta-${pareja[0]}')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('carta-${pareja[1]}')));
        await _avanzar(tester, 1.5);
      }

      await _avanzar(tester, 0.5);

      expect(find.byKey(const ValueKey('fin-puntos')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // La nueva tanda se descarga antes de enseñar nada.
      final pendiente = Completer<bool>();

      EscudoRival.precargadorDeRed = (contexto, url) => pendiente.future;

      await tester.tap(find.byKey(const ValueKey('otra-vez')));
      await tester.pump();
      await tester.pump();

      expect(servicio.escudosPedidos, [12, 12]);
      expect(find.byKey(const ValueKey('cargando-escudos')), findsOneWidget);
      expect(find.byKey(const ValueKey('carta-0')), findsNothing);
      expect(find.byKey(const ValueKey('fin-puntos')), findsNothing);

      pendiente.complete(true);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('carta-0')), findsOneWidget);
      expect(find.text('0:00,0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Descubre las 16 cartas de una en una (esperando a que se vuelvan a girar las que no son pareja) y devuelve el
/// nombre del club de cada posición.
Future<Map<int, String>> _descubrir(WidgetTester tester) async {
  final posiciones = <int, String>{};

  for (var i = 0; i < 16; i++) {
    await tester.tap(find.byKey(ValueKey('carta-$i')));
    await _avanzar(tester, 0.4);

    final carta = find.descendant(
      of: find.byKey(ValueKey('carta-$i')),
      matching: find.textContaining('Club '),
    );

    if (carta.evaluate().isNotEmpty) {
      posiciones[i] = (carta.evaluate().single.widget as Text).data!;
    }

    // Cada dos cartas, a esperar a que el par que no coincide se vuelva a girar.
    if (i.isOdd) await _avanzar(tester, 1.4);
  }

  return posiciones;
}
