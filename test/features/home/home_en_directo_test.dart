import 'dart:async';

import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/features/home/home_page.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/news/models/news_model.dart';
import 'package:app_mutxamel_cf/features/news/services/news_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _MatchFalso extends MatchService {
  final List<MatchModel> respuestas;
  int llamadas = 0;
  bool fallar = false;

  _MatchFalso(this.respuestas);

  @override
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async {
    llamadas++;
    if (fallar) throw Exception('sin red');

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

const _proximo = MatchModel(
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'Pego C.F.',
  hora: '17:00',
);

MatchModel _enJuego(int favor, {String fase = 'PRIMERA_PARTE'}) => MatchModel(
  categoria: 'Primer Equipo',
  equipo: 'Primer Equipo',
  rival: 'Pego C.F.',
  enJuego: true,
  fase: fase,
  golesFavor: favor,
  golesContra: 0,
);

const _intervalo = Duration(seconds: 30);

Future<void> _pintar(
  WidgetTester tester,
  _MatchFalso partidos, {
  Stream<void>? avisos,
  ValueNotifier<bool>? visible,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(
        matchService: partidos,
        newsService: _NoticiasFalsas(),
        avisosDeResultados: avisos ?? const Stream<void>.empty(),
        visible: visible,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _quitarPagina(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  testWidgets('en juego: letrero y marcador, y se vuelve a pedir cada 30 segundos', (
    tester,
  ) async {
    final partidos = _MatchFalso([_enJuego(0), _enJuego(1), _enJuego(2)]);

    await _pintar(tester, partidos);

    expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);
    expect(find.text('0 - 0'), findsOneWidget);
    expect(partidos.llamadas, 1);

    await tester.pump(_intervalo);
    await tester.pump();
    await tester.pump();

    expect(partidos.llamadas, 2);
    expect(find.text('1 - 0'), findsOneWidget);

    await tester.pump(_intervalo);
    await tester.pump();
    await tester.pump();

    expect(partidos.llamadas, 3);
    expect(find.text('2 - 0'), findsOneWidget);

    await _quitarPagina(tester);
  });

  testWidgets('la actualización no vuelve a la tarjeta de "cargando"', (
    tester,
  ) async {
    final partidos = _MatchFalso([_enJuego(0), _enJuego(1)]);

    await _pintar(tester, partidos);
    await tester.pump(_intervalo);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);

    await _quitarPagina(tester);
  });

  testWidgets('si una actualización falla se queda lo que ya se veía', (
    tester,
  ) async {
    final partidos = _MatchFalso([_enJuego(1)]);

    await _pintar(tester, partidos);
    partidos.fallar = true;
    await tester.pump(_intervalo);
    await tester.pump();
    await tester.pump();

    expect(find.text('1 - 0'), findsOneWidget);
    expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);

    await _quitarPagina(tester);
  });

  testWidgets('con el descanso se ve "Descanso" y sigue pidiendo', (
    tester,
  ) async {
    final partidos = _MatchFalso([_enJuego(0), _enJuego(1, fase: 'DESCANSO')]);

    await _pintar(tester, partidos);
    await tester.pump(_intervalo);
    await tester.pump();
    await tester.pump();

    expect(find.text('Descanso'), findsOneWidget);

    await tester.pump(_intervalo);
    expect(partidos.llamadas, 3);

    await _quitarPagina(tester);
  });

  testWidgets('sin partido en juego no hay temporizador', (tester) async {
    final partidos = _MatchFalso([_proximo]);

    await _pintar(tester, partidos);
    await tester.pump(const Duration(minutes: 5));

    expect(partidos.llamadas, 1);
    expect(find.text('PARTIDO EN JUEGO'), findsNothing);

    await _quitarPagina(tester);
  });

  testWidgets('al terminar el partido el temporizador se para', (tester) async {
    final partidos = _MatchFalso([
      _enJuego(2),
      const MatchModel(
        categoria: 'Primer Equipo',
        equipo: 'Primer Equipo',
        rival: 'Pego C.F.',
        resultado: '2-0',
        fase: 'FINALIZADO',
        goleadores: ['Pepe (2)'],
      ),
    ]);

    await _pintar(tester, partidos);
    await tester.pump(_intervalo);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Goles'), findsNothing);
    expect(find.text('2-0'), findsOneWidget);
    expect(partidos.llamadas, 2);

    await tester.pump(const Duration(minutes: 5));

    expect(partidos.llamadas, 2);

    await _quitarPagina(tester);
  });

  testWidgets('al salir de la pantalla el temporizador se para', (tester) async {
    final partidos = _MatchFalso([_enJuego(0)]);

    await _pintar(tester, partidos);
    await _quitarPagina(tester);

    final antes = partidos.llamadas;
    await tester.pump(const Duration(minutes: 5));

    expect(partidos.llamadas, antes);
  });

  testWidgets(
    'con la portada oculta no pide, y al volver a verse actualiza al momento',
    (tester) async {
      final partidos = _MatchFalso([_enJuego(0), _enJuego(1)]);
      final visible = ValueNotifier<bool>(true);

      await _pintar(tester, partidos, visible: visible);

      visible.value = false;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(minutes: 5));

      expect(partidos.llamadas, 1);

      visible.value = true;
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(partidos.llamadas, 2);
      expect(find.text('1 - 0'), findsOneWidget);

      await _quitarPagina(tester);
    },
  );

  testWidgets('con la app en segundo plano no pide, y al volver actualiza', (
    tester,
  ) async {
    final partidos = _MatchFalso([_enJuego(0), _enJuego(1)]);

    await _pintar(tester, partidos);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));

    expect(partidos.llamadas, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(partidos.llamadas, 2);

    await _quitarPagina(tester);
  });

  testWidgets(
    'un push del directo refresca la tarjeta al momento, también sin partido en juego',
    (tester) async {
      final avisos = StreamController<void>.broadcast();
      final partidos = _MatchFalso([_proximo, _enJuego(0)]);

      await _pintar(tester, partidos, avisos: avisos.stream);

      expect(find.text('PARTIDO EN JUEGO'), findsNothing);

      avisos.add(null);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(partidos.llamadas, 2);
      expect(find.text('PARTIDO EN JUEGO'), findsOneWidget);

      // Y desde ese momento empieza a pedir cada 30 segundos.
      await tester.pump(_intervalo);
      expect(partidos.llamadas, 3);

      await _quitarPagina(tester);
      await avisos.close();
    },
  );

  test('el servicio de push avisa a la portada con los pushes del directo', () async {
    var avisos = 0;
    final suscripcion = PushNotificationService.avisosDeResultados.listen(
      (_) => avisos++,
    );

    await PushNotificationService.mostrarEnPrimerPlano(
      const RemoteMessage(data: {'tipo': 'RESULTADO'}),
    );
    // El push de un topic anónimo no trae datos.
    await PushNotificationService.mostrarEnPrimerPlano(const RemoteMessage());
    // Una noticia no es del directo.
    await PushNotificationService.mostrarEnPrimerPlano(
      const RemoteMessage(data: {'tipo': 'NOTICIA'}),
    );
    await Future<void>.delayed(Duration.zero);

    expect(avisos, 2);

    await suscripcion.cancel();
  });

  testWidgets(
    'compatibilidad: un backend sin los campos nuevos pinta la tarjeta de siempre',
    (tester) async {
      final partidos = _MatchFalso([
        MatchModel.fromJson({
          'categoria': 'Primer Equipo',
          'equipo': 'Primer Equipo',
          'rival': 'Pego C.F.',
          'resultado': '1-0',
        }),
      ]);

      await _pintar(tester, partidos);
      await tester.pump(const Duration(minutes: 5));

      expect(find.text('1-0'), findsOneWidget);
      expect(partidos.llamadas, 1);

      await _quitarPagina(tester);
    },
  );
}
