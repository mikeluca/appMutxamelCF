import 'dart:async';

import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/reloj_directo.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_cabecera.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_detalle.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/reloj_en_directo.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/models/partido_en_vivo_models.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un temporizador que no corre solo: el test lo dispara a mano y mira si sigue activo.
class _Espia implements Timer {
  final void Function(Timer) alTic;
  bool cancelado = false;

  _Espia(this.alTic);

  void disparar() => alTic(this);

  @override
  void cancel() => cancelado = true;

  @override
  bool get isActive => !cancelado;

  @override
  int get tick => 0;
}

class _Temporizadores {
  final List<_Espia> creados = [];

  Timer crear(Duration intervalo, void Function(Timer) alTic) {
    final espia = _Espia(alTic);
    creados.add(espia);
    return espia;
  }

  int get activos => creados.where((e) => !e.cancelado).length;

  _Espia get ultimo => creados.last;
}

/// Un reloj del backend: el servidor va [servidorPorDelante] por delante del móvil, que recibió la respuesta en
/// [movil], y la parte lleva [enCurso] jugándose.
RelojDirecto _reloj({
  FaseReloj fase = FaseReloj.primeraParte,
  Duration enCurso = const Duration(minutes: 5),
  int minutoBase = 0,
  Duration servidorPorDelante = Duration.zero,
  required DateTime movil,
}) {
  final servidor = movil.add(servidorPorDelante);

  return RelojDirecto(
    fase: fase,
    inicioParteEpochMs: fase == FaseReloj.descanso
        ? null
        : servidor.subtract(enCurso).millisecondsSinceEpoch,
    minutoBase: minutoBase,
    minutosParte: 45,
    ahoraServidorEpochMs: servidor.millisecondsSinceEpoch,
    recibidoEn: movil,
  );
}

Widget _app(Widget hijo, {Locale locale = const Locale('es')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: hijo)),
  );
}

void main() {
  final inicio = DateTime(2026, 11, 16, 12, 0, 0);

  group('RelojDirecto (cálculo)', () {
    test('en la primera parte cuenta desde el inicio de la parte', () {
      final r = _reloj(
        movil: inicio,
        enCurso: const Duration(minutes: 5, seconds: 30),
      );

      expect(r.texto(inicio), '05:30');
      expect(r.texto(inicio.add(const Duration(seconds: 1))), '05:31');
    });

    test('en la segunda parte suma el minutoBase', () {
      final r = _reloj(
        fase: FaseReloj.segundaParte,
        minutoBase: 45,
        enCurso: const Duration(minutes: 3, seconds: 7),
        movil: inicio,
      );

      expect(r.texto(inicio), '48:07');
    });

    test('pasada la duración de la parte sigue contando, sin parar', () {
      final primera = _reloj(
        enCurso: const Duration(minutes: 47, seconds: 13),
        movil: inicio,
      );
      final segunda = _reloj(
        fase: FaseReloj.segundaParte,
        minutoBase: 45,
        enCurso: const Duration(minutes: 2, seconds: 13),
        movil: inicio,
      );

      expect(primera.texto(inicio), '47:13');
      expect(segunda.texto(inicio), '47:13');
      expect(segunda.texto(inicio.add(const Duration(minutes: 60))), '107:13');
    });

    test(
      'corrige el desfase de un móvil atrasado: el reloj es el del servidor',
      () {
        // El móvil va 2 minutos atrasado respecto al servidor y la parte lleva 10 minutos.
        final r = _reloj(
          movil: inicio,
          servidorPorDelante: const Duration(minutes: 2),
          enCurso: const Duration(minutes: 10),
        );

        expect(r.desfase, const Duration(minutes: 2));
        expect(r.texto(inicio), '10:00');
        expect(r.texto(inicio.add(const Duration(seconds: 30))), '10:30');
      },
    );

    test('corrige el desfase de un móvil adelantado', () {
      final r = _reloj(
        movil: inicio,
        servidorPorDelante: const Duration(minutes: -3),
        enCurso: const Duration(minutes: 10),
      );

      expect(r.texto(inicio), '10:00');
    });

    test('nunca baja del minutoBase aunque el inicio salga en el futuro', () {
      final r = _reloj(
        fase: FaseReloj.segundaParte,
        minutoBase: 45,
        enCurso: const Duration(seconds: -5),
        movil: inicio,
      );

      expect(r.texto(inicio), '45:00');
    });

    test('en el descanso no hay tiempo', () {
      final r = _reloj(fase: FaseReloj.descanso, minutoBase: 45, movil: inicio);

      expect(r.enDescanso, isTrue);
      expect(r.tiempo(inicio), isNull);
      expect(r.texto(inicio), isNull);
    });

    test(
      'desdeJson lee el objeto y devuelve null sin él o si no se entiende',
      () {
        final r = RelojDirecto.desdeJson({
          'fase': 'SEGUNDA_PARTE',
          'inicioParteEpochMs': 1000,
          'minutoBase': 45,
          'minutosParte': 45,
          'ahoraServidorEpochMs': 61000,
        }, recibidoEn: inicio)!;

        expect(r.fase, FaseReloj.segundaParte);
        expect(r.minutoBase, 45);
        expect(r.recibidoEn, inicio);

        final descanso = RelojDirecto.desdeJson({
          'fase': 'DESCANSO',
          'inicioParteEpochMs': null,
          'minutoBase': 45,
          'minutosParte': 45,
          'ahoraServidorEpochMs': 61000,
        })!;
        expect(descanso.enDescanso, isTrue);

        expect(RelojDirecto.desdeJson(null), isNull);
        expect(RelojDirecto.desdeJson({'fase': 'FINAL'}), isNull);
        expect(
          RelojDirecto.desdeJson({
            'fase': 'PRIMERA_PARTE',
            'ahoraServidorEpochMs': 1,
          }),
          isNull,
        );
      },
    );

    test('los modelos leen "reloj" y, sin él, todo queda como antes', () {
      final json = {
        'fase': 'PRIMERA_PARTE',
        'inicioParteEpochMs': 1000,
        'minutoBase': 0,
        'minutosParte': 45,
        'ahoraServidorEpochMs': 5000,
      };

      expect(CabeceraFicha.fromJson({'reloj': json}).reloj, isNotNull);
      expect(CabeceraFicha.fromJson({'estado': 'EN_JUEGO'}).reloj, isNull);
      expect(
        EstadoPartidoEnVivo.fromJson({'partidoId': 1, 'reloj': json}).reloj,
        isNotNull,
      );
      expect(EstadoPartidoEnVivo.fromJson({'partidoId': 1}).reloj, isNull);
      expect(
        MatchModel.fromJson({
          'categoria': 'c',
          'equipo': 'e',
          'rival': 'r',
          'reloj': json,
        }).reloj,
        isNotNull,
      );
      expect(
        MatchModel.fromJson({
          'categoria': 'c',
          'equipo': 'e',
          'rival': 'r',
        }).reloj,
        isNull,
      );
    });
  });

  group('RelojEnDirecto (widget y temporizador)', () {
    testWidgets(
      'pinta MM:ss con el punto parpadeante y se repinta cada segundo',
      (tester) async {
        var movil = inicio;
        final temporizadores = _Temporizadores();

        await tester.pumpWidget(
          _app(
            RelojEnDirecto(
              reloj: _reloj(movil: inicio),
              ahora: () => movil,
              crearTemporizador: temporizadores.crear,
            ),
          ),
        );

        expect(find.text('05:00'), findsOneWidget);
        expect(find.byKey(const ValueKey('punto-en-directo')), findsOneWidget);
        expect(temporizadores.activos, 1);

        movil = movil.add(const Duration(seconds: 1));
        temporizadores.ultimo.disparar();
        await tester.pump();

        expect(find.text('05:01'), findsOneWidget);

        // Se quita la pantalla: el temporizador se cancela.
        await tester.pumpWidget(const SizedBox());
        expect(temporizadores.activos, 0);
      },
    );

    testWidgets(
      'el temporizador no pide nada: solo repinta (la hora sale de los datos)',
      (tester) async {
        var movil = inicio;
        final temporizadores = _Temporizadores();

        await tester.pumpWidget(
          _app(
            RelojEnDirecto(
              reloj: _reloj(
                movil: inicio,
                servidorPorDelante: const Duration(minutes: 2),
                enCurso: const Duration(minutes: 10),
              ),
              ahora: () => movil,
              crearTemporizador: temporizadores.crear,
            ),
          ),
        );

        // Con el móvil 2 minutos atrasado sigue saliendo el tiempo del servidor.
        expect(find.text('10:00'), findsOneWidget);
        movil = movil.add(const Duration(seconds: 42));
        temporizadores.ultimo.disparar();
        await tester.pump();
        expect(find.text('10:42'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'en el descanso pone "Descanso" ("Descans", "Half-time") y no hay temporizador',
      (tester) async {
        for (final (locale, texto) in [
          (const Locale('es'), 'Descanso'),
          (const Locale('ca'), 'Descans'),
          (const Locale('en'), 'Half-time'),
        ]) {
          final temporizadores = _Temporizadores();

          await tester.pumpWidget(
            _app(
              RelojEnDirecto(
                reloj: _reloj(
                  fase: FaseReloj.descanso,
                  minutoBase: 45,
                  movil: inicio,
                ),
                ahora: () => inicio,
                crearTemporizador: temporizadores.crear,
              ),
              locale: locale,
            ),
          );

          expect(find.text(texto), findsOneWidget);
          expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);
          expect(find.byKey(const ValueKey('punto-en-directo')), findsNothing);
          expect(temporizadores.creados, isEmpty);
        }
      },
    );

    testWidgets(
      'pasa del reloj al descanso (y vuelta) con los datos nuevos, parando y arrancando el temporizador',
      (tester) async {
        final temporizadores = _Temporizadores();
        final movil = inicio;

        Widget con(RelojDirecto reloj) => _app(
          RelojEnDirecto(
            reloj: reloj,
            ahora: () => movil,
            crearTemporizador: temporizadores.crear,
          ),
        );

        await tester.pumpWidget(con(_reloj(movil: inicio)));
        expect(temporizadores.activos, 1);

        await tester.pumpWidget(
          con(_reloj(fase: FaseReloj.descanso, minutoBase: 45, movil: inicio)),
        );
        expect(temporizadores.activos, 0);
        expect(find.text('Descanso'), findsOneWidget);

        await tester.pumpWidget(
          con(
            _reloj(
              fase: FaseReloj.segundaParte,
              minutoBase: 45,
              enCurso: const Duration(seconds: 3),
              movil: inicio,
            ),
          ),
        );
        expect(temporizadores.activos, 1);
        expect(find.text('45:03'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        expect(temporizadores.activos, 0);
      },
    );

    testWidgets(
      'con la app en segundo plano se para y al volver se recalcula sin acumular error',
      (tester) async {
        var movil = inicio;
        final temporizadores = _Temporizadores();

        await tester.pumpWidget(
          _app(
            RelojEnDirecto(
              reloj: _reloj(movil: inicio),
              ahora: () => movil,
              crearTemporizador: temporizadores.crear,
            ),
          ),
        );
        expect(temporizadores.activos, 1);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(temporizadores.activos, 0);

        // Pasan 10 minutos con la app dormida (los ticks no corren).
        movil = movil.add(const Duration(minutes: 10));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        expect(temporizadores.activos, 1);
        expect(find.text('15:00'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        expect(temporizadores.activos, 0);
      },
    );

    testWidgets(
      'con la pantalla tapada por otra (ticks desactivados) no corre',
      (tester) async {
        final temporizadores = _Temporizadores();

        await tester.pumpWidget(
          _app(
            TickerMode(
              enabled: false,
              child: RelojEnDirecto(
                reloj: _reloj(movil: inicio),
                ahora: () => inicio,
                crearTemporizador: temporizadores.crear,
              ),
            ),
          ),
        );

        expect(temporizadores.creados, isEmpty);

        await tester.pumpWidget(
          _app(
            TickerMode(
              enabled: true,
              child: RelojEnDirecto(
                reloj: _reloj(movil: inicio),
                ahora: () => inicio,
                crearTemporizador: temporizadores.crear,
              ),
            ),
          ),
        );

        expect(temporizadores.activos, 1);

        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('cabecera de la ficha', () {
    CabeceraFicha cabecera({
      EstadoFicha estado = EstadoFicha.enJuego,
      RelojDirecto? reloj,
    }) => CabeceraFicha(
      partidoId: 30,
      equipoLocal: 'Mutxamel CF',
      equipoVisitante: 'Pego C.F.',
      dia: DateTime(2026, 11, 16),
      hora: '12:00',
      golesFavor: 1,
      golesContra: 0,
      estado: estado,
      competicion: 'Liga',
      reloj: reloj,
    );

    testWidgets(
      'con reloj muestra MM:ss con el punto en lugar de "En directo"',
      (tester) async {
        final temporizadores = _Temporizadores();

        await tester.pumpWidget(
          _app(
            FichaCabecera(
              cabecera: cabecera(
                reloj: _reloj(
                  movil: inicio,
                  enCurso: const Duration(minutes: 12, seconds: 5),
                ),
              ),
              ahora: () => inicio,
              crearTemporizador: temporizadores.crear,
            ),
          ),
        );

        expect(find.text('12:05'), findsOneWidget);
        expect(find.text('En directo'), findsNothing);
        expect(find.byKey(const ValueKey('punto-en-directo')), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        expect(temporizadores.activos, 0);
      },
    );

    testWidgets('sin reloj (backend antiguo) sale "En directo" como siempre', (
      tester,
    ) async {
      await tester.pumpWidget(_app(FichaCabecera(cabecera: cabecera())));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('En directo'), findsOneWidget);
      expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('en el descanso sale "Descanso", sin reloj', (tester) async {
      final temporizadores = _Temporizadores();

      await tester.pumpWidget(
        _app(
          FichaCabecera(
            cabecera: cabecera(
              estado: EstadoFicha.descanso,
              reloj: _reloj(
                fase: FaseReloj.descanso,
                minutoBase: 45,
                movil: inicio,
              ),
            ),
            ahora: () => inicio,
            crearTemporizador: temporizadores.crear,
          ),
        ),
      );

      expect(find.text('Descanso'), findsOneWidget);
      expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);
      expect(temporizadores.creados, isEmpty);
    });

    testWidgets('finalizado, sin reloj: "Finalizado"', (tester) async {
      await tester.pumpWidget(
        _app(FichaCabecera(cabecera: cabecera(estado: EstadoFicha.finalizado))),
      );

      expect(find.text('Finalizado'), findsOneWidget);
      expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);
    });
  });

  group('tarjeta de la portada', () {
    MatchModel partido({RelojDirecto? reloj, String fase = 'PRIMERA_PARTE'}) =>
        MatchModel(
          id: 30,
          categoria: 'Primer Equipo',
          equipo: 'Mutxamel CF',
          rival: 'Pego C.F.',
          enJuego: true,
          fase: fase,
          golesFavor: 1,
          golesContra: 0,
          reloj: reloj,
        );

    testWidgets('en juego con reloj: MM:ss con el punto, junto al marcador', (
      tester,
    ) async {
      final temporizadores = _Temporizadores();

      await tester.pumpWidget(
        _app(
          MatchCard(
            match: partido(
              reloj: _reloj(
                movil: inicio,
                enCurso: const Duration(minutes: 33, seconds: 9),
              ),
            ),
            ahora: () => inicio,
            crearTemporizador: temporizadores.crear,
          ),
        ),
      );

      expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);
      expect(find.byKey(const ValueKey('marcador-en-directo')), findsOneWidget);
      expect(find.text('33:09'), findsOneWidget);
      expect(find.byKey(const ValueKey('punto-en-directo')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(temporizadores.activos, 0);
    });

    testWidgets('en el descanso "Descanso" (el de siempre) y sin reloj', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MatchCard(
            match: partido(
              fase: 'DESCANSO',
              reloj: _reloj(
                fase: FaseReloj.descanso,
                minutoBase: 45,
                movil: inicio,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('descanso')), findsOneWidget);
      expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);
    });

    testWidgets('sin reloj se ve como ahora', (tester) async {
      await tester.pumpWidget(_app(MatchCard(match: partido())));

      expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);
      expect(find.byKey(const ValueKey('reloj-en-directo')), findsNothing);
      expect(find.byKey(const ValueKey('punto-en-directo')), findsNothing);
    });
  });

  group('detalle de la ficha con eventos del rival', () {
    FichaPartido ficha(List<EventoFicha> eventos, {bool local = true}) =>
        FichaPartido(
          cabecera: CabeceraFicha(
            partidoId: 30,
            equipoLocal: local ? 'Mutxamel CF' : 'Pego C.F.',
            equipoVisitante: local ? 'Pego C.F.' : 'Mutxamel CF',
            estado: EstadoFicha.enJuego,
          ),
          eventos: eventos,
        );

    /// ¿La fila de [texto] está a la izquierda o a la derecha del centro?
    bool aLaIzquierda(WidgetTester tester, Finder texto) {
      final centro = tester.getCenter(find.byType(FichaDetalle)).dx;

      return tester.getCenter(texto).dx < centro;
    }

    testWidgets(
      'la tarjeta del rival y su gol van en el lado del rival, con "Dorsal 9"',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(
            SizedBox(
              height: 800,
              child: FichaDetalle(
                ficha: ficha(const [
                  EventoFicha(
                    tipo: 'TARJETA_AMARILLA',
                    minuto: 40,
                    jugador: 'Pablo',
                  ),
                  EventoFicha(
                    tipo: 'TARJETA_AMARILLA',
                    minuto: 30,
                    jugador: 'Dorsal 9',
                    rival: true,
                    dorsalRival: 9,
                  ),
                  EventoFicha(
                    tipo: 'GOL_CONTRA',
                    minuto: 20,
                    golesFavor: 0,
                    golesContra: 1,
                    dorsalRival: 7,
                  ),
                  EventoFicha(
                    tipo: 'GOL_CONTRA',
                    minuto: 10,
                    golesFavor: 0,
                    golesContra: 1,
                  ),
                ]),
              ),
            ),
          ),
        );

        // Mutxamel local: lo nuestro a la izquierda, lo del rival a la derecha.
        expect(aLaIzquierda(tester, find.text('Pablo')), isTrue);
        expect(find.text('Dorsal 9'), findsOneWidget);
        expect(aLaIzquierda(tester, find.text('Dorsal 9')), isFalse);
        // El gol del rival con dorsal dice "Dorsal 7"; sin dorsal, como siempre.
        expect(find.text('Dorsal 7'), findsOneWidget);
        expect(aLaIzquierda(tester, find.text('Dorsal 7')), isFalse);
        expect(find.text('Gol del rival'), findsOneWidget);
      },
    );

    testWidgets(
      'sin dorsal la tarjeta del rival no lleva texto (ni el "Rival" que el backend manda a la app antigua)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(
            SizedBox(
              height: 800,
              child: FichaDetalle(
                ficha: ficha(const [
                  EventoFicha(
                    tipo: 'TARJETA_ROJA',
                    minuto: 50,
                    jugador: 'Rival',
                    rival: true,
                  ),
                ]),
              ),
            ),
          ),
        );

        expect(find.text('Rival'), findsNothing);
        expect(find.byKey(const ValueKey('tarjeta-rival')), findsOneWidget);
        expect(
          aLaIzquierda(tester, find.byKey(const ValueKey('tarjeta-rival'))),
          isFalse,
        );
      },
    );

    testWidgets('si el Mutxamel es visitante el rival queda a la izquierda', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 800,
            child: FichaDetalle(
              ficha: ficha(const [
                EventoFicha(
                  tipo: 'TARJETA_AMARILLA',
                  minuto: 30,
                  rival: true,
                  dorsalRival: 4,
                ),
              ], local: false),
            ),
          ),
        ),
      );

      expect(aLaIzquierda(tester, find.text('Dorsal 4')), isTrue);
    });

    testWidgets(
      'la doble amarilla del rival se pinta como la nuestra: roja con la segunda amarilla',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(
            SizedBox(
              height: 800,
              child: FichaDetalle(
                ficha: ficha(const [
                  EventoFicha(
                    tipo: 'TARJETA_ROJA',
                    minuto: 60,
                    rival: true,
                    dorsalRival: 9,
                    dobleAmarilla: true,
                  ),
                  EventoFicha(
                    tipo: 'TARJETA_ROJA',
                    minuto: 70,
                    jugador: 'Pablo',
                    dobleAmarilla: true,
                  ),
                ]),
              ),
            ),
          ),
        );

        expect(find.text('Dorsal 9'), findsOneWidget);
        // La nota de la segunda amarilla sale en la del rival y en la nuestra.
        expect(find.text('Doble amarilla'), findsNWidgets(2));
      },
    );

    test(
      'el modelo lee rival y dorsalRival y, sin ellos, todo es nuestro como antes',
      () {
        final rival = EventoFicha.fromJson({
          'tipo': 'TARJETA_AMARILLA',
          'rival': true,
          'dorsalRival': 9,
          'jugador': 'Dorsal 9',
        });
        final antiguo = EventoFicha.fromJson({
          'tipo': 'TARJETA_AMARILLA',
          'jugador': 'Pablo',
        });
        final golContra = EventoFicha.fromJson({
          'tipo': 'GOL_CONTRA',
          'dorsalRival': 7,
        });

        expect(rival.rival, isTrue);
        expect(rival.dorsalRival, 9);
        expect(rival.esNuestro, isFalse);
        expect(antiguo.rival, isFalse);
        expect(antiguo.dorsalRival, isNull);
        expect(antiguo.esNuestro, isTrue);
        expect(golContra.esNuestro, isFalse);
        expect(golContra.dorsalRival, 7);
      },
    );
  });
}
