import 'dart:async';

import 'package:app_mutxamel_cf/features/directo/models/momentos_partido.dart';
import 'package:app_mutxamel_cf/features/directo/widgets/barra_momentos.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/reloj_directo.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

EventoFicha _gol(int minuto, {String? jugador = 'Pepe'}) => EventoFicha(
  tipo: EventoFicha.golFavor,
  minuto: minuto,
  jugador: jugador,
  golesFavor: 1,
  golesContra: 0,
);

EventoFicha _golRival(int minuto, {int? dorsal}) => EventoFicha(
  tipo: EventoFicha.golContra,
  minuto: minuto,
  golesFavor: 0,
  golesContra: 1,
  dorsalRival: dorsal,
);

EventoFicha _tarjeta(int minuto, {bool roja = false, bool rival = false}) =>
    EventoFicha(
      tipo: roja ? EventoFicha.tarjetaRoja : EventoFicha.tarjetaAmarilla,
      minuto: minuto,
      jugador: rival ? null : 'Luis',
      rival: rival,
    );

EventoFicha _cambio(int minuto) => EventoFicha(
  tipo: EventoFicha.cambio,
  minuto: minuto,
  jugador: 'Luis',
  jugadorEntra: 'Juanma',
);

const EventoFicha _descanso = EventoFicha(tipo: EventoFicha.descanso);
const EventoFicha _final = EventoFicha(tipo: EventoFicha.finalPartido);

/// Lo último primero, como llega de la ficha.
List<EventoFicha> _recientesPrimero(List<EventoFicha> cronologico) =>
    cronologico.reversed.toList();

void main() {
  group('colocarMomentos', () {
    List<Momento> colocar(
      List<EventoFicha> cronologico, {
      int minutosParte = 45,
      bool local = true,
      FaseReloj? fase,
    }) => colocarMomentos(
      _recientesPrimero(cronologico),
      minutosParte: minutosParte,
      mutxamelEsLocal: local,
      fase: fase,
    ).reversed.toList(); // cronológico, para comparar con lo escrito

    test('la posición es el minuto sobre el total (0 a 2·minutosParte)', () {
      final m = colocar([
        _gol(0),
        _gol(23),
        _descanso,
        _gol(45),
        _gol(67),
        _gol(90),
      ]);

      expect(m.map((x) => x.fraccion), [0.0, 23 / 90, 0.5, 67 / 90, 1.0]);
    });

    test('la duración de la parte sale de minutosParte (F8: 25)', () {
      final m = colocar([_gol(10), _descanso, _gol(40)], minutosParte: 25);

      expect(m[0].fraccion, closeTo(10 / 50, 1e-9));
      expect(m[1].fraccion, closeTo(40 / 50, 1e-9));
    });

    test('el añadido de la primera parte va al final de la primera parte', () {
      // El 47' es anterior al descanso: se queda en el 45' (la mitad), sin pasarse a la segunda parte.
      final m = colocar([_gol(30), _gol(47), _descanso, _gol(50)]);

      expect(m.map((x) => x.fraccion), [30 / 90, 0.5, 50 / 90]);
    });

    test(
      'el añadido de la segunda parte va al final de la barra, sin salirse',
      () {
        final m = colocar([_gol(10), _descanso, _gol(88), _gol(93), _gol(99)]);

        expect(m.map((x) => x.fraccion).toList(), [10 / 90, 88 / 90, 1.0, 1.0]);
        expect(m.every((x) => x.fraccion <= 1.0), isTrue);
      },
    );

    test(
      'un hecho de la primera parte con minuto de la segunda no se sale hacia atrás',
      () {
        // El minuto 44 pero ya en la segunda parte (separador antes): se coloca en la mitad como mínimo.
        final m = colocar([_descanso, _gol(44)]);

        expect(m.single.fraccion, 0.5);
      },
    );

    test('sin descanso registrado: la fase del reloj o, si no, el minuto', () {
      // En la primera parte con añadido (47'), se queda al final de la primera.
      final enPrimera = colocar([_gol(47)], fase: FaseReloj.primeraParte);

      expect(enPrimera.single.fraccion, 0.5);

      // Sin reloj, un 47' se toma por segunda parte.
      final sinReloj = colocar([_gol(47)]);

      expect(sinReloj.single.fraccion, closeTo(47 / 90, 1e-9));
    });

    test(
      'arriba el equipo local y abajo el visitante: de local, lo nuestro arriba',
      () {
        final m = colocar([
          _gol(10),
          _golRival(20),
          _tarjeta(30),
          _tarjeta(35, rival: true),
          _cambio(40),
        ]);

        expect(m.map((x) => x.arriba), [true, false, true, false, true]);
      },
    );

    test('de visitante se invierten los lados', () {
      final m = colocar([_gol(10), _golRival(20)], local: false);

      expect(m.map((x) => x.arriba), [false, true]);
    });

    test('los separadores y los hechos sin minuto no se colocan', () {
      final m = colocar([
        _gol(10),
        _descanso,
        const EventoFicha(tipo: EventoFicha.golFavor),
        _final,
      ]);

      expect(m, hasLength(1));
      expect(m.single.evento.tipo, EventoFicha.golFavor);
    });

    test('los muy juntos del mismo lado se reparten en dos filas', () {
      final m = colocar([_gol(10), _gol(11), _gol(12), _gol(60)]);

      expect(m.map((x) => x.fila), [0, 1, 0, 0]);
    });

    test('guarda el índice del evento en la lista de la ficha', () {
      final eventos = _recientesPrimero([_gol(10), _descanso, _gol(60)]);
      final m = colocarMomentos(
        eventos,
        minutosParte: 45,
        mutxamelEsLocal: true,
      );

      // Salen en el orden de la ficha (lo último primero).
      expect(eventos[m.first.indice].minuto, 60);
      expect(eventos[m.last.indice].minuto, 10);
    });
  });

  group('BarraMomentos', () {
    FichaPartido ficha(
      List<EventoFicha> cronologico, {
      int minutosParte = 45,
      RelojDirecto? reloj,
      bool local = true,
    }) => FichaPartido(
      cabecera: CabeceraFicha(
        partidoId: 30,
        equipoLocal: local ? 'Mutxamel CF' : 'Pego C.F.',
        equipoVisitante: local ? 'Pego C.F.' : 'Mutxamel CF',
        estado: reloj == null ? EstadoFicha.finalizado : EstadoFicha.enJuego,
        minutosParte: minutosParte,
        reloj: reloj,
      ),
      eventos: _recientesPrimero(cronologico),
    );

    Future<void> pintar(WidgetTester tester, FichaPartido f) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          Center(
            child: BarraMomentos(
              ficha: f,
              ahora: () => DateTime.fromMillisecondsSinceEpoch(1000000),
            ),
          ),
        ),
      );
    }

    double centroX(WidgetTester tester, int indice) =>
        tester.getCenter(find.byKey(ValueKey('momento-$indice'))).dx;

    testWidgets('sin eventos no se muestra', (tester) async {
      await pintar(tester, ficha([]));

      expect(find.byKey(const ValueKey('barra-momentos')), findsNothing);
    });

    testWidgets('solo con separadores o hechos sin minuto, tampoco', (
      tester,
    ) async {
      await pintar(
        tester,
        ficha([
          _descanso,
          const EventoFicha(tipo: EventoFicha.golFavor),
          _final,
        ]),
      );

      expect(find.byKey(const ValueKey('barra-momentos')), findsNothing);
    });

    testWidgets(
      'marcas en 0, la mitad con "DESC." y el final (2·minutosParte)',
      (tester) async {
        await pintar(tester, ficha([_gol(10)]));

        expect(find.text("0'"), findsOneWidget);
        expect(find.text('DESC.'), findsOneWidget);
        expect(find.text("90'"), findsOneWidget);
      },
    );

    testWidgets('con minutosParte 25 el final es el 50', (tester) async {
      await pintar(tester, ficha([_gol(10)], minutosParte: 25));

      expect(find.text("50'"), findsOneWidget);
    });

    testWidgets('sin minutosParte (backend antiguo) usa 45', (tester) async {
      final cabecera = CabeceraFicha.fromJson({'partidoId': 30});

      expect(cabecera.minutosParte, 45);
      expect(CabeceraFicha.fromJson({'minutosParte': 25}).minutosParte, 25);
      expect(CabeceraFicha.fromJson({'minutosParte': 0}).minutosParte, 45);
    });

    testWidgets(
      'cada hecho está en su minuto y los de arriba y abajo en su lado',
      (tester) async {
        // Cronológico: gol 0' (índice 3 al ir lo último primero), gol rival 45'...
        final f = ficha([_gol(9), _golRival(45), _gol(81)]);

        await pintar(tester, f);

        final barra = tester.getRect(
          find.byKey(const ValueKey('barra-momentos')),
        );
        final eventos = f.eventos;
        final iGol9 = eventos.indexWhere((e) => e.minuto == 9);
        final iRival = eventos.indexWhere((e) => e.minuto == 45);
        final iGol81 = eventos.indexWhere((e) => e.minuto == 81);

        // De izquierda a derecha en el orden del tiempo.
        expect(centroX(tester, iGol9), lessThan(centroX(tester, iRival)));
        expect(centroX(tester, iRival), lessThan(centroX(tester, iGol81)));
        // El 45' está en la mitad de la barra.
        expect(centroX(tester, iRival), closeTo(barra.center.dx, 2));

        // Los nuestros (de local) arriba y el del rival abajo.
        final yGol = tester
            .getCenter(find.byKey(ValueKey('momento-$iGol9')))
            .dy;
        final yRival = tester
            .getCenter(find.byKey(ValueKey('momento-$iRival')))
            .dy;

        expect(yGol, lessThan(yRival));
      },
    );

    testWidgets('el añadido se queda al final de la barra, dentro de ella', (
      tester,
    ) async {
      final f = ficha([_gol(10), _descanso, _gol(97)]);

      await pintar(tester, f);

      final barra = tester.getRect(
        find.byKey(const ValueKey('barra-momentos')),
      );
      final i97 = f.eventos.indexWhere((e) => e.minuto == 97);
      final icono = tester.getRect(find.byKey(ValueKey('momento-$i97')));

      expect(icono.right, lessThanOrEqualTo(barra.right));
    });

    testWidgets(
      'iconos: balón, tarjetas amarilla y roja y flechas del cambio',
      (tester) async {
        await pintar(
          tester,
          ficha([_gol(5), _tarjeta(20), _tarjeta(30, roja: true), _cambio(60)]),
        );

        expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
        expect(find.byType(Tooltip), findsNWidgets(4));
      },
    );

    testWidgets('tocar un icono muestra el globo con el detalle', (
      tester,
    ) async {
      final f = ficha([
        _gol(23),
        _golRival(31, dorsal: 9),
        _tarjeta(40),
        _cambio(67),
      ]);

      await pintar(tester, f);

      Future<void> tocar(int minuto, String texto) async {
        final i = f.eventos.indexWhere((e) => e.minuto == minuto);

        await tester.tap(find.byKey(ValueKey('momento-$i')));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(texto), findsOneWidget);

        // Se cierra al tocar fuera.
        await tester.tapAt(const Offset(5, 5));
        await tester.pump(const Duration(seconds: 4));
      }

      await tocar(23, "23' Pepe");
      await tocar(31, "31' Gol del rival · Dorsal 9");
      await tocar(40, "40' Tarjeta amarilla · Luis");
      await tocar(67, "67' Cambio: entra Juanma, sale Luis");
    });

    testWidgets('en directo, la marca del minuto actual avanza con el reloj', (
      tester,
    ) async {
      var ahora = DateTime.fromMillisecondsSinceEpoch(10 * 60 * 1000);

      // Primera parte empezada en el 0; el servidor y el móvil van a la par.
      final reloj = RelojDirecto(
        fase: FaseReloj.primeraParte,
        inicioParteEpochMs: 0,
        ahoraServidorEpochMs: ahora.millisecondsSinceEpoch,
        recibidoEn: ahora,
      );

      Timer? tic;
      late void Function(Timer) alTic;

      pantalla(tester);
      await tester.pumpWidget(
        appCon(
          Center(
            child: BarraMomentos(
              ficha: ficha([_gol(5)], reloj: reloj),
              ahora: () => ahora,
              crearTemporizador: (intervalo, f) {
                alTic = f;
                return tic = Timer(const Duration(days: 365), () {});
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('marca-minuto-actual')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('marca-minuto-texto')))
            .data,
        '10:00',
      );

      final antes = tester.getCenter(
        find.byKey(const ValueKey('marca-minuto-actual')),
      );

      // Pasan 20 minutos.
      ahora = ahora.add(const Duration(minutes: 20));
      alTic(tic!);
      await tester.pump();

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('marca-minuto-texto')))
            .data,
        '30:00',
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('marca-minuto-actual'))).dx,
        greaterThan(antes.dx),
      );

      tic!.cancel();
    });

    testWidgets(
      'sin reloj (partido terminado) no hay marca del minuto actual',
      (tester) async {
        await pintar(tester, ficha([_gol(5)]));

        expect(find.byKey(const ValueKey('marca-minuto-actual')), findsNothing);
      },
    );

    testWidgets('con letra grande y pantalla pequeña se sigue leyendo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: appCon(
            Center(
              child: BarraMomentos(ficha: ficha([_gol(5), _golRival(60)])),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('barra-momentos')), findsOneWidget);
    });
  });
}
