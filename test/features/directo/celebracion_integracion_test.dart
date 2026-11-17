import 'dart:async';

import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/services/ficha_partido_service.dart';
import 'package:app_mutxamel_cf/features/home/home_page.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/news/models/news_model.dart';
import 'package:app_mutxamel_cf/features/news/services/news_services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _celebracion = ValueKey('celebracion-gol');
const _avisoRival = ValueKey('aviso-gol-rival');
const _destelloVerde = ValueKey('destello-verde');
const _destelloRojo = ValueKey('destello-rojo');

// ---------------------------------------------------------------------------------------------------------------
// La ficha
// ---------------------------------------------------------------------------------------------------------------

class _FichaFalsa extends FichaPartidoService {
  FichaPartido ficha;
  int llamadas = 0;

  _FichaFalsa(this.ficha);

  @override
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) async {
    llamadas++;

    return ficha;
  }
}

FichaPartido _ficha(
  int favor,
  int contra, {
  List<EventoFicha> eventos = const [],
  EstadoFicha estado = EstadoFicha.enJuego,
}) => FichaPartido(
  cabecera: CabeceraFicha(
    partidoId: 30,
    equipoLocal: 'Mutxamel CF',
    equipoVisitante: 'Pego C.F.',
    dia: DateTime(2026, 11, 14),
    hora: '18:00',
    golesFavor: favor,
    golesContra: contra,
    estado: estado,
    competicion: 'Liga',
  ),
  eventos: eventos,
);

EventoFicha _gol(String jugador, int minuto) => EventoFicha(
  tipo: EventoFicha.golFavor,
  minuto: minuto,
  jugador: jugador,
  golesFavor: 1,
  golesContra: 0,
);

Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<_FichaFalsa> _abrirFicha(
  WidgetTester tester,
  FichaPartido inicial, {
  required StreamController<void> avisos,
  bool reducir = false,
}) async {
  pantalla(tester);
  final servicio = _FichaFalsa(inicial);

  await tester.pumpWidget(
    appCon(
      FichaPartidoPage(
        partidoId: 30,
        service: servicio,
        avisosDeResultados: avisos.stream,
      ),
      reducirAnimaciones: reducir,
    ),
  );
  await _asentar(tester);

  return servicio;
}

void main() {
  group('la ficha', () {
    testWidgets(
      'al abrirla no celebra aunque ya haya goles; al llegar el push y subir el marcador, "¡GOOOL!" con el goleador y el marcador late en verde',
      (tester) async {
        final vibraciones = anotarVibraciones(tester);
        final avisos = StreamController<void>.broadcast();
        addTearDown(avisos.close);

        final servicio = await _abrirFicha(
          tester,
          _ficha(1, 0, eventos: [_gol('Pepe', 12)]),
          avisos: avisos,
        );

        expect(find.byKey(_celebracion), findsNothing);
        expect(find.byKey(_destelloVerde), findsNothing);
        expect(vibraciones, isEmpty);

        // Llega el push del directo y la ficha ya trae el 2-0 con el goleador Juanma.
        servicio.ficha = _ficha(
          2,
          0,
          eventos: [_gol('Juanma', 30), _gol('Pepe', 12)],
        );
        avisos.add(null);
        await _asentar(tester);

        expect(find.byKey(_celebracion), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('celebracion-marcador')))
              .data,
          '2-0',
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('celebracion-goleador')))
              .data,
          'Juanma',
        );
        expect(vibraciones, ['HapticFeedbackType.heavyImpact']);

        // Y el marcador de la cabecera late con destello verde.
        expect(find.byKey(_destelloVerde), findsOneWidget);

        // Tocarla la cierra.
        await tester.tap(find.byKey(_celebracion));
        await tester.pump();
        expect(find.byKey(_celebracion), findsNothing);

        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets('gol del rival: aviso discreto con su dorsal y destello rojo', (
      tester,
    ) async {
      final vibraciones = anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      final servicio = await _abrirFicha(tester, _ficha(1, 0), avisos: avisos);

      servicio.ficha = _ficha(
        1,
        1,
        eventos: [
          const EventoFicha(
            tipo: EventoFicha.golContra,
            minuto: 40,
            golesFavor: 1,
            golesContra: 1,
            dorsalRival: 9,
          ),
        ],
      );
      avisos.add(null);
      await _asentar(tester);

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(_avisoRival), findsOneWidget);
      expect(find.text('Gol del rival · 1-1 · Dorsal 9'), findsOneWidget);
      expect(find.byKey(_destelloRojo), findsOneWidget);
      expect(vibraciones, ['HapticFeedbackType.lightImpact']);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('si el marcador baja (gol anulado) solo se actualiza, sin destello', (
      tester,
    ) async {
      final vibraciones = anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      final servicio = await _abrirFicha(tester, _ficha(2, 0), avisos: avisos);

      servicio.ficha = _ficha(1, 0);
      avisos.add(null);
      await _asentar(tester);

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(_avisoRival), findsNothing);
      expect(find.byKey(_destelloVerde), findsNothing);
      expect(find.byKey(_destelloRojo), findsNothing);
      expect(vibraciones, isEmpty);
    });

    testWidgets('con pull to refresh también se celebra', (tester) async {
      anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      final servicio = await _abrirFicha(tester, _ficha(0, 0), avisos: avisos);

      servicio.ficha = _ficha(1, 0, eventos: [_gol('Pepe', 3)]);

      await tester.fling(
        find.byKey(const ValueKey('ficha-sin-eventos')).evaluate().isEmpty
            ? find.byType(ListView).first
            : find.byKey(const ValueKey('ficha-sin-eventos')),
        const Offset(0, 400),
        1000,
      );
      await _asentar(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(_celebracion), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('con la animación reducida: aviso y vibración, sin pantalla completa ni destello', (
      tester,
    ) async {
      final vibraciones = anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      final servicio = await _abrirFicha(
        tester,
        _ficha(0, 0),
        avisos: avisos,
        reducir: true,
      );

      servicio.ficha = _ficha(1, 0, eventos: [_gol('Pepe', 3)]);
      avisos.add(null);
      await _asentar(tester);

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(const ValueKey('aviso-gol-nuestro')), findsOneWidget);
      expect(find.byKey(_destelloVerde), findsNothing);
      expect(vibraciones, ['HapticFeedbackType.heavyImpact']);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('si se abre la ficha de un partido ya terminado no celebra nada', (
      tester,
    ) async {
      final vibraciones = anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      await _abrirFicha(
        tester,
        _ficha(3, 1, estado: EstadoFicha.finalizado),
        avisos: avisos,
      );

      expect(find.byKey(_celebracion), findsNothing);
      expect(vibraciones, isEmpty);
    });
  });

  // -------------------------------------------------------------------------------------------------------------
  // La portada
  // -------------------------------------------------------------------------------------------------------------

  group('la portada', () {
    MatchModel enJuego(int favor, int contra, {int id = 30}) => MatchModel(
      id: id,
      categoria: 'Primer Equipo',
      equipo: 'Primer Equipo',
      rival: 'Pego C.F.',
      enJuego: true,
      fase: 'PRIMERA_PARTE',
      golesFavor: favor,
      golesContra: contra,
    );

    Future<_MatchFalso> abrir(
      WidgetTester tester,
      List<MatchModel> respuestas, {
      required StreamController<void> avisos,
    }) async {
      pantalla(tester);
      // La portada necesita más ancho que el de un móvil pequeño (como en sus otros tests).
      tester.view.physicalSize = const Size(800, 1400);
      final partidos = _MatchFalso(respuestas);

      await tester.pumpWidget(
        appCon(
          HomePage(
            matchService: partidos,
            newsService: _NoticiasFalsas(),
            avisosDeResultados: avisos.stream,
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      return partidos;
    }

    testWidgets('al abrirla no celebra; con el push y el marcador arriba, sí, y la tarjeta late', (
      tester,
    ) async {
      final vibraciones = anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      await abrir(tester, [enJuego(0, 0), enJuego(1, 0)], avisos: avisos);

      expect(find.byKey(_celebracion), findsNothing);
      expect(vibraciones, isEmpty);

      avisos.add(null);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(_celebracion), findsOneWidget);
      // En la portada no se conoce el goleador.
      expect(find.byKey(const ValueKey('celebracion-goleador')), findsNothing);
      expect(vibraciones, ['HapticFeedbackType.heavyImpact']);
      expect(find.byKey(_destelloVerde), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('gol del rival en la portada: aviso discreto y destello rojo', (
      tester,
    ) async {
      final vibraciones = anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      await abrir(tester, [enJuego(1, 0), enJuego(1, 1)], avisos: avisos);

      avisos.add(null);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(_celebracion), findsNothing);
      expect(find.byKey(_avisoRival), findsOneWidget);
      expect(find.byKey(_destelloRojo), findsOneWidget);
      expect(vibraciones, ['HapticFeedbackType.lightImpact']);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('si pasa a otro partido, su marcador no se celebra', (
      tester,
    ) async {
      final vibraciones = anotarVibraciones(tester);
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      await abrir(
        tester,
        [enJuego(0, 0), enJuego(3, 2, id: 31)],
        avisos: avisos,
      );

      avisos.add(null);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(_celebracion), findsNothing);
      expect(vibraciones, isEmpty);
    });
  });
}

class _MatchFalso extends MatchService {
  final List<MatchModel> respuestas;
  int llamadas = 0;

  _MatchFalso(this.respuestas);

  @override
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async {
    llamadas++;

    return respuestas[(llamadas - 1).clamp(0, respuestas.length - 1)];
  }
}

class _NoticiasFalsas extends NewsService {
  @override
  Future<List<NewsModel>> obtenerNoticias({
    int? antesId,
    int limite = 5,
  }) async => const [];
}
