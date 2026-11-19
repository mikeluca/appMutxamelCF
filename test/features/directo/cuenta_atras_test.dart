import 'dart:async';

import 'package:app_mutxamel_cf/features/directo/models/cuenta_atras.dart';
import 'package:app_mutxamel_cf/features/directo/widgets/cuenta_atras_texto.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// El inicio de un partido, en UTC, para 2026-11-14 a las 18:00 de Madrid (CET: UTC+1).
final DateTime _inicio = DateTime.utc(2026, 11, 14, 17);

CuentaAtras _falta(Duration d) =>
    CuentaAtras.calcular(_inicio, _inicio.subtract(d));

void main() {
  group('HoraMadrid', () {
    test('en invierno Madrid va una hora por delante de UTC', () {
      expect(
        HoraMadrid.instante(DateTime(2026, 11, 14), '18:00'),
        DateTime.utc(2026, 11, 14, 17),
      );
    });

    test('en verano, dos horas', () {
      expect(
        HoraMadrid.instante(DateTime(2026, 7, 4), '18:00'),
        DateTime.utc(2026, 7, 4, 16),
      );
    });

    test('el cambio de hora: último domingo de marzo y de octubre', () {
      // 2026: el 29 de marzo y el 25 de octubre.
      expect(
        HoraMadrid.instante(DateTime(2026, 3, 28), '12:00'),
        DateTime.utc(2026, 3, 28, 11),
      );
      expect(
        HoraMadrid.instante(DateTime(2026, 3, 29), '12:00'),
        DateTime.utc(2026, 3, 29, 10),
      );
      expect(
        HoraMadrid.instante(DateTime(2026, 10, 24), '12:00'),
        DateTime.utc(2026, 10, 24, 10),
      );
      expect(
        HoraMadrid.instante(DateTime(2026, 10, 25), '12:00'),
        DateTime.utc(2026, 10, 25, 11),
      );
    });

    test('la hora con espacios y sin hora o con basura no cuenta', () {
      expect(
        HoraMadrid.instante(DateTime(2026, 11, 14), '18:30 '),
        DateTime.utc(2026, 11, 14, 17, 30),
      );
      expect(HoraMadrid.instante(DateTime(2026, 11, 14), null), isNull);
      expect(HoraMadrid.instante(DateTime(2026, 11, 14), ''), isNull);
      expect(HoraMadrid.instante(DateTime(2026, 11, 14), 'tarde'), isNull);
      expect(HoraMadrid.instante(DateTime(2026, 11, 14), '25:00'), isNull);
      expect(HoraMadrid.instante(null, '18:00'), isNull);
    });
  });

  group('CuentaAtras.calcular', () {
    test('días y horas', () {
      final c = _falta(const Duration(days: 2, hours: 4, minutes: 30));

      expect(c.fase, FaseCuentaAtras.dias);
      expect((c.dias, c.horas), (2, 4));
    });

    test('un día justo', () {
      final c = _falta(const Duration(days: 1));

      expect(c.fase, FaseCuentaAtras.dias);
      expect((c.dias, c.horas), (1, 0));
    });

    test('horas y minutos', () {
      final c = _falta(const Duration(hours: 3, minutes: 15, seconds: 40));

      expect(c.fase, FaseCuentaAtras.horas);
      expect((c.horas, c.minutos), (3, 15));
    });

    test('menos de una hora: minutos', () {
      final c = _falta(const Duration(minutes: 45, seconds: 10));

      expect(c.fase, FaseCuentaAtras.minutos);
      expect(c.minutos, 45);
    });

    test('desde 30 min antes: calentando', () {
      expect(
        _falta(const Duration(minutes: 30)).fase,
        FaseCuentaAtras.calentando,
      );
      expect(
        _falta(const Duration(minutes: 12)).fase,
        FaseCuentaAtras.calentando,
      );
      expect(
        _falta(const Duration(minutes: 30, seconds: 1)).fase,
        FaseCuentaAtras.minutos,
      );
      expect(
        _falta(const Duration(seconds: 1)).fase,
        FaseCuentaAtras.calentando,
      );
    });

    test('ya pasó la hora: a punto de empezar, nunca negativo', () {
      expect(_falta(Duration.zero).fase, FaseCuentaAtras.aPuntoDeEmpezar);
      expect(
        _falta(const Duration(minutes: -10)).fase,
        FaseCuentaAtras.aPuntoDeEmpezar,
      );
      expect(
        _falta(const Duration(days: -3)).fase,
        FaseCuentaAtras.aPuntoDeEmpezar,
      );
    });
  });

  group('CuentaAtrasTexto', () {
    /// El reloj del móvil: se puede mover.
    DateTime ahora = DateTime.utc(2026, 11, 12, 13);

    Widget cuenta({
      String? hora = '18:00',
      Locale locale = const Locale('es'),
      CrearTemporizadorCuentaAtras? temporizador,
      GlobalKey<NavigatorState>? navegador,
    }) => appCon(
      Center(
        child: CuentaAtrasTexto(
          dia: DateTime(2026, 11, 14),
          hora: hora,
          ahora: () => ahora,
          crearTemporizador: temporizador,
        ),
      ),
      locale: locale,
      navegador: navegador,
    );

    String texto(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const ValueKey('cuenta-atras'))).data!;

    testWidgets('"Empieza en 2 d 4 h"', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 12, 13); // faltan 2 d 4 h

      await tester.pumpWidget(cuenta());

      expect(texto(tester), 'Empieza en 2 d 4 h');
    });

    testWidgets('"Empieza en 3 h 15 min"', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 14, 13, 45);

      await tester.pumpWidget(cuenta());

      expect(texto(tester), 'Empieza en 3 h 15 min');
    });

    testWidgets('"Empieza en 45 min", en catalán y en inglés', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 14, 16, 15);

      await tester.pumpWidget(cuenta());
      expect(texto(tester), 'Empieza en 45 min');

      await tester.pumpWidget(cuenta(locale: const Locale('ca')));
      expect(texto(tester), 'Comença en 45 min');

      await tester.pumpWidget(cuenta(locale: const Locale('en')));
      expect(texto(tester), 'Starts in 45 min');
    });

    testWidgets('desde 30 min antes: "Calentando…"', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 14, 16, 40);

      await tester.pumpWidget(cuenta());

      expect(texto(tester), 'Calentando…');
    });

    testWidgets('pasada la hora sin inicio: "A punto de empezar"', (
      tester,
    ) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 14, 17, 20);

      await tester.pumpWidget(cuenta());

      expect(texto(tester), 'A punto de empezar');
      expect(texto(tester).contains('-'), isFalse);
    });

    testWidgets('sin hora no pinta nada (solo el día, como antes)', (
      tester,
    ) async {
      pantalla(tester);

      await tester.pumpWidget(cuenta(hora: null));

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(CuentaAtrasTexto.aplica(DateTime(2026, 11, 14), null), isFalse);
      expect(CuentaAtrasTexto.aplica(DateTime(2026, 11, 14), '18:00'), isTrue);
    });

    testWidgets(
      'se repinta cada minuto y el temporizador se para al llegar a "A punto de empezar"',
      (tester) async {
        pantalla(tester);
        ahora = DateTime.utc(2026, 11, 14, 16, 10);
        final temporizadores = <_TemporizadorFalso>[];

        await tester.pumpWidget(
          cuenta(
            temporizador: (intervalo, alTic) {
              final t = _TemporizadorFalso(intervalo, alTic);
              temporizadores.add(t);
              return t;
            },
          ),
        );

        expect(temporizadores, hasLength(1));
        expect(temporizadores.single.intervalo, const Duration(minutes: 1));
        expect(texto(tester), 'Empieza en 50 min');
      },
    );

    testWidgets('cada tic recalcula con la hora de ahora', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 14, 15, 59);
      late _TemporizadorFalso temporizador;

      await tester.pumpWidget(
        cuenta(
          temporizador: (intervalo, alTic) =>
              temporizador = _TemporizadorFalso(intervalo, alTic),
        ),
      );
      expect(texto(tester), 'Empieza en 1 h 1 min');

      ahora = DateTime.utc(2026, 11, 14, 16, 10);
      temporizador.tic();
      await tester.pump();
      expect(texto(tester), 'Empieza en 50 min');

      ahora = DateTime.utc(2026, 11, 14, 16, 45);
      temporizador.tic();
      await tester.pump();
      expect(texto(tester), 'Calentando…');

      ahora = DateTime.utc(2026, 11, 14, 17, 1);
      temporizador.tic();
      await tester.pump();
      expect(texto(tester), 'A punto de empezar');
      expect(temporizador.cancelado, isTrue);
    });

    testWidgets(
      'el temporizador se para con la app en segundo plano, con otra pantalla encima y al salir',
      (tester) async {
        pantalla(tester);
        ahora = DateTime.utc(2026, 11, 14, 13);
        final temporizadores = <_TemporizadorFalso>[];
        final navegador = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          cuenta(
            navegador: navegador,
            temporizador: (intervalo, alTic) {
              final t = _TemporizadorFalso(intervalo, alTic);
              temporizadores.add(t);
              return t;
            },
          ),
        );

        expect(temporizadores.last.cancelado, isFalse);

        // Segundo plano.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(temporizadores.last.cancelado, isTrue);

        // Al volver, otro temporizador (y se repinta con la hora de ahora).
        ahora = DateTime.utc(2026, 11, 14, 14);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(temporizadores, hasLength(2));
        expect(temporizadores.last.cancelado, isFalse);
        expect(texto(tester), 'Empieza en 3 h 0 min');

        // Otra pantalla encima.
        unawaited(
          navegador.currentState!.push(
            MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        );
        await tester.pumpAndSettle();
        expect(temporizadores.last.cancelado, isTrue);

        navegador.currentState!.pop();
        await tester.pumpAndSettle();
        expect(temporizadores, hasLength(3));
        expect(temporizadores.last.cancelado, isFalse);

        // Al salir.
        await tester.pumpWidget(const SizedBox());
        expect(temporizadores.last.cancelado, isTrue);
      },
    );
  });
}

class _TemporizadorFalso implements Timer {
  final Duration intervalo;
  final void Function(Timer) alTic;
  bool cancelado = false;
  int _tics = 0;

  _TemporizadorFalso(this.intervalo, this.alTic);

  void tic() {
    _tics++;
    alTic(this);
  }

  @override
  void cancel() => cancelado = true;

  @override
  bool get isActive => !cancelado;

  @override
  int get tick => _tics;
}
